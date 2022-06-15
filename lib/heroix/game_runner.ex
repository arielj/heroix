defmodule Heroix.GameRunner do
  use GenServer
  use HeroixLog, "GameRunner"

  @topic "game_status"
  @binary Application.fetch_env!(:heroix, :legendary_bin_wrapper)

  def running_game(), do: GenServer.call(GameRunner, :game_running)
  def launch_game(app_name), do: GenServer.cast(GameRunner, {:launch, app_name})
  def stop_game(), do: GenServer.cast(GameRunner, :stop)
  def reset(), do: GenServer.call(GameInstaller, :reset)

  def start_link(options) do
    log("GenServer starting")
    GenServer.start_link(__MODULE__, [], options)
  end

  def init([]) do
    log("GenServer started")
    {:ok, initial_state()}
  end

  def handle_cast({:launch, app_name}, state) do
    args = ["launch", app_name]
    log("Launching game with: #{Enum.join(args, " ")}")

    {:ok, pid, osPid} = @binary.run(args)
    log("Running in pid: #{Heroix.pid_to_string(pid)} (OS pid: #{osPid})")

    state =
      Map.merge(state, %{
        app_name: app_name,
        args: args,
        legendary_pid: pid
      })

    HeroixWeb.Endpoint.broadcast!(@topic, "launched", %{app_name: app_name})

    {:noreply, state}
  end

  def handle_cast(:stop, state) do
    %{game_pid: game_pid, legendary_pid: legendary_pid, app_name: app_name} = state

    if legendary_pid do
      log("Stopping legendary before game launched")

      @binary.kill(legendary_pid)
    else
      log("Stopping #{app_name} (OS pid: #{game_pid})")

      @binary.kill(game_pid)
    end

    {:noreply, state}
  end

  def handle_call(:game_running, _from, state = %{app_name: app_name}) do
    {:reply, app_name, state}
  end

  def handle_call(:reset, _from, _), do: {:reply, nil, initial_state()}

  def handle_info({std, _pid, msg}, state) when std in [:stderr, :stdout] do
    log("[Legendary] #{msg}")

    {:noreply, state}
  end

  # search for the game's OS PID after legendary process ends
  def handle_info(msg = {:DOWN, os_pid, :process, pid, :normal}, state) do
    %{app_name: app_name, legendary_pid: legendary_pid, game_pid: game_pid} = state

    cond do
      pid == legendary_pid ->
        case find_game_pid(app_name) do
          1 ->
            log("Legendary stopped before launching the game")

            HeroixWeb.Endpoint.broadcast(@topic, "stopped", %{app_name: app_name})

            {:noreply, Map.put(state, :legendary_pid, nil)}

          game_pid ->
            log("Legendary launched the game in process: #{game_pid}")

            # monitor OS process
            :exec.manage(game_pid, [:stderr, :stdout, :monitor])

            {:noreply, Map.merge(state, %{game_pid: game_pid, legendary_pid: nil})}
        end

      os_pid == game_pid ->
        log("Game stopped")
        HeroixWeb.Endpoint.broadcast(@topic, "stopped", %{app_name: app_name})

        {:noreply, Map.put(state, :game_pid, nil)}

      true ->
        log("Unknown process DOWN #{inspect(msg)}")
        {:noreply, state}
    end
  end

  # updates state after game process ends
  def handle_info(msg = {:DOWN, os_pid, :process, _pid, {:exit_status, exit_status}}, state) do
    %{game_pid: game_pid, app_name: app_name} = state

    # update the state with this PID
    if os_pid == game_pid do
      log("Game finished with status: #{exit_status}")
      HeroixWeb.Endpoint.broadcast(@topic, "stopped", %{app_name: app_name})
      {:noreply, initial_state()}
    else
      log("Unknown process DOWN #{msg}")
      {:noreply, state}
    end
  end

  def handle_info(msg, state) do
    log("Unhandled message: #{inspect(msg)}")
    {:noreply, state}
  end

  defp initial_state() do
    %{
      app_name: nil,
      args: [],
      game_pid: nil,
      legendary_pid: nil
    }
  end

  # find the game's PID using the `ps` command
  defp find_game_pid(app_name) do
    {output, 0} = System.cmd("ps", ["x"])

    {pid, _} =
      find_game_line(output, app_name)
      |> extract_pid()
      |> Integer.parse()

    pid
  end

  # find line in `ps` output
  defp find_game_line(output, app_name) do
    output
    |> String.split("\n")
    |> Enum.filter(fn line -> line =~ ~r/-epicapp=#{app_name}/ end)
    |> List.first() || "1"
  end

  defp extract_pid(line) do
    Regex.split(~r/\s/, line, trim: true)
    |> List.first()
  end
end
