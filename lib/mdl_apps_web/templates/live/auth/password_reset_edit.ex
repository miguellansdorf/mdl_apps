defmodule MdlAppsWeb.Live.Auth.PasswordResetEdit do
  use MdlAppsWeb, :live_view

  alias MdlApps.Accounts

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    case Accounts.verify_user_reset_password_token(token) do
      :ok ->
        links = prepare_links(:password_reset, socket)

        {:ok,
         assign(socket,
           links: links,
           token: token,
           changeset:
             Accounts.change_user_reset_password(%Accounts.User{}, %{}, hash_password: false)
         )}

      :error ->
        {:ok,
         socket
         |> put_flash(:error, "Token invalid or expired")
         |> push_redirect(to: Routes.live_path(socket, MdlAppsWeb.Live.Auth.PasswordResetNew))}
    end
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      %Accounts.User{}
      |> Accounts.change_user_reset_password(user_params, hash_password: false)
      |> Map.put(:action, :update)

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("reset", %{"user" => params}, socket) do
    case Accounts.reset_password_user(socket.assigns.token, params) do
      {:ok, _} ->
        {
          :noreply,
          socket
          |> put_flash(:info, "Password reset successfully")
          |> push_redirect(to: Routes.live_path(socket, MdlAppsWeb.Live.Auth.Login))
        }

      :error ->
        {
          :noreply,
          socket
          |> put_flash(:error, "Token invalid or expired")
          |> push_redirect(to: Routes.live_path(socket, MdlAppsWeb.Live.Auth.PasswordResetNew))
        }
    end
  end
end
