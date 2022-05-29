defmodule HeroixWeb.GameImageComponent do
  use Phoenix.Component

  def game_image(assigns) do
    app_name = assigns.game["app_name"]

    ~H"""
    <div class="game_image">
      <img src={"/image/#{app_name}/tall"} class="cover" />
      <%= if has_logo(@game) do %>
        <img src={"/image/#{app_name}/logo"} class="logo" />
      <% end %>
    </div>
    """
  end

  defp has_logo(game) do
    Heroix.get_game_image(game, "logo") != nil
  end
end
