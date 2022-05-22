defmodule Heroix.LegendaryTest do
  use ExUnit.Case

  alias Heroix.Legendary

  # Use the fixture data at test/fixtures/legendary

  test "owned_games returns a map with all the games" do
    assert %{
      "0a697c1235fb4706a635cfa33f0306ec" => game_one,
      "0afb9d54dd3743a582b48b506466d3f8" => game_two } = Legendary.owned_games()
    assert %Game{
      :app_name => "0a697c1235fb4706a635cfa33f0306ec",
      :app_title => "Stranger Things 3: The Game"} = game_one
    assert %Game{
      :app_name => "0afb9d54dd3743a582b48b506466d3f8",
      :app_title => "Sherlock Holmes Crimes and Punishments"} = game_two
  end

  test "game_info returns the game data as a map" do
    {:ok, game_info} = Legendary.game_info("0a697c1235fb4706a635cfa33f0306ec")

    assert %Game{
      :app_name => "0a697c1235fb4706a635cfa33f0306ec",
      :app_title => "Stranger Things 3: The Game"} = game_info
  end

  test "game_info resturns an error if invalid app_name" do
    assert {:error, "Game not found"} = Legendary.game_info("invalid")
  end
end
