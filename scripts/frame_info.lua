-- Based on https://raw.githubusercontent.com/Kagami/mpv_frame_info/master/frame_info.lua
local assdraw = require "mp.assdraw"
local options = require "mp.options"
local utils = require('mp.utils')
local msg = require('mp.msg')
local sm = require("strings-module")

TEMPERATURE = ""
HUMIDITY = ""
LIGHT = ""
ZT = ""
REF_HOUR = 6



function loadTable(path)
  function tableLength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
  end
  local myTable = {}
  local file = io.open(path, "r")
  if file then
    local contents = file:read("*a")
    io.close(file)
    local length = string.len(contents)
    msg.debug("[persistence]", "bookmark file successfully loaded. length: " .. length)
    if length == 0 then
      contents = "{}"
    end
    myTable = utils.parse_json(contents);
    if not myTable then
      error("Corrupt bookmark file '" .. path .. "', please remove it! bookmarker will automatically create a new file.")
    end
    msg.debug("[persistence]", tableLength(myTable) .. " slots found.")
    return myTable
  end
  msg.warn("[persistence]", "could not load bookmark file!")
  return nil
end

local info_active = false
local o = {
    font_size = 10,
    font_color = "00FFFF",
    border_size = 1.0,
    border_color = "000000",
}
options.read_options(o)


function get_chunk_id()
    filename = mp.get_property("filename")
    chunk_id = sm.split(filename, ".")[1]
    return chunk_id
end


function get_formatting()
    return string.format(
        "{\\fs%d}{\\1c&H%s&}{\\bord%f}{\\3c&H%s&}",
        o.font_size, o.font_color,
        o.border_size, o.border_color
    )
end

function timestamp(duration)
    -- mpv may return nil before exiting.
    if not duration then return "" end
    local hours = duration / 3600
    local minutes = duration % 3600 / 60
    local seconds = duration % 60
    return string.format("%02d:%02d:%06.03f", hours, minutes, seconds)
end


function get_environment()
    chunk = get_chunk_id()
    json_file = chunk .. ".extra.json"
    data = loadTable(json_file)
    time_pos = mp.get_property_native("time-pos")
    if time_pos == nil
    then
        return
    end
    frame_number = time_pos * 40
    for k, v in pairs(data) do
        if tonumber(frame_number) == tonumber(v.frame_in_chunk)
        then
            TEMPERATURE = v.temperature
            HUMIDITY = v.humidity
            LIGHT = v.light
	    break
        end
    end
end

function format_clock_time(clock_time)
	local h = tonumber(sm.split(clock_time, ":")[1])
	local m = tonumber(sm.split(clock_time, ":")[2])
	local s = tonumber(sm.split(clock_time, ":")[3])
	local clock_time = h + m / 60 + s/ 3600
	return clock_time
end
 
function get_clock_time()
    chunk = get_chunk_id()
    json_file = chunk .. ".extra.json"
    data = loadTable(json_file)
    time_pos = mp.get_property_native("time-pos")
    if time_pos == nil
    then
        return
    end

    frame_number = time_pos * 40

    local file, err = io.open("metadata.yaml", "r")
        -- TODO This assumes the created_utc field is in the 4th line of the file
        file:read()
        file:read()
        file:read()
        created_utc = sm.split(file:read(), "'")[2]
	start_time = format_clock_time(sm.split(created_utc, "T")[2])
    file.close()

    for k, v in pairs(data) do
        if tonumber(frame_number) == tonumber(v.frame_in_chunk)
        then
            ZT = math.floor(((start_time + v.time / 3600) - REF_HOUR) * 100) / 100
	    break
        end
    end
end
 
function get_info()
   get_clock_time()
   get_environment()
   return string.format(
        "%sName: %s\\NTime: %s\\NEnv -> %s\\NZT: %s",
        get_formatting(),
        mp.get_property("filename"),
        timestamp(mp.get_property_native("time-pos")),
	"T: " .. TEMPERATURE .. " C, " .. "H: " .. HUMIDITY .. " %, " .. " L: " .. LIGHT,
	ZT
    )
end

function render_info()
    ass = assdraw.ass_new()
    ass:pos(0, 0)
    ass:append(get_info())
    mp.set_osd_ass(0, 0, ass.text)
end

function clear_info()
    mp.set_osd_ass(0, 0, "")
end

function toggle_info()
    if info_active then
        mp.unregister_event(render_info)
        clear_info()
    else
        -- TODO: Rewrite to timer + pause/unpause handlers.
        mp.register_event("tick", render_info)
        render_info()
    end
    info_active = not info_active
end

mp.add_key_binding("TAB", mp.get_script_name(), toggle_info)
