defmodule HeroixWeb.GameView do
  use HeroixWeb, :live_view

  require Logger

  alias Heroix.Legendary
  alias Heroix.GameRunner
  alias Heroix.GameInstaller
  alias Heroix.GameUninstaller
  alias HeroixWeb.GameConfigComponent
  alias HeroixWeb.AddGameDialogComponent
  import HeroixWeb.GameImageComponent
  import HeroixWeb.FontIconComponent

  def mount(%{"app_name" => app_name}, _, socket) do
    {:ok, game_info} = Legendary.game_info(app_name)
    # IO.inspect(game_info)

    # subscribe to game status updates
    HeroixWeb.Endpoint.subscribe("game_status")

    if !game_info["installed_info"] do
      GameInstaller.fetch_install_info(app_name)
    end

    {:ok,
     assign(socket,
       app_name: app_name,
       game: game_info,
       page_title: game_info["app_title"],
       game_running: GameRunner.running_game(),
       installing: GameInstaller.installing(),
       install_queue: GameInstaller.queue(),
       install_progress: nil,
       install_eta: nil,
       install_info: nil,
       show_add_game: false,
       show_config: false
     )}
  end

  defp datetime(value) do
    {:ok, dt, _} = DateTime.from_iso8601(value)
    Calendar.strftime(dt, "%Y-%m-%d %I:%M:%S")
  end

  defp date(value) do
    {:ok, dt, _} = DateTime.from_iso8601(value)

    dt
    |> DateTime.to_date()
    |> Calendar.strftime("%Y-%m-%d")
  end

  def info(assigns) do
    installed_info = assigns.game["installed_info"]
    metadata = assigns.game["metadata"]
    release_date = hd(metadata["releaseInfo"])["dateAdded"]
    last_update_at = metadata["lastModifiedDate"]

    ~H"""
    <dl class="info">
      <dt>Version</dt>
      <dd><%= @game["app_version"] || "Unknown" %></dd>
      <%= if installed_info do %>
        <dt>Install Path</dt>
        <dd><%= installed_info["install_path"] %></dd>
        <dt>Size in Disk</dt>
        <dd><%= Heroix.bytes_to_human(installed_info["install_size"]) %></dd>
      <% end %>
      <dt>Developer</dt>
      <dd><%= metadata["developer"] %></dd>
      <%= if release_date do %>
        <dt>Release Date</dt>
        <dd><%= date(release_date) %></dd>
      <% end %>
      <%= if last_update_at do %>
        <dt>Last Updated At</dt>
        <dd><%= datetime(last_update_at) %></dd>
      <% end %>
    </dl>
    """
  end

  def render(assigns) do
    app_name = assigns.game["app_name"]

    ~H"""
    <section id="game" class={@show_config && "show-config"}>
      <div class="left">
        <.game_image game={@game} />
        <div class="actions">
          <%= if @game["installed_info"] != nil do %>
            <%= if @game_running == app_name do %>
              <button phx-click="stop">
                <.font_icon icon="stop" />
                Stop
              </button>
            <% else %>
              <%= if @game_running == nil do %>
                <button phx-click="launch">
                  <.font_icon icon="play-alt-1" />
                  Launch
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
            <%= if @installing == app_name do %>
              <%= if @install_progress && @install_eta do %>
                Installing <%= @install_progress %>% (ETA: <%= @install_eta %>)
              <% else %>
                Starting installation...
              <% end %>
              <button phx-click="stop-installation">
                <.font_icon icon="stop" />
                Stop Installation
              </button>
            <% else %>
              <%= if Enum.member?(@install_queue, app_name) do %>
                In install queue
              <% else %>
                <button phx-click="add-game">
                  <.font_icon icon="database-add" />
                  Add Game
                </button>
              <% end %>
            <% end %>
          <% end %>
          <button id="game-config__toggle" phx-click="toggle-config">
            <%= if @show_config, do: "Close" %>
            Config
          </button>
        </div>
      </div>
      <div class="right">
        <h1><%= @game["app_title"] %></h1>
        <p class="description"><%= @game["metadata"]["description"] %></p>
        <.info game={@game} />
      </div>
      <.live_component module={GameConfigComponent} id={"game-config:#{app_name}"} app_name={app_name} />
      <%= if @show_add_game do %>
        <.live_component module={AddGameDialogComponent} id={"add-game:#{app_name}"} game_info={@game} install_info={@install_info} />
      <% end %>
    </section>
    """
  end

  #### Handle events triggered by the user

  def handle_event("launch", _, socket) do
    GameRunner.launch_game(socket.assigns.app_name)
    {:noreply, socket}
  end

  def handle_event("stop", _, socket) do
    GameRunner.stop_game()
    {:noreply, socket}
  end

  def handle_event("add-game", _, socket) do
    {:noreply, assign(socket, :show_add_game, true)}
  end

  def handle_event("uninstall", _, socket) do
    GameUninstaller.uninstall_game(socket.assigns.app_name)
    {:noreply, socket}
  end

  def handle_event("stop-installation", _, socket) do
    GameInstaller.stop_installation()
    {:noreply, socket}
  end

  def handle_event("toggle-config", _, socket) do
    {:noreply, assign(socket, :show_config, !socket.assigns.show_config)}
  end

  def handle_event("cancel-install", _data, socket) do
    {:noreply, assign(socket, :show_add_game, false)}
  end

  def handle_event("add-game-closed", _, socket) do
    {:noreply, assign(socket, :show_add_game, false)}
  end

  def handle_info("add-game-closed", socket) do
    {:noreply, assign(socket, :show_add_game, false)}
  end

  #### handle GameRunner broadcasted messages

  def handle_info(%{event: "launched", payload: %{app_name: app_name}}, socket) do
    {:noreply, assign(socket, game_running: app_name)}
  end

  def handle_info(%{event: "stopped"}, socket) do
    {:noreply, assign(socket, game_running: nil)}
  end

  #### handle GameInstaller broadcasted events

  def handle_info(%{event: "enqueued"}, socket) do
    {:noreply,
     assign(socket, installing: GameInstaller.installing(), install_queue: GameInstaller.queue())}
  end

  def handle_info(%{event: "installing"}, socket) do
    {:noreply,
     assign(socket, installing: GameInstaller.installing(), install_queue: GameInstaller.queue())}
  end

  def handle_info(%{event: "installation_progress", payload: payload}, socket) do
    %{app_name: app_name, percent: percent, eta: eta} = payload

    if app_name == socket.assigns.app_name do
      {:noreply, assign(socket, install_progress: percent, install_eta: eta)}
    else
      {:noreply, socket}
    end
  end

  def handle_info(%{event: "installed", payload: %{app_name: app_name}}, socket) do
    if app_name == socket.assigns.app_name do
      {:ok, game_info} = Legendary.game_info(app_name)

      {:noreply,
       assign(socket,
         game: game_info,
         installing: GameInstaller.installing(),
         install_queue: GameInstaller.queue(),
         install_progress: nil,
         install_eta: nil
       )}
    else
      {:noreply, socket}
    end
  end

  def handle_info(%{event: "installation_stopped", payload: %{app_name: app_name}}, socket) do
    if app_name == socket.assigns.app_name do
      {:noreply,
       assign(socket,
         installing: GameInstaller.installing(),
         install_queue: GameInstaller.queue()
       )}
    else
      {:noreply, socket}
    end
  end

  def handle_info(%{event: "install_info_ready", payload: payload}, socket) do
    %{app_name: app_name, install_info: install_info} = payload

    if socket.assigns.show_add_game do
      send_update(AddGameDialogComponent,
        id: "add-game:#{app_name}",
        install_info: install_info,
        game_info: socket.assigns.game
      )
    end

    {:noreply, assign(socket, :install_info, install_info)}
  end

  #### handle GameUninstaller broadcasted events

  def handle_info(%{event: "uninstalling"}, socket) do
    {:noreply, socket}
  end

  def handle_info(%{event: "uninstalled", payload: %{app_name: app_name}}, socket) do
    if app_name == socket.assigns.app_name do
      {:ok, game_info} = Legendary.game_info(app_name)
      {:noreply, assign(socket, game: game_info)}
    else
      {:noreply, socket}
    end
  end

  def handle_info(event, socket) do
    log("Unhandled info: #{inspect(event)}")
    {:noreply, socket}
  end

  defp log(msg) do
    Logger.info("[GameView] #{String.trim(msg)}")
  end
end
