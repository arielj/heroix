defmodule Heroix.Legendary do
  def owned_games do
    Path.wildcard("#{metadata_path()}/*.json")
    |> Enum.map(fn filename -> process_metadata(filename) end)
    |> Enum.into(%{})
  end

  def game_info(app_name) do
    case Heroix.get_json(game_metadata_path(app_name)) do
      {:error, :enoent} -> {:error, "Game not found"}
      {:ok, json} -> {:ok, json}
    end
  end

  def installed_games do
    case Heroix.get_json(installed_path()) do
      {:ok, json} -> json
      {:error, :enoent} -> %{}
    end
  end

  defp process_metadata(filename) do
    case Heroix.get_json(filename) do
      {:ok, json} ->
        %{ "app_name" => app_name} = json
        { app_name, json }
      {:error, :enoent} -> %{}
    end
  end

  defp metadata_path do
    legendary_path("metadata")
  end

  defp game_metadata_path(app_name) do
    Path.join(metadata_path(), "#{app_name}.json")
  end

  defp installed_path do
    legendary_path("installed.json")
  end

  defp legendary_path(segments) do
    Path.join([Application.fetch_env!(:heroix, :legendary_config_path), segments])
  end
end
