defmodule HeroixWeb.SettingsView do
  use HeroixWeb, :live_view

  import HeroixWeb.FormComponents
  alias Heroix.Settings
  # import HeroixWeb.FontIconComponent

  @langs %{"en" => "English", "es" => "Español"}
  @settings_metadata %{
    "language" => %{
      apply_to: "heroix",
      save_on_change: true,
      label: gettext("Heroix's Language"),
      default: "en",
      hint: ""
    },
    "default_prefixes_folder" => %{
      apply_to: "heroix",
      save_on_change: false,
      label: gettext("Default Prefixes Folder"),
      default: "No prefix?",
      hint: ""
    },
    "install_dir" => %{
      apply_to: "legendary",
      save_on_change: false,
      label: gettext("Default Installation Folder"),
      default: "~/Games",
      hint: ""
    },
    "debug_level" => %{
      apply_to: "legendary",
      save_on_change: true,
      label: gettext("Debug Level"),
      default: "?",
      hint: ""
    },
    "wrapper" => %{
      apply_to: "default",
      save_on_change: false,
      label: gettext("Wrapper"),
      default: "No wrapper",
      hint: ""
    },
    "wine_executable" => %{
      apply_to: "default",
      save_on_change: false,
      label: gettext("Wine Executable"),
      default: "wine",
      hint: ""
    },
    "wine_prefix" => %{
      apply_to: "default",
      save_on_change: false,
      label: gettext("Wine Prefix"),
      default: "No prefix",
      hint: ""
    }
  }

  def mount(_, _, socket) do
    {:ok,
     assign(socket,
       page_title: "Global settings",
       global: Settings.global(),
       legendary: Settings.legendary(),
       game_defaults: Settings.defaults()
     )}
  end

  def config_field(assigns) do
    metadata = @settings_metadata[assigns.key]

    ~H"""
      <.config_text_field
        label={metadata.label}
        hint={metadata.hint}
        key={@key}
        value={@value}
        default={metadata.default}
        target="form"
      />
    """
  end

  def render(assigns) do
    langs = @langs

    ~H"""
    <section id="global_settings">
      <form phx-change="change">
        <div class="input-field">
          <label for="language"><%= gettext("Language") %></label>
          <select  id="language" name="language">
            <%= for {lang_code, language} <- langs do %>
              <option value={lang_code} selected={lang_code == @global["language"]}><%= language %></option>
            <% end %>
          </select>
        </div>

        <.config_field key="install_dir" value={@legendary["install_dir"]} />

        <.config_field key="default_prefixes_folder" value={@global["default_prefixes_folder"]} />
      </form>
    </section>
    """
  end

  def set_setting("heroix", key, value, save) do
    new_global = Settings.set_global_config(key, value, save)
    {:global, new_global}
  end

  def set_setting("legendary", key, value, save) do
    new_legendary = Settings.set_legendary_config(key, value, save)
    {:legendary, new_legendary}
  end

  def set_setting("default", key, value, save) do
    new_default = Settings.set_default_config(key, value, save)
    {:default, new_default}
  end

  # update global settings, save them immediately in some cases
  def handle_event("change", data, socket) do
    key = List.first(data["_target"])
    value = data[key]
    setting_metadata = @settings_metadata[key]

    {assign_key, assign_value} =
      set_setting(setting_metadata.apply_to, key, value, setting_metadata.save_on_change)

    {:noreply, assign(socket, assign_key, assign_value)}
  end

  # save global settings when some fields are blured
  def handle_event("blur", data, socket) do
    key = data["blurred"]
    setting_metadata = @settings_metadata[key]

    case setting_metadata.apply_to do
      "heroix" ->
        IO.puts("heroixxxx")
        Settings.save_global()

      x when x in ["legendary", "default"] ->
        Settings.save_legendary_config()
    end

    {:noreply, socket}
  end
end
