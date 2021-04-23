defmodule AlarmClockUI.Util do
  @days ~w(
    MONDAY
    TUESDAY
    WEDNESDAY
    THURSDAY
    FRIDAY
    SATURDAY
    SUNDAY
  )

  @months ~w(
    JANUARY
    FEBRUARY
    MARCH
    APRIL
    MAY
    JUNE
    JULY
    AUGUST
    SEPTEMBER
    OCTOBER
    NOVEMBER
    DECEMBER
  )

  # --------------------------------------------------------
  def day_name(day), do: Enum.at(@days, day - 1)

  # --------------------------------------------------------
  def month_name(month), do: Enum.at(@months, month - 1)

  # --------------------------------------------------------
  def next_alarm_day(day) when day >= 7, do: 1
  def next_alarm_day(day), do: day + 1

  # --------------------------------------------------------
  def previous_alarm_day(day) when day <= 1, do: 7
  def previous_alarm_day(day), do: day - 1

  # --------------------------------------------------------
  def pad_part(part), do: String.pad_leading(to_string(part), 2, "0")

  # --------------------------------------------------------
  def format_time({_, {hour, minute, _}}) do
    "#{pad_part(hour)}:#{pad_part(minute)}"
  end
end
