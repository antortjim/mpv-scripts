print("Loading frame-info-module")
ocal mp = require "mp"

local mod = {}

function mod.frame_info()
    return "Frame info"
end

function mod.get_chunk_id()
    filename = mp.get_property("filename")
    chunk_id = sm.split(filename, ".")[1]
    return chunk_id
end


return mod
