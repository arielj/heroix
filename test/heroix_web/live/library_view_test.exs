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

  setup do
    alan_wake = escape("Alan Wake's American Nightmare")
    sherlock = "Sherlock Holmes Crimes and Punishments"
    stranger = "Stranger Things 3: The Game"
    batman = "Batman™ Arkham Asylum Game of the Year Edition"
    Heroix.GameInstaller.reset()
    Heroix.GameUninstaller.reset()

    %{games: %{alan_wake: alan_wake, batman: batman, sherlock: sherlock, stranger: stranger}}
  end

  test "lists all games and can search", %{conn: conn, games: games} do
    {:ok, view, html} = live(conn, "/library")

    assert html =~ games[:alan_wake]
    assert html =~ games[:sherlock]
    assert html =~ games[:stranger]
    assert html =~ games[:batman]

    html = view |> element("#search_form") |> render_change(%{search: "sh"})
    refute html =~ games[:alan_wake]
    assert html =~ games[:sherlock]
    refute html =~ games[:stranger]
    refute html =~ games[:batman]

    html = view |> element("#search_form .input-field button") |> render_click()
    assert html =~ games[:alan_wake]
    assert html =~ games[:sherlock]
    assert html =~ games[:stranger]
    assert html =~ games[:batman]
  end

  test "shows installed games with the correct class", %{conn: conn, games: games} do
    {:ok, view, _} = live(conn, "/library")
    assert view |> element("a[title='#{games[:sherlock]}']:not(.installed)") |> has_element?()
    assert view |> element("a[title='#{games[:stranger]}']:not(.installed)") |> has_element?()
    assert view |> element("a[title='#{games[:batman]}'].installed)") |> has_element?()
    # use string directly here so it's not escaped, testing the `'` character
    assert view
           |> element("a[title=\"Alan Wake's American Nightmare\"].installed)")
           |> has_element?()
  end

  test "links to the game page", %{conn: conn, games: games} do
    {:ok, view, _} = live(conn, "/library")
    view |> element("a[title='#{games[:batman]}'].installed)") |> render_click()
    assert_redirected(view, "/library/Godwit")
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
