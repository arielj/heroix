defmodule HeroixWeb.FontIconComponent do
  use Phoenix.Component

  def font_icon(assigns) do
    ~H"""
    <i class={"icofont-#{@icon}"} />
    """
  end
end
