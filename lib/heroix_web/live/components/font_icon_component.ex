defmodule HeroixWeb.FontIconComponent do
  use HeroixWeb, :component

  def font_icon(assigns) do
    ~H"""
    <i class={"icofont-#{@icon}"} />
    """
  end
end
