use Mix.Config

config :alarm_clock, :viewport, %{
  name: :main_viewport,
  default_scene: {AlarmClock.Scene.Clock, nil},
  size: {128, 64},
  drivers: [
    %{
      module: ScenicDriverOLEDBonnet
    }
  ]
}
