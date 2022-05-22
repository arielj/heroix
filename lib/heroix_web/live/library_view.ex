defmodule HeroixWeb.LibraryView do
  use HeroixWeb, :live_view

  def mount(_params, %{}, socket) do
    {:ok, assign(socket, order: "asc", games_list: get_sorted_games("asc"))}
  end

  def render(assigns) do
    ~H"""
    <section id="Library">
      <button phx-click="toggle_order">Toggle order</button>
      <%= for game <- @games_list do %>
        <article id={game.app_name} title={game.app_title}><%= game.app_title %></article>
      <% end %>
    </section>
    """
  end

  def get_sorted_games(order \\ "asc") do
    Heroix.Legendary.owned_games()
      |> Enum.map(fn {_, game} -> game end)
      |> Enum.sort(fn (el1, el2) ->
        case order do
          "desc" -> el1.app_title > el2.app_title
          _ -> el1.app_title < el2.app_title
        end
      end)
  end

  def handle_event("toggle_order", _, socket) do
    new_order =
      case socket.assigns.order do
        "asc" -> "desc"
        "desc" -> "asc"
      end

    {:noreply, assign(socket, order: new_order, games_list: get_sorted_games(new_order))}
  end
end
