use Mix.Config

config :alarm_clock, :viewport, %{
  name: :main_viewport,
  default_scene: {AlarmClock.Scene.Clock, nil},
  size: {128, 64},
  opts: [scale: 1.0],
  drivers: [
    %{
      module: Scenic.Driver.Glfw,
      opts: [title: "MIX_TARGET=host, app = :alarm_clock"]
    }
  ]
}
