defmodule Heroix.GameInstaller do
  use GenServer
  require Logger

  alias Heroix.Legendary

  @topic "game_installer"

  # execute actions and get state
  def install_game(app_name), do: GenServer.cast(GameInstaller, {:install, app_name})
  def update_game(app_name), do: GenServer.cast(GameInstaller, {:update, app_name})
  def uninstall_game(app_name), do: GenServer.cast(GameInstaller, {:uninstall, app_name})
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
    pid = install(app_name, state)

    HeroixWeb.Endpoint.broadcast!(@topic, "installing_game", %{app_name: app_name})

    {:noreply, Map.merge(state, %{installing: app_name, installing_pid: pid})}
  end

  # if something is being installed, enqueue app_name
  def handle_cast({:install, app_name}, state = %{installing: installing_app_name}) do
    log("Installation in progress (#{installing_app_name}), enqueuing.")

    state = Map.put(state, :queue, state.queue ++ [app_name])

    {:noreply, state}
  end

  # stop the current installation in progress
  def handle_cast(:stop, state = %{installing_pid: pid, installing: installing_app_name}) do
    log("Stop installation of #{installing_app_name}")

    :exec.kill(pid, :sigkill)

    {:noreply, state}
  end

  # uninstall app_name
  def handle_cast({:uninstall, app_name}, state) do
    pid = uninstall(app_name, state)

    HeroixWeb.Endpoint.broadcast!(@topic, "uninstalling_game", %{app_name: app_name})

    {:noreply, Map.merge(state, %{uninstalling: app_name, uninstalling_pid: pid})}
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
    %{installing: stopped_app_name, queue: queue} = state

    HeroixWeb.Endpoint.broadcast!(@topic, "installation_stopped", %{app_name: stopped_app_name})

    # remove game from queue
    new_queue = Enum.reject(queue, fn name -> name == stopped_app_name end)

    # update state
    new_state =
      Map.merge(state, %{
        queue: new_queue,
        installing_pid: nil,
        installing: nil
      })

    {:noreply, new_state}
  end

  # when legendary command ends normally
  def handle_info(msg = {:DOWN, _os_pid, :process, pid, :normal}, state) do
    %{
      installing: installing_app_name,
      queue: queue,
      installing_pid: installing_pid,
      uninstalling_pid: uninstalling_pid,
      uninstalling: uninstalling_app_name
    } = state

    # check if pid matches an installation or uninstallation pid
    cond do
      pid == installing_pid ->
        log("Installation completed")

        # remove game from queue
        new_queue = Enum.reject(queue, fn name -> name == installing_app_name end)

        # update state
        new_state =
          Map.merge(state, %{
            queue: new_queue,
            installing_pid: nil,
            installing: nil
          })

        # noreply and then broadcast installed
        {:noreply, new_state, {:continue, {:broadcast_installed, installing_app_name}}}

      pid == uninstalling_pid ->
        log("Uninstall completed")

        # update state
        new_state = Map.merge(state, %{uninstalling_pid: nil, uninstalling: nil})

        # noreply and then broadcast uninstalled
        {:noreply, new_state, {:continue, {:broadcast_uninstalled, uninstalling_app_name}}}

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

  # broadcast installed game and then check queue to continue installing
  def handle_continue({:broadcast_installed, app_name}, state) do
    HeroixWeb.Endpoint.broadcast!(@topic, "game_installed", %{app_name: app_name})

    {:noreply, state, {:continue, :check_queue}}
  end

  # broadcast uninstalled game
  def handle_continue({:broadcast_uninstalled, app_name}, state) do
    HeroixWeb.Endpoint.broadcast!(@topic, "game_uninstalled", %{app_name: app_name})

    {:noreply, state}
  end

  # check if queue has something to install
  def handle_continue(:check_queue, state = %{queue: queue}) do
    log("Checking install queue")
    # trigger installation of next game in queue
    if length(queue) > 0 do
      # install_game(hd(queue))
      log("Should install #{hd(queue)}")
    end

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
      uninstalling: nil,
      uninstalling_pid: nil,
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

  # run legendary uninstall app, monitor process and return pid
  defp uninstall(app_name, %{path: path}) do
    args = ["-y", "uninstall", app_name]
    log("Uninstalling: #{app_name}")

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
