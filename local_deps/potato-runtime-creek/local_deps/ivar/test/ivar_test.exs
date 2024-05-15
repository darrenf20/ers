defmodule IvarTest do
  use ExUnit.Case
  doctest Ivar

  test "greets the world" do
    assert Ivar.hello() == :world
  end
end
