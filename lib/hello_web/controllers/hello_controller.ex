defmodule HelloWeb.HelloController do
  use HelloWeb, :controller

  def index(conn, _param), do: render(conn, "index.html")

  def show(conn, %{"messenger" => messenger}) do
    render(conn, "show.html", messenger: messenger)
  end
end
