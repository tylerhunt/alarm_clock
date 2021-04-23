defmodule AlarmClockUI.Scene.Clock do
  use Scenic.Scene
  require Logger

  alias Scenic.ViewPort
  alias Scenic.Graph
  alias Scenic.Primitive
  import Scenic.Primitives

  alias AlarmClockUI.{Backend, Font, Util}

  @width 128
  @height 64

  @font_size 15

  @enter ["enter", "S"]

  # ============================================================================
  # setup

  # --------------------------------------------------------
  def init(_state, _opts) do
    Font.load()

    {:ok, alarms} = Backend.get_alarms()
    day = Date.utc_today() |> Date.day_of_week()

    alarm = alarms |> Map.get(day)
    time = current_time()

    graph =
      Graph.build(font: Font.hash(), font_size: @font_size)
      |> day_of_week(time)
      |> time(time)
      |> alarm(alarm)

    # start clock in the future close to the second boundary
    {microseconds, _} = DateTime.utc_now().microsecond
    Process.send_after(self(), :start_clock, 1001 - trunc(microseconds / 1000))

    :ok = Backend.subscribe()

    state = %{
      alarms: alarms,
      day: day,
      graph: graph,
      time: time,
      timer: nil
    }

    {:ok, state, push: graph}
  end

  # ============================================================================
  # callbacks

  def handle_info({:refresh, alarms}, %{day: day, graph: graph} = state) do
    alarm = alarms |> Map.get(day)
    graph = update_alarm(graph, alarm)
    {:noreply, %{state | alarms: alarms, graph: graph}, push: graph}
  end

  # --------------------------------------------------------
  def handle_info(:start_clock, state) do
    # start the timer on a one-second interval
    {:ok, timer} = :timer.send_interval(1000, :tick)

    {:noreply, %{state | timer: timer}}
  end

  # --------------------------------------------------------
  def handle_info(:tick, %{graph: graph, time: old_time} = state) do
    time = current_time()

    graph =
      cond do
        time_changed?(old_time, time) -> update_time(graph, time)
        true -> graph
      end

    {:noreply, %{state | graph: graph, time: time}, push: graph}
  end

  # ============================================================================
  # event handlers

  # --------------------------------------------------------
  def handle_input(
        {:key, {key, :press, 0}},
        context,
        %{alarms: alarms, day: day} = state
      ) when key in @enter do
    alarm = alarms |> Map.get(day)

    ViewPort.set_root(
      context.viewport,
      {AlarmClockUI.Scene.SetAlarms, %{alarm: alarm, day: day}}
    )

    {:halt, state}
  end

  # --------------------------------------------------------
  def handle_input(message, _context, state) do
    Logger.debug("Input: #{inspect(message)}")
    {:noreply, state}
  end

  # ============================================================================
  # UI elements

  # --------------------------------------------------------
  defp alarm(graph, {enabled, time} = _alarm) do
    AlarmClockUI.Component.Alarm.add_to_graph(
      graph,
      {__MODULE__, time},
      id: :alarm,
      hidden: enabled == :off,
      translate: {@width / 2 - 28, @height - 11}
    )
  end

  # --------------------------------------------------------
  def day_of_week(graph, time) do
    text(
      graph,
      format_day(time),
      id: :day,
      text_align: :center_top,
      translate: {@width / 2, -2}
    )
  end

  # --------------------------------------------------------
  defp time(graph, time) do
    AlarmClockUI.Component.Time.add_to_graph(
      graph,
      {__MODULE__, time},
      id: :time,
      translate: {@width / 2, @height / 2 - 1}
    )
  end

  # ============================================================================
  # helpers

  # --------------------------------------------------------
  def current_time do
    :calendar.local_time()
  end

  # --------------------------------------------------------
  defp update_alarm(graph, {:on, time}) do
    graph
    |> Graph.modify(:alarm, &Primitive.put(&1, {__MODULE__, time}))
    |> Graph.modify(:alarm, &update_opts(&1, hidden: false))
  end

  defp update_alarm(graph, {:off, _}) do
    graph
    |> Graph.modify(:alarm, &update_opts(&1, hidden: true))
  end

  # --------------------------------------------------------
  def update_time(graph, time) when is_tuple(time) do
    graph
    |> Graph.modify(
      :time,
      &Primitive.put(&1, {AlarmClockUI.Component.Time, {__MODULE__, time}})
    )
    |> Graph.modify(:day, &text(&1, format_day(time)))
  end

  # --------------------------------------------------------
  def format_day({{year, month, day}, _}) do
    {:ok, date} = Date.new(year, month, day)
    Util.day_name(Date.day_of_week(date))
  end

  # --------------------------------------------------------
  # Compares two times ignoring the seconds part
  defp time_changed?(old_time, new_time) do
    time_without_seconds(old_time) != time_without_seconds(new_time)
  end

  # --------------------------------------------------------
  defp time_without_seconds(time) do
    time |> Tuple.to_list() |> Enum.flat_map(&Tuple.to_list(&1)) |> Enum.take(5)
  end
end
