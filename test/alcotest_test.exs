defmodule AlcotestTest do
  use ExUnit.Case
  doctest Alcotest

  test "greets the world" do
    assert Alcotest.hello() == :world
  end
end
