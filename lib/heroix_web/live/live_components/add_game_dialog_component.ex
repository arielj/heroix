defmodule HeroixWeb.AddGameDialogComponent do
  use HeroixWeb, :live_component

  alias Phoenix.LiveView.JS

  alias Heroix.Settings

  def hide_modal(js \\ %JS{}) do
    js
    |> JS.hide(transition: "fade-out", to: "#modal")
    |> JS.hide(transition: "fade-out-scale", to: "#modal-content")
    |> JS.push("add-game-closed")
  end

  def confirm_install(js \\ %JS{}) do
    js
    |> hide_modal()
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
          <form phx-change="config-changed" phx-target={@myself}>
            <label>Install Folder:</label>
            <span><%= @legendary_config["install_dir"]%>/<%= @game_info["metadata"]["customAttributes"]["FolderName"]["value"] %></span>
            <%= if @show_edit_path do %>
              <div class="form-field text-field">
                <input id="install-folder" name="install-folder" value={@legendary_config["install_dir"]} />
              </div>
            <% else %>
              <button type="button" phx-click="show-edit-path" phx-target={@myself}>Edit</button>
            <% end %>

            <button type="button" phx-click={confirm_install()}>Install</button>
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
       legendary_config: Settings.legendary(),
       default: Settings.legendary_game_config(:default),
       show_edit_path: Map.get(assigns, :show_edit_path, false)
     )}
  end

  def handle_event("show-edit-path", _data, socket) do
    {:noreply, assign(socket, :show_edit_path, true)}
  end
end
