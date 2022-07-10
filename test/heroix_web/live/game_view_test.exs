defmodule HeroixWeb.GameViewTest do
  use HeroixWeb.ConnCase

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  alias Heroix.Settings
  @endpoint HeroixWeb.Endpoint

  setup do
    Heroix.GameInstaller.reset()
    Heroix.GameUninstaller.reset()

    %{}
  end

  describe "install button" do
    test "starts installing a game", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/library/0afb9d54dd3743a582b48b506466d3f8")

      view |> element("button", "Add Game") |> render_click()
      view |> element("button", "Install") |> render_click()

      assert Heroix.GameInstaller.installing() == "0afb9d54dd3743a582b48b506466d3f8"
    end

    test "adds a game to the install queue", %{conn: conn} do
      Heroix.GameInstaller.install_game("0a697c1235fb4706a635cfa33f0306ec", %{})

      assert Heroix.GameInstaller.installing() == "0a697c1235fb4706a635cfa33f0306ec"

      {:ok, view, _html} = live(conn, "/library/0afb9d54dd3743a582b48b506466d3f8")

      view |> element("button", "Add Game") |> render_click()
      view |> element("button", "Install") |> render_click()

      assert Heroix.GameInstaller.installing() == "0a697c1235fb4706a635cfa33f0306ec"

      assert Heroix.GameInstaller.queue() == [
               %{app_name: "0afb9d54dd3743a582b48b506466d3f8", opts: %{"install_path" => nil}}
             ]
    end
  end

  describe "stop installation button" do
    test "cancels the installation", %{conn: conn} do
      Heroix.GameInstaller.install_game("0a697c1235fb4706a635cfa33f0306ec", %{})

      assert Heroix.GameInstaller.installing() == "0a697c1235fb4706a635cfa33f0306ec"
      assert Heroix.GameInstaller.queue() == []

      {:ok, view, html} = live(conn, "/library/0a697c1235fb4706a635cfa33f0306ec")

      assert html =~ "Starting installation..."

      view |> element("button", "Stop Installation") |> render_click()

      assert :sys.get_state(GameInstaller).stopping() == "0a697c1235fb4706a635cfa33f0306ec"
    end
  end

  describe "uninstall button" do
    test "triggers the game uninstallation", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/library/Godwit")

      view |> element("button", "Uninstall") |> render_click()

      assert :sys.get_state(GameUninstaller).uninstalling == "Godwit"
    end
  end

  describe "settings" do
    test "shows games settings", %{conn: conn} do
      HeroixWeb.Endpoint.subscribe("settings")

      {:ok, view, _html} = live(conn, "/library/Condor")

      refute view |> element("#game.show-config") |> has_element?()

      view |> element("button", "Config") |> render_click()

      assert view |> element("#game.show-config") |> has_element?()

      assert Settings.legendary_game_config("Condor")["language"] == nil

      view
      |> element("#game-config form")
      |> render_change(%{"_target" => ["language"], "language" => "en"})

      assert Settings.legendary_game_config("Condor")["language"] == "en"

      view
      |> element("#game-config input[name=\"language\"]")
      |> render_blur()

      assert_received %Phoenix.Socket.Broadcast{event: "save_legendary_config"}
    end
  end
end
