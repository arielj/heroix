defmodule HeroixWeb.GameView do
  use HeroixWeb, :live_view

  alias Heroix.Legendary
  import HeroixWeb.GameImageComponent

  def mount(%{"app_name" => app_name}, _, socket) do
    {:ok, game_info} = Legendary.game_info(app_name)
    installed = Legendary.installed_games()[app_name] != nil
    {:ok, assign(socket, app_name: app_name, game: game_info, installed: installed, page_title: game_info["app_title"] )}
  end

  def render(assigns) do
    ~H"""
    <div id="game">
      <.game_image game={@game} />
      <h1><%= @game["app_title"] %></h1>
      <%= if @installed do %>
        <button phx-click="launch">Lunch</button>
      <% end %>
    </div>
    """
  end

  def handle_event("launch", %{}, socket) do
    Heroix.launch_game(socket.assigns.app_name)
    {:noreply, socket}
  end
end
