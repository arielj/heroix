defmodule HeroixWeb.GameView do
  use HeroixWeb, :live_view

  alias Heroix.Legendary
  import HeroixWeb.GameImageComponent
  import HeroixWeb.FontIconComponent

  def mount(%{"app_name" => app_name}, _, socket) do
    {:ok, game_info} = Legendary.game_info(app_name)
    # IO.inspect(game_info)
    {:ok, assign(socket, app_name: app_name, game: game_info, page_title: game_info["app_title"] )}
  end

  defp datetime(value) do
    {:ok, dt, _ } = DateTime.from_iso8601(value)
    Calendar.strftime(dt, "%Y-%m-%d %I:%M:%S")
  end

  defp date(value) do
    {:ok, dt, _ } = DateTime.from_iso8601(value)
    dt
    |> DateTime.to_date()
    |> Calendar.strftime("%Y-%m-%d")
  end

  def info(assigns) do
    install_info = assigns.game["install_info"]
    metadata = assigns.game["metadata"]

    ~H"""
    <dl class="info">
      <dt>Version</dt>
      <dd><%= @game["app_version"] %></dd>
      <dt>Install Path</dt>
      <dd><%= install_info["install_path"] %></dd>
      <dt>Size in Disk</dt>
      <dd><%= install_info["install_size"] %></dd>
      <dt>Developer</dt>
      <dd><%= metadata["developer"] %></dd>
      <dt>Release Date</dt>
      <dd><%= date(List.first(metadata["releaseInfo"])["dateAdded"]) %></dd>
      <dt>Last Updated At</dt>
      <dd><%= datetime(metadata["lastModifiedDate"]) %></dd>
    </dl>
    """
  end

  def render(assigns) do
    ~H"""
    <div id="game">
      <div class="left">
        <.game_image game={@game} />
        <div class="actions">
          <%= if @game["install_info"] != nil do %>
            <button phx-click="launch">
              <.font_icon icon="play-alt-1" />
              Lunch
            </button>
            <button phx-click="uninstall">
              <.font_icon icon="database-remove" />
              Uninstall
            </button>
          <% else %>
            <button phx-click="install">
              <.font_icon icon="database-add" />
              Install
            </button>
          <% end %>
        </div>
      </div>
      <div class="right">
        <h1><%= @game["app_title"] %></h1>
        <p class="description"><%= @game["metadata"]["description"] %></p>
        <.info game={@game} />
      </div>
    </div>
    """
  end

  def handle_event("launch", %{}, socket) do
    Heroix.launch_game(socket.assigns.app_name)
    {:noreply, socket}
  end
end
