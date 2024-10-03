defmodule NotebookServerWeb.Router do
  use NotebookServerWeb, :router

  import NotebookServerWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {NotebookServerWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", NotebookServerWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", NotebookServerWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:notebook_server, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: NotebookServerWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", NotebookServerWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{NotebookServerWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/login", UserLoginLive, :new
      live "/reset-password", UserForgotPasswordLive, :new
      live "/reset-password/:token", UserResetPasswordLive, :edit
    end

    post "/login", UserSessionController, :create
  end

  scope "/", NotebookServerWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{NotebookServerWeb.UserAuth, :ensure_authenticated}] do
      live "/settings", UserSettingsLive, :edit
      delete "/logout", UserSessionController, :delete

      scope "/orgs" do
        pipe_through :require_admin_user

        live "/", OrgLive.Index, :index
        live "/new", OrgLive.Index, :new
        live "/:id/edit", OrgLive.Index, :edit
        live "/:id", OrgLive.Show, :show
        live "/:id/show/edit", OrgLive.Show, :edit
      end

      scope "/users" do
        #live "/", UserLive.Index, :index
        #live "/new", UserLive.Index, :new
        #live "/:id/edit", UserLive.Index, :edit
        #live "/:id", UserLive.Show, :show
        #live "/:id/show/edit", UserLive.Show, :edit
      end
    end
  end
end
