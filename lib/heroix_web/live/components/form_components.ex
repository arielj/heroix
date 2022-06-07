defmodule HeroixWeb.FormComponents do
  use HeroixWeb, :component

  def config_text_field(assigns) do
    ~H"""
    <div class="form-field text-field">
      <label for={@key}><%= @label %></label>
      <input id={@key} name={@key} type="text" value={@value} phx-blur="blur" phx-target={@target} phx-value-blurred={@key} />
      <p class="hint">
        (?) <%= @hint %>
        <br />
        Defaults to: <%= @default %>
      </p>
    </div>
    """
  end

  def config_yes_no_field(assigns) do
    ~H"""
    <div class="form-field yes-no-field">
      <label><%= @label %></label>
      <div class="yes-no-options">
        <label>Yes <input name={@key} type="radio" value="true" checked={@value == "true"} /></label>
        /
        <label>No <input name={@key} type="radio" value="false" checked={@value == "false"} /></label>
        /
        <label>Default <input name={@key} type="radio" value="" checked={!@value || @value == ""} /></label>
      </div>
      <p class="hint">
        (?) <%= @hint %>
        <br />
        Defaults to: <%= @default %>
      </p>
    </div>
    """
  end
end
