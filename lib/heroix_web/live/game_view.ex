defmodule HeroixWeb.GameView do
  use HeroixWeb, :live_view

  alias Heroix.Legendary
  import HeroixWeb.GameImageComponent
  import HeroixWeb.FontIconComponent

  @topic "game_runner"

  def mount(%{"app_name" => app_name}, _, socket) do
    {:ok, game_info} = Legendary.game_info(app_name)
    # IO.inspect(game_info)

    # check if it's running
    game_running = GenServer.call(GameRunner, :game_running)

    # subscribe to game runner updates
    HeroixWeb.Endpoint.subscribe(@topic)

    {:ok, assign(socket, app_name: app_name, game: game_info, page_title: game_info["app_title"], game_running: game_running )}
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
            <%= if @game_running == @game["app_name"] do %>
              <button phx-click="stop">
                <.font_icon icon="stop" />
                Stop
              </button>
            <% else %>
              <%= if @game_running == nil do %>
                <button phx-click="launch">
                  <.font_icon icon="play-alt-1" />
                  Lunch
                </button>
              <% else %>
                <p>
                  <a href={"/library/#{@game_running}"}>Another game</a>
                  is currently running
                </p>
              <% end %>
            <% end %>
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

  def handle_event("stop", %{}, socket) do
    Heroix.stop_game()
    {:noreply, socket}
  end

  def handle_info(%{event: "game_launched", payload: %{app_name: app_name}}, socket) do
    {:noreply, assign(socket, game_running: app_name)}
  end

  def handle_info(%{event: "game_stopped"}, socket) do
    {:noreply, assign(socket, game_running: nil)}
  end
end
