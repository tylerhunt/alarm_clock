defmodule AlarmClock.Util do
  def next_alarm_day(day) when day >= 7, do: 1
  def next_alarm_day(day), do: day + 1

  def previous_alarm_day(day) when day <= 1, do: 7
  def previous_alarm_day(day), do: day - 1
end
