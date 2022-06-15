defmodule Heroix do
  @moduledoc """
  Heroix keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def logger(tag) do
    quote do
      require Logger

      def log(to_log) do
        Logger.info("[#{unquote(tag)}] #{inspect(to_log)}")
      end
    end
  end

  def get_json(filename) do
    with {:ok, body} <- File.read(filename),
         {:ok, json} <- Jason.decode(body) do
      {:ok, json}
    else
      {:error, err} -> {:error, err}
    end
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

      _ ->
        imgData["url"]
    end
  end

  @bytes_in_kilo 1024
  @bytes_in_mega 1024 * 1024
  @bytes_in_giga 1024 * 1024 * 1024
  def bytes_to_human(value) when is_binary(value) do
    {num, _} = Integer.parse(value)
    bytes_to_human(num)
  end

  def bytes_to_human(value) when is_integer(value) do
    [value, unit] =
      cond do
        value > @bytes_in_giga ->
          [value / @bytes_in_giga, "GB"]

        value > @bytes_in_mega ->
          [value / @bytes_in_mega, "MB"]

        value > @bytes_in_kilo ->
          [value / @bytes_in_kilo, "KB"]

        true ->
          [value, "B"]
      end

    "#{Float.round(value, 2)}#{unit}"
  end

  # Converts Elixir pid (not OS pid) to string
  def pid_to_string(pid) do
    cond do
      is_binary(pid) -> pid
      is_integer(pid) -> Integer.to_string(pid)
      true -> pid |> :erlang.pid_to_list() |> to_string()
    end
  end
end
