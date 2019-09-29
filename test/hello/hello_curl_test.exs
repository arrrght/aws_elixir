defmodule Hello.CurlTest do
  use ExUnit.Case
  import Hello.Curl

  test "bayan" do
    assert (%{:a => "123"} ||| %{:b => "234"}) == %{:a => "123", :b => "234"}
    assert (%{:a => "123"} ||| %{:a => "234"}) == %{:a => "234"}
    assert (%{} ||| nil) == %{}
  end


  test "md_parse" do
    s = """
## Actors
*Libraries and tools for working with actors and such.*

* [dflow](https://github.com/dalmatinerdb/dflow) - Pipelined flow processing engine.
* [exactor](https://github.com/sasa1977/exactor) - Helpers for easier implementation of actors in Elixir.
* [exos](https://github.com/awetzel/exos) - A Port Wrapper which forwards cast and call to a linked Port.
* [sbroker](https://github.com/fishcakez/sbroker) - Sojourn-time based active queue management library.
* [workex](https://github.com/sasa1977/workex) - Backpressure and flow control in EVM processes.
"""
    ret = md_parse(String.split(s, "\n"), [])
    assert length(ret) > 0
    IO.inspect(ret)
    assert length(ret) == 0
  end


end
