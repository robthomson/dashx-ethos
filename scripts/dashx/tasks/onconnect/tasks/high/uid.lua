--[[
 * Copyright (C) dashx Project
 *
 *
 * License GPLv3: https://www.gnu.org/licenses/gpl-3.0.en.html
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 
 * Note.  Some icons have been sourced from https://www.flaticon.com/
 * 
]] --

local uid = {}

-- FNV-1a 32-bit
local function fnv1a32(s)
    local hash = 0x811C9DC5 -- 2166136261
    for i = 1, #s do
        hash = (hash ~ s:byte(i)) & 0xffffffff
        hash = (hash * 0x01000193) & 0xffffffff -- 16777619
    end
    return hash
end

-- 128-bit UUID-like string derived from the path
local function path_to_uuid(path)
    -- (Optional) normalize if your paths vary by slashes/case:
    -- path = path:gsub("\\", "/")

    local parts = {}
    for i = 1, 4 do
        local h = fnv1a32(path .. "\0" .. i)
        parts[i] = string.format("%08x", h)
    end
    local full = table.concat(parts) -- 32 hex chars

    return string.format("%s-%s-%s-%s-%s",
        full:sub(1, 8),
        full:sub(9, 12),
        full:sub(13, 16),
        full:sub(17, 20),
        full:sub(21, 32)
    )
end

-- If you prefer a short stable ID instead:
local function path_to_id32(path)
    return string.format("%08x", fnv1a32(path))
end

function uid.wakeup()
    -- quick exit if no apiVersion
    if dashx.session.mcu_id == nil then  

            dashx.session.mcu_id = path_to_uuid(model.path())

    end

end

function uid.reset()
    dashx.session.mcu_id = nil
end

function uid.isComplete()
    if dashx.session.mcu_id ~= nil  then
        return true
    end
end

return uid