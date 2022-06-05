defmodule HeroixWeb.GameConfigComponent do
  use HeroixWeb, :live_component

  alias Heroix.Settings

  # ; (all) wrapper to run the game with (e.g. "gamemode")
  # wrapper = gamemode
  # ; (linux/macOS) Wine executable and prefix
  # wine_executable = wine
  # wine_prefix = /home/user/.wine
  # ; (macOS) CrossOver options
  # crossover_app = /Applications/CrossOver.app
  # crossover_bottle = Legendary
  # ; launch game without online authentication by default
  # offline = true
  # ; Skip checking for updates when launching this game
  # skip_update_check = true
  # ; start parameters to use (in addition to the required ones)
  # start_params = -windowed
  # ; override language with two-letter language code
  # language = fr
  # ; Do not run this executable with WINE (e.g. when the wrapper handles that)
  # no_wine = true
  # ; Override the executable launched for this game, for example to bypass a launcher (e.g. Borderlands)
  # override_exe = relative/path/to/file.exe
  # ; Disable selective downloading for this title
  # disable_sdl = true
  # ; Command to run before launching the gmae
  # pre_launch_command = /path/to/script.sh
  # ; Whether or not to wait for command to finish running
  # pre_launch_wait = false

  @save_on_change ["wrapper"]

  def update(assigns, socket) do
    {:ok,
     assign(socket,
       app_name: assigns.app_name,
       default: Settings.legendary_game_config(:default),
       config: Settings.legendary_game_config(assigns.app_name)
     )}
  end

  def render(assigns) do
    default_language = assigns.default["language"] || "System language"

    ~H"""
    <div id="game-config">
      <form phx-change="config-changed" phx-target={@myself}>
        <div class="form-field checkbox-field">
          <label for="wrapper"><%= gettext("Use gamemode wrapper?") %></label>
          <input id="wrapper" name="wrapper" type="checkbox" checked={@config["wrapper"] == "gamemode"} />
        </div>

        <div class="form-field text-field">
          <label for="language"><%= gettext("Game Language") %></label>
          <input id="language" name="language" type="text" value={@config["language"]} phx-blur="blur" phx-target={@myself}>
          <p class="hint">
            Note that some games may not supports setting the specified language from outside the game.
            <br />
            Defaults to: <%= default_language %>
          </p>
        </div>

        <div class="form-field text-field">
          <label for="wine_executable"><%= gettext("Wine Executable") %></label>
          <input id="wine_executable" name="wine_executable" type="text" value={@config["wine_executable"]} phx-blur="blur" phx-target={@myself}>
          <p class="hint">
            Absolute path to the Wine executable that will be used to launch the game.
            <br />
            Defaults to: <%= @default["wine_executable"] || "No Wine" %>
          </p>
        </div>

        <div class="form-field text-field">
          <label for="wine_prefix"><%= gettext("Wine Prefix") %></label>
          <input id="wine_prefix" name="wine_prefix" type="text" value={@config["wine_prefix"]} phx-blur="blur" phx-target={@myself}>
          <p class="hint">
            Absolute path to the WinePrefix folder that will be used to launch the game.
            <br />
            Defaults to: <%= @default["wine_prefix"] || "No Wine Prefix" %>
          </p>
        </div>
      </form>
    </div>
    """
  end

  # update global settings, save them immediately in some cases
  def handle_event("config-changed", data, socket) do
    app_name = socket.assigns.app_name
    key = List.first(data["_target"])
    value = data[key]

    config =
      Settings.set_legendary_game_config(app_name, key, value, Enum.member?(@save_on_change, key))

    {:noreply, assign(socket, :config, config)}
  end

  # save global settings when some fields are blured
  def handle_event("blur", _, socket) do
    Settings.save_legendary_config()
    {:noreply, socket}
  end
end
