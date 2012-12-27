Code.require_file "../../../test_helper.exs", __FILE__

defmodule CouchNormalizer.RegistryTest do
  use ExUnit.Case, async: true

  def setup(_), do: CouchNormalizer.Registry.init


  test "tries to acquire with invalid title (without normpos)" do
    assert_raise RuntimeError, fn ->
      CouchNormalizer.Registry.acquire("scenario", fn(_x) -> nil end)
    end
  end


  test "acquire(title, scenario)" do
    assert CouchNormalizer.Registry.acquire("1-scenario", fn(_x) -> nil end) == true
    assert CouchNormalizer.Registry.acquire("10-scenario", fn(_x) -> nil end) == true

    registry = CouchNormalizer.Registry.to_ets

    [s] = :ets.lookup(registry, "1")

    assert :ets.member(registry, "1")  == true
    assert :ets.member(registry, "10") == true
    assert {"1", "1-scenario", _} = s
  end


  test "acquire(title, scenario) multiple" do
    Enum.each ["3-scenario", "2-scenario", "1-scenario"], CouchNormalizer.Registry.acquire(&1, fn(_x) -> nil end)
    registry = CouchNormalizer.Registry.to_ets

    assert :ets.first(registry)      == "1"
    assert :ets.next(registry, "1")  == "2"
    assert :ets.last(registry)       == "3"
  end


  test "load('test/1-test-scenario.exs')" do
    assert CouchNormalizer.Registry.load("test/1-test-scenario.exs") == []

    registry = CouchNormalizer.Registry.to_ets
    [h|_t] = :ets.lookup(registry, "1")

    assert tuple_size(h) == 3

    assert List.member?(tuple_to_list(h), "1") == true
    assert List.member?(tuple_to_list(h), "1-test-scenario") == true
    assert is_function(List.last(tuple_to_list(h)))
  end

end