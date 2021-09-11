import Config

config :nerves, :firmware,
  fwup_conf: "config/rpi0/fwup.conf"

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
