defmodule AlarmClock.Application do
  @moduledoc false

  @target Mix.target()

  use Application

  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: __MODULE__]
    Supervisor.start_link(children(@target), opts)
  end

  defp children(_target) do
    main_viewport_config = Application.get_env(:alarm_clock, :viewport)

    [
      {AlarmClock.Backend, name: AlarmClock.Backend},
      {Scenic, viewports: [main_viewport_config]}
    ]
  end
end
