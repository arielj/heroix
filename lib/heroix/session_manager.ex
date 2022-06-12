defmodule Heroix.SessionManager do
  use GenServer
  require Logger

  @binary Application.fetch_env!(:heroix, :legendary_bin_wrapper)

  def current_user, do: GenServer.call(SessionManager, :current_user)

  def start_link(options) do
    log("GenServer starting")
    GenServer.start_link(__MODULE__, [], options)
  end

  def init([]) do
    log("GenServer started")
    {:ok, initial_state(), {:continue, :check_user}}
  end

  def log(msg) do
    Logger.info("[SessionManager] #{String.trim(msg)}")
  end

  def handle_continue(:check_user, state) do
    output =
      @binary.run(["status"], [:sync])
      |> extract_output()

    new_state =
      case Regex.run(~r/Epic account: (.*)\n/, output) do
        [_match, "<not logged in>"] ->
          log("No logged in")
          state

        [_match, user_name] ->
          log("logged as #{user_name}")

          HeroixWeb.Endpoint.broadcast("session", "current_user", %{user_name: user_name})

          Map.put(state, :current_user, user_name)

        _ ->
          state
      end

    {:noreply, new_state}
  end

  def handle_call(:current_user, _, state = %{current_user: current_user}) do
    {:reply, current_user, state}
  end

  defp extract_output({:ok, [stdout: [output]]}), do: output
  defp extract_output({:ok, [stdout: [output], stderr: _]}), do: output

  defp initial_state() do
    %{
      current_user: nil
    }
  end
end
