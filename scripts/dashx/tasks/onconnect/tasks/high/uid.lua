--[[
  Copyright (C) 2025 Rob Thomson
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local dashx = require("dashx")

local uid = {}

local function fnv1a32(s)
    local hash = 0x811C9DC5
    for i = 1, #s do
        hash = (hash ~ s:byte(i)) & 0xffffffff
        hash = (hash * 0x01000193) & 0xffffffff
    end
    return hash
end

local function path_to_uuid(path)

    local parts = {}
    for i = 1, 4 do
        local h = fnv1a32(path .. "\0" .. i)
        parts[i] = string.format("%08x", h)
    end
    local full = table.concat(parts)

    return string.format("%s-%s-%s-%s-%s", full:sub(1, 8), full:sub(9, 12), full:sub(13, 16), full:sub(17, 20), full:sub(21, 32))
end

local function path_to_id32(path) return string.format("%08x", fnv1a32(path)) end

function uid.wakeup() if dashx.session.mcu_id == nil then dashx.session.mcu_id = path_to_uuid(model.path()) end end

function uid.reset() dashx.session.mcu_id = nil end

function uid.isComplete() if dashx.session.mcu_id ~= nil then return true end end

return uid
