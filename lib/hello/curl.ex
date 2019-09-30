defmodule Hello.Curl do
  import Ecto.Query
  alias Hello.{Repo, Rep}

  def a  ||| b, do: Map.merge(a || %{}, b || %{}) # le bayan

  def md_parse([], res), do: Enum.reverse res
  def md_parse([str|rest], arr) do
    result = cond do
      Regex.match?(~r/^##.+/, str)    -> Regex.named_captures(~r/^## (?<grp_name>.+$)/, str)
      Regex.match?(~r/^\*.+\*$/, str) -> Regex.named_captures(~r/^\*(?<grp_desc>.+)\*$/, str)
      Regex.match?(~r/^\* \[/, str)   -> Regex.named_captures(~r/^\* \[(?<name>.+)\]\((?<url>.+)\) - (?<desc>.+$)/, str)
      true -> %{}
    end
    md_parse(rest, [result | arr])
  end
    
  def clean_up(some), do: clean_up(some, [], %{})
  def clean_up([], some, _), do: some
  def clean_up([h|t], some, cur) when h == %{}, do: clean_up(t, some, cur)
  def clean_up([head|tail], res, cur) do
    if Map.has_key?(head, "grp_name") || Map.has_key?(head, "grp_desc") do
      clean_up(tail, res, cur ||| head)
    else
      clean_up(tail, [cur ||| head | res], cur)
    end
  end

  def map_to_int(data) do
    Enum.map(data, fn {k,v} ->
      case Integer.parse(v) do
        { num, _ } -> %{ k => num }
        _ -> %{ k => :error }
      end
    end) |> Enum.reduce(fn x,acc -> x ||| acc end)
  end

  def map_to_days_past(nil), do: %{}
  def map_to_days_past(data) do
    Enum.map(data, fn {k,v} ->
      case DateTime.from_iso8601(v) do
        { :ok, date, _ } -> %{ k => trunc(DateTime.diff(DateTime.utc_now(), date)/60/60/24) }
        _ -> %{ k => :error }
      end
    end) |> Enum.reduce(fn x,acc -> x ||| acc end)
  end

  def cut_stars(txt) do
    stars = Regex.named_captures(~r/aria-label=\"(?<stars>\d+) user.+starred this repository/, txt)
    watch = Regex.named_captures(~r/aria-label=\"(?<watch>\d+) user.+ watching this repository/, txt)
    fork  = Regex.named_captures(~r/aria-label=\"(?<fork>\d+) user.+ forked this repository/, txt)
    days  = Regex.named_captures(~r/dateModified\"><relative-time datetime=\"(?<days>\S+)\"/, txt) 
    IO.inspect days
    map_to_int(stars ||| watch ||| fork) ||| map_to_days_past(days)
  end

  # thx, s/o
  #def pmap(collection, func) do
  #  collection
  #    |> Enum.map(&(Task.async(fn -> func.(&1) end)))
  #    |> Enum.map(&Task.await(10000))
  #end

  def add_stars(data) do
    Enum.map(data, fn elem ->
    #pmap(data, fn elem ->
      IO.puts "--------"
      IO.inspect elem
      ret = case HTTPoison.get(elem["real_url"] || elem["url"], [], follow_redirect: true) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} -> cut_stars(body)
        _ -> %{}
      end
      IO.inspect(ret)
      elem ||| ret
    end)
  end

  def get_url_from_hexpm(url) do
    case HTTPoison.get(url, [], follow_redirect: true) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        Regex.named_captures(~r/<a href=\"(?<real_url>.+)\" .+[Gg]it[Hh]ub/, body) || %{:unparsable_url => true}
      _ -> %{}
    end
  end

  def get_true_url(data) do
    Enum.map(data, fn elem ->
      cond do
        String.starts_with?(elem["url"], "https://github.com") -> elem 
        String.starts_with?(elem["url"], "https://hex.pm") -> elem ||| get_url_from_hexpm(elem["url"])
        true -> elem ||| %{:unparsable_url => true}
      end
    end)
  end
  
  def make_persists(data) do
    Repo.delete_all(Rep)
    Enum.each(data, fn x -> 
      Repo.insert(%Rep{name: x["name"], desc: x["desc"], stars: x["stars"],
        days: x["days"], url: x["url"], grp_name: x["grp_name"], grp_desc: x["grp_desc"]})
    end)
    data
  end

  def get_it_back2(stars \\ 0) do
    groups = from(r in Rep, where: r.stars > ^stars, where: not is_nil(r.grp_name), select: %{grp_name: r.grp_name, grp_desc: r.grp_desc}, distinct: true, order_by: r.grp_name)
    Enum.map(Repo.all(groups), fn x -> 
      q = from(r in Rep, where: r.stars > ^stars, where: r.grp_name == ^x.grp_name)
      x ||| %{ :items => Repo.all(q) }
    end)
  end

  def get_list(url \\ "https://raw.githubusercontent.com/h4cc/awesome-elixir/master/README.md") do
    case HTTPoison.get(url, [], follow_redirect: true) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        md_parse(String.split(body, "\n"), []) 
              |> clean_up 
              #|> Enum.filter(fn x -> !String.starts_with?(x["url"], "https://github.com") end) # debug
              #|> Enum.shuffle # debug
              #|> Enum.take(12) # debug cutof
              |> get_true_url
              #|> Enum.map(fn x -> if Map.has_key?(x, :unparsable_url) do IO.inspect(x);x else x end end) # debug
              |> Enum.filter(fn x -> !Map.has_key?(x, :unparsable_url) end)
              |> add_stars
              |> make_persists
        res = get_it_back2()
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
end
