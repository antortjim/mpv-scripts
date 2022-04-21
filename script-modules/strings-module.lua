print("Loading strings-module.lua")

local mod = {}

function mod.split(inputstr, sep)
    print("This is the strings-module.lua")
    if sep == nil then
        sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            table.insert(t, str)
    end
    return t
end

return mod
