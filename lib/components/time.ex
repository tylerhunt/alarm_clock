defmodule AlarmClock.Component.Time do
  use Scenic.Component

  alias Scenic.Graph
  import Scenic.Primitives

  alias AlarmClock.Util

  @font_size 44
  @radius 5
  @padding 4
  @gap_padding 2

  @part 44
  @width @part * 2 + @padding * 2
  @height 32
  @baseline_offset 2

  # ============================================================================
  # callbacks

  # --------------------------------------------------------
  def verify({scene, time} = data) when is_atom(scene) and is_tuple(time),
    do: {:ok, data}

  def verify({scene, time, part} = data)
      when is_atom(scene) and is_tuple(time) and part in [:none, :hour, :minute],
      do: {:ok, data}

  def verify(_), do: :invalid_data

  # ============================================================================
  # setup

  # --------------------------------------------------------
  def init({scene, time}, opts), do: init({scene, time, :none}, opts)

  def init({_scene, time, part}, _opts) do
    ProFont.load()

    graph =
      Graph.build(font: ProFont.hash(), font_size: @font_size)
      |> hour(time)
      |> hour_selection(part)
      |> minute(time)
      |> minute_selection(part)

    {:ok, graph, push: graph}
  end

  # ============================================================================
  # UI elements

  defp hour(graph, {_, {hour, _, _}}) do
    text(
      graph,
      Util.pad_part(hour),
      id: :hour,
      text_align: :left_middle,
      translate: {-@width / 2 + 2, @baseline_offset}
    )
  end

  defp hour_selection(graph, part) do
    rrect(
      graph,
      {@part + @padding + @gap_padding, @height + @padding, @radius},
      hidden: part != :hour,
      stroke: {1, :white},
      translate: {
        -@width / 2 - @padding / 2,
        -@height / 2 - @baseline_offset
      }
    )
  end

  defp minute(graph, {_, {_, minute, _}}) do
    text(
      graph,
      Util.pad_part(minute),
      id: :minute,
      text_align: :right_middle,
      translate: {@width / 2 + 1, @baseline_offset}
    )
  end

  defp minute_selection(graph, part) do
    rrect(
      graph,
      {@part + @padding + @gap_padding, @height + @padding, @radius},
      hidden: part != :minute,
      stroke: {1, :white},
      translate: {
        0,
        -@height / 2 - @baseline_offset
      }
    )
  end
end
