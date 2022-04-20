defmodule MdlAppsWeb.Live.Account.Profile do
  use MdlAppsWeb, :live_view

  alias MdlApps.Accounts

  @avatar_options [
    adventurer: "adventurer",
    "adventurer-neutral": "adventurer-neutral",
    avataaars: "avataaars",
    "big-ears": "big-ears",
    "big-ears-neutral": "big-ears-neutral",
    "big-smile": "big-smile",
    bottts: "bottts",
    croodles: "croodles",
    "croodles-neutral": "croodles-neutral",
    identicon: "identicon",
    initials: "initials",
    micah: "micah",
    miniavs: "miniavs",
    "open-peeps": "open-peeps",
    personas: "personas",
    "pixel-art": "pixel-art",
    "pixel-art-neutral": "pixel-art-neutral"
  ]

  @impl true
  def mount(_args, %{"user_token" => token}, socket) do
    links = prepare_links(:profile, socket)

    password_changeset =
      Accounts.change_user_change_password(%Accounts.User{}, %{}, socket.assigns.current_user,
        hash_password: false,
        should_verify: false
      )

    {:ok,
     assign(socket,
       links: links,
       token: token,
       password_changeset: password_changeset,
       avatar_options: @avatar_options
     )}
  end

  @impl true
  def handle_event("select_avatar", %{"avatar" => _avatar} = params, socket) do
    case Accounts.change_user_avatar(socket.assigns.current_user, params) do
      {:error, _changeset} ->
        {
          :noreply,
          socket
          |> put_flash(:error, "Incorrect avatar")
        }

      {:ok, user} ->
        {
          :noreply,
          socket
          |> clear_flash()
          |> assign(current_user: user)
        }
    end
  end

  def handle_event("validate_password", %{"user" => user_params}, socket) do
    changeset =
      %Accounts.User{}
      |> Accounts.change_user_change_password(user_params, socket.assigns.current_user,
        hash_password: false,
        should_verify: false
      )
      |> Map.put(:action, :update)

    {:noreply, assign(socket, password_changeset: changeset)}
  end

  def handle_event("change_password", %{"user" => user_params}, socket) do
    case Accounts.change_user_password(
           socket.assigns.current_user,
           user_params,
           socket.assigns.token
         ) do
      {:error, changeset} ->
        changeset = Map.put(changeset, :action, :update)

        {
          :noreply,
          socket
          |> put_flash(:error, "Something went wrong. Please check the errors below")
          |> assign(password_changeset: changeset)
        }

      {:ok, _user} ->
        {
          :noreply,
          socket
          |> put_flash(:info, "Password changed successfully. Redirecting to login page")
          |> push_redirect(to: Routes.live_path(socket, MdlAppsWeb.Live.Auth.Login))
        }
    end
  end
end
