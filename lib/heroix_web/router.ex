defmodule HeroixWeb.Router do
  use HeroixWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {HeroixWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :image do
    plug :accepts, ["image/png"]
  end

  scope "/image", HeroixWeb do
    pipe_through :image

    get "/:app_name/:variant", ImagesController, :get
  end

  live_session :default, on_mount: {HeroixWeb.InitSession, :set_current_user} do
    scope "/", HeroixWeb do
      pipe_through :browser

      live "/", LibraryView
      live "/login", LoginView
      live "/library", LibraryView
      live "/library/:app_name", GameView
      live "/downloads", DownloadsView
      live "/settings", SettingsView
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", HeroixWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: HeroixWeb.Telemetry
    end
  end
end
