defmodule AlarmClock.Component.Alarm do
  use Scenic.Component

  import Scenic.Primitives
  alias Scenic.Graph

  @height 12
  @width 12

  @diameter @width / 2
  @radius @diameter / 2

  @color :white

  # ============================================================================
  # callbacks

  # --------------------------------------------------------
  def verify({scene, _} = data) when is_atom(scene), do: {:ok, data}
  def verify(_), do: :invalid_data

  # ============================================================================
  # setup

  # --------------------------------------------------------
  def init({_, alarm}, _opts) do
    graph =
      Graph.build(font: :roboto_mono, font_size: 16)
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
      |> text(
        alarm,
        id: :alarm,
        fill: @color,
        text_align: :left_bottom,
        text_height: 16,
        translate: {@width, @height}
      )

    {:ok, %{alarm: alarm, graph: graph}, push: graph}
  end
end
