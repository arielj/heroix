defmodule Heroix.GameInstaller do
  use GenServer
  require Logger

  @binary Application.fetch_env!(:heroix, :legendary_bin_wrapper)

  @topic "game_status"

  # execute actions and get state
  def install_game(app_name, opts),
    do: GenServer.cast(GameInstaller, {:install, app_name, opts})

  def update_game(app_name), do: GenServer.cast(GameInstaller, {:update, app_name})
  def stop_installation(), do: GenServer.cast(GameInstaller, :stop)

  def fetch_install_info(app_name),
    do: GenServer.cast(GameInstaller, {:fetch_install_info, app_name})

  def reset(), do: GenServer.call(GameInstaller, :reset)
  def installing(), do: GenServer.call(GameInstaller, :installing)
  def queue(), do: GenServer.call(GameInstaller, :queue)

  def start_link(options) do
    log("GenServer starting")
    GenServer.start_link(__MODULE__, [], options)
  end

  def init([]) do
    log("GenServer started")
    {:ok, initial_state()}
  end

  #### Trigger an async action, don't wait for result

  # if nothing is being installed, start installing app_name
  def handle_cast({:install, app_name, opts}, state = %{installing: nil}) do
    pid = install(app_name, opts)
    log("Install #{app_name} in pid #{Heroix.pid_to_string(pid)}")

    new_state = Map.merge(state, %{installing: app_name, installing_pid: pid})

    HeroixWeb.Endpoint.broadcast!(@topic, "installing", %{app_name: app_name})

    {:noreply, new_state}
  end

  # if something is being installed, enqueue app_name
  def handle_cast({:install, app_name, opts}, state = %{installing: installing_app_name}) do
    log("Installation in progress (#{installing_app_name}), enqueuing.")

    state = Map.put(state, :queue, state.queue ++ [%{app_name: app_name, opts: opts}])

    HeroixWeb.Endpoint.broadcast!(@topic, "enqueued", %{app_name: app_name})

    {:noreply, state}
  end

  # stop the current installation in progress
  def handle_cast(:stop, state = %{installing_pid: pid, installing: app_name}) do
    log("Stopping installation of #{app_name}")

    @binary.kill(pid)

    {:noreply, Map.merge(state, %{stopping: app_name})}
  end

  def handle_cast({:fetch_install_info, app_name}, state) do
    Task.Supervisor.async_nolink(Task.MySupervisor, fn ->
      install_info = Heroix.Legendary.game_install_info(app_name)

      HeroixWeb.Endpoint.broadcast!(@topic, "install_info_ready", %{
        app_name: app_name,
        install_info: install_info
      })

      {:install_info_ready}
    end)

    {:noreply, state}
  end

  #### Handle info messages sent by the legendary commands

  # process legendary output
  def handle_info({std, pid, msg}, state) when std in [:stdout, :stderr] do
    log("[Legendary] (#{pid}) #{msg}")

    %{installing: app_name} = state
    process_progress(msg, app_name)

    {:noreply, state}
  end

  # # when the installation is stopped by an exception in Legendary
  # def handle_info({:DOWN, _os_pid, :process, _pid, {:exit_status, 256}}, state) do
  #   %{installing: stopped_app_name} = state

  #   IO.inspect("Error installing game, check logs")

  #   {:noreply, state, {:continue, {:remove_from_queue, stopped_app_name}}}
  # end

  # the fetch install info task is terminated, do nothing
  def handle_info({:DOWN, ref, :process, _pid, :normal}, state) when is_reference(ref) do
    {:noreply, state}
  end

  # when legendary command ends
  def handle_info(msg = {:DOWN, _os_pid, :process, pid, :normal}, state) do
    %{
      installing: installing_app_name,
      installing_pid: installing_pid,
      stopped: stopping_app_name
    } = state

    # check if the installation was stopped or completed
    cond do
      installing_app_name && installing_app_name == stopping_app_name ->
        log("Installation of #{stopping_app_name} stopped by the user")

        new_state = Map.merge(state, %{installing_pid: nil, installing: nil, stopped: nil})

        HeroixWeb.Endpoint.broadcast!(@topic, "installation_stopped", %{
          app_name: stopping_app_name
        })

        {:noreply, new_state, {:continue, {:remove_from_queue, stopping_app_name}}}

      installing_pid && pid == installing_pid ->
        log("Installation completed")

        new_state = Map.merge(state, %{installing_pid: nil, installing: nil})

        HeroixWeb.Endpoint.broadcast!(@topic, "installed", %{app_name: installing_app_name})

        {:noreply, new_state, {:continue, {:remove_from_queue, installing_app_name}}}

      true ->
        log("Unknown process DOWN #{inspect(msg)}")
        {:noreply, state}
    end
  end

  # fetch install info async task finished, do nothing
  def handle_info({_ref, {:install_info_ready}}, state) do
    {:noreply, state}
  end

  def handle_info(msg, state) do
    log("Unhandled message: #{inspect(msg)}")
    {:noreply, state}
  end

  #### Actions to perform after main commands

  def handle_continue({:remove_from_queue, app_name}, state = %{queue: queue}) do
    log("Removing game from queue")

    new_queue = Enum.reject(queue, fn queue_item -> queue_item.app_name == app_name end)

    {:noreply, Map.merge(state, %{queue: new_queue}), {:continue, :check_queue}}
  end

  def handle_continue(:check_queue, state = %{queue: queue}) do
    log("Checking install queue")

    if length(queue) > 0 do
      [app_to_install | new_queue] = queue
      app_name_to_install = app_to_install.app_name
      opts_to_install = app_to_install.opts

      {:noreply, Map.merge(state, %{queue: new_queue}),
       {:continue, {:install, app_name_to_install, opts_to_install}}}
    else
      {:noreply, state}
    end
  end

  def handle_continue({:install, nil}, state), do: {:noreply, state}

  def handle_continue({:install, app_to_install, opts}, state) do
    install_game(app_to_install, opts)
    # log("Should install #{app_to_install}")
    {:noreply, state}
  end

  #### Sync functions, return some data to caller

  # return name of the current game being installed
  def handle_call(:installing, _from, state = %{installing: app_name}) do
    {:reply, app_name, state}
  end

  # return the list of all games in the install queue
  def handle_call(:queue, _from, state = %{queue: queue}), do: {:reply, queue, state}

  def handle_call(:reset, _from, _), do: {:reply, nil, initial_state()}

  #### Some helper function

  defp log(msg) do
    Logger.info("[GameInstaller] #{String.trim(msg)}")
  end

  defp initial_state() do
    %{
      installing: nil,
      installing_pid: nil,
      stopped: nil,
      queue: []
    }
  end

  # run legendary install app, monitor process and return pid
  defp install(app_name, opts) do
    args = if opts["install_path"], do: ["--base-path", opts["install_path"]], else: []

    log("Installing: #{app_name} (args: #{args}")

    {:ok, pid, osPid} = @binary.install(app_name, args)
    log("Running in pid: #{Heroix.pid_to_string(pid)} (OS pid: #{osPid})")

    pid
  end

  # process log entry, extract installation progress and broadcast
  defp process_progress(msg, app_name) do
    # Progress: 99.50% (596/599), Running for 00:00:24, ETA: 00:00:00
    case Regex.run(~r/Progress: (\d+\.\d+)% .*, ETA: (\d\d:\d\d:\d\d)/, msg) do
      nil ->
        nil

      [_match, percent, eta] ->
        HeroixWeb.Endpoint.broadcast!(@topic, "installation_progress", %{
          app_name: app_name,
          percent: percent,
          eta: eta
        })
    end
  end
end
