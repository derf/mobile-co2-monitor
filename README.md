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

Mobile CO₂ monitor using an ESP8266, SCD4x, and SSD1306

## Images

![](https://finalrewind.org/projects/mobile-co2-monitor/media/preview.jpg)
![](https://finalrewind.org/projects/mobile-co2-monitor/media/mobile-co2-monitor-board.jpg)
