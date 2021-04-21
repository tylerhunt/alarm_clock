defmodule AlarmClock.Scene.Clock do
  use Scenic.Scene

  alias Scenic.ViewPort
  alias Scenic.Graph
  alias Scenic.Primitive
  import Scenic.Primitives

  alias AlarmClock.{Backend, Util}

  @width 128
  @height 64

  # ============================================================================
  # setup

  # --------------------------------------------------------
  def init(_state, _opts) do
    {:ok, alarms} = Backend.get_alarms()
    day = Date.utc_today() |> Date.day_of_week()

    state = %{alarms: alarms, day: day, graph: nil}
    alarm = alarms |> Map.get(day)

    graph =
      Graph.build(font: :roboto_mono, font_size: 16)
      |> date()
      |> day_of_week()
      |> time()
      |> alarm(alarm)

    :ok = Backend.subscribe()

    {:ok, %{state | graph: graph}, push: graph}
  end

  # --------------------------------------------------------
  def filter_event({:tick, time}, _from, %{graph: graph} = state) do
    graph = update_date(graph, time)
    {:noreply, %{state | graph: graph}, push: graph}
  end

  # ============================================================================
  # callbacks

  def handle_info({:refresh, alarms}, %{day: day, graph: graph} = state) do
    alarm = alarms |> Map.get(day)
    graph = update_alarm(graph, alarm)
    {:noreply, %{state | alarms: alarms, graph: graph}, push: graph}
  end

  # ============================================================================
  # event handlers

  # --------------------------------------------------------
  def handle_input(
        {:key, {"enter", :press, 0}},
        context,
        %{alarms: alarms, day: day} = state
      ) do
    alarm = alarms |> Map.get(day)

    ViewPort.set_root(
      context.viewport,
      {AlarmClock.Scene.SetAlarms, %{alarm: alarm, day: day}}
    )

    {:halt, state}
  end

  # --------------------------------------------------------
  def handle_input(_msg, _context, graph) do
    {:noreply, graph}
  end

  # ============================================================================
  # UI elements

  # --------------------------------------------------------
  defp alarm(graph, {enabled, time} = _alarm) do
    AlarmClock.Component.Alarm.add_to_graph(
      graph,
      {__MODULE__, time},
      id: :alarm,
      hidden: enabled == :off,
      translate: {@width - 50, @height - 12}
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
      translate: {@width / 2, @height / 2 - 1}
    )
  end

  # ============================================================================
  # helpers

  # --------------------------------------------------------
  defp update_alarm(graph, {:on, time}) do
    graph
    |> Graph.modify(:alarm, &Primitive.put(&1, {__MODULE__, time}, []))
    |> Graph.modify(:alarm, &update_opts(&1, hidden: false))
  end

  defp update_alarm(graph, {:off, _}) do
    graph
    |> Graph.modify(:alarm, &update_opts(&1, hidden: true))
  end

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
