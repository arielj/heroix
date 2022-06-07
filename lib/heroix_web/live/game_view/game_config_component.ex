defmodule HeroixWeb.GameConfigComponent do
  use HeroixWeb, :live_component

  import HeroixWeb.FormComponents
  alias Heroix.Settings

  # ; (all) wrapper to run the game with (e.g. "gamemode")
  # wrapper = gamemode
  # ; (linux/macOS) Wine executable and prefix
  # wine_executable = wine
  # wine_prefix = /home/user/.wine
  # ; (macOS) CrossOver options
  # crossover_app = /Applications/CrossOver.app
  # crossover_bottle = Legendary
  # ; start parameters to use (in addition to the required ones)
  # start_params = -windowed
  # ; override language with two-letter language code
  # language = fr
  # ; Override the executable launched for this game, for example to bypass a launcher (e.g. Borderlands)
  # override_exe = relative/path/to/file.exe
  # ; Command to run before launching the gmae
  # pre_launch_command = /path/to/script.sh
  # ; launch game without online authentication by default
  # offline = true
  # ; Whether or not to wait for command to finish running
  # pre_launch_wait = false
  # ; Skip checking for updates when launching this game
  # skip_update_check = true
  # ; Do not run this executable with WINE (e.g. when the wrapper handles that)
  # no_wine = true
  # ; Disable selective downloading for this title
  # disable_sdl = true

  @save_on_change ["offline"]

  def update(assigns, socket) do
    {:ok,
     assign(socket,
       app_name: assigns.app_name,
       default: Settings.legendary_game_config(:default),
       config: Settings.legendary_game_config(assigns.app_name)
     )}
  end

  def render(assigns) do
    ~H"""
    <div id="game-config">
      <h2>Game Configuration</h2>
      <form phx-change="config-changed" phx-target={@myself}>
        <.config_text_field
          label={gettext("Game Language")}
          hint="Note that some games may not supports setting the specified language from outside the game."
          key="language"
          value={@config["language"]}
          default={@default["language"] || "System Language"}
          target={@myself}
        />

        <.config_text_field
          label={gettext("Wine Executable")}
          hint="Absolute path to the Wine executable that will be used to launch the game."
          key="wine_executable"
          value={@config["wine_executable"]}
          default={@default["wine_executable"] || "The `wine` command"}
          target={@myself}
        />

        <.config_text_field
          label={gettext("Wine Prefix")}
          hint="Absolute path to the WinePrefix folder that will be used to launch the game."
          key="wine_prefix"
          value={@config["wine_prefix"]}
          default={@default["wine_prefix"] || "No Wine Prefix"}
          target={@myself}
        />

        <.config_text_field
          label={gettext("Wrapper Executable")}
          hint={"Command or absolute path to a wrapper command that will be used to launch the game (i.e.: \"/usr/bin/gamemode\")."}
          key="wrapper"
          value={@config["wrapper"]}
          default={@default["wrapper"] || "No Wrapper"}
          target={@myself}
        />

        <.config_text_field
          label={gettext("Override Game Exe")}
          hint="Override the executable launched for this game, for example to bypass a launcher (e.g. Borderlands)"
          key="override_exe"
          value={@config["override_exe"]}
          default={@default["override_exe"] || "No Override"}
          target={@myself}
        />

        <.config_text_field
          label={gettext("Pre-Launch Command")}
          hint="Command to run before launching the game."
          key="pre_launch_command"
          value={@config["pre_launch_command"]}
          default={@default["pre_launch_command"] || "No Pre-Launch Command"}
          target={@myself}
        />

        <.config_yes_no_field
          label={gettext("Wait for Pre-Launch Command")}
          hint="Whether or not to wait for Pre-Launch Command to finish running."
          key="pre_launch_wait"
          value={@config["pre_launch_wait"]}
          default={@default["pre_launch_wait"] || "No"}
        />

        <.config_text_field
          label={gettext("Extra Launch Params")}
          hint="Extra launch parameters to use (in addition to the required ones)."
          key="start_params"
          value={@config["start_params"]}
          default={@default["start_params"] || "No Extra Params"}
          target={@myself}
        />

        <.config_yes_no_field
          label={gettext("Run in Offline Mode")}
          hint="Launch game without online authentication."
          key="offline"
          value={@config["offline"]}
          default={@default["offline"] || "No"}
        />

        <.config_text_field
          label={gettext("Crossover App Path")}
          hint="Path to Crossover (only needed on MacOS)."
          key="crossover_app"
          value={@config["crossover_app"]}
          default={@default["crossover_app"] || "No Crossover App"}
          target={@myself}
        />

        <.config_text_field
          label={gettext("Crossover Bottle Name")}
          hint="Name of the Crossover Bottle (i.e.: Legendary). Only needed on MacOS."
          key="crossover_bottle"
          value={@config["crossover_bottle"]}
          default={@default["crossover_bottle"] || "Legendary"}
          target={@myself}
        />
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
