# Alarm Clock

An embedded alarm clock project built with Scenic and made to run on a
[Raspberry Pi Zero W][pi] with the [Adafruit OLED Bonnet][bonnet].

[pi]: https://www.raspberrypi.org/products/raspberry-pi-zero-w/
[bonnet]: https://www.adafruit.com/product/3531

## Running on the Host

```sh
cd alarm_clock_ui
mix do deps.get, scenic.run
```

## Bootstrapping Target

This will build the firmware and burn it to an SD card.

```sh
cd alarm_clock
mix do deps.get, firmware, firmeware.burn
```
