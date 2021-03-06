defmodule Heroix.Legendary do
  @binary Application.fetch_env!(:heroix, :legendary_bin_wrapper)
  @file_manager Application.fetch_env!(:heroix, :file_manager)

  def owned_games do
    installed_info = installed_games()

    Path.wildcard("#{metadata_path()}/*.json")
    |> Enum.map(fn filename -> process_metadata(filename, installed_info) end)
    |> Enum.into(%{})
  end

  def game_info(app_name) do
    case Heroix.get_json(game_metadata_path(app_name)) do
      {:error, :enoent} ->
        {:error, "Game not found"}

      {:ok, json} ->
        %{"app_name" => app_name} = json
        json = Map.put(json, "installed_info", installed_games()[app_name])
        {:ok, json}
    end
  end

  def games_info(app_names) do
    installed = installed_games()

    app_names
    |> Enum.reject(&is_nil/1)
    |> Enum.map(fn app_name ->
      case Heroix.get_json(game_metadata_path(app_name)) do
        {:error, :enoent} ->
          {:error, "Game not found"}

        {:ok, json} ->
          %{"app_name" => app_name} = json
          json = Map.put(json, "installed_info", installed[app_name])
          {:ok, json}
      end
    end)
  end

  def installed_games do
    case Heroix.get_json(installed_path()) do
      {:ok, json} -> json
      {:error, :enoent} -> %{}
    end
  end

  def read_config() do
    case @file_manager.read(config_ini_path()) do
      {:ok, body} ->
        lines = String.split(body, "\n")
        process_first_line(lines, %{})

      _ ->
        %{}
    end
  end

  def game_install_info(app_name) do
    with {:ok, [stdout: output, stderr: _]} <-
           @binary.run(["info", app_name, "--json"], [:sync]),
         output <- Enum.join(output, " "),
         {:ok, json} <-
           Jason.decode(output) do
      json
    else
      {:error, err} -> err
    end
  end

  def game_download_info(app_name, base_path) do
    args = if base_path, do: ["--base-path", base_path], else: []

    {:error, [exit_status: 256, stdout: _, stderr: output]} =
      @binary.run(["install", app_name] ++ args, [:sync])

    output = Enum.join(output, " ")

    [_match, "Download size", download_size] =
      Regex.run(~r/(Download size): (.*) \(Compression/, output)

    [value, unit] = String.split(download_size, " ")

    Heroix.human_to_bytes(value, unit)
  end

  defp process_first_line(lines, acc, key \\ "")

  defp process_first_line([line | rest], acc, key) do
    cond do
      # ignore comment line
      String.match?(line, ~r/^; /) ->
        process_first_line(rest, acc, key)

      # ignore empty lines
      String.trim(line) == "" ->
        process_first_line(rest, acc, key)

      # add nested env
      String.match?(line, ~r/^\[.*\.env\]/) ->
        [_match, key_found] = Regex.run(~r/^\[(.*)\.env\]/, line)
        acc = Map.put(acc, key_found, Map.merge(acc[key_found], %{"env" => %{}}))
        process_first_line(rest, acc, {key_found, "env"})

      # add nested aliases
      String.match?(line, ~r/^\[.*\.aliases\]/) ->
        [_match, key_found] = Regex.run(~r/^\[(.*)\.aliases\]/, line)
        acc = Map.put(acc, key_found, Map.merge(acc[key_found], %{"aliases" => %{}}))
        process_first_line(rest, acc, {key_found, "aliases"})

      # add config key
      String.match?(line, ~r/^\[.*\]/) ->
        [_match, key_found] = Regex.run(~r/^\[(.*)\]/, line)
        acc = Map.put(acc, key_found, %{})
        process_first_line(rest, acc, key_found)

      # process line
      true ->
        [_match, config_key, value] = Regex.run(~r/^(.*)\=(.*)/, line)
        config_key = String.trim(config_key)

        value =
          value
          |> String.trim()
          |> String.replace_prefix("\"", "")
          |> String.replace_suffix("\"", "")

        # update accumulater with the config / value
        acc =
          case key do
            {parent_key, sub_key} ->
              sub_map = Map.merge(acc[parent_key][sub_key], %{config_key => value})
              Map.put(acc, parent_key, Map.put(acc[parent_key], sub_key, sub_map))

            _ ->
              Map.put(acc, key, Map.merge(acc[key], %{config_key => value}))
          end

        process_first_line(rest, acc, key)
    end
  end

  # end recursion
  defp process_first_line([], acc, _), do: acc

  def write_config(config_map) do
    keys =
      config_map
      |> Map.keys()
      |> Enum.reject(fn x -> x in ["Legendary", "default"] end)

    content =
      ["Legendary" | ["default" | keys]]
      |> Enum.map(fn key ->
        case config_map[key] do
          nil -> nil
          config -> "[#{key}]\n#{config_to_string(config, key)}"
        end
      end)
      |> Enum.reject(fn x -> is_nil(x) end)
      |> Enum.join("\n\n")

    @file_manager.write(config_ini_path(), content <> "\n")
  end

  defp config_to_string(config, parent_key) do
    pairs = Map.to_list(config)

    string_content =
      pairs
      |> Enum.filter(fn {_, value} -> is_binary(value) end)
      |> Enum.map(fn {config_key, value} ->
        cond do
          String.trim(value) == "" ->
            nil

          String.contains?(value, " ") ->
            "#{config_key} = \"#{value}\""

          true ->
            "#{config_key} = #{value}"
        end
      end)
      |> Enum.reject(fn x -> is_nil(x) end)
      |> Enum.join("\n")

    case Enum.filter(pairs, fn {_, value} -> is_map(value) end) do
      [] ->
        string_content

      map_values ->
        map_content =
          map_values
          |> Enum.map(fn {sub_key, map} ->
            "[#{parent_key}.#{sub_key}]\n#{config_to_string(map, sub_key)}"
          end)

        Enum.join([string_content, map_content], "\n\n")
    end
  end

  defp process_metadata(filename, installed_info) do
    case Heroix.get_json(filename) do
      {:ok, json} ->
        %{"app_name" => app_name} = json
        json = Map.put(json, "installed_info", installed_info[app_name])
        {app_name, json}

      {:error, :enoent} ->
        %{}
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

  defp config_ini_path do
    legendary_path("config.ini")
  end
end
