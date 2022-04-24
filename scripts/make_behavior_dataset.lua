-- make-behavior-dataset
-- A script to generate .csv files for each instance of a behavior of interest 
-- The script saves
--    x (int) and y (int) coordinates
--    time (int) in ms of the behavior (assuming a constant framerate)
--        i.e. if the video has 12000 frames
--        150000 ms points to the middle frame
--        regardless of whether the frames actually are equally spaced or not
--        in terms of sampling time
--    identifier (str) A string documenting the parent folder of the video, and the video name
--        in the flyhostel data structure, this is equal to the experiment name (timestamp) and the imgstore chunk
-- The name of the behavior is given by the content of the BEHAVIOR variable at the beginning of the script
--
-- In order to not have any black bars around the video feed, it is recommended to try 
-- several values of --window-scale=X (where X goes from 0 to 1)
-- so the maximum that has no bars is selected
-- This is needed so that osd-width and osd-height represent the shape of the video GUI in the program
-- If bars are present, the normalization of x and y, which come in coordinates of the GUI window,
-- will be incorrect

local msg = require("mp.msg")
local utils = require 'mp.utils'
local uin = require "user-input-module"
local sm = require "strings-module"
local fim = require "frame-info-module"
-- local json = require "json-module"
--

-- TODO
-- This should be loaded from the frame-info-module
-- but the loading process does not work
function get_chunk_id()
    filename = mp.get_property("filename")
    chunk_id = sm.split(filename, ".")[1]
    return chunk_id
end



function dummy_f(x, err, flag)
    return x
end


function save_behavior(filename, data)
    os.execute( "mkdir -p mpv_annotation" )
    local f = assert(io.open(filename, "w"))
    f:write(data)
    mp.commandv("show-text", 'Saving')
    f:close()
    mp.set_property_native("pause", false)
    end

msg.verbose('Initializing getcoords')


function collect_data(behavior)
    if (behavior == nil) 
    then
        return
    end
    chunk_id = get_chunk_id()
    local chunk = tonumber(chunk_id)
    local x, y = mp.get_mouse_pos()
    local time_pos = mp.get_property_number("time-pos")
    local video_width = mp.get_property("width")
    local video_height = mp.get_property("height")
    local wd = utils.getcwd()
    local root, folder = utils.split_path(wd)
    local identifier = folder .. "_" .. chunk_id 

--    print("Video has resolution " .. video_width .. "x" .. video_height)

    window_width = mp.get_property_native("osd-width")
    window_height = mp.get_property_native("osd-height")
    x_coord = math.floor(x / window_width * video_width)
    y_coord = math.floor(y / window_height * video_height)
    pos_ms = time_pos * 1000

--    message = "behavior detected at (" .. x_coord .. ", " .. y_coord .. ") " .. pos_ms .. " ms"
--    print(message)
    local filename = "behaviors/behavior_" .. identifier .. "-" .. pos_ms .. ".csv"
    local data = x_coord .. "," .. y_coord .. "," .. pos_ms .. "," .. behavior .. "," .. identifier .. "\n"

    save_behavior(filename, data)
end


function behavior_handler(mouse_table)
        mp.set_property_native("pause", true)
	uin.get_user_input(collect_data, {
            request_text = "Enter behavior name",
            replace = true,
        },
       "replace"
 )
end

mp.add_key_binding("MBTN_RIGHT", "behavior", behavior_handler)
