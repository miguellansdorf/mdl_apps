defmodule MdlAppsWeb.Live.Components.Avatar do
  use MdlAppsWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <img src={"http://localhost:3000/api/#{@style}/#{@seed}.svg"} alt="">
    """
  end
end
