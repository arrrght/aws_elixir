defmodule HelloWeb.PageController do
  use HelloWeb, :controller
  import Ecto.Query
  alias Hello.{Repo, Rep, Curl}


  def curl(conn, _params) do
    {_ans, body} = Curl.get_list()
    render(conn, "curl.html", data: body)
    #redirect(conn, to: "/")
  end

  def index(conn, %{"min_stars" => stars }) do
    data = Curl.get_it_back2(stars)
    render(conn, "index.html", data: data)
  end

  def index(conn, _params) do
    data = Curl.get_it_back2(2)
    render(conn, "index.html", data: data)
  end
end
