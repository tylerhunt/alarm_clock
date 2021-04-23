defmodule AlarmClockTest do
  use ExUnit.Case
  doctest AlarmClock

  test "greets the world" do
    assert AlarmClock.hello() == :world
  end
end
