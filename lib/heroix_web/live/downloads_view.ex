defmodule HeroixWeb.DownloadsView do
  use HeroixWeb, :live_view

  alias Heroix.GameInstaller

  def mount(_, _, socket) do
    queue = GameInstaller.queue()
    installing = GameInstaller.installing()

    HeroixWeb.Endpoint.subscribe("game_status")

    {:ok,
     assign(socket,
       page_title: "Downloads",
       queue: queue,
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
        <div>
          <label><%= @installing %></label>
          <span>Progress: <%= @installation_progress %>%</span>
          <span>ETA: <%= @installation_eta %></span>
          <button phx-click="stop">Stop</button>
        </div>
      <% end %>

      <%= for game <- @queue do %>
        <div>
          <label><%= game %></label>
        </div>
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

    {:noreply, assign(socket, queue: queue, installing: installing)}
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
    IO.inspect("Unhandled info: #{inspect(event)}")
    {:noreply, socket}
  end
end
