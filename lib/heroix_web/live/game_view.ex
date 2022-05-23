defmodule HeroixWeb.GameView do
  use HeroixWeb, :live_view

  alias Heroix.Legendary

  def mount(%{"app_name" => app_name}, _, socket) do
    {:ok, game_info} = Legendary.game_info(app_name)
    installed = Legendary.installed_games()[app_name] != nil
    {:ok, assign(socket, app_name: app_name, game: game_info, installed: installed )}
  end

  def render(assigns) do
    ~H"""
    <div id="game">
      <div class="game_image">
        <img src={get_game_image(@game)} />
        <%= if has_logo(@game) do %>
          <img src={get_logo_image(@game)} />
        <% end %>
      </div>
      <h1><%= @game["app_title"] %></h1>
      <%= if @installed do %>
        <button phx-click="launch">Lunch</button>
      <% end %>
    </div>
    """
  end

  def get_game_image(game) do
    "#{Heroix.get_game_image(game, :tall)}?h=300&resize=1&w=200"
  end

  def get_logo_image(game) do
    case Heroix.get_game_image(game, :logo) do
      nil -> nil
      url -> "#{url}?h=50&resize=1&w=100"
    end
  end

  def has_logo(game) do
    Heroix.get_game_image(game, :logo) != nil
  end

  def handle_event("launch", %{}, socket) do
    Heroix.launch_game(socket.assigns.app_name)
    {:noreply, socket}
  end
end
