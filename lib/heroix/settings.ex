defmodule Heroix.Settings do
  use GenServer
  require Logger

  alias Heroix.Legendary

  # @pubsub_topic "settings"

  def legendary_game_config(app_name) do
    GenServer.call(Settings, {:legendary_game_config, app_name})
  end

  def set_legendary_game_config(app_name, key, value, save) do
    GenServer.call(Settings, {:set_legendary_game_config, app_name, key, value, save})
  end

  def set_legendary_game_env(app_name, key, value, save) do
    GenServer.call(Settings, {:set_legendary_game_config, app_name, {"env", key}, value, save})
  end

  def set_legendary_config(key, value, save) do
    GenServer.call(Settings, {:set_legendary_config, key, value, save})
  end

  def set_default_config(key, value, save) do
    GenServer.call(Settings, {:set_legendary_game_config, "default", key, value, save})
  end

  def set_global_config(key, value, save) do
    GenServer.call(Settings, {:set_global, key, value, save})
  end

  def global, do: GenServer.call(Settings, :global_settings)
  def legendary, do: GenServer.call(Settings, :legendary_config)
  def defaults, do: GenServer.call(Settings, :default_config)

  def save_global, do: GenServer.cast(Settings, :save_global)
  def save_legendary_config, do: GenServer.cast(Settings, :save_legendary_config)

  def start_link(options) do
    log("GenServer starting")
    GenServer.start_link(__MODULE__, [], options)
  end

  def init([]) do
    log("GenServer started")

    state = initial_state()
    global = Map.merge(state.global, read_global_settings())
    legendary = Heroix.Legendary.read_config()
    state = Map.merge(initial_state(), %{global: global, legendary: legendary})

    {:ok, state}
  end

  def handle_call(:global_settings, _from, state = %{global: global_settings}) do
    {:reply, global_settings, state}
  end

  def handle_call(:legendary_config, _from, state = %{legendary: legendary_config}) do
    {:reply, legendary_config["Legendary"], state}
  end

  def handle_call(:default_config, _from, state = %{legendary: legendary_config}) do
    {:reply, legendary_config["default"], state}
  end

  def handle_call({:legendary_game_config, app_name}, _from, state) do
    %{legendary: legendary_settings} = state

    app_settings =
      case Map.fetch(legendary_settings, app_name) do
        {:ok, value} -> value
        _ -> %{}
      end

    {:reply, app_settings, state}
  end

  def handle_call({:set_legendary_game_config, app_name, key, value, save}, _from, state) do
    %{legendary: legendary_config} = state
    app_config = legendary_config[app_name] || %{}

    new_app_config =
      case key do
        {"env", config_key} ->
          env = app_config["env"] || %{}
          new_env = Map.put(env, config_key, value)
          Map.put(app_config, "env", new_env)

        _ ->
          Map.put(app_config, key, value)
      end

    new_legendary_config = Map.put(legendary_config, app_name, new_app_config)
    new_state = Map.put(state, :legendary, new_legendary_config)

    if save, do: Heroix.Legendary.write_config(new_legendary_config)

    {:reply, new_app_config, new_state}
  end

  def handle_call({:set_global, key, value, save}, _from, state) do
    %{global: global_settings} = state

    new_global = Map.put(global_settings, key, value)
    new_state = Map.put(state, :global, new_global)

    if save, do: write_global_settings(new_global)

    {:reply, new_global, new_state}
  end

  def handle_call({:set_legendary_config, key, value, save}, _from, state) do
    %{legendary: legendary_config} = state

    new_legendary_config = Map.put(legendary_config["Legendary"], key, value)
    new_legendary = Map.put(legendary_config, "Legendary", new_legendary_config)
    new_state = Map.put(state, :legendary, new_legendary)

    IO.inspect(new_legendary_config)
    IO.inspect(new_legendary)
    IO.inspect(new_state)

    if save, do: Legendary.write_config(new_legendary)

    {:reply, new_legendary_config, new_state}
  end

  def handle_cast(:save_global, state = %{global: global_settings}) do
    write_global_settings(global_settings)

    {:noreply, state}
  end

  def handle_cast(:save_legendary_config, state = %{legendary: legendary_config}) do
    Heroix.Legendary.write_config(legendary_config)

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
      },
      legendary: %{}
    }
  end

  defp read_global_settings() do
    case Heroix.get_json(global_settings_path()) do
      {:ok, json} -> json
      {:error, _} -> %{}
    end
  end

  defp write_global_settings(global_settings) do
    {:ok, json_string} = Jason.encode(global_settings, pretty: true)
    File.write!(global_settings_path(), json_string)
  end

  defp global_settings_path() do
    path = Path.join([Application.fetch_env!(:heroix, :heroix_config_path), "settings"])
    unless File.exists?(path), do: File.mkdir_p(path)
    Path.join(path, "global.json")
  end
end
