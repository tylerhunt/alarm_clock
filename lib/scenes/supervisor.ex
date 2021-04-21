defmodule AlarmClock.Scene.Supervisor do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    children = [
      {AlarmClock.Scene.Clock, {nil, [name: :clock]}},
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end
