use Mix.Config

config :alarm_clock, :viewport, %{
  name: :main_viewport,
  # default_scene: {AlarmClock.Scene.Crosshair, nil},
  default_scene: {AlarmClock.Scene.SysInfo, nil},
  size: {800, 480},
  opts: [scale: 1.0],
  drivers: [
    %{
      module: Scenic.Driver.Glfw,
      opts: [title: "MIX_TARGET=host, app = :alarm_clock"]
    }
  ]
}
