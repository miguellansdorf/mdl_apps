defmodule MdlAppsWeb.Live.Home do
  use MdlAppsWeb, :live_view

  @impl true
  def mount(_args, _session, socket) do
    links = prepare_links(:home, socket)
    {:ok, assign(socket, links: links)}
  end
end
