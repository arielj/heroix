defmodule HeroixWeb.ImagesController do
  use HeroixWeb, :controller

  @images_cache Application.fetch_env!(:heroix, :images_cache)

  def get(conn, %{"app_name" => app_name, "variant" => variant}) do
    case @images_cache.get(app_name, variant) do
      nil ->
        halt(conn)

      filename ->
        conn =
          Plug.Conn.merge_resp_headers(conn, [{"cache-control", "max-age=31536000, immutable"}])

        Plug.Conn.send_file(conn, 200, filename)
    end
  end
end
