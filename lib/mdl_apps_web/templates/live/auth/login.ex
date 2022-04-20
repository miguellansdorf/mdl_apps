defmodule MdlAppsWeb.Live.Auth.Login do
  use MdlAppsWeb, :live_view

  @impl true
  def mount(_args, _session, socket) do
    links = prepare_links(:login, socket)
    {:ok, assign(socket, links: links)}
  end
end
