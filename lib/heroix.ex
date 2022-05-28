defmodule Heroix do
  @moduledoc """
  Heroix keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def launch_game(app_name) do
    GenServer.cast(GameRunner, {:launch, app_name})
  end

  def stop_game() do
    GenServer.cast(GameRunner, :stop)
  end

  # def install_game(app_name) do
  #   System.cmd(legendary_bin(), ["install", app_name])
  #   IO.puts "Installs #{app_name}"
  #   IO.puts "lengendary bin: #{legendary_bin()}"
  # end

  def uninstall_game(app_name) do
    # System.cmd(legendary_bin(), ["uninstall", app_name])
    IO.puts "Unnstalls #{app_name}"
    IO.puts "lengendary bin: #{legendary_bin()}"
  end

  def legendary_bin do
    [os, bin_name] =
      case :os.type() do
        {:unix, :linux} -> ["linux", "legendary"]
        {:win32, _} -> ["win32", "legendary.exe"]
        {_, _} -> ["darwin", "legendary"]
      end
    Path.join([File.cwd!(), "priv", "bins", os, bin_name])
  end

  def get_json(filename) do
    with {:ok, body} <- File.read(filename),
         {:ok, json} <- Jason.decode(body), do: {:ok, json}
  end

  def get_game_image(game, "tall"), do: get_game_image(game, "DieselGameBoxTall", "wide")
  def get_game_image(game, "wide"), do: get_game_image(game, "DieselGameBox", "tall")
  def get_game_image(game, "logo"), do: get_game_image(game, "DieselGameBoxLogo", nil)
  def get_game_image(game, image_type, fallback \\ nil) do
    imgData =
      game["metadata"]["keyImages"]
      |> Enum.find(fn img -> img["type"] == image_type end)

    case imgData do
      nil ->
        case fallback do
          nil -> nil
          _ -> get_game_image(game, fallback)
        end
      _ -> imgData["url"]
    end
  end
end
