defmodule Heroix.GameInstaller do
  use GenServer
  use HeroixLog, "GameInstaller"

  @binary Application.fetch_env!(:heroix, :legendary_bin_wrapper)

  @topic "game_status"
  # @sdl_api "https://api.legendary.gl/v1/sdl/#{Fortnite}.json"

  # execute actions and get state
  def install_game(app_name, opts),
    do: GenServer.cast(GameInstaller, {:install, app_name, opts})

  def update_game(app_name), do: GenServer.cast(GameInstaller, {:update, app_name})
  def stop_installation(), do: GenServer.cast(GameInstaller, :stop)

  def fetch_install_info(app_name),
    do: GenServer.cast(GameInstaller, {:fetch_install_info, app_name})

  def fetch_download_info(app_name, base_path),
    do: GenServer.cast(GameInstaller, {:fetch_download_info, app_name, base_path})

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
    case state.install_info[app_name] do
      nil ->
        Task.Supervisor.async_nolink(Task.MySupervisor, fn ->
          install_info = Heroix.Legendary.game_install_info(app_name)

          HeroixWeb.Endpoint.broadcast!(@topic, "install_info_ready", %{
            app_name: app_name,
            install_info: install_info
          })

          {:install_info_ready, app_name, install_info}
        end)

      install_info ->
        HeroixWeb.Endpoint.broadcast!(@topic, "install_info_ready", %{
          app_name: app_name,
          install_info: install_info
        })
    end

    {:noreply, state}
  end

  def handle_cast({:fetch_download_info, app_name, base_path}, state) do
    Task.Supervisor.async_nolink(Task.MySupervisor, fn ->
      download_info = Heroix.Legendary.game_download_info(app_name, base_path)

      HeroixWeb.Endpoint.broadcast!(@topic, "download_info_ready", %{
        app_name: app_name,
        download_info: download_info
      })

      {:download_info_ready}
    end)

    {:noreply, state}
  end

  #### Handle info messages sent by the legendary commands

  # process legendary output
  def handle_info({std, pid, msg}, state) when std in [:stdout, :stderr] do
    log("[Legendary] (#{pid}) #{msg}")

    %{installing: app_name, install_progress: install_progress} = state

    # Download size: 7920.80 MiB (Compression savings: 6.1%)
    # Progress: 99.50% (596/599), Running for 00:00:24, ETA: 00:00:00
    # Downloaded: 390.03 MiB, Written: 1157.98 MiB
    new_state =
      case Regex.run(
             ~r/(Download size): (.*) \(Compression|(Progress).*, ETA: (\d\d:\d\d:\d\d)|(Downloaded): (.*), Written/,
             msg
           ) do
        nil ->
          state

        [_match, "Download size", to_download] ->
          # find how much has to be downloaded and compare with total download size
          total_to_download = state.install_info[app_name]["manifest"]["download_size"]

          [value, unit] = String.split(to_download, " ")

          to_download = Heroix.human_to_bytes(value, unit)

          new_install_progress =
            Map.merge(install_progress, %{
              total_size: total_to_download,
              to_download: to_download,
              reusable: total_to_download - to_download
            })

          Map.put(state, :install_progress, new_install_progress)

        [_match, "", "", "Progress", eta] ->
          # find the ETA
          new_install_progress = Map.merge(install_progress, %{eta: eta})

          Map.put(state, :install_progress, new_install_progress)

        [_match, "", "", "", "", "Downloaded", downloaded] ->
          # find how much was downloaded, add reusable files and calculate %
          [value, unit] = String.split(downloaded, " ")

          total_downloaded = install_progress.reusable + Heroix.human_to_bytes(value, unit)

          percent = "#{Float.round(100 * total_downloaded / install_progress.total_size, 2)}%"

          new_install_progress =
            Map.merge(install_progress, %{
              downloaded: total_downloaded,
              percent: percent
            })

          HeroixWeb.Endpoint.broadcast!(@topic, "installation_progress", %{
            app_name: app_name,
            progress: new_install_progress
          })

          Map.put(state, :install_progress, new_install_progress)
      end

    {:noreply, new_state}
  end

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
  def handle_info({_ref, {:install_info_ready, app_name, install_info}}, state) do
    new_install_info = Map.put(state.install_info, app_name, install_info)
    new_state = Map.put(state, :install_info, new_install_info)

    {:noreply, new_state}
  end

  def handle_info({_ref, {:download_info_ready}}, state) do
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

  defp initial_state() do
    %{
      installing: nil,
      installing_pid: nil,
      stopped: nil,
      queue: [],
      install_info: %{},
      install_progress: %{total_size: 0, to_download: 0, downloaded: 0, percent: "0%", eta: "--"}
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
end
