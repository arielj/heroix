defmodule HeroixWeb.SettingsView do
  use HeroixWeb, :live_view

  # import HeroixWeb.FontIconComponent

  @langs %{"en" => "English", "es" => "Español"}
  @save_on_change ["language"]

  def mount(_, _, socket) do
    settings = GenServer.call(Settings, :global)

    {:ok, assign(socket, settings: settings )}
  end

  def render(assigns) do
    langs = @langs
    ~H"""
    <div id="global_settings">
      <form phx-change="change">
        <div class="input-field">
          <label for="language"><%= gettext("Language") %></label>
          <select  id="language" name="language">
            <%= for {lang_code, language} <- langs do %>
              <option value={lang_code} selected={lang_code == @settings["language"]}><%= language %></option>
            <% end %>
          </select>
        </div>

        <div class="input-field">
          <label for="default_install_path"><%= gettext("Default install path") %></label>
          <input phx-blur="blur" type="text" value={@settings["default_install_path"]} id="default_install_path" name="default_install_path" />
        </div>
      </form>
    </div>
    """
  end

  # update global settings, save them immediately in some cases
  def handle_event("change", data, socket) do
    key = List.first(data["_target"])
    value = data[key]
    settings = GenServer.call(Settings, {:set_global, key, value, save: Enum.member?(@save_on_change, key)})
    {:noreply, assign(socket, :settings, settings)}
  end

  # save global settings when some fields are blured
  def handle_event("blur", _, socket) do
    GenServer.cast(Settings, :save_global)
    {:noreply, socket}
  end
end
