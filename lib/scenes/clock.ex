defmodule AlarmClock.Scene.Clock do
  use Scenic.Scene

  alias Scenic.ViewPort
  alias Scenic.Graph
  import Scenic.Primitives
  import AlarmClock.Util

  @width 128
  @height 64

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

  @graph Graph.build(font: :roboto_mono, font_size: 16)
         |> text(
           "",
           id: :date,
           text_align: :center_middle,
           text_height: 16,
           translate: {@width / 2, 8}
         )
         |> text(
           "",
           id: :time,
           font_size: 48,
           text_align: :center_middle,
           text_height: @height,
           translate: {@width / 2, (@height / 2) - 1}
         )
         |> text(
           "",
           id: :day,
           text_align: :center_middle,
           text_height: 16,
           translate: {@width / 2, @height - 8}
         )

  # ============================================================================
  # setup

  # --------------------------------------------------------
  def init(_state, _opts) do
    now = DateTime.utc_now

    %{graph: graph} = state = %{
      alarm_day: Date.day_of_week(now),
      graph: update_time(@graph),
      timer: nil,
    }

    # start clock in the future close to the second boundary
    {microseconds, _} = now.microsecond
    Process.send_after(self(), :start_clock, 1001 - trunc(microseconds / 1000))

    {:ok, state, push: graph}
  end

  # ============================================================================
  # event handlers

  # --------------------------------------------------------
  def handle_input(
    {:key, {"left", :press, 0}},
    context,
    %{alarm_day: alarm_day} = state
  ) do
    ViewPort.set_root(
      context.viewport,
      {
        AlarmClock.Scene.Menu,
        state |> Map.put(:alarm_day, previous_alarm_day(alarm_day))
      }
    )

    {:halt, state}
  end

  # --------------------------------------------------------
  def handle_input(
    {:key, {"right", :press, 0}},
    context,
    %{alarm_day: alarm_day} = state
  ) do
    ViewPort.set_root(
      context.viewport,
      {
        AlarmClock.Scene.Menu,
        state |> Map.put(:alarm_day, next_alarm_day(alarm_day))
      }
    )

    {:halt, state}
  end

  # --------------------------------------------------------
  def handle_input(_msg, _context, graph) do
    {:noreply, graph}
  end

  # --------------------------------------------------------
  def handle_info(:start_clock, %{graph: graph} = state) do
    # start the timer on a one-second interval
    {:ok, timer} = :timer.send_interval(1000, :tick_tock)

    # update the clock
    graph = update_time(graph)
    {:noreply, %{state | timer: timer}, push: graph}
  end

  # --------------------------------------------------------
  def handle_info(:tick_tock, %{graph: graph} = state) do
    graph = update_time(graph)
    {:noreply, state, push: graph}
  end

  # ============================================================================
  # helpers

  # --------------------------------------------------------
  defp update_time(graph) do
    time = :calendar.local_time()

    graph
    |> Graph.modify(:date, &text(&1, format_date(time)))
    |> Graph.modify(:day, &text(&1, format_day(time)))
    |> Graph.modify(:time, &text(&1, format_time(time)))
  end

  # --------------------------------------------------------
  defp format_date({{_, m, d}, _}) do
    "#{format_month(m)} #{d}"
  end

  # --------------------------------------------------------
  defp format_day({{y, m, d}, _}) do
    {:ok, date} = Date.new(y, m, d)
    Enum.at(@days, Date.day_of_week(date) - 1)
  end

  # --------------------------------------------------------
  defp format_time({_, {h, m, _}}) do
    "#{h}:#{format_minutes(m)}"
  end

  # --------------------------------------------------------
  defp format_minutes(m) when m >= 0 and m < 10, do: "0#{m}"
  defp format_minutes(m), do: to_string(m)

  # --------------------------------------------------------
  defp format_month(m), do: Enum.at(@months, m - 1)
end
