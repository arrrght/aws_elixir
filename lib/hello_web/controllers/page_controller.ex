defmodule HelloWeb.PageController do
  use HelloWeb, :controller

  def md_parse([], _), do: %{}
  #def md_parse([_v],_), do: %{}

  def md_parse([str|rest], arr) do
    result = cond do
      Regex.match?(~r/^##.+/, str)    -> Regex.named_captures(~r/^## (?<grp_name>.+$)/, str)
      Regex.match?(~r/^\*.+\*$/, str) -> Regex.named_captures(~r/^\*(?<grp_info>.+\*$)/, str)
      Regex.match?(~r/^\* \[/, str)   -> Regex.named_captures(~r/^\* \[(?<rep>.+)\]\((?<url>.+)\) - (?<desc>.+$)/, str)
      true -> []
    end
    IO.inspect result
    md_parse(rest, [])
    "OK"
  end
    
  def get_list() do
    case HTTPoison.get("https://raw.githubusercontent.com/h4cc/awesome-elixir/master/README.md") do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        IO.puts "Got that"
        {:ok, md_parse(String.split(body, "\n"), [])}
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        IO.puts "404"
        {:error, "404"}
      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.puts "Some err:"
        IO.inspect reason
        {:error, "some"}
    end
  end

  def curl(conn, _params) do
    {ans, body} = get_list()
    render(conn, "index.html")
    #redirect(conn, to: "/")
  end

  def index(conn, %{"stars" => stars }) do
    render(conn, "index.html", stars: stars)
  end

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
