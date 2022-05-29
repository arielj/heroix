defmodule Heroix.ImagesCache do
  def get(app_name, variant) do
    case Heroix.Legendary.game_info(app_name) do
      {:ok, game_info} ->
        case Heroix.get_game_image(game_info, variant) do
          nil -> nil
          url -> local_path_for(url, app_name, variant)
        end

      {:error, _} ->
        nil
    end
  end

  defp local_path_for(url, app_name, variant) do
    path = filepath(app_name, variant, Path.extname(url))
    download("#{url}#{size_query_string(variant)}", path)
    path
  end

  defp size_query_string("logo"), do: "?h=50&resize=1&w=100"
  defp size_query_string(_), do: "?h=300&resize=1&w=200"

  defp download(url, to) do
    unless File.exists?(to) do
      %HTTPoison.Response{body: body} = HTTPoison.get!(url)
      File.write!(to, body)
    end
  end

  defp filepath(app_name, variant, extension) do
    # TODO: kinda ugly to check env here
    filename =
      case Application.get_env(:your_app, :env) do
        :test -> "test-image.png"
        _ -> "#{app_name}-#{variant}#{extension}"
      end

    Path.join([images_cache_path(), filename])
  end

  defp images_cache_path do
    path = Path.join([Application.fetch_env!(:heroix, :heroix_config_path), "images_cache"])
    unless File.exists?(path), do: File.mkdir_p(path)
    path
  end
end
