defmodule Heroix.MockedImagesCache do
  def get(_app_name, _variant) do
    Path.join([images_cache_path(), "test-image.png"])
  end

  defp images_cache_path do
    path = Path.join([Application.fetch_env!(:heroix, :heroix_config_path), "images_cache"])
    unless File.exists?(path), do: File.mkdir_p(path)
    path
  end
end
