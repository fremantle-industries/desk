defmodule DeskTest do
  use ExUnit.Case
  doctest Desk

  test "greets the world" do
    assert Desk.hello() == :world
  end
end
