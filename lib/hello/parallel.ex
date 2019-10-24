defmodule Hello.Parallel do

  # --------------------- Api ---------------------
  def run(col, workers, fun) do
    run(col, fun, workers, 0, [])
  end

  # --------------------- Priv ---------------------
  defp run([h|t], fun, workers, n, res) when n < workers do
    me = self()

    IO.puts "total: #{n + 1}"

    spawn_link fn ->
      send me, {h, fun.(h)}
    end
    run(t, fun, workers, n + 1, res)
  end

  defp run([], fun, workers, n, res) when n > 0 do
    receive do
      value -> run([], fun, workers, n - 1, [value|res])
    end
  end

  defp run([], _fun, _workers, _n, res) do
    res
  end

  defp run(col, fun, workers, n, res) do
    receive do
      value -> run(col, fun, workers, n - 1, [value|res])
    end
  end

  # --------------------- Helper ---------------------
  def run_helper(number, workers) do
    1..number
      |> Enum.to_list
      |> Parallel.run(workers, fn(x) ->
                                 :erlang.timestamp |> :random.seed
                                 :random.uniform(1000) |> :timer.sleep
                                 x * 2
                               end)
  end
end

