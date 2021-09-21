defmodule AlarmClock.Alarm do
  use GenServer

  @alsa_global_state "/var/lib/alsa/asound.state"
  @alsa_local_state "/data/asound.state"
  @sound "/usr/share/alarm.wav"
  @volume_pattern ~r/\[(?<left>\d{1,2}%)\].*\[(?<right>\d{1,2}%)\]/ms

  # public API

  def play(path \\ @sound) do
    GenServer.cast(__MODULE__, {:play, path})
  end

  def get_volume() do
    GenServer.call(__MODULE__, :get_volume)
  end

  def set_volume(volume) do
    GenServer.call(__MODULE__, {:set_volume, volume})
  end

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  # callbacks

  @impl GenServer

  def init(:ok) do
    case System.cmd("alsactl", ["restore", "-f", @alsa_local_state]) do
      {_, 0} -> :ok
        {:ok, %{volume: volume()}}
      {_, 99} ->
        File.cp @alsa_global_state, @alsa_local_state
        init(:ok)
    end
  end

  @impl GenServer

  def handle_cast({:play, path}, state) do
    {_, 0} = System.cmd("aplay", [path])
    {:noreply, state}
  end

  @impl GenServer

  def handle_call(:get_volume, _from, state) do
    volume = volume()
    {:reply, {:ok, volume}, state}
  end

  def handle_call({:set_volume, new_volume}, _from, state) do
    with {_, 0} <- System.cmd("amixer", ["sset", "PCM", new_volume]),
         {_, 0} <- System.cmd("alsactl", ["store", "-f", @alsa_local_state]),
         volume <- volume() do
      {:reply, {:ok, volume}, %{state | volume: volume}}
    end
  end

  # helpers

  defp volume do
    with {output, _} <- System.cmd("amixer", ~w[get PCM]),
         %{"left" => left, "right" => right} <-
           Regex.named_captures(@volume_pattern, output) do
      {left, right}
    end
  end
end
