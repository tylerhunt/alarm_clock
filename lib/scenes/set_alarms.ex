defmodule AlarmClock.Scene.SetAlarms do
  use Scenic.Scene

  alias Scenic.ViewPort
  alias Scenic.Graph
  alias Scenic.Primitive
  import Scenic.Primitives

  alias AlarmClock.{Backend,Util}

  @width 128
  @height 64

  @parts %{
    hour: {9, (@height / 2) - 16},
    minute: {75, (@height / 2) - 16},
  }
  @default_part :hour

  # ============================================================================
  # setup

  # --------------------------------------------------------
  def init(%{day: day, alarm: {enabled, time}}, _opts) do
    %{editing: editing, enabled: enabled} = state = %{
      day: day,
      editing: false,
      enabled: enabled == :on,
      graph: nil,
      part: @default_part,
      time: time,
    }

    graph =
      Graph.build(font: :roboto_mono, font_size: 12)
      |> title(enabled, editing)
      |> time()
      |> part()
      |> day_of_week(day)

    {:ok, %{state | graph: graph}, push: graph}
  end

  # ============================================================================
  # event handlers

  # --------------------------------------------------------
  def handle_input(
    {:key, {"enter", :press, 0}},
    _context,
    %{editing: false} = state
  ) do
    {state, graph} = start_editing(state)
    {:noreply, state, push: graph}
  end
  def handle_input(
    {:key, {"enter", :press, 0}},
    _context,
    %{editing: true} = state
  ) do
    {state, graph} = end_editing(state)
    {:noreply, state, push: graph}
  end

  # --------------------------------------------------------
  def handle_input(
    {:key, {"escape", :press, 0}},
    context,
    %{editing: false} = state
  ) do
    ViewPort.reset(context.viewport)
    {:halt, state}
  end
  def handle_input(
    {:key, {"escape", :press, 0}},
    _context,
    %{editing: true} = state
  ) do
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
    %{graph: graph, part: part} = state
  ) do
    {part, graph} = swap_part(part, graph)
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
    %{graph: graph, part: part} = state
  ) do
    {part, graph} = swap_part(part, graph)
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
    %{editing: true, graph: graph, part: part} = state
  ) do
    time = graph |> Graph.get!(:time) |> Primitive.get()
    new_time = change_part(time, part, 1)
    graph = Graph.modify(graph, :time, &text(&1, new_time))
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
    %{editing: true, graph: graph, part: part} = state
  ) do
    time = graph |> Graph.get!(:time) |> Primitive.get()
    new_time = change_part(time, part, -1)
    graph = Graph.modify(graph, :time, &text(&1, new_time))
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
      font_size: 16,
      text_align: :center_middle,
      text_height: 16,
      translate: {@width / 2, 8}
    )
  end

  # --------------------------------------------------------
  defp time(graph) do
    text(
      graph,
      "06:00",
      id: :time,
      font_size: 48,
      text_align: :center_middle,
      text_height: @height,
      translate: {@width / 2, (@height / 2) - 1}
    )
  end

  # --------------------------------------------------------
  defp part(graph) do
    rrect(
      graph,
      {44, 33, 5},
      id: :part,
      hidden: true,
      stroke: {1, :white},
      translate: @parts |> Map.get(@default_part)
    )
  end

  # --------------------------------------------------------
  defp day_of_week(graph, day) do
    text(
      graph,
      Util.day_name(day),
      id: :day,
      font_size: 16,
      text_align: :center_middle,
      text_height: 16,
      translate: {@width / 2, @height - 8}
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
  defp start_editing(%{enabled: enabled, graph: graph} = state) do
    editing = true
    {part, graph} = show_part(@default_part, graph) # reset part to default

    graph =
      graph
      |> Graph.modify(:title, &text(&1, title_text(enabled, editing)))
      |> Graph.modify(:part, &update_opts(&1, hidden: false))

    {%{state | editing: editing, graph: graph, part: part}, graph}
  end

  # --------------------------------------------------------
  defp end_editing(
    %{day: day, enabled: enabled, graph: graph} = state
  ) do
    editing = false

    graph =
      graph
      |> Graph.modify(:title, &text(&1, title_text(enabled, editing)))
      |> Graph.modify(:part, &update_opts(&1, hidden: true))

    Backend.set_alarm(day, alarm_tuple(state))

    {%{state | editing: editing, graph: graph}, graph}
  end

  # --------------------------------------------------------
  defp alarm_tuple(%{enabled: true, time: time}), do: {:on, time}
  defp alarm_tuple(%{enabled: false, time: time}), do: {:off, time}

  # --------------------------------------------------------
  defp swap_part(part, graph) do
    part = (part == :hour && :minute || :hour)
    show_part(part, graph)
  end

  # --------------------------------------------------------
  defp show_part(part, graph) do
    translation = @parts |> Map.get(part)

    graph =
      Graph.modify(
        graph,
        :part,
        &Primitive.put_transform(&1, :translate, translation)
      )

    {part, graph}
  end

  # --------------------------------------------------------
  defp change_part(time, part, sign) do
    {:ok, time} = Time.from_iso8601("#{time}:00")

    case part do
      :hour -> [Time.add(time, 60 * 60 * sign).hour, time.minute]
      :minute -> [time.hour, Time.add(time, 5 * 60 * sign).minute]
    end
    |> Enum.map(&String.pad_leading(to_string(&1), 2, "0"))
    |> Enum.join(":")
  end

  # --------------------------------------------------------
  defp title_text(_, true), do: "ALARM: SET"
  defp title_text(false, false), do: "ALARM: OFF"
  defp title_text(true, false), do: "ALARM: ON "
end
