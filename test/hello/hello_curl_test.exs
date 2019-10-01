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
    # only on key "grp_name"
    assert Enum.reduce(ret, 0, fn x, sum -> if Map.has_key?(x, "grp_name"), do: sum+1, else: sum end) == 1
  end

  test "clean_up" do
    ret = md_parse(String.split(test_string(), "\n"), []) |> clean_up
    # IO.inspect ret
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

  test "cut_stars" do
    ret = cut_stars(test_github_string())
    assert ret["stars"] == 1231
    assert ret["watch"] == 74
    assert ret["fork"] == 298
    assert ret["days"] > 359
    case HTTPoison.get("https://github.com/dalmatinerdb/dflow", [], follow_redirect: true) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        ret = cut_stars(body)
        assert ret["stars"] > 0
        assert ret["watch"] > 0
        assert ret["fork"] > 0
        assert ret["days"] > 0
      _ -> IO.puts "Test skiped, unable to get src"
    end
  end

  test "pmap_add_stars" do
    a = [ %{
      "url" => "https://github.com/dalmatinerdb/dflow",
      "name" => "dflow",
      "desc" => "Libraries and tools for working with actors and such.",
      "grp_desc" => "Group_desc",
      "grp_name" => "Actors"
    }]
    ret = pmap_add_stars(a)
    assert length(ret) > 0
    assert List.first(ret)["name"] == "dflow"
    assert List.first(ret)["stars"] > 0
    assert List.first(ret)["watch"] > 0
    assert List.first(ret)["fork"] > 0
    assert List.first(ret)["days"] > 0
  end

  test "get_url_from_hexpm" do
    assert get_url_from_hexpm("https://hex.pm/packages/data_morph") == %{"real_url" => "https://github.com/robmckinnon/data_morph"}
    assert get_url_from_hexpm("https://github.com/herenowcoder/eastar") == %{}
    assert get_url_from_hexpm("https://bitbucket.org/Anwen/majremind") == %{}
  end
  
  test "get_true_url" do
    a = [
      %{ "url" => "https://hex.pm/packages/data_morph" },
      %{ "url" => "https://github.com/herenowcoder/eastar" },
      %{ "url" => "https://bitbucket.org/Anwen/majremind" }
    ]
    ret = get_true_url(a)
    [b,c,d] = ret
    assert b["real_url"] == "https://github.com/robmckinnon/data_morph"
    assert c["url"] == "https://github.com/herenowcoder/eastar"
    assert d[:unparsable_url]
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
  defp test_github_string, do: """
<button type="submit" class="btn btn-sm btn-with-count js-toggler-target" aria-label="Unstar this repository" title="Unstar devinus/poolboy" data-hydro-click="{&quot;event_type&quot;:&quot;repository.click&quot;,&quot;payload&quot;:{&quot;target&quot;:&quot;UNSTAR_BUTTON&quot;,&quot;repository_id&quot;:1046213,&quot;client_id&quot;:&quot;158097352.1553441596&quot;,&quot;originating_request_id&quot;:&quot;8768:35CDB:37461B4:54448B6:5D923DAC&quot;,&quot;originating_url&quot;:&quot;https://github.com/devinus/poolboy&quot;,&quot;referrer&quot;:&quot;https://github.com/h4cc/awesome-elixir/blob/master/README.md&quot;,&quot;user_id&quot;:601792}}" data-hydro-click-hmac="62aba3c64fd093598b557584ccad9d181b61ca506272d575f1713e7c627d9a6e" data-ga-click="Repository, click unstar button, action:files#disambiguate; text:Unstar">        <svg class="octicon octicon-star v-align-text-bottom" viewBox="0 0 14 16" version="1.1" width="14" height="16" aria-hidden="true"><path fill-rule="evenodd" d="M14 6l-4.9-.64L7 1 4.9 5.36 0 6l3.6 3.26L2.67 14 7 11.67 11.33 14l-.93-4.74L14 6z"/></svg>
Unstar
</button>        <a class="social-count js-social-count" href="/devinus/poolboy/stargazers"
aria-label="1231 users starred this repository">
1,231
</a>
</form>
<!-- '"` --><!-- </textarea></xmp> --></option></form><form class="unstarred js-social-form" action="/devinus/poolboy/star" accept-charset="UTF-8" method="post"><input name="utf8" type="hidden" value="&#x2713;" /><input type="hidden" name="authenticity_token" value="W3uzaU/oH21RdJ2ye2A4BRzCiyij0PadU/O3rwUACX2pspkoR33IJEL7e1bqMav2w54QjOb36yC6en+bwvYGnA==" />
<input type="hidden" name="context" value="repository"></input>
<button type="submit" class="btn btn-sm btn-with-count js-toggler-target" aria-label="Unstar this repository" title="Star devinus/poolboy" data-hydro-click="{&quot;event_type&quot;:&quot;repository.click&quot;,&quot;payload&quot;:{&quot;target&quot;:&quot;STAR_BUTTON&quot;,&quot;repository_id&quot;:1046213,&quot;client_id&quot;:&quot;158097352.1553441596&quot;,&quot;originating_request_id&quot;:&quot;8768:35CDB:37461B4:54448B6:5D923DAC&quot;,&quot;originating_url&quot;:&quot;https://github.com/devinus/poolboy&quot;,&quot;referrer&quot;:&quot;https://github.com/h4cc/awesome-elixir/blob/master/README.md&quot;,&quot;user_id&quot;:601792}}" data-hydro-click-hmac="f013fe7f18a188c1d4e1839b8cec0db5614a9073341601fb7d68248426ee2d87" data-ga-click="Repository, click star button, action:files#disambiguate; text:Star">        <svg class="octicon octicon-star v-align-text-bottom" viewBox="0 0 14 16" version="1.1" width="14" height="16" aria-hidden="true"><path fill-rule="evenodd" d="M14 6l-4.9-.64L7 1 4.9 5.36 0 6l3.6 3.26L2.67 14 7 11.67 11.33 14l-.93-4.74L14 6z"/></svg>
Star
</button>        <a class="social-count js-social-count" href="/devinus/poolboy/stargazers"
aria-label="1231 users starred this repository">
1,231
</a>
</form>  </div>
</div>
</details-menu>
</details>
<a class="social-count js-social-count"
href="/devinus/poolboy/watchers"
aria-label="74 users are watching this repository">
74
</a>
</form>
</li>
</span>
</button></form>
<a href="/devinus/poolboy/network/members" class="social-count"
aria-label="298 users forked this repository">
298
</a>
<div class="commit-desc"><pre class="text-small">Convert worker list to queue for consistent lifo|fifo performance</pre></div>
</div>
<div class="no-wrap d-flex flex-items-baseline">
<span class="mr-1">Latest commit</span>
<a class="commit-tease-sha mr-1" href="/devinus/poolboy/commit/9212a8770edb149ee7ca0bca353855e215f7cba5" data-pjax>
9212a87
</a>
<span itemprop="dateModified"><relative-time datetime="2018-10-06T02:03:34Z">Oct 6, 2018</relative-time></span>
</div>
</div>
"""
end
