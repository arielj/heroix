defmodule Heroix do
  @moduledoc """
  Heroix keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def get_json(filename, as \\ %{}) do
    with {:ok, body} <- File.read(filename),
         {:ok, json} <- Poison.decode(body, as: as), do: {:ok, json}
  end
end
