defmodule AlarmClock.Scene.Clock do
  use Scenic.Scene

  alias Scenic.ViewPort
  alias Scenic.Graph
  import Scenic.Primitives

  alias AlarmClock.Util

  @width 128
  @height 64

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
           text_align: :left_middle,
           text_height: 16,
           translate: {0, @height - 8}
         )
         |> AlarmClock.Component.Alarm.add_to_graph(
           {__MODULE__, "06:00"},
           translate: {@width - 48, @height - 12}
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
        state |> Map.put(:alarm_day, Util.previous_alarm_day(alarm_day))
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
        state |> Map.put(:alarm_day, Util.next_alarm_day(alarm_day))
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
  defp format_date({{_, month, day}, _}) do
    "#{Util.month_name(month)} #{day}"
  end

  # --------------------------------------------------------
  def format_day({{year, month, day}, _}) do
    {:ok, date} = Date.new(year, month, day)
    Util.day_name(Date.day_of_week(date))
  end

  # --------------------------------------------------------
  defp format_time({_, {hour, minute, _}}) do
    "#{Util.pad_part(hour)}:#{Util.pad_part(minute)}"
  end
end
