defmodule AlarmClock.Component.Clock do
  use Scenic.Component

  alias Scenic.Graph
  import Scenic.Primitives

  alias AlarmClock.Util

  @size 48

  @graph Graph.build(font: :roboto_mono, font_size: @size)
         |> text(
           "",
           id: :time,
           text_align: :center_middle
         )

  # ============================================================================
  # callbacks

  # --------------------------------------------------------
  def verify(scene) when is_atom(scene), do: {:ok, scene}
  def verify(_), do: :invalid_data

  # ============================================================================
  # setup

  # --------------------------------------------------------
  def init(_state, _opts) do
    now = DateTime.utc_now

    %{graph: graph} = state = %{
      graph: update_time(@graph),
      timer: nil,
    }

    # start clock in the future close to the second boundary
    {microseconds, _} = now.microsecond
    Process.send_after(self(), :start_clock, 1001 - trunc(microseconds / 1000))

    {:ok, state, push: graph}
  end

  # ============================================================================
  # event handlers

  # --------------------------------------------------------
  def handle_info(:start_clock, %{graph: graph} = state) do
    # start the timer on a one-second interval
    {:ok, timer} = :timer.send_interval(1000, :tick_tock)

    # update the clock
    graph = update_time(graph)
    {:noreply, %{state | timer: timer}, push: graph}
  end

  # --------------------------------------------------------
  def handle_info(:tick_tock, %{graph: graph} = state) do
    graph = update_time(graph)
    {:noreply, state, push: graph}
  end

  # ============================================================================
  # helpers

  # --------------------------------------------------------
  defp update_time(graph) do
    time = :calendar.local_time()
    send_event({:tick, time})
    Graph.modify(graph, :time, &text(&1, format_time(time)))
  end

  # --------------------------------------------------------
  defp format_time({_, {hour, minute, _}}) do
    "#{Util.pad_part(hour)}:#{Util.pad_part(minute)}"
  end
end
