defmodule HeroixWeb.InitSession do
  @moduledoc """
  Ensures common `assigns` are applied to all LiveViews attaching this hook.
  """

  import Phoenix.LiveView

  alias Heroix.SessionManager

  def on_mount(:set_current_user, _params, _session, socket) do
    HeroixWeb.Endpoint.subscribe("session")
    {:cont, assign(socket, :current_user, SessionManager.current_user())}
  end
end
