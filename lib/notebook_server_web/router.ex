defmodule NotebookServerWeb.Router do
  use NotebookServerWeb, :router

  import NotebookServerWeb.UserAuth
  import NotebookServerWeb.I18n

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {NotebookServerWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
    plug :fetch_locale
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
  # TODO: create a screen to redirect the user when it's banned
  # TODO: create a screen to redirect the user when it's inactive
  # TODO: create a screen to redirect the user when it's not confirmed
  # TODO: create a screen to redirect the user when the org it's not verified or in process of verifying
  # TODO: create a stepper to fill the required org data
  # TODO: create an onboarding screen

  scope "/", NotebookServerWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{NotebookServerWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/login", UserLoginLive, :new
      live "/register", UserRegisterLive, :new
      live "/reset-password", UserForgotPasswordLive, :new
      live "/reset-password/:token", UserResetPasswordLive, :edit
    end

    post "/login", UserSessionController, :create
  end

  scope "/", NotebookServerWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [
        {NotebookServerWeb.UserAuth, :ensure_authenticated}
      ] do
      live "/settings", UserSettingsLive, :edit
      live "/dashboard", DashboardLive.Show

      scope "/orgs" do
        pipe_through :require_admin_user

        live "/", OrgLive.Index, :index
        live "/new", OrgLive.Index, :new
        live "/:id/edit", OrgLive.Index, :edit
        live "/:id", OrgLive.Show, :show
        live "/:id/show/edit", OrgLive.Show, :edit
      end

      scope "/certificates" do
        pipe_through :require_admin_user
        live "/", CertificateLive.Index, :index
        live "/new", CertificateLive.Index, :new
        live "/:id/revoke", CertificateLive.Index, :revoke
        live "/:id/delete", CertificateLive.Index, :delete
        live "/:id", CertificateLive.Show, :show
        live "/:id/show/edit", CertificateLive.Show, :edit
      end

      scope "/bridges" do
        pipe_through :require_admin_user
        live "/", BridgeLive.Index, :index
        live "/new", BridgeLive.Index, :new
        live "/:id/edit", BridgeLive.Index, :edit
        live "/:id", BridgeLive.Show, :show
        live "/:id/show/edit", BridgeLive.Show, :edit
      end

      scope "/users" do
        pipe_through :require_org_admin_user
        live "/", UserLive.Index, :index
        live "/new", UserLive.Index, :new
        live "/:id/edit", UserLive.Index, :edit
        live "/:id", UserLive.Show, :show
        live "/:id/show/edit", UserLive.Show, :edit
      end

      scope "/schemas" do
        pipe_through :require_org_admin_user
        live "/", SchemaLive.Index, :index
        live "/new", SchemaLive.Index, :new
        live "/:id/edit", SchemaLive.Index, :edit
        live "/:id", SchemaLive.Show, :show
        live "/:id/show/edit", SchemaLive.Show, :edit
      end

      scope "/evidence-bridges" do
        pipe_through :require_org_admin_user
        live "/", EvidenceBridgeLive.Index, :index
        live "/new", EvidenceBridgeLive.Index, :new
        live "/:id/edit", EvidenceBridgeLive.Index, :edit
      end

      scope "/wall" do
        pipe_through :require_org_admin_user
        live "/show", WallLive.Show, :show
      end

      scope "/credentials" do
        live "/", CredentialLive.Index, :index
        live "/new", CredentialLive.Index, :new
        live "/:id", CredentialLive.Show, :show
        live "/:id/qr", CredentialLive.Index, :qr
      end
    end
  end

  scope "/", NotebookServerWeb do
    pipe_through [:browser]

    delete "/logout", UserSessionController, :delete

    scope "/:id/wall" do
      live "/", WallLive.Public, :show
      live "/evidence-bridges/email/:public_id", EmailEvidenceBridgeLive.FormComponent, :show
    end

    live_session :current_user,
      on_mount: [{NotebookServerWeb.UserAuth, :mount_current_user}] do
      live "/confirm/:token", UserConfirmationLive, :edit
      live "/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
