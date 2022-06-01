defmodule Heroix.Settings do
  use GenServer
  require Logger

  # @pubsub_topic "settings"

  def start_link(options) do
    log("GenServer starting")
    GenServer.start_link(__MODULE__, [], options)
  end

  def init([]) do
    log("GenServer started")

    state = initial_state()
    global = Map.merge(state.global, read_global_settings())
    state = Map.put(initial_state(), :global, global)

    {:ok, state}
  end

  def handle_call(:global, _from, state = %{global: global_settings}) do
    {:reply, global_settings, state}
  end

  def handle_call({:set_global, key, value, save: save}, _from, state) do
    %{global: global_settings} = state

    new_global = Map.put(global_settings, key, value)
    state = Map.put(state, :global, new_global)

    if save, do: write_global_settings(new_global)

    {:reply, new_global, state}
  end

  def handle_cast(:save_global, state = %{global: global_settings}) do
    write_global_settings(global_settings)

    {:noreply, state}
  end

  def handle_info(msg, state) do
    log("Unhandled message: #{inspect(msg)}")
    {:noreply, state}
  end

  def log(msg) do
    Logger.info("[Settings] #{String.trim(msg)}")
  end

  defp initial_state() do
    %{
      global: %{
        "language" => "en",
        "default_install_path" => ""
      }
    }
  end

  defp read_global_settings() do
    case Heroix.get_json(global_settings_path()) do
      {:ok, json} -> json
      {:error, _} -> %{}
    end
  end

  defp write_global_settings(global_settings) do
    {:ok, json_string} = Jason.encode(global_settings)
    File.write!(global_settings_path(), json_string)
  end

  defp global_settings_path() do
    path = Path.join([Application.fetch_env!(:heroix, :heroix_config_path), "settings"])
    unless File.exists?(path), do: File.mkdir_p(path)
    Path.join(path, "global.json")
  end
end
