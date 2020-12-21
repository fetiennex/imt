defmodule RabbitmqProjectTest do
  use ExUnit.Case
  doctest RabbitmqProject

  test "greets the world" do
    assert RabbitmqProject.hello() == :world
  end
end
