--[[
  Copyright (C) 2025 Rob Thomson
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local dashx = require("dashx")
local utils = {}

function utils.resolveModelName(foldername)
    if foldername == nil then return "Unknown" end

    local iniName = "LOGS:dashx/telemetry/" .. foldername .. "/logs.ini"
    local iniData = dashx.ini.load_ini_file(iniName) or {}

    if iniData["model"] and iniData["model"].name then return iniData["model"].name end
    return "Unknown"
end

function utils.hasModelName(foldername)
    if foldername == nil then return false end

    local iniName = "LOGS:dashx/telemetry/" .. foldername .. "/logs.ini"
    local iniData = dashx.ini.load_ini_file(iniName) or {}

    if iniData["model"] and iniData["model"].name then return true end
    return false
end

function utils.getLogs(logDir)
    local files = system.listFiles(logDir)
    local entries = {}

    for _, fname in ipairs(files) do
        if fname:match("%.csv$") then
            local date, time = fname:match("(%d%d%d%d%-%d%d%-%d%d)_(%d%d%-%d%d%-%d%d)_")
            if date and time then table.insert(entries, {name = fname, ts = date .. 'T' .. time}) end
        end
    end

    table.sort(entries, function(a, b) return a.ts > b.ts end)

    local maxEntries = 50
    for i = maxEntries + 1, #entries do os.remove(logDir .. "/" .. entries[i].name) end

    local result = {}
    for i = 1, math.min(#entries, maxEntries) do table.insert(result, entries[i].name) end
    return result
end

function utils.getLogPath()

    os.mkdir("LOGS:")
    os.mkdir("LOGS:/dashx")
    os.mkdir("LOGS:/dashx/telemetry")

    return "LOGS:/dashx/telemetry/"
end

function utils.getLogDir(dirname)

    os.mkdir("LOGS:")
    os.mkdir("LOGS:/dashx")
    os.mkdir("LOGS:/dashx/telemetry")

    if not dirname then
        local defaultDir = "LOGS:/dashx/telemetry/"
        os.mkdir(defaultDir)
        return defaultDir
    end

    return "LOGS:/dashx/telemetry/"
end

function utils.getLogsDir(logDir)
    local files = system.listFiles(logDir)
    local dirs = {}
    for _, name in ipairs(files) do if not (name == "." or name == ".." or name:match("^%.%w%w%w$") or name:match("%.%w%w%w$")) then if utils.hasModelName(name) then dirs[#dirs + 1] = {foldername = name} end end end
    return dirs
end

return utils
