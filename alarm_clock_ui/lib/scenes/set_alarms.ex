defmodule AlarmClockUI.Scene.SetAlarms do
  use Scenic.Scene

  alias Scenic.ViewPort
  alias Scenic.Graph
  alias Scenic.Primitive
  import Scenic.Primitives

  alias AlarmClockUI.{Backend, Font, Util}

  @width 128
  @height 64

  @default_part :hour

  @enter ["enter", "S"]
  @escape ["escape", "A"]

  # ============================================================================
  # setup

  # --------------------------------------------------------
  def init(%{day: day, alarm: {enabled, time}}, _opts) do
    Font.load()

    %{editing: editing, enabled: enabled} =
      state = %{
        day: day,
        editing: false,
        enabled: enabled == :on,
        graph: nil,
        part: @default_part,
        time: time
      }

    graph =
      Graph.build(font: Font.hash(), font_size: 13)
      |> title(enabled, editing)
      |> time(time)
      |> day_of_week(day)

    {:ok, %{state | graph: graph}, push: graph}
  end

  # ============================================================================
  # event handlers

  # --------------------------------------------------------
  def handle_input(
        {:key, {key, :press, 0}},
        _context,
        %{editing: false} = state
      ) when key in @enter do
    {state, graph} = start_editing(state)
    {:noreply, state, push: graph}
  end

  def handle_input(
        {:key, {key, :press, 0}},
        _context,
        %{editing: true} = state
      ) when key in @enter do
    {state, graph} = end_editing(state)
    {:noreply, state, push: graph}
  end

  # --------------------------------------------------------
  def handle_input(
        {:key, {key, :press, 0}},
        context,
        %{editing: false} = state
      ) when key in @escape do
    ViewPort.reset(context.viewport)
    {:halt, state}
  end

  def handle_input(
        {:key, {key, :press, 0}},
        _context,
        %{editing: true} = state
      ) when key in @escape do
    {state, graph} = end_editing(state)
    {:noreply, state, push: graph}
  end

  # --------------------------------------------------------
  def handle_input(
        {:key, {"left", :press, 0}},
        _context,
        %{day: day, editing: false, graph: graph} = state
      ) do
    day = Util.previous_alarm_day(day)
    graph = Graph.modify(graph, :day, &text(&1, Util.day_name(day)))
    {:halt, %{state | day: day, graph: graph}, push: graph}
  end

  def handle_input(
        {:key, {"left", :press, 0}},
        _context,
        %{graph: graph, part: part, time: time} = state
      ) do
    {graph, part} = swap_part(graph, time, part)
    {:noreply, %{state | graph: graph, part: part}, push: graph}
  end

  # --------------------------------------------------------
  def handle_input(
        {:key, {"right", :press, 0}},
        _context,
        %{day: day, editing: false, graph: graph} = state
      ) do
    day = Util.next_alarm_day(day)
    graph = Graph.modify(graph, :day, &text(&1, Util.day_name(day)))
    {:halt, %{state | day: day, graph: graph}, push: graph}
  end

  def handle_input(
        {:key, {"right", :press, 0}},
        _context,
        %{graph: graph, part: part, time: time} = state
      ) do
    {graph, part} = swap_part(graph, time, part)
    {:noreply, %{state | graph: graph, part: part}, push: graph}
  end

  # --------------------------------------------------------
  def handle_input(
        {:key, {"up", :press, 0}},
        _context,
        %{day: day, editing: false, enabled: enabled} = state
      ) do
    {state, graph} = set_alarm(%{state | enabled: !enabled})
    Backend.set_alarm(day, alarm_tuple(state))
    {:noreply, state, push: graph}
  end

  def handle_input(
        {:key, {"up", :press, 0}},
        _context,
        %{editing: true, graph: graph, part: part, time: time} = state
      ) do
    new_time = change_part(time, part, 1)
    graph = update_time(graph, new_time, part)
    {:noreply, %{state | graph: graph, time: new_time}, push: graph}
  end

  # --------------------------------------------------------
  def handle_input(
        {:key, {"down", :press, 0}},
        _context,
        %{day: day, editing: false, enabled: enabled} = state
      ) do
    {state, graph} = set_alarm(%{state | enabled: !enabled})
    Backend.set_alarm(day, alarm_tuple(state))
    {:noreply, state, push: graph}
  end

  def handle_input(
        {:key, {"down", :press, 0}},
        _context,
        %{editing: true, graph: graph, part: part, time: time} = state
      ) do
    new_time = change_part(time, part, -1)
    graph = update_time(graph, new_time, part)
    {:noreply, %{state | graph: graph, time: new_time}, push: graph}
  end

  # --------------------------------------------------------
  def handle_input(_msg, _, graph) do
    {:noreply, graph}
  end

  # ============================================================================
  # UI elements

  # --------------------------------------------------------
  defp title(graph, enabled, editing) do
    text(
      graph,
      title_text(enabled, editing),
      id: :title,
      text_align: :center_top,
      text_height: 16,
      translate: {@width / 2, 0}
    )
  end

  # --------------------------------------------------------
  defp time(graph, time) do
    AlarmClockUI.Component.Time.add_to_graph(
      graph,
      {__MODULE__, time, :none},
      id: :time,
      translate: {@width / 2, @height / 2 - 1}
    )
  end

  # --------------------------------------------------------
  defp day_of_week(graph, day) do
    text(
      graph,
      Util.day_name(day),
      id: :day,
      text_align: :center_bottom,
      translate: {@width / 2, @height}
    )
  end

  # ============================================================================
  # helpers

  # --------------------------------------------------------
  defp set_alarm(%{editing: editing, enabled: enabled, graph: graph} = state) do
    graph =
      graph
      |> Graph.modify(:title, &text(&1, title_text(enabled, editing)))

    {%{state | enabled: enabled, graph: graph}, graph}
  end

  # --------------------------------------------------------
  defp start_editing(%{enabled: enabled, graph: graph, time: time} = state) do
    editing = true
    part = @default_part

    graph =
      graph
      |> Graph.modify(:title, &text(&1, title_text(enabled, editing)))
      |> update_time(time, part)

    {%{state | editing: editing, graph: graph, part: part}, graph}
  end

  # --------------------------------------------------------
  defp end_editing(
    %{day: day, enabled: enabled, graph: graph, time: time} = state
  ) do
    editing = false
    part = :none

    graph =
      graph
      |> Graph.modify(:title, &text(&1, title_text(enabled, editing)))
      |> update_time(time, part)

    Backend.set_alarm(day, alarm_tuple(state))

    {%{state | editing: editing, graph: graph, part: part}, graph}
  end

  # --------------------------------------------------------
  defp alarm_tuple(%{enabled: true, time: time}), do: {:on, time}
  defp alarm_tuple(%{enabled: false, time: time}), do: {:off, time}

  # --------------------------------------------------------
  defp swap_part(graph, time, part) do
    part = (part == :hour && :minute) || :hour
    graph = update_time(graph, time, part)
    {graph, part}
  end

  # --------------------------------------------------------
  defp update_time(graph, time, part) do
    graph
    |> Graph.modify(
      :time,
      &Primitive.put(
        &1,
        {AlarmClockUI.Component.Time, {__MODULE__, time, part}}
      )
    )
  end

  # --------------------------------------------------------
  defp change_part({date, _} = old_time, part, sign) do
    {:ok, time} = Time.from_iso8601("#{Util.format_time(old_time)}:00")

    [hour, minute] =
      case part do
        :hour -> [Time.add(time, 60 * 60 * sign).hour, time.minute]
        :minute -> [time.hour, Time.add(time, 5 * 60 * sign).minute]
      end

    {date, {hour, minute, nil}}
  end

  # --------------------------------------------------------
  defp title_text(_, true), do: "ALARM: SET"
  defp title_text(false, false), do: "ALARM: OFF"
  defp title_text(true, false), do: "ALARM: ON "
end
