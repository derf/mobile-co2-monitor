station_cfgs = {}

chip_id = string.format("%06X", node.chipid())
device_id = "esp8266_" .. chip_id

dofile("config.lua")

i2c.setup(0, 1, 2, i2c.SLOW)
ssd1306 = require("ssd1306")
fn = require("terminus16")
fb = require("framebuffer")
scd4x = require("scd4x")

ledpin = 4
gpio.mode(ledpin, gpio.OUTPUT)
gpio.write(ledpin, 0)

ssd1306.init(128, 64)
ssd1306.contrast(128)
fb.init(128, 64)

wifi_index = 1
no_wifi_count = 0
publish_count = 0

past_pos = 1
past = {}

-- cal 2023-01-06
-- 4.2V -> "4.36V" (raw ~ 948)
-- 4.0V -> "4.16V" (raw ~ 905)
-- 3.8V -> "3.95V" (raw ~ 859)
-- 3.6V -> "3.74V" (raw ~ 814)
function get_battery_mv()
	return adc.read(0) * 461 / 104
end

function get_battery_percent(bat_mv)
	if bat_mv > 4160 then
		return 100
	end
	if bat_mv < 3360 then
		return 0
	end
	return (bat_mv - 3360) / 8
end

function connect_wifi()
	print("Connecting to ESSID " .. station_cfgs[wifi_index].ssid)
	wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, wifi_connected)
	wifi.eventmon.register(wifi.eventmon.STA_DHCP_TIMEOUT, wifi_err)
	wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, wifi_err)
	wifi.setmode(wifi.STATION, false)
	wifi.sta.config(station_cfgs[wifi_index])
end

function scd4x_start()
	if scd4x.start() then
		gpio.write(ledpin, 1)
	else
		print("SCD4x error")
	end
	local measure_t = tmr.create()
	measure_t:register(5 * 1000, tmr.ALARM_AUTO, measure)
	measure_t:start()
end

function measure()
	if publishing_http then
		return
	end

	local co2, raw_temp, raw_humi = scd4x.read()
	local bat_mv = get_battery_mv()
	local bat_p = get_battery_percent(bat_mv)

	gpio.write(ledpin, co2 >= 1600 and 0 or 1)

	fb.init(128, 64)
	fb.draw_battery_8(0, 0, bat_p)
	if have_wifi then
		fb.x = 96
		fb.y = 16
		fb.print(fn, string.format("%d", wifi.sta.getrssi()))
	else
		if no_wifi_count == 5 then
			wifi_index = (wifi_index % table.getn(station_cfgs)) + 1
			wifi.setmode(wifi.NULLMODE, false)
		end
		if no_wifi_count < 24 then
			no_wifi_count = no_wifi_count + 1
		else
			no_wifi_count = 0
			connect_wifi()
		end
	end

	fb.x = 0
	fb.y = 16
	if co2 == nil then
		fb.print(fn, "SCD4x error")
		ssd1306.show(fb.buf)
		fb.init(128, 64)
		collectgarbage()
		return
	end
	fb.x = 16
	fb.print(fn, string.format("%5d ppm", co2))
	fb.x = 16
	fb.y = 0
	fb.print(fn, string.format("%4d.%d c %3d.%d %%", raw_temp/65536 - 45, (raw_temp%65536)/6554, raw_humi/65536, (raw_humi%65536)/6554))

	past[past_pos] = (co2 - 400) / 50
	past[past_pos] = past[past_pos] >=  0 and past[past_pos] or  0
	past[past_pos] = past[past_pos] <= 31 and past[past_pos] or 31
	past_pos = (past_pos) % 128 + 1

	for i = 1, 128 do
		fb.buf[i * 2] = bit.lshift(1, 31 - (past[(past_pos + (i-2)) % 128 + 1] or 0))
	end

	ssd1306.show(fb.buf)
	fb.init(128, 64)
	collectgarbage()
	publish_count = publish_count + 1
	if have_wifi and influx_url and publish_count >= 4 and not publishing_http then
		publish_count = 0
		publish_influx(co2, raw_temp, raw_humi, bat_mv)
	end
end

function publish_influx(co2, raw_temp, raw_humi, bat_mv)
	publishing_http = true
	http.post(influx_url, influx_header, string.format("scd4x%s co2_ppm=%d,temperature_celsius=%d.%d,humidity_relpercent=%d.%d", influx_attr, co2, raw_temp/65536 - 45, (raw_temp%65536)/6554, raw_humi/65536, (raw_humi%65536)/6554), function(code, data)
		http.post(influx_url, influx_header, string.format("esp8266%s battery_mv=%d", influx_attr, bat_mv), function(code, data)
			collectgarbage()
			publishing_http = false
		end)
	end)
end

local init_t = tmr.create()
init_t:register(1 * 1000, tmr.ALARM_SINGLE, scd4x_start)
init_t:start()

function wifi_connected()
	print("Connected")
	have_wifi = true
	no_wifi_count = 0
end

function wifi_err()
	have_wifi = false
end

print("WiFi MAC: " .. wifi.sta.getmac())
connect_wifi()
