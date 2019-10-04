defmodule Hello.Curl do
  import Ecto.Query
  alias Hello.{Repo, Rep}
  #use Task, restart: :transient

  @doc "Функция для сокращения написания Map.merge"
  def a ||| b, do: Map.merge(a || %{}, b || %{}) # le bayan

  @doc """
    Парсит документ на предмет заголовков, описания заголовков, имен и url проектов
    Работает построково, только парсинг по порядку
  """
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
    
  @doc """
    Приборка после функции md_parse, идет по порядку добавляет к каждой записи группу
    Удаляет пустые / не нужные уже записи(типа заголовков групп)
  """
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

  @doc """
    Преобразует все записи String -> Int
  """
  def map_to_int(nil), do:  %{}
  def map_to_int(data) do
    Enum.map(data, fn {k,v} ->
      case Integer.parse(v) do
        { num, _ } -> %{ k => num }
        _ -> %{ k => :error }
      end
    end) |> Enum.reduce(fn x,acc -> x ||| acc end)
  end

  @doc """
    Преобразует все записи Map в число от текущей даты 
    - если в будущем,
    :error - если не удалось преобразовать
  """
  def map_to_days_past(nil), do: %{}
  def map_to_days_past(data) do
    Enum.map(data, fn {k,v} ->
      case DateTime.from_iso8601(v) do
        { :ok, date, _ } -> %{ k => trunc(DateTime.diff(DateTime.utc_now(), date)/60/60/24) }
        _ -> %{ k => :error }
      end
    end) |> Enum.reduce(fn x,acc -> x ||| acc end)
  end

  @doc """
    Вырезает из текста stars, watch, fork, дни как текст и отдает через приведение к чистлу каждый
  """
  def cut_stars(txt) do
    stars = Regex.named_captures(~r/aria-label=\"(?<stars>\d+) user.+starred this repository/, txt)
    watch = Regex.named_captures(~r/aria-label=\"(?<watch>\d+) user.+ watching this repository/, txt)
    fork  = Regex.named_captures(~r/aria-label=\"(?<fork>\d+) user.+ forked this repository/, txt)
    days  = Regex.named_captures(~r/dateModified\"><relative-time datetime=\"(?<days>\S+)\"/, txt) 
    IO.inspect(stars)
    IO.inspect(watch)
    IO.inspect(fork)
    IO.inspect(days)

    #IO.inspect map_to_int(%{} ||| stars ||| watch ||| fork)
    map_to_int(%{:some => "123"} ||| stars ||| watch ||| fork) ||| map_to_days_past(days)
  end

  @doc """
    Тащит текст по ссылке, парсит звезды, добавлет к записи
  """
  def proc(elem) do
    elem ||| case HTTPoison.get(elem["real_url"] || elem["url"], [], follow_redirect: true) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} -> IO.write "."; Hello.Curl.cut_stars(body)
      _ -> %{}
    end
  end

  @doc """
    Функция обхода записей
  """
  def pmap_add_stars(data) do
    Enum.map(data, fn x -> proc(x) end)
  end

  @doc """
    Обходит массив одновременно по N записей
  """
  def pmap_add_stars2(data) do
    data
      #|> Task.async_stream(&proc/1) 
      |> Task.async_stream(&proc/1, [max_concurency: 20, ordered: false, timeout: 10000, on_timeout: :kill_task]) 
      #|> Task.async_stream(Processor, :proc, [], max_concurency: 20) 
      |> Enum.map(fn({:ok, res}) -> res end)
      #|> Enum.to_list()
      #|> Enum.reduce([], fn x, acc -> case x do 
      #    {:ok, some} -> [some|acc]
      #    _ -> acc
      #  end end)
  end

  @doc """
    Пытается вытащить ссылку из hexpm на github.com
  """
  def get_url_from_hexpm(url) do
    case HTTPoison.get(url, [], follow_redirect: true) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        ret = Regex.named_captures(~r/<a href=\"(?<real_url>.+)\" .+[Gg]it[Hh]ub/, body) 
        if (ret["real_url"] && String.starts_with?(ret["real_url"], "https://github.com/")), do: ret, else: %{}
      _ -> %{}
    end
  end

  @doc """
    Проверка на ссылки, где можно вытащить звезды
    hex.pm - парсим
    github - отдаем сразу
    другое - выставляем флаг :unparsable_url
  """
  def get_true_url(data) do
    Enum.map(data, fn elem ->
      cond do
        String.starts_with?(elem["url"], "https://github.com") -> elem 
        String.starts_with?(elem["url"], "https://hex.pm") -> elem ||| get_url_from_hexpm(elem["url"])
        true -> elem ||| %{:unparsable_url => true}
      end
    end)
  end
  
  @doc """
    Запись в базу отпарсенных значений (предвараительно удалив старые)
    TODO #dolikeburatino Сделано неверно Порождает тонны sql
  """
  def make_persists(data) do
    Repo.delete_all(Rep)
    Enum.each(data, fn x -> 
      Repo.insert(%Rep{name: x["name"], desc: x["desc"], stars: x["stars"],
        days: x["days"], url: x["url"], grp_name: x["grp_name"], grp_desc: x["grp_desc"]})
    end)
    data
  end

  @doc """
    Вытаскивает из базы сначала группы, затем записи по каждой группе
    TODO #dolikeburatino Сделано неверно Порождает тонны sql
  """
  def get_it_back2(stars \\ 0) do
    groups = from(r in Rep, where: r.stars > ^stars, where: not is_nil(r.grp_name), select: %{grp_name: r.grp_name, grp_desc: r.grp_desc}, distinct: true, order_by: r.grp_name)
    Enum.map(Repo.all(groups), fn x -> 
      q = from(r in Rep, where: r.stars > ^stars, where: r.grp_name == ^x.grp_name)
      x ||| %{ :items => Repo.all(q) }
    end)
  end

  @doc """
    Основная функция - тащит README из elixir-awesome-list, пргоняет через все вспомогательные функции
    Отвечает :ok / :error в зависимости от от результата
  """
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
              |> pmap_add_stars
              |> make_persists
        {:ok}
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
