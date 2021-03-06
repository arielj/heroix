defmodule Heroix.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      HeroixWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Heroix.PubSub},
      # Start the Endpoint (http/https)
      HeroixWeb.Endpoint,
      {Heroix.SessionManager, name: SessionManager},
      {Heroix.GameRunner, name: GameRunner},
      {Heroix.Settings, name: Settings},
      {Heroix.GameInstaller, name: GameInstaller},
      {Heroix.GameUninstaller, name: GameUninstaller},
      {Task.Supervisor, name: Task.MySupervisor}
      # Start a worker by calling: Heroix.Worker.start_link(arg)
      # {Heroix.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Heroix.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    HeroixWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
