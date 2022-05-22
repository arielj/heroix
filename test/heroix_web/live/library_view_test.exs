defmodule HeroixWeb.LibraryViewTest do
  use HeroixWeb.ConnCase

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  @endpoint HeroixWeb.Endpoint

  alias HeroixWeb.LibraryView

  test "lists all games", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/library")
    assert html =~ ~r/Sherlock Holmes Crimes and Punishments.*Stranger Things 3: The Game/
  end

  describe "get_sorted_games" do
    test "sorts by ascending title by default" do
      [first_game, second_game] = LibraryView.get_sorted_games()
      assert "Sherlock Holmes Crimes and Punishments" = first_game.app_title
      assert "Stranger Things 3: The Game" = second_game.app_title
    end

    test "sorts by descending title if specified" do
      [first_game, second_game] = LibraryView.get_sorted_games("desc")
      assert "Stranger Things 3: The Game" = first_game.app_title
      assert "Sherlock Holmes Crimes and Punishments" = second_game.app_title
    end

    test "sorts by ascending title if specified" do
      [first_game, second_game] = LibraryView.get_sorted_games("asc")
      assert "Sherlock Holmes Crimes and Punishments" = first_game.app_title
      assert "Stranger Things 3: The Game" = second_game.app_title
    end

    test "sorts by ascending title if invalid value" do
      [first_game, second_game] = LibraryView.get_sorted_games("what?")
      assert "Sherlock Holmes Crimes and Punishments" = first_game.app_title
      assert "Stranger Things 3: The Game" = second_game.app_title
    end
  end
end
