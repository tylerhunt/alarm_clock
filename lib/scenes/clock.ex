defmodule AlarmClock.Scene.Clock do
  use Scenic.Scene

  alias Scenic.ViewPort
  alias Scenic.Graph
  import Scenic.Primitives

  alias AlarmClock.Util

  @width 128
  @height 64


  # ============================================================================
  # setup

  # --------------------------------------------------------
  def init(_state, _opts) do
    graph =
      Graph.build(font: :roboto_mono, font_size: 16)
      |> date()
      |> day_of_week()
      |> time()
      |> alarm()

    {:ok, %{alarms: @alarms, graph: graph}, push: graph}
  end

  # --------------------------------------------------------
  def filter_event({:tick, time}, _from, %{graph: graph} = state) do
    graph = update_date(graph, time)
    {:noreply, %{state | graph: graph}, push: graph}
  end

  # ============================================================================
  # event handlers

  # --------------------------------------------------------
  def handle_input({:key, {"enter", :press, 0}}, context, state) do
    ViewPort.set_root(context.viewport, {AlarmClock.Scene.SetAlarms, nil})
    {:halt, state}
  end

  # --------------------------------------------------------
  def handle_input(_msg, _context, graph) do
    {:noreply, graph}
  end

  # ============================================================================
  # UI elements

  # --------------------------------------------------------
  defp alarm(graph) do
    AlarmClock.Component.Alarm.add_to_graph(
      graph,
      {__MODULE__, "06:00"},
      id: :alarm,
      translate: {@width - 48, @height - 12}
    )
  end

  # --------------------------------------------------------
  defp date(graph) do
     text(
       graph,
       "",
       id: :date,
       text_align: :center_middle,
       text_height: 16,
       translate: {@width / 2, 8}
     )
  end

  # --------------------------------------------------------
  def day_of_week(graph) do
    text(
      graph,
      "",
      id: :day,
      text_align: :left_middle,
      text_height: 16,
      translate: {0, @height - 8}
    )
  end

  # --------------------------------------------------------
  defp time(graph) do
    AlarmClock.Component.Time.add_to_graph(
      graph,
      __MODULE__,
      translate: {@width / 2, (@height / 2) - 1}
    )
  end

  # ============================================================================
  # helpers

  # --------------------------------------------------------
  defp update_date(graph, time) do
    graph
    |> Graph.modify(:date, &text(&1, format_date(time)))
    |> Graph.modify(:day, &text(&1, format_day(time)))
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
end
