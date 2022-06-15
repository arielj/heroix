defmodule HeroixWeb.DownloadsView do
  use HeroixWeb, :live_view
  use HeroixLog, "DownloadsView"

  alias Heroix.GameInstaller
  alias Heroix.Legendary

  def mount(_, _, socket) do
    queue = GameInstaller.queue()
    installing = GameInstaller.installing()

    HeroixWeb.Endpoint.subscribe("game_status")

    {:ok,
     assign(socket,
       page_title: "Downloads",
       queue: queue,
       games_info: games_info_for(installing, queue),
       installing: installing,
       installation_progress: "",
       installation_eta: ""
     )}
  end

  def render(assigns) do
    ~H"""
    <section id="downloads">
      <h1>Downloads</h1>
      <%= if @installing do %>
        <div class="download current">
          <label><%= @games_info[@installing]["app_title"] %></label>
          <img src={"/image/#{@installing}/wide"} class="cover" />
          <span>Progress: <%= @installation_progress %>%</span>
          <span>ETA: <%= @installation_eta %></span>
          <button phx-click="stop">Stop</button>
        </div>
      <% end %>

      <%= if length(@queue) > 0 do %>
        <h3>Next in queue</h3>
        <%= for queue_item <- @queue do %>
          <div class="download queue">
            <img src={"/image/#{queue_item.app_name}/wide"} class="cover" />
            <label><%= @games_info[queue_item.app_name]["app_title"] %></label>
          </div>
        <% end %>
      <% end %>
    </section>
    """
  end

  def handle_event("stop", %{}, socket) do
    GameInstaller.stop_installation()
    {:noreply, socket}
  end

  def handle_info(%{event: event}, socket) when event in ["installing", "enqueued"] do
    queue = GameInstaller.queue()
    installing = GameInstaller.installing()

    {:noreply,
     assign(socket,
       queue: queue,
       installing: installing,
       games_info: games_info_for(installing, queue)
     )}
  end

  def handle_info(%{event: event}, socket) when event in ["installed", "installation_stopped"] do
    queue = GameInstaller.queue()
    installing = GameInstaller.installing()

    {:noreply,
     assign(socket,
       installing: installing,
       queue: queue,
       installation_progress: "",
       installation_eta: ""
     )}
  end

  def handle_info(%{event: "installation_progress", payload: payload}, socket) do
    %{percent: percent, eta: eta} = payload

    {:noreply, assign(socket, installation_progress: percent, installation_eta: eta)}
  end

  def handle_info(event, socket) do
    log("Unhandled info: #{inspect(event)}")
    {:noreply, socket}
  end

  def games_info_for(installing, queue) do
    app_names = Enum.map(queue, fn queue_item -> queue_item.app_name end) ++ [installing]

    app_names
    |> Legendary.games_info()
    |> Enum.map(fn {:ok, json} -> {json["app_name"], json} end)
    |> Enum.into(%{})
  end
end
