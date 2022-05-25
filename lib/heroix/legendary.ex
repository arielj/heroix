defmodule Heroix.Legendary do
  def owned_games do
    installed_info = installed_games()

    Path.wildcard("#{metadata_path()}/*.json")
    |> Enum.map(fn filename -> process_metadata(filename, installed_info) end)
    |> Enum.into(%{})
  end

  def game_info(app_name) do
    case Heroix.get_json(game_metadata_path(app_name)) do
      {:error, :enoent} -> {:error, "Game not found"}
      {:ok, json} ->
        %{ "app_name" => app_name} = json
        json = Map.put(json, "install_info", installed_games()[app_name])
        {:ok, json}
    end
  end

  def installed_games do
    case Heroix.get_json(installed_path()) do
      {:ok, json} -> json
      {:error, :enoent} -> %{}
    end
  end

  defp process_metadata(filename, installed_info) do
    case Heroix.get_json(filename) do
      {:ok, json} ->
        %{ "app_name" => app_name} = json
        json = Map.put(json, "install_info", installed_info[app_name])
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
