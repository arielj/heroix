defmodule GameRunner do
  use GenServer
  require Logger

  def start_link(app_name, options) do
    GenServer.start_link(__MODULE__, app_name, options)
  end

  def init(app_name) do
    # initialize state
    state = %{
      app_name: app_name,
      path: Heroix.legendary_bin(),
      args: ["launch", app_name],
      game_pid: nil
    }

    {:ok, state, {:continue, :launch_game}}
  end

  # execute the legendary command and monitor the process
  def handle_continue(:launch_game, state = %{path: path, args: args}) do
    :exec.start_link([]) # :exec.start_link([:debug])
    Logger.info "[GameRunner] Launching game: #{path} #{args}"
    {:ok, pid, osPid} = :exec.run([path | args], [:stdout, :stderr, :monitor])
    Logger.info "[GameRunner] Running in #{pid_to_string(pid)} #{osPid}"

    {:noreply, state}
  end

  def handle_call(:stop, _from, state = %{game_pid: game_pid}) do
    Logger.info "[GameRunner] Stopping pid #{game_pid}"
    System.cmd("kill", ["-9", game_pid])
    {:stop, :shutdown, state}
  end

  def handle_info({:stderr, _pid, msg}, state) do
    Logger.info "[Legendary] #{msg}"
    {:noreply, state}
  end

  def handle_info({:stdout, _pid, msg}, state) do
    Logger.info "[Legendary] #{msg}"
    {:noreply, state}
  end

  # search for the game's actual PID after legendary process ends
  def handle_info({:DOWN, _osPid, :process, _pid, :normal}, state = %{app_name: app_name}) do
    Logger.info "[GameRunner] Legendary launched the game"
    game_pid = find_game_pid(app_name)
    Logger.info "[GameRunner] In process: #{game_pid}"

    # update the state with this PID
    {:noreply, Map.put(state, :game_pid, game_pid)}
  end

  def handle_info(msg, state) do
    Logger.info "Unhandled message: #{inspect msg}"
    {:noreply, state}
  end

  # find the game's PID using the `ps` command
  defp find_game_pid(app_name) do
    {output, 0} = System.cmd("ps", ["x"])
    find_game_line(output, app_name)
    |> extract_pid()
  end

  # find line in `ps` output
  defp find_game_line(output, app_name) do
    output
    |> String.split("\n")
    |> Enum.filter(fn line -> line =~ ~r/-epicapp=#{app_name}/ end)
    |> List.first()
  end

  defp extract_pid(line) do
    Regex.split(~r/\s/, line, [trim: true])
    |> List.first()
  end

  # Converts Elixir pid (not OS pid) to string
  defp pid_to_string(pid) do
    pid |> :erlang.pid_to_list() |> to_string()
  end
end
