defmodule MdlAppsWeb.UserAuth do
  use Phoenix.Controller
  import Plug.Conn

  alias MdlApps.Accounts
  alias MdlAppsWeb.Router.Helpers, as: Routes

  @max_age 60 * 60 * 24 * 60
  @remember_me_cookie "_mdlapps_web_user_remember_me"
  @remember_me_options [sign: true, max_age: @max_age, same_site: "Lax"]

  @doc """
  Create user session data for authentication
  """
  @spec login_user(Plug.Conn.t(), %Accounts.User{}, map) :: Plug.Conn.t()
  def login_user(conn, user, params \\ %{}) do
    token = Accounts.generate_user_session_token(user)

    conn
    |> renew_session()
    |> put_session(:user_token, token)
    |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
    |> maybe_write_remember_me_cookie(token, params)
    |> redirect(to: Routes.live_path(conn, MdlAppsWeb.Live.Home))
  end

  defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}) do
    put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
  end

  defp maybe_write_remember_me_cookie(conn, _token, _params) do
    conn
  end

  @doc """
  Destroy user session data for logout
  """
  @spec log_out_user(Plug.Conn.t()) :: Plug.Conn.t()
  def log_out_user(conn) do
    user_token = get_session(conn, :user_token)
    user_token && Accounts.delete_session_token(user_token)

    if live_socket_id = get_session(conn, :live_socket_id) do
      MdlAppsWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session()
    |> delete_resp_cookie(@remember_me_cookie)
    |> redirect(to: Routes.live_path(conn, MdlAppsWeb.Live.Auth.Login))
  end

  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  @doc """
  Gets the current authenticated user by the session token
  """
  @spec fetch_current_user(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def fetch_current_user(conn, _opts \\ []) do
    {user_token, conn} = ensure_user_token(conn)
    user = user_token && Accounts.get_user_by_session_token(user_token)
    assign(conn, :current_user, user)
  end

  defp ensure_user_token(conn) do
    if user_token = get_session(conn, :user_token) do
      {user_token, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if user_token = conn.cookies[@remember_me_cookie] do
        {user_token, put_session(conn, :user_token, user_token)}
      else
        {nil, conn}
      end
    end
  end

  @doc """
  Redirects the user to the homepage if authenticated
  """
  @spec redirect_if_user_is_authenticated(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def redirect_if_user_is_authenticated(conn, _opts \\ []) do
    if conn.assigns[:current_user] do
      conn
      |> redirect(to: signed_in_path(conn))
      |> halt()
    else
      conn
    end
  end

  @doc """
  Redirects the user to the login page if not authenticated
  """
  @spec require_authenticated_user(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def require_authenticated_user(conn, _opts \\ []) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> maybe_store_return_to()
      |> redirect(to: Routes.live_path(conn, MdlAppsWeb.Live.Auth.Login))
      |> halt()
    end
  end

  @doc """
  Redirects the user to the confirmation page if account not confirmed
  """
  @spec require_confirmed_user(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def require_confirmed_user(conn, _opts \\ []) do
    with %Accounts.User{} = user <- conn.assigns[:current_user],
         false <- is_nil(user.confirmed_at) do
      conn
    else
      _ ->
        conn
        |> put_flash(:error, "Please confirm your account before continuing.")
        |> redirect(to: Routes.live_path(conn, MdlAppsWeb.Live.Auth.ConfirmNew))
        |> halt()
    end
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :user_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn

  defp signed_in_path(conn), do: Routes.live_path(conn, MdlAppsWeb.Live.Home)
end
