defmodule MdlAppsWeb.Live.Auth.ConfirmEdit do
  use MdlAppsWeb, :live_view

  alias MdlApps.Accounts

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    links = prepare_links(:confirm, socket)
    {:ok, assign(socket, links: links, token: token)}
  end

  @impl true
  def handle_event("confirm", _params, socket) do
    case Accounts.confirm_user(socket.assigns.token) do
      {:ok, _user} ->
        if socket.assigns.current_user do
          Process.send_after(self(), {:redirect, :home}, 2000)
        else
          Process.send_after(self(), {:redirect, :login}, 2000)
        end

        {
          :noreply,
          socket
          |> put_flash(:info, "User confirmed successfully. Redirecting")
        }

      :error ->
        {
          :noreply,
          socket
          |> put_flash(:error, "Invalid token")
        }
    end
  end

  @impl true
  def handle_info({:redirect, :login}, socket) do
    {:noreply, push_redirect(socket, to: Routes.live_path(socket, MdlAppsWeb.Live.Auth.Login))}
  end

  def handle_info({:redirect, :home}, socket) do
    {:noreply, push_redirect(socket, to: Routes.live_path(socket, MdlAppsWeb.Live.Home))}
  end
end
