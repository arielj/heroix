defmodule Heroix.LegendaryTest do
  use ExUnit.Case

  alias Heroix.Legendary

  @config_path Application.fetch_env!(:heroix, :legendary_config_path)
  @config_ini Path.join([@config_path, "config.ini"])
  @config_ini_sample Path.join([@config_path, "config.ini.sample"])

  @config_as_map %{
    "Legendary" => %{
      "log_level" => "debug",
      "max_memory" => "2048",
      "max_workers" => "8",
      "install_dir" => "/mnt/tank/games",
      "locale" => "en-US",
      "egl_sync" => "false",
      "egl_programdata" => "/home/user/Games/epic-games-store/drive_c/...",
      "preferred_cdn" => "epicgames-download1.akamaized.net",
      "disable_https" => "false",
      "disable_update_check" => "false",
      "disable_update_notice" => "false",
      "disable_auto_aliasing" => "false",
      "default_platform" => "Windows",
      "install_platform_fallback" => "true",
      "disable_auto_crossover" => "false",
      "mac_install_dir" => "/User/legendary/Applications",
      "aliases" => %{
        "HITMAN 3" => "Eider",
        "gtav" => "9d2d0eb64d5c44529cece33fe2a46482"
      }
    },
    "default" => %{
      "wrapper" => "gamemode",
      "wine_executable" => "wine",
      "wine_prefix" => "/home/user/.wine",
      "crossover_app" => "/Applications/CrossOver.app",
      "crossover_bottle" => "Legendary",
      "env" => %{
        "WINEPREFIX" => "/home/user/legendary/.wine"
      }
    },
    "AppName" => %{
      "offline" => "true",
      "skip_update_check" => "true",
      "start_params" => "-windowed",
      "language" => "fr",
      "wine_executable" => "/path/to/wine64",
      "env" => %{
        "WINEPREFIX" => "/mnt/tank/games/Game/.wine",
        "DXVK_CONFIG_FILE" => "/mnt/tank/games/Game/dxvk.conf"
      }
    },
    "AppName2" => %{
      "wrapper" => "/path/with spaces/gamemoderun",
      "no_wine" => "true",
      "override_exe" => "relative/path/to/file.exe",
      "disable_sdl" => "true"
    },
    "AppName3" => %{
      "pre_launch_command" => "/path/to/script.sh",
      "pre_launch_wait" => "false",
      "crossover_app" => "/Applications/CrossOver Nightly.app",
      "crossover_bottle" => "SomethingElse"
    }
  }

  # Use the fixture data at test/fixtures/legendary

  test "owned_games returns a map with all the games" do
    assert %{
             "0a697c1235fb4706a635cfa33f0306ec" => game_one,
             "0afb9d54dd3743a582b48b506466d3f8" => game_two
           } = Legendary.owned_games()

    assert %{
             "app_name" => "0a697c1235fb4706a635cfa33f0306ec",
             "app_title" => "Stranger Things 3: The Game"
           } = game_one

    assert %{
             "app_name" => "0afb9d54dd3743a582b48b506466d3f8",
             "app_title" => "Sherlock Holmes Crimes and Punishments"
           } = game_two
  end

  test "game_info returns the game data as a map" do
    {:ok, game_info} = Legendary.game_info("0a697c1235fb4706a635cfa33f0306ec")

    assert %{
             "app_name" => "0a697c1235fb4706a635cfa33f0306ec",
             "app_title" => "Stranger Things 3: The Game"
           } = game_info
  end

  test "game_info resturns an error if invalid app_name" do
    assert {:error, "Game not found"} = Legendary.game_info("invalid")
  end

  test "reads config.ini correctly" do
    File.copy(@config_ini_sample, @config_ini)

    assert @config_as_map == Legendary.read_config()

    File.rm(@config_ini)
  end

  test "writes config.ini properly" do
    config_content = """
    [Legendary]
    default_platform = Windows
    disable_auto_aliasing = false
    disable_auto_crossover = false
    disable_https = false
    disable_update_check = false
    disable_update_notice = false
    egl_programdata = /home/user/Games/epic-games-store/drive_c/...
    egl_sync = false
    install_dir = /mnt/tank/games
    install_platform_fallback = true
    locale = en-US
    log_level = debug
    mac_install_dir = /User/legendary/Applications
    max_memory = 2048
    max_workers = 8
    preferred_cdn = epicgames-download1.akamaized.net

    [Legendary.aliases]
    HITMAN 3 = Eider
    gtav = 9d2d0eb64d5c44529cece33fe2a46482

    [default]
    crossover_app = /Applications/CrossOver.app
    crossover_bottle = Legendary
    wine_executable = wine
    wine_prefix = /home/user/.wine
    wrapper = gamemode

    [default.env]
    WINEPREFIX = /home/user/legendary/.wine

    [AppName]
    language = fr
    offline = true
    skip_update_check = true
    start_params = -windowed
    wine_executable = /path/to/wine64

    [AppName.env]
    DXVK_CONFIG_FILE = /mnt/tank/games/Game/dxvk.conf
    WINEPREFIX = /mnt/tank/games/Game/.wine

    [AppName2]
    disable_sdl = true
    no_wine = true
    override_exe = relative/path/to/file.exe
    wrapper = "/path/with spaces/gamemoderun"

    [AppName3]
    crossover_app = "/Applications/CrossOver Nightly.app"
    crossover_bottle = SomethingElse
    pre_launch_command = /path/to/script.sh
    pre_launch_wait = false
    """

    Legendary.write_config(@config_as_map)

    {:ok, body} = File.read(@config_ini)

    assert body == config_content

    File.rm(@config_ini)
  end

  test "ignores empty configurations" do
    config_content = """
    [default]
    wrapper = gamemode
    """

    Legendary.write_config(%{"default" => %{"wrapper" => "gamemode", "wine" => ""}})

    {:ok, body} = File.read(@config_ini)

    assert body == config_content

    File.rm(@config_ini)
  end
end
