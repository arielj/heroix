defmodule HeroixWeb.LibraryView do
  use HeroixWeb, :live_view

  alias Heroix.Legendary

  def mount(_params, %{}, socket) do
    {:ok, assign(socket, order: "asc", search_term: "", games_list: get_games(), installed_games: Legendary.installed_games())}
  end

  def game_card(assigns) do
    class = if assigns.installed, do: "installed", else: ""
    %{"app_name" => app_name, "app_title" => app_title} = assigns.game

    ~H"""
    <a id={app_name} title={app_title} href={"/library/#{app_name}"} class={class}>
      <div class="game_image">
        <img src={"/image/#{app_name}/tall"} />
        <%= if has_logo(@game) do %>
          <img src={"/image/#{app_name}/logo"} />
        <% end %>
      </div>
      <%= app_title %>
    </a>
    """
  end

  def header(assigns) do
    ~H"""
    <header>
      <form phx-change="search" id="search_form">
        <div class="input-field">
          <input name="search" value={@search_term} />
        </div>
      </form>
      <span class="total">Total: <%= length(@games_list) %></span>
    </header>
    """
  end

  def render(assigns) do
    ~H"""
    <section id="library">
      <.header games_list={@games_list} search_term={@search_term} />
      <div class="filters">
        <button phx-click="toggle_order">Toggle order</button>
      </div>
      <ul id="games_list">
        <%= for game <- @games_list do %>
          <li><.game_card game={game} installed={@installed_games[game["app_name"]] != nil} /></li>
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
    installed = Legendary.installed_games()
    Enum.sort(games, fn (%{"app_name" => name1}, %{"app_name" => name2}) ->
      cond do
        installed[name1] && installed[name2] -> true
        installed[name1] && !installed[name2] -> true
        !installed[name1] && installed[name2] -> false
        true -> true
      end
    end)
  end

  # def get_game_image(game) do
  #   "#{Heroix.get_game_image(game, :tall)}?h=300&resize=1&w=200"
  # end

  # def get_logo_image(game) do
  #   case Heroix.get_game_image(game, "logo") do
  #     nil -> nil
  #     url -> "#{url}?h=50&resize=1&w=100"
  #   end
  # end

  def has_logo(game) do
    Heroix.get_game_image(game, "logo") != nil
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
