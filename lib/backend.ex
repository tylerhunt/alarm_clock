defmodule AlarmClock.Backend do
  use GenServer

  defmodule State do
    @alarms %{
      # Monday
      1 => {:off, "06:00"},
      # Tuesday
      2 => {:off, "06:00"},
      # Wednesday
      3 => {:off, "06:00"},
      # Thursday
      4 => {:off, "06:00"},
      # Friday
      5 => {:off, "06:00"},
      # Saturday
      6 => {:off, "06:00"},
      # Sunday
      7 => {:off, "06:00"}
    }

    defstruct alarms: @alarms, subscribers: []
  end

  # Public API

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def subscribe() do
    GenServer.call(__MODULE__, :subscribe)
  end

  def get_alarms do
    GenServer.call(__MODULE__, :get_alarms)
  end

  def set_alarm(day, {enabled, time} = alarm)
      when day in 1..7 and enabled in [:on, :off] and is_bitstring(time) do
    GenServer.call(__MODULE__, {:set_alarm, day, alarm})
  end

  # Server API

  def init(:ok) do
    {:ok, %State{}}
  end

  def handle_call(:subscribe, {subscriber, _ref}, state) do
    {:reply, :ok, %{state | subscribers: [subscriber | state.subscribers]}}
  end

  def handle_call(:get_alarms, _from, %{alarms: alarms} = state) do
    {:reply, {:ok, alarms}, state}
  end

  def handle_call(
        {:set_alarm, day, {enabled, time} = alarm},
        _from,
        %{alarms: alarms} = state
      )
      when day in 1..7 and enabled in [:on, :off] and is_bitstring(time) do
    alarms = alarms |> Map.put(day, alarm)
    new_state = %{state | alarms: alarms}

    refresh_subscribers(new_state)

    {:reply, :ok, new_state}
  end

  # Helpers

  defp refresh_subscribers(%{alarms: alarms, subscribers: subscribers}) do
    subscribers |> Enum.each(&send(&1, {:refresh, alarms}))
  end
end
