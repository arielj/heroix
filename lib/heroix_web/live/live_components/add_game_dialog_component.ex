defmodule HeroixWeb.AddGameDialogComponent do
  use HeroixWeb, :live_component

  alias Phoenix.LiveView.JS

  alias Heroix.Settings
  alias Heroix.GameInstaller

  def hide_modal(js \\ %JS{}, send_closed_event \\ true) do
    js
    |> JS.hide(transition: "fade-out", to: "#modal")
    |> JS.hide(transition: "fade-out-scale", to: "#modal-content")
    |> push_close(send_closed_event)
  end

  def push_close(js, false), do: js
  def push_close(js, true), do: JS.push(js, "add-game-closed")

  def confirm_install(js \\ %JS{}) do
    js
    |> hide_modal(false)
    |> JS.push("confirm-install")
  end

  def render(assigns) do
    ~H"""
    <div id="add-game-modal" class="modal" phx-remove={hide_modal()}>
      <div
        id="modal-content"
        class="modal-content"
        phx-click-away={hide_modal()}
        phx-window-keydown={hide_modal()}
        phx-key="escape"
      >
        <button class="phx-modal-close" phx-click={hide_modal()}>✖</button>
        <%= if @install_info do %>
          <span>Install</span>
          <h2><%= @install_info["game"]["title"] %></h2>
          <div><label>Download Size:</label> <%= Heroix.bytes_to_human(@install_info["manifest"]["download_size"]) %></div>
          <div><label>Installed Size:</label> <%= Heroix.bytes_to_human(@install_info["manifest"]["disk_size"]) %></div>
          <form phx-change="install-config-changed" phx-target={@myself}>
            <label>Install Folder (base path can be edited):</label>
            <div class="install-folder">
              <input type="hidden" name="install-path" value={@install_path} />
              <span id="base-path" class="base-path" contenteditable="true" phx-hook="ContentEditable" phx-update="ignore" data-input-name="install-path"><%= @install_path %></span>
              /
              <span><%= @game_info["metadata"]["customAttributes"]["FolderName"]["value"] %></span>
            </div>
            <button type="button" phx-click={confirm_install()} phx-target={@myself}>Install</button>
            <button type="button" phx-click={hide_modal()}>Cancel</button>
          </form>
        <% else %>
          <div>loading</div>
        <% end %>
      </div>
    </div>
    """
  end

  def update(assigns, socket) do
    {:ok,
     assign(socket,
       game_info: assigns.game_info,
       install_info: Map.get(assigns, :install_info, nil),
       install_path: Map.get(assigns, :install_path, Settings.legendary()["install_dir"]),
       default: Settings.legendary_game_config(:default)
     )}
  end

  def handle_event("add-game-closed", _data, socket) do
    send(self(), "add-game-closed")
    {:noreply, socket}
  end

  def handle_event("confirm-install", _data, socket) do
    install_options = %{
      "install_path" => socket.assigns.install_path
    }

    GameInstaller.install_game(socket.assigns.game_info["app_name"], install_options)

    send(self(), "add-game-closed")

    {:noreply, socket}
  end

  def handle_event("install-config-changed", data, socket) do
    install_path =
      data["install-path"] ||
        socket.assigns.install_path
        |> String.replace("\n", "")

    {:noreply, assign(socket, :install_path, install_path)}
  end
end
