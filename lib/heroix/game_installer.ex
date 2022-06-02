defmodule Heroix.GameInstaller do
  use GenServer
  require Logger

  alias Heroix.Legendary

  @topic "game_status"

  # execute actions and get state
  def install_game(app_name), do: GenServer.cast(GameInstaller, {:install, app_name})
  def update_game(app_name), do: GenServer.cast(GameInstaller, {:update, app_name})
  def stop_installation(), do: GenServer.cast(GameInstaller, :stop)
  def installing(), do: GenServer.call(GameInstaller, :installing)
  def queue(), do: GenServer.call(GameInstaller, :queue)

  def start_link(options) do
    log("GenServer starting")
    GenServer.start_link(__MODULE__, [], options)
  end

  def init([]) do
    log("GenServer started")
    # :exec.start_link([])
    :exec.start_link([:debug])
    {:ok, initial_state()}
  end

  #### Trigger an async action, don't wait for result

  # if nothing is being installed, install app_name
  def handle_cast({:install, app_name}, state = %{installing: nil}) do
    log("Install #{app_name}")

    pid = install(app_name, state)

    HeroixWeb.Endpoint.broadcast!(@topic, "installing", %{app_name: app_name})

    {:noreply, Map.merge(state, %{installing: app_name, installing_pid: pid})}
  end

  # if something is being installed, enqueue app_name
  def handle_cast({:install, app_name}, state = %{installing: installing_app_name}) do
    log("Installation in progress (#{installing_app_name}), enqueuing.")

    state = Map.put(state, :queue, state.queue ++ [app_name])

    HeroixWeb.Endpoint.broadcast!(@topic, "enqueued", %{app_name: app_name})

    {:noreply, state}
  end

  # stop the current installation in progress
  def handle_cast(:stop, state = %{installing_pid: pid, installing: installing_app_name}) do
    log("Stop installation of #{installing_app_name}")

    :exec.kill(pid, :sigkill)

    HeroixWeb.Endpoint.broadcast!(@topic, "installation_stopped", %{app_name: installing_app_name})

    {:noreply, Map.merge(state, %{installing: nil, installing_pid: nil}),
     {:continue, {:remove_from_queue, installing_app_name}}}
  end

  #### Handle info messages sent by the legendary commands

  # process legendary process output
  def handle_info({std, _pid, msg}, state) when std in [:stdout, :stderr] do
    log("[Legendary] #{msg}")

    %{installing: app_name} = state
    process_progress(msg, app_name)

    {:noreply, state}
  end

  # when installation is stopped by the user
  def handle_info({:DOWN, _os_pid, :process, _pid, {:exit_status, 9}}, state) do
    # %{installing: stopped_app_name} = state

    {:noreply, state}
  end

  # # when installation is stopped by an exception in Legendary
  # def handle_info({:DOWN, _os_pid, :process, _pid, {:exit_status, 256}}, state) do
  #   %{installing: stopped_app_name} = state

  #   IO.inspect("Error installing game, check logs")

  #   {:noreply, state, {:continue, {:remove_from_queue, stopped_app_name}}}
  # end

  # when legendary command ends normally
  def handle_info(msg = {:DOWN, _os_pid, :process, pid, :normal}, state) do
    %{
      installing: installing_app_name,
      installing_pid: installing_pid
    } = state

    # check if pid matches an installation or uninstallation pid
    cond do
      pid == installing_pid ->
        log("Installation completed")

        # update state
        new_state =
          Map.merge(state, %{
            installing_pid: nil,
            installing: nil
          })

        HeroixWeb.Endpoint.broadcast!(@topic, "installed", %{app_name: installing_app_name})

        # noreply and then broadcast installed
        {:noreply, new_state, {:continue, {:remove_from_queue, installing_app_name}}}

      true ->
        log("Unknown process DOWN #{inspect(msg)}")
        {:noreply, state}
    end
  end

  def handle_info(msg, state) do
    log("Unhandled message: #{inspect(msg)}")
    {:noreply, state}
  end

  #### Actions to perform after main commands

  def handle_continue({:remove_from_queue, app_name}, state = %{queue: queue}) do
    log("Removing game from queue")

    new_queue = Enum.reject(queue, fn name -> name == app_name end)

    {:noreply, Map.merge(state, %{queue: new_queue}), {:continue, :check_queue}}
  end

  def handle_continue(:check_queue, state = %{queue: queue}) do
    log("Checking install queue")

    if length(queue) > 0 do
      [app_to_install | new_queue] = queue
      {:noreply, Map.merge(state, %{queue: new_queue}), {:continue, {:install, app_to_install}}}
    else
      {:noreply, state}
    end
  end

  def handle_continue({:install, nil}, state), do: {:noreply, state}

  def handle_continue({:install, app_to_install}, state) do
    install_game(app_to_install)
    # log("Should install #{hd(queue)}")
    {:noreply, state}
  end

  #### Sync functions, return some data to caller

  # return name of the current game being installed
  def handle_call(:installing, _from, state = %{installing: app_name}) do
    {:reply, app_name, state}
  end

  # return the list of all games in the install queue
  def handle_call(:queue, _from, state = %{queue: queue}), do: {:reply, queue, state}

  #### Some helper function

  defp log(msg) do
    Logger.info("[GameInstaller] #{String.trim(msg)}")
  end

  defp initial_state() do
    %{
      path: Legendary.bin_path(),
      installing: nil,
      installing_pid: nil,
      queue: []
    }
  end

  # Converts Elixir pid (not OS pid) to string
  defp pid_to_string(pid) do
    pid |> :erlang.pid_to_list() |> to_string()
  end

  # run legendary install app, monitor process and return pid
  defp install(app_name, %{path: path}) do
    args = ["-y", "install", app_name]
    log("Installing: #{app_name}")

    {:ok, pid, osPid} = :exec.run([path | args], [:stdout, :stderr, :monitor])
    log("Running in pid: #{pid_to_string(pid)} (OS pid: #{osPid})")

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
