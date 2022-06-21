defmodule LaphubWeb.Router do
  use LaphubWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {LaphubWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", LaphubWeb do
    pipe_through :browser

    get "/", PageController, :index

    post "/account/login", AccountController, :login
    live "/account/login", LoginLive, :login_form
    live "/account/reset", ResetLive, :reset_form

    live "/account/register", RegisterLive, :register_form

    live "/laps", SessionsView
    live "/laps/:s", LapView

  end

  # Other scopes may use custom stacks.
  # scope "/api", LaphubWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/", LaphubWeb do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: Telemetry
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
