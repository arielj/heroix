defmodule HeroixWeb.LibraryView do
  use HeroixWeb, :live_view

  alias Heroix.Legendary
  import HeroixWeb.GameImageComponent

  def mount(_params, %{}, socket) do
    {:ok, assign(socket, order: "asc", search_term: "", games_list: get_games())}
  end

  defp game_card(assigns) do
    class = if assigns.installed, do: "installed", else: ""
    %{"app_name" => app_name, "app_title" => app_title} = assigns.game

    ~H"""
    <a id={app_name} title={app_title} href={"/library/#{app_name}"} class={class}>
      <.game_image game={@game} />
      <%= app_title %>
    </a>
    """
  end

  defp header(assigns) do
    ~H"""
    <header>
      <form phx-change="search" id="search_form">
      <div class="input-field">
      <input name="search" value={@search_term} />
      </div>
      </form>
      <span class="total">Total: <%= length(@games_list) %></span>
      <div class="filters">
        <button phx-click="toggle_order">Toggle order</button>
      </div>
    </header>
    """
  end

  def render(assigns) do
    ~H"""
    <section id="library">
      <.header games_list={@games_list} search_term={@search_term} />
      <ul id="games_list">
        <%= for game <- @games_list do %>
          <li><.game_card game={game} installed={game["install_info"] != nil} /></li>
        <% end %>
      </ul>
    </section>
    """
  end

  # default
  def get_games(), do: get_games(%{search_term: "", order: "asc"})
  # allow 2 positional args
  def get_games(search_term, order), do: get_games(%{search_term: search_term, order: order})
  def get_games(%{search_term: search_term, order: order}) do
    get_all_games()
    |> filter(search_term || "")
    |> sort(order || "asc")
    |> installed_first()
  end
  # allow passing only one criteria
  def get_games(%{order: order}), do: get_games(%{search_term: "", order: order})
  def get_games(%{search_term: search_term}), do: get_games(%{search_term: search_term, order: "asc"})

  defp get_all_games() do
    Legendary.owned_games()
    |> Enum.map(fn {_, game} -> game end)
  end

  defp filter(games, search_term) do
    search_term =
      search_term
      |> String.trim()
      |> String.downcase()

    games
    |> Enum.filter(fn %{"app_title" => app_title} -> String.contains?(String.downcase(app_title), search_term) end)
  end

  defp sort(games, order) do
    Enum.sort(games, fn (%{"app_title" => title1}, %{"app_title" => title2}) ->
      case order do
        "desc" -> title1 > title2
        _ -> title1 < title2
      end
    end)
  end

  defp installed_first(games) do
    Enum.sort(games, fn (%{"install_info" => installed1}, %{"install_info" => installed2}) ->
      cond do
        installed1 && installed2 -> true
        installed1 && !installed2 -> true
        !installed1 && installed2 -> false
        true -> true
      end
    end)
  end

  def handle_event("toggle_order", _, socket) do
    new_order =
      case socket.assigns.order do
        "asc" -> "desc"
        "desc" -> "asc"
      end

    search_term = socket.assigns.search_term

    {:noreply, assign(socket, order: new_order, games_list: get_games(search_term, new_order))}
  end

  def handle_event("search", %{"search" => search}, socket) do
    order = socket.assigns.order

    {:noreply, assign(socket, search_term: search, games_list: get_games(search, order))}
  end
end
