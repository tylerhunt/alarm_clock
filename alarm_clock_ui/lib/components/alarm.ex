defmodule AlarmClockUI.Component.Alarm do
  use Scenic.Component

  import Scenic.Primitives
  alias Scenic.Graph

  alias AlarmClockUI.{Font, Util}

  @width 12

  @diameter @width / 2
  @radius @diameter / 2

  @color :white
  @font_size 18

  # ============================================================================
  # callbacks

  # --------------------------------------------------------
  def verify({scene, _} = data) when is_atom(scene), do: {:ok, data}
  def verify(_), do: :invalid_data

  # ============================================================================
  # setup

  # --------------------------------------------------------
  def init({_, time}, _opts) do
    Font.load()

    graph =
      Graph.build(font: Font.hash(), font_size: @font_size)
      |> icon()
      |> time(time)

    {:ok, %{time: time, graph: graph}, push: graph}
  end

  # ============================================================================
  # UI elements

  # --------------------------------------------------------
  defp icon(graph) do
    graph
    |> circle(
      @radius,
      fill: @color,
      translate: {@width / 2, @radius}
    )
    |> rect(
      {@diameter, @diameter},
      fill: @color,
      translate: {@width / 2 - @radius, @radius}
    )
    |> triangle(
      {
        {0, @diameter + @radius},
        {@width, @diameter + @radius},
        {@width / 2, 0}
      },
      fill: @color
    )
    |> sector(
      {@radius / 2, 0, :math.pi()},
      fill: @color,
      translate: {@width / 2, @diameter + @radius + @radius / 8}
    )
  end

  # --------------------------------------------------------
  defp time(graph, time) do
    text(
      graph,
      Util.format_time(time),
      fill: @color,
      text_align: :left_top,
      text_height: 16,
      translate: {@width + 2, -2}
    )
  end
end
