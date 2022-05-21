defmodule HeroixWeb.PageController do
  use HeroixWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
