defmodule Hello.CurlTest do
  use ExUnit.Case
  import Hello.Curl

  test "bayan" do
    assert (%{:a => "123"} ||| %{:b => "234"}) == %{:a => "123", :b => "234"}
    assert (%{:a => "123"} ||| %{:a => "234"}) == %{:a => "234"}
    assert (%{} ||| nil) == %{}
  end


  test "md_parse" do
    ret = md_parse(String.split(test_string(), "\n"), [])
    # arr length with garbage
    assert length(ret) == 9
    # only on ewith key "grp_name"
    assert Enum.reduce(ret, 0, fn x, sum -> if Map.has_key?(x, "grp_name"), do: sum+1, else: sum end) == 1
  end

  test "clean_up" do
    ret = md_parse(String.split(test_string(), "\n"), []) |> clean_up
    #IO.inspect ret
    assert length(ret) == 5
    # all of them has grp_name field
    assert Enum.all?(ret, fn x -> Map.has_key?(x, "grp_name") end ) == true
  end

  test "map_to_int" do
    a = %{:a => "123", :b => "123.22", :c => "0", :d => "ASDA"}
    ret = map_to_int(a)
    assert ret[:a] == 123
    assert ret[:b] == 123
    assert ret[:c] == 0
    assert ret[:d] == :error
  end

  test "map_to_days_past" do
    a = %{:a => "2019-09-16T13:05:52Z", :b => "skjhasdf", :c => "2029-09-16T13:05:52Z"}
    ret = map_to_days_past(a)
    assert ret[:a] > 0
    assert ret[:b] == :error
    assert ret[:c] < 0
  end

  defp test_string, do: """
## Actors
*Libraries and tools for working with actors and such.*

* [dflow](https://github.com/dalmatinerdb/dflow) - Pipelined flow processing engine.
* [exactor](https://github.com/sasa1977/exactor) - Helpers for easier implementation of actors in Elixir.
* [exos](https://github.com/awetzel/exos) - A Port Wrapper which forwards cast and call to a linked Port.
* [sbroker](https://github.com/fishcakez/sbroker) - Sojourn-time based active queue management library.
* [workex](https://github.com/sasa1977/workex) - Backpressure and flow control in EVM processes.
"""
end
