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
    assert html =~ alan_wake
    assert html =~ sherlock
    assert html =~ stranger

    html = view |> element("[id='search_form']") |> render_change(%{search: "sh"})
    refute html =~ alan_wake
    assert html =~ sherlock
    refute html =~ stranger

    html = view |> element("[id='search_form']") |> render_change(%{search: ""})
    assert html =~ alan_wake
    assert html =~ sherlock
    assert html =~ stranger

    assert view |> element("a[id='0a697c1235fb4706a635cfa33f0306ec']:not(.installed)") |> has_element?()
    assert view |> element("a[id='0afb9d54dd3743a582b48b506466d3f8']:not(.installed)") |> has_element?()
    el = view |> element("a[id='Condor'].installed)")
    assert el |> has_element?()

    el |> render_click()
    assert_redirected view, "/library/Condor"
  end

  describe "get_games sorting" do
    test "sorts by ascending title by default" do
      [first_game, second_game, third_game] = LibraryView.get_games()
      assert "Alan Wake's American Nightmare" == first_game["app_title"]
      assert "Sherlock Holmes Crimes and Punishments" == second_game["app_title"]
      assert "Stranger Things 3: The Game" == third_game["app_title"]
    end

    test "sorts by descending title if specified" do
      [first_game, second_game, third_game] = LibraryView.get_games(%{order: "desc"})
      assert "Stranger Things 3: The Game" == first_game["app_title"]
      assert "Sherlock Holmes Crimes and Punishments" == second_game["app_title"]
      assert "Alan Wake's American Nightmare" == third_game["app_title"]
    end

    test "sorts by ascending title if specified" do
      [first_game, second_game, third_game] = LibraryView.get_games()
      assert "Alan Wake's American Nightmare" == first_game["app_title"]
      assert "Sherlock Holmes Crimes and Punishments" == second_game["app_title"]
      assert "Stranger Things 3: The Game" == third_game["app_title"]
    end

    test "sorts by ascending title if invalid value" do
      [first_game, second_game, third_game] = LibraryView.get_games()
      assert "Alan Wake's American Nightmare" == first_game["app_title"]
      assert "Sherlock Holmes Crimes and Punishments" == second_game["app_title"]
      assert "Stranger Things 3: The Game" == third_game["app_title"]
    end
  end

  describe "get_games filtering" do
    test "does not filter by default" do
      [first_game, second_game, third_game] = LibraryView.get_games()
      assert "Alan Wake's American Nightmare" == first_game["app_title"]
      assert "Sherlock Holmes Crimes and Punishments" == second_game["app_title"]
      assert "Stranger Things 3: The Game" == third_game["app_title"]
    end

    test "filters by lowercase term" do
      [game | rest] = LibraryView.get_games(%{search_term: "she"})

      rest = length(rest)
      assert rest == 0

      assert "Sherlock Holmes Crimes and Punishments" == game["app_title"]
    end
  end
end
