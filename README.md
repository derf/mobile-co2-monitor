# Moile CO₂ Monitor

This repository contains NodeMCU Lua source code for a [mobile CO₂ monitor](https://finalrewind.org/projects/mobile-co2-monitor/).
I found it quite interesting to see how bad the air inside meeting rooms and train carriages can get, and how well ventilation in other areas can work.
There is also OpenSCAD source code for 3D-printing a case – however, as I relied on hand-soldering rather than designing a PCB for this task, it will likely need adjustments.

## Features

* Display for CO₂, temperature, humidity, and battery level
* Logging to InfluxDB
* WiFi roaming (i.e., can connect to more than one WiFi network)

## Components

* Processor: ESP8266
* CO₂ sensor: SCD4x (In principle, adding support for [MH-Z19](https://finalrewind.org/projects/esp8266-nodemcu-mh-z19) and similar is not hard, however those rely on a 5V supply which this board does not provide)
* Display: 128x64 OLED via SSD1306 (128x32 also supported with some changes)
* Power Supply: AliExpress TP4056 charge controller + BMS board; 2.5V cutoff
* Battery: Regular 18650 LiIon cell; LiPo also works

## Configuration

WiFi and InfluxDB configuration is read from `src/config.lua`.
You will need the following entries.

### WiFi

The application takes a list of WiFi networks and tries to connect to them in
order, waiting a few minutes between connection attempts. Configure them
like so:

```lua
station_cfgs[1] = {ssid = "home network", pwd = "swordfish"}
station_cfgs[2] = {ssid = "37C3-open" }
```

### InfluxDB

These settings are optional. Specify a URL and attributes in order to enable
InfluxDB publishing. For instance, if measurements should be stored as
`mh_z19,location=lounge` in the `sensors` database on
`http://influxdb.example.org`, the configuration is as follows.

```lua
influx_url = 'http://influxdb.example.org/write?db=sensors'
influx_attr = ',location=lounge'
```

You can also use the `esp8266_XXXXXX` device id here, like so:

```lua
influx_url = 'http://influxdb.example.org/write?db=sensors'
influx_attr = ',location=' .. device_id
```

Optionally, you can set `influx_header` to an HTTP header that is passed as
part of the POST request to InfluxDB.

## Images

![](https://finalrewind.org/projects/mobile-co2-monitor/media/preview.jpg)
![](https://finalrewind.org/projects/mobile-co2-monitor/media/mobile-co2-monitor-board.jpg)

## Resources

Mirrors of this repository are maintained at the following locations:

* [Chaosdorf](https://chaosdorf.de/git/derf/mobile-co2-monitor)
* [Finalrewind](https://git.finalrewind.org/derf/mobile-co2-monitor)
* [GitHub](https://github.com/derf/mobile-co2-monitor)
