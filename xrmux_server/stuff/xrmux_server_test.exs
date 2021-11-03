defmodule XrmuxServerTest do
  use ExUnit.Case
  doctest XrmuxServer

  test "greets the world" do
    assert XrmuxServer.hello() == :world
  end
end
