defmodule HelloWeb.PageController do
  use HelloWeb, :controller

  def md_parse([], res), do: res
  def md_parse([str|rest], arr) do
    result = cond do
      Regex.match?(~r/^##.+/, str)    -> Regex.named_captures(~r/^## (?<grp_name>.+$)/, str)
      Regex.match?(~r/^\*.+\*$/, str) -> Regex.named_captures(~r/^\*(?<grp_desc>.+\*$)/, str)
      Regex.match?(~r/^\* \[/, str)   -> Regex.named_captures(~r/^\* \[(?<rep>.+)\]\((?<url>.+)\) - (?<desc>.+$)/, str)
      true -> %{}
    end
    #IO.inspect result
    md_parse(rest, [result | arr])
  end
    
  def clean_up(some), do: clean_up(some, [], %{})
  def clean_up([], some, _), do: some
  def clean_up([h|t], some, cur) when h == %{}, do: clean_up(t, some, cur)
  def clean_up([head|tail], res, cur) do
      if Map.has_key?(head, "grp_name") || Map.has_key?(head, "grp_desc") do
        IO.inspect head
        clean_up(tail, res, Map.merge(head,cur))
      else
        clean_up(tail, [Map.merge(head,cur)|res], cur)
      end
  end

  def add_stars(data) do
    Enum.map(data, fn elem ->
      IO.puts "--------"
      IO.inspect elem
      ret = case get_list(elem["url"]) do
        {:ok, data} -> data
        _ -> []
      end
      #Map.merge(elem, %{:dbg => "true"})
    end)
  end

  def get_list(url \\ "https://raw.githubusercontent.com/h4cc/awesome-elixir/master/README.md") do
    case HTTPoison.get(url, [], follow_redirect: true) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        res = md_parse(String.split(body, "\n"), []) |> clean_up |> add_stars
        IO.inspect res
        {:ok, res}
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
