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

          <div>
            <h3>Download Size</h3>
              <%= if @reusable_percent > 0 do %>
                <b>A paused download was found in the selected directory</b>
                <br />
                Total download size: <%= Heroix.bytes_to_human(@total_download) %>
                <br />
                To download: <%= Heroix.bytes_to_human(@download_info) %> (Found: <%= Heroix.bytes_to_human(@total_download - @download_info) %> (<%= @reusable_percent %>%))
              <% else %>
                <%= Heroix.bytes_to_human(@total_download) %>
              <% end %>
          </div>

          <div>
            <label>Installed Size:</label> <%= Heroix.bytes_to_human(@install_info["manifest"]["disk_size"]) %>
          </div>

          <form phx-change="install-config-changed" phx-target={@myself}>
            <label>Install Folder (base path can be edited):</label>
            <div class="install-folder">
              <input type="hidden" name="install-path" value={@install_path} phx-debounce="500" />
              <span id="base-path" class="base-path" contenteditable="true" phx-hook="ContentEditable" phx-update="ignore" data-input-name="install-path"><%= @install_path %></span>
              /
              <span><%= @game_info["metadata"]["customAttributes"]["FolderName"]["value"] %></span>
            </div>
            <%= if @calculating_download do %>
              Calculating download... wait
            <% else %>
              <button type="button" phx-click={confirm_install()} phx-target={@myself}>Install</button>
            <% end %>
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
    install_info = Map.get(assigns, :install_info, nil)
    total_download = if install_info, do: install_info["manifest"]["download_size"], else: nil
    download_info = Map.get(assigns, :download_info, nil)

    reusable_percent =
      if total_download && download_info do
        x = 100 * (total_download - download_info) / total_download
        Float.round(x, 1)
      else
        0
      end

    {:ok,
     assign(socket,
       game_info: assigns.game_info,
       install_info: install_info,
       total_download: total_download,
       download_info: download_info,
       reusable_percent: reusable_percent,
       install_path: Map.get(assigns, :install_path, Settings.legendary()["install_dir"]),
       default: Settings.legendary_game_config(:default),
       calculating_download: assigns.calculating_download
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

    GameInstaller.fetch_download_info(socket.assigns.game_info["app_name"], install_path)

    {:noreply, assign(socket, install_path: install_path, calculating_download: true)}
  end
end
