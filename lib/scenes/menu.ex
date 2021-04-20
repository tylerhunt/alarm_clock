defmodule AlarmClock.Scene.Menu do
  use Scenic.Scene

  alias Scenic.ViewPort
  alias Scenic.Graph
  alias Scenic.Primitive
  import Scenic.Primitives

  alias AlarmClock.Util

  @width 128
  @height 64

  @parts %{
    hour: {9, (@height / 2) - 16},
    minute: {75, (@height / 2) - 16},
  }
  @default_part :hour

  @graph Graph.build(font: :roboto_mono, font_size: 12)
         |> text(
           "SET ALARM",
           id: :date,
           font_size: 16,
           text_align: :center_middle,
           text_height: 16,
           translate: {@width / 2, 8}
         )
         |> text(
           "06:00",
           id: :time,
           font_size: 48,
           text_align: :center_middle,
           text_height: @height,
           translate: {@width / 2, (@height / 2) - 1}
         )
         |> rrect(
           {44, 33, 5},
           id: :part,
           stroke: {1, :white},
           translate: @parts |> Map.get(@default_part)
         )
         |> text(
           "",
           id: :day,
           font_size: 16,
           text_align: :center_middle,
           text_height: 16,
           translate: {@width / 2, @height - 8}
         )

  # ============================================================================
  # setup

  # --------------------------------------------------------
  def init(%{alarm_day: alarm_day}, _opts) do
    %{graph: graph} = state = %{
      alarm_day: alarm_day,
      part: @default_part,
      graph: @graph |> Graph.modify(:day, &text(&1, Util.day_name(alarm_day)))
    }

    {:ok, state, push: graph}
  end

  # ============================================================================
  # event handlers

  # --------------------------------------------------------
  def handle_input({:key, {"enter", :press, 0}}, context, state) do
    ViewPort.reset(context.viewport)
    {:halt, state}
  end

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
  #def handle_input(
  #  {:key, {"right", :press, 0}},
  #  context,
  #  %{alarm_day: alarm_day} = state
  #) do
  #  ViewPort.set_root(
  #    context.viewport,
  #    {
  #      AlarmClock.Scene.Menu,
  #      state |> Map.put(:alarm_day, Util.next_alarm_day(alarm_day))
  #    }
  #  )
  #  {:halt, state}
  #end
  def handle_input(
    {:key, {"right", :press, 0}},
    _context,
    %{graph: graph, part: part} = state
  ) do
    part = (part == :hour && :minute || :hour)
    translation = @parts |> Map.get(part)

    graph =
      Graph.modify(
        graph,
        :part,
        &Primitive.put_transform(&1, :translate, translation)
      )

    {:noreply, %{state | graph: graph, part: part}, push: graph}
  end

  # --------------------------------------------------------
  def handle_input(
    {:key, {"up", :press, 0}},
    _context,
    %{graph: graph, part: part} = state
  ) do
    time = Graph.get!(graph, :time).data
    graph = Graph.modify(graph, :time, &text(&1, change_part(time, part, 1)))
    {:noreply, %{state | graph: graph}, push: graph}
  end

  # --------------------------------------------------------
  def handle_input(
    {:key, {"down", :press, 0}},
    _context,
    %{graph: graph, part: part} = state
  ) do
    time = Graph.get!(graph, :time).data
    graph = Graph.modify(graph, :time, &text(&1, change_part(time, part, -1)))
    {:noreply, %{state | graph: graph}, push: graph}
  end

  # ============================================================================
  # helpers

  # --------------------------------------------------------
  def handle_input(_msg, _, graph) do
    {:noreply, graph}
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
end
