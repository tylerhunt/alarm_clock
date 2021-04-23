defmodule AlarmClockUI.Scene.Home do
  use Scenic.Scene
  require Logger

  alias Scenic.Graph
  import Scenic.Primitives

  @width 128
  @height 64

  @font_size 16

  def init(_, _opts) do
    graph =
      Graph.build(font_size: @font_size)
      |> welcome()

    {:ok, graph, push: graph}
  end

  def handle_input(event, _context, state) do
    Logger.info("Received event: #{inspect(event)}")
    {:noreply, state}
  end

  defp welcome(graph) do
    text(
      graph,
      "Welcome!",
      text_align: :center_middle,
      translate: {@width / 2, @height / 2}
    )
  end
end
