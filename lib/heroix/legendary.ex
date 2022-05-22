defmodule Heroix.Legendary do
  @spec owned_games() :: %{binary => %Game{}}
  def owned_games do
    Path.wildcard("#{metadata_path()}/*.json")
    |> Enum.map(fn filename -> process_metadata(filename) end)
    |> Enum.into(%{})
  end

  @spec game_info(binary) :: {:error, binary} | {:ok, %Game{}}
  def game_info(app_name) do
    case Heroix.get_json(game_metadata_path(app_name), %Game{}) do
      {:error, :enoent} -> {:error, "Game not found"}
      {:ok, json} -> {:ok, json}
    end
  end

  @spec process_metadata(binary) :: {binary, %Game{}}
  defp process_metadata(filename) do
    case Heroix.get_json(filename, %Game{}) do
      {:ok, json} ->
        %{ :app_name => app_name} = json
        { app_name, json }
      {:error, :enoent} -> %{}
    end
  end

  @spec metadata_path() :: binary
  defp metadata_path do
    Path.join([Application.fetch_env!(:heroix, :legendary_config_path), "metadata"])
  end

  @spec game_metadata_path(binary) :: binary
  defp game_metadata_path(app_name) do
    Path.join(metadata_path(), "#{app_name}.json")
  end
end
