Code.require_file "../../test_helper.exs", __FILE__

defmodule CouchNormalizer.RegistryTest do
  use ExUnit.Case, async: true


  def setup(_) do
    Erlang.application.set_env(:couch_normalizer_manager, :registry, Erlang.ets.new(:s, [:ordered_set, {:keypos, 1}]))
  end


  test "try to acquire(title, scenario)" do
    assert_raise RuntimeError, fn ->
      CouchNormalizer.Registry.acquire("scenario", fn(_x) -> nil end)
    end
  end


  test "acquire(title, scenario)" do
    assert CouchNormalizer.Registry.acquire("1-scenario", fn(_x) -> nil end) == true
    assert CouchNormalizer.Registry.acquire("10-scenario", fn(_x) -> nil end) == true
    {:ok, t} = Erlang.couch_normalizer_manager.registry

    [s] = Erlang.ets.lookup(t, "1")

    assert Erlang.ets.member(t, "1")  == true
    assert Erlang.ets.member(t, "10") == true
    assert {"1", "1-scenario", _} = s
  end


  test "acquire(title, scenario) multiple" do
    Enum.each ["3-scenario", "2-scenario", "1-scenario"], CouchNormalizer.Registry.acquire(&1, fn(_x) -> nil end)
    {:ok, t} = Erlang.couch_normalizer_manager.registry

    assert Erlang.ets.first(t)      == "1"
    assert Erlang.ets.next(t, "1")  == "2"
    assert Erlang.ets.last(t)       == "3"
  end


  test "load('test/1-test-scenario.exs')" do
    assert CouchNormalizer.Registry.load("test/1-test-scenario.exs") == []
    {:ok, t} = Erlang.couch_normalizer_manager.registry
    [h|t] = Erlang.ets.lookup(t, "1")

    assert tuple_size(h) == 3

    assert List.member?(tuple_to_list(h), "1") == true
    assert List.member?(tuple_to_list(h), "1-test-scenario") == true
    assert is_function(List.last(tuple_to_list(h)))
  end

end