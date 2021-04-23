import Config

config :alarm_clock_ui, :viewport, %{
  name: :main_viewport,
  default_scene: {AlarmClockUI.Scene.Clock, nil},
  size: {128, 64},
  drivers: [
    %{
      module: ScenicDriverOLEDBonnet
    }
  ]
}
