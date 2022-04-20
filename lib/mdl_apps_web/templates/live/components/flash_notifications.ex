defmodule MdlAppsWeb.Live.Components.FlashNotifications do
  use MdlAppsWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <p class="text-center text-white bg-sky-500" role="alert"
        phx-click="lv:clear-flash"
        phx-value-key="info"><%= live_flash(@flash, :info) %></p>
    
      <p class="text-center text-white bg-red-600" role="alert"
          phx-click="lv:clear-flash"
          phx-value-key="error"><%= live_flash(@flash, :error) %></p>
    </div>
    """
  end
end
