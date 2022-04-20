defmodule MdlAppsWeb.Router do
  use MdlAppsWeb, :router

  import MdlAppsWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {MdlAppsWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Open routes
  scope "/", MdlAppsWeb do
    pipe_through :browser

    live_session :main, on_mount: MdlAppsWeb.Live.OnMount do
      live "/auth/confirm", Live.Auth.ConfirmNew
      live "/auth/confirm/:token", Live.Auth.ConfirmEdit
    end
  end

  # Requires no authentication
  scope "/auth", MdlAppsWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :no_auth, on_mount: MdlAppsWeb.Live.OnMount do
      live "/register", Live.Auth.Register
      live "/login", Live.Auth.Login
      live "/password_reset", Live.Auth.PasswordResetNew
      live "/password_reset/:token", Live.Auth.PasswordResetEdit
    end

    post "/session", SessionController, :create
  end

  # Requires authentication but not confirmation
  scope "/", MdlAppsWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :main_auth, on_mount: MdlAppsWeb.Live.OnMount do
      live "/", Live.Home
      live "/user/profile", Live.Account.Profile
    end

    delete "/auth/session", SessionController, :delete
  end

  # Requires authentication and confirmation
  scope "/", MdlAppsWeb do
    pipe_through [:browser, :require_authenticated_user, :require_confirmed_user]
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: MdlAppsWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
