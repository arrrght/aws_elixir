defmodule HelloWeb.Router do
  use HelloWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HelloWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/curl", PageController, :curl
    get "/hello", HelloController, :index
    get "/hello/:messenger", HelloController, :show
    forward "/jobs", BackgroundJob.Plug
    #get "/", RootController, :index
  end

  # Other scopes may use custom stacks.
  #scope "/api", HelloWeb do
  #  #pipe_through [:authenticate_user, :ensure_admin]
  #  forward "/jobs", BackgroundJob.Plug
  #end
end
