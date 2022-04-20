defmodule MdlAppsWeb.Live.Auth.Register do
  use MdlAppsWeb, :live_view

  alias MdlApps.Accounts

  @impl true
  def mount(_arg, _session, socket) do
    links = prepare_links(:register, socket)

    {:ok,
     assign(socket,
       links: links,
       changeset: Accounts.change_user_registration(%Accounts.User{}, %{}, hash_password: false)
     )}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      %Accounts.User{}
      |> Accounts.change_user_registration(user_params, hash_password: false)
      |> Map.put(:action, :insert)

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.send_user_confirmation_instructions(
            user,
            &Routes.live_url(socket, MdlAppsWeb.Live.Auth.ConfirmEdit, &1)
          )

        {:noreply,
         socket
         |> put_flash(
           :info,
           "Registration was successful. An email has been sent to you with further instructions"
         )
         |> push_redirect(to: Routes.live_path(socket, MdlAppsWeb.Live.Auth.ConfirmNew))}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
