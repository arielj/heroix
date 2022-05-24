defmodule HeroixWeb.LibraryViewTest do
  use HeroixWeb.ConnCase

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  @endpoint HeroixWeb.Endpoint

  alias HeroixWeb.LibraryView

  defp escape(str) do
    str
    |> Phoenix.HTML.html_escape()
    |> Phoenix.HTML.safe_to_string()
  end

  test "lists all games", %{conn: conn} do
    {:ok, view, html} = live(conn, "/library")
    alan_wake = escape("Alan Wake's American Nightmare")
    sherlock = "Sherlock Holmes Crimes and Punishments"
    stranger = "Stranger Things 3: The Game"
    batman = "Batman™ Arkham Asylum Game of the Year Edition"

    assert html =~ alan_wake
    assert html =~ sherlock
    assert html =~ stranger
    assert html =~ batman

    html = view |> element("[id='search_form']") |> render_change(%{search: "sh"})
    refute html =~ alan_wake
    assert html =~ sherlock
    refute html =~ stranger
    refute html =~ batman

    html = view |> element("[id='search_form']") |> render_change(%{search: ""})
    assert html =~ alan_wake
    assert html =~ sherlock
    assert html =~ stranger
    assert html =~ batman

    assert view |> element("a[title='#{sherlock}']:not(.installed)") |> has_element?()
    assert view |> element("a[title='#{stranger}']:not(.installed)") |> has_element?()
    assert view |> element("a[title='#{batman}'].installed)") |> has_element?()

    el = view |> element("a[title=\"Alan Wake's American Nightmare\"].installed)")
    assert el |> has_element?

    el |> render_click()
    assert_redirected view, "/library/Condor"
  end

  describe "get_games sorting" do
    test "sorts by ascending title by default" do
      [first_game, second_game, third_game, fourth_game] = LibraryView.get_games()
      assert "Alan Wake's American Nightmare" == first_game["app_title"]
      assert "Batman\u2122 Arkham Asylum Game of the Year Edition" == second_game["app_title"]
      assert "Sherlock Holmes Crimes and Punishments" == third_game["app_title"]
      assert "Stranger Things 3: The Game" == fourth_game["app_title"]
    end

    test "sorts by descending title if specified" do
      [first_game, second_game, third_game, fourth_game] = LibraryView.get_games(%{order: "desc"})
      assert "Batman\u2122 Arkham Asylum Game of the Year Edition" == first_game["app_title"]
      assert "Alan Wake's American Nightmare" == second_game["app_title"]
      assert "Stranger Things 3: The Game" == third_game["app_title"]
      assert "Sherlock Holmes Crimes and Punishments" == fourth_game["app_title"]
    end

    test "sorts by ascending title if specified" do
      [first_game, second_game, third_game, fourth_game] = LibraryView.get_games()
      assert "Alan Wake's American Nightmare" == first_game["app_title"]
      assert "Batman\u2122 Arkham Asylum Game of the Year Edition" == second_game["app_title"]
      assert "Sherlock Holmes Crimes and Punishments" == third_game["app_title"]
      assert "Stranger Things 3: The Game" == fourth_game["app_title"]
    end

    test "sorts by ascending title if invalid value" do
      [first_game, second_game, third_game, fourth_game] = LibraryView.get_games()
      assert "Alan Wake's American Nightmare" == first_game["app_title"]
      assert "Batman\u2122 Arkham Asylum Game of the Year Edition" == second_game["app_title"]
      assert "Sherlock Holmes Crimes and Punishments" == third_game["app_title"]
      assert "Stranger Things 3: The Game" == fourth_game["app_title"]
    end
  end

  describe "get_games filtering" do
    test "does not filter by default" do
      [first_game, second_game, third_game, fourth_game] = LibraryView.get_games()
      assert "Alan Wake's American Nightmare" == first_game["app_title"]
      assert "Batman\u2122 Arkham Asylum Game of the Year Edition" == second_game["app_title"]
      assert "Sherlock Holmes Crimes and Punishments" == third_game["app_title"]
      assert "Stranger Things 3: The Game" == fourth_game["app_title"]
    end

    test "filters by lowercase term" do
      [game | rest] = LibraryView.get_games(%{search_term: "she"})

      rest = length(rest)
      assert rest == 0

      assert "Sherlock Holmes Crimes and Punishments" == game["app_title"]
    end
  end
end
