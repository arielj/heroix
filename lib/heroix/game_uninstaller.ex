defmodule Heroix.GameUninstaller do
  use GenServer
  require Logger

  @binary Application.fetch_env!(:heroix, :legendary_bin_wrapper)
  @topic "game_status"

  # execute actions and get state
  def uninstall_game(app_name), do: GenServer.cast(GameUninstaller, {:uninstall, app_name})
  def reset(), do: GenServer.call(GameInstaller, :reset)

  def start_link(options) do
    log("GenServer starting")
    GenServer.start_link(__MODULE__, [], options)
  end

  def init([]) do
    log("GenServer started")
    {:ok, initial_state()}
  end

  #### Trigger an async action, don't wait for result

  # uninstall app_name
  def handle_cast({:uninstall, app_name}, state) do
    pid = uninstall(app_name)

    new_state = Map.merge(state, %{uninstalling: app_name, uninstalling_pid: pid})

    HeroixWeb.Endpoint.broadcast!(@topic, "uninstalling", %{app_name: app_name})

    {:noreply, new_state}
  end

  #### Handle info messages sent by the legendary commands

  # process legendary process output
  def handle_info({std, _pid, msg}, state) when std in [:stdout, :stderr] do
    log("[Legendary] #{msg}")

    {:noreply, state}
  end

  # when legendary command ends normally
  def handle_info(msg = {:DOWN, _os_pid, :process, pid, :normal}, state) do
    %{
      uninstalling_pid: uninstalling_pid,
      uninstalling: uninstalling_app_name
    } = state

    # check if pid matches an installation or uninstallation pid
    cond do
      pid == uninstalling_pid ->
        log("Uninstall completed")

        new_state = Map.merge(state, %{uninstalling_pid: nil, uninstalling: nil})

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

  def handle_call(:reset, _from, _), do: {:reply, nil, initial_state()}

  #### Actions to perform after main commands

  # broadcast uninstalled game
  def handle_continue({:broadcast_uninstalled, app_name}, state) do
    HeroixWeb.Endpoint.broadcast!(@topic, "uninstalled", %{app_name: app_name})

    {:noreply, state}
  end

  #### Some helper function

  defp log(msg) do
    Logger.info("[GameUninstaller] #{String.trim(msg)}")
  end

  defp initial_state() do
    %{
      uninstalling: nil,
      uninstalling_pid: nil
    }
  end

  # run legendary uninstall app, monitor process and return pid
  defp uninstall(app_name) do
    args = ["-y", "uninstall", app_name]
    log("Uninstalling: #{app_name}")

    {:ok, pid, osPid} = @binary.run(args)
    log("Running in pid: #{Heroix.pid_to_string(pid)} (OS pid: #{osPid})")

    pid
  end
end
