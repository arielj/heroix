defmodule HeroixWeb.SidebarComponent do
  use HeroixWeb, :live_component

  # alias Phoenix.LiveView.JS
  import HeroixWeb.FontIconComponent

  def render(assigns) do
    ~H"""
    <aside>
      <%= if @current_user do %>
        <%= link to: "/session" do %>
          <.font_icon icon="user" /> <%= @current_user %>
        <% end  %>
        <%= link to: "/library" do %>
          <.font_icon icon="table" /> <%= gettext("Library") %>
        <% end  %>
      <% else %>
        <%= link to: "/login" do %>
          <.font_icon icon="login" /> <%= gettext("Login") %>
        <% end  %>
      <% end %>
      <%= link to: "/settings" do %>
        <.font_icon icon="ui-settings" /> <%= gettext("Settings") %>
      <% end  %>
      <%= link to: "/downloads" do %>
        <.font_icon icon="download-alt" /> <%= gettext("Downloads") %>
      <% end  %>
    </aside>
    """
  end

  def update(assigns, socket) do
    {:ok, assign(socket, current_user: assigns.current_user)}
  end
end
