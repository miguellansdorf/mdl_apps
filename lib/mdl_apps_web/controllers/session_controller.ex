defmodule MdlAppsWeb.SessionController do
  use MdlAppsWeb, :controller

  alias MdlApps.Accounts
  alias MdlAppsWeb.UserAuth

  def create(conn, %{"user" => user_params}) do
    %{"login" => login, "password" => password} = user_params

    case Accounts.get_user_by_credentials(login, password) do
      {:ok, user} ->
        UserAuth.login_user(conn, user, user_params)

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Invalid credentials")
        |> redirect(to: Routes.live_path(conn, MdlAppsWeb.Live.Auth.Login))
    end
  end

  def delete(conn, _args) do
    conn
    |> put_flash(:info, "Logged out successfully")
    |> UserAuth.log_out_user()
  end
end
