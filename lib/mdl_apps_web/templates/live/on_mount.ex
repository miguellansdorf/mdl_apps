defmodule MdlAppsWeb.Live.OnMount do
  import Phoenix.LiveView

  alias MdlApps.Accounts

  def on_mount(:default, _params, session, socket) do
    user_token = session["user_token"]
    user = user_token && Accounts.get_user_by_session_token(user_token)
    {:cont, assign(socket, :current_user, user)}
  end
end
