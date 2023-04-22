station_cfg = {}

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
ssd1306.contrast(255)
fb.init(128, 64)

timestamp = 0
old_timestamp = 0
no_wifi_count = 0
publish_count = 0
message_queue = {}

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

function get_time()
	publishing_http = true
	http.get("http://arclight:1234/", nil, function(status, body, headers)
		publishing_http = false
		if timestamp < 604800 then
			old_timestamp = timestamp
		end
		timestamp = tonumber(body)
	end)
end

function connect_wifi()
	print("WiFi MAC: " .. wifi.sta.getmac())
	print("Connecting to ESSID " .. station_cfg.ssid)
	wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, wifi_connected)
	wifi.eventmon.register(wifi.eventmon.STA_DHCP_TIMEOUT, wifi_err)
	wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, wifi_err)
	wifi.setmode(wifi.STATION)
	wifi.sta.config(station_cfg)
	wifi.sta.connect()
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
	timestamp = timestamp + 5
	fb.init(128, 64)
	local co2, raw_temp, raw_humi = scd4x.read()
	local bat_mv = get_battery_mv()
	local bat_p = get_battery_percent(bat_mv)
	local line1 = ""
	local line2 = ""
	if co2 == nil then
		line1 = "SCD4x error"
		fb.print(fn, line1)
		ssd1306.show(fb.buf)
		return
	end
	line1 = string.format("%8d ppm\n\n", co2)
	line2 = string.format("%8d.%d c\n%8d.%d %%", raw_temp/65536 - 45, (raw_temp%65536)/6554, raw_humi/65536, (raw_humi%65536)/6554)
	fb.print(fn, line1)
	fb.print(fn, line2)
	fb.draw_battery_8(114, 0, bat_p)
	if have_wifi then
		fb.x = 90
		fb.print(fn, string.format("%02d:%02d", (timestamp / 3600) % 24, (timestamp / 60) % 60))
	elseif no_wifi_count < 120 then
		no_wifi_count = no_wifi_count + 1
	else
		table.insert(message_queue, {timestamp, co2, raw_temp, raw_humi})
		fb.x = 100
		fb.print(fn, string.format("%d", table.getn(message_queue)))
		no_wifi_count = 0
		connect_wifi()
	end
	ssd1306.show(fb.buf)
	fb.init(128, 64)
	publish_count = publish_count + 1
	if have_wifi and influx_url and publish_count >= 4 and not publishing_http then
		publish_count = 0
		gpio.write(ledpin, 0)
		publish_influx(co2, raw_temp, raw_humi, bat_mv)
	elseif have_wifi and influx_url and not publishing_http and timestamp > 604800 then
		for i, v in ipairs(message_queue) do
			if v[1] < 604800 then
				v[1] = timestamp - (old_timestamp - v[1])
			end
		end
		--print(timestamp)
		empty_queue(message_queue)
	else
		collectgarbage()
	end
end

function publish_influx(co2, raw_temp, raw_humi, bat_mv)
	publishing_http = true
	http.post(influx_url, influx_header, string.format("scd4x%s co2_ppm=%d,temperature_celsius=%d.%d,humidity_relpercent=%d.%d", influx_attr, co2, raw_temp/65536 - 45, (raw_temp%65536)/6554, raw_humi/65536, (raw_humi%65536)/6554), function(code, data)
		http.post(influx_url, influx_header, string.format("esp8266%s battery_mv=%d", influx_attr, bat_mv), function(code, data)
			publishing_http = false
			gpio.write(ledpin, 1)
			get_time()
			collectgarbage()
		end)
	end)
end

function empty_queue(q)
	local n = table.getn(q)
	if n > 0 then
		publishing_http = true
		gpio.write(ledpin, 0)
		local ts = q[n][1]
		local co2 = q[n][2]
		local t = q[n][3]
		local h = q[n][4]
		table.remove(q)
		--print(influx_url .. '&precision=s')
		--print(string.format("scd4x%s co2_ppm=%d,temperature_celsius=%d.%d,humidity_relpercent=%d.%d %d", influx_attr, co2, t/65536 - 45, (t%65536)/6554, h/65536, (h%65536)/6554, ts))
		http.post(influx_url .. '&precision=s', influx_header, string.format("scd4x%s co2_ppm=%d,temperature_celsius=%d.%d,humidity_relpercent=%d.%d %d", influx_attr, co2, t/65536 - 45, (t%65536)/6554, h/65536, (h%65536)/6554, ts), function(code, data)
			--print('Q ' .. n .. ' returned ' .. code .. ' ' .. data)
			empty_queue(q)
		end)
	else
		publishing_http = false
		gpio.write(ledpin, 1)
	end
end

local init_t = tmr.create()
init_t:register(1 * 1000, tmr.ALARM_SINGLE, scd4x_start)
init_t:start()

function wifi_connected()
	have_wifi = true
end

function wifi_err()
	have_wifi = false
end

connect_wifi()
