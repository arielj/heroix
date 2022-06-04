defmodule HeroixWeb.GameConfigComponent do
  use Phoenix.Component

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

  def game_config(assigns) do
    ~H"""
    <div id="game-config">
      <%= inspect @config %>
    </div>
    """
  end
end
