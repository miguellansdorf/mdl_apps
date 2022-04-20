defmodule MdlAppsWeb.Live.Auth.ConfirmNew do
  use MdlAppsWeb, :live_view

  alias MdlApps.Accounts

  @impl true
  def mount(_args, _session, socket) do
    links = prepare_links(:confirm, socket)
    {:ok, assign(socket, links: links)}
  end

  @impl true
  def handle_event("resend", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.send_user_confirmation_instructions(
        user,
        &Routes.live_url(socket, MdlAppsWeb.Live.Auth.ConfirmEdit, &1)
      )
    end

    {
      :noreply,
      socket
      |> put_flash(:info, "Instructions have been sent to your mailbox")
    }
  end
end
