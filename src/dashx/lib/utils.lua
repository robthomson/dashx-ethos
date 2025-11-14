--[[
  Copyright (C) 2025 Rob Thomson
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local dashx = require("dashx")

local utils = {}

local arg = {...}
local config = arg[1]

function utils.session()
    dashx.session = {}
    dashx.session.tailMode = nil
    dashx.session.swashMode = nil
    dashx.session.activeProfile = nil
    dashx.session.activeRateProfile = nil
    dashx.session.activeProfileLast = nil
    dashx.session.activeRateLast = nil
    dashx.session.servoCount = nil
    dashx.session.servoOverride = nil
    dashx.session.clockSet = nil
    dashx.session.apiVersion = nil
    dashx.session.activeProfile = nil
    dashx.session.activeRateProfile = nil
    dashx.session.activeProfileLast = nil
    dashx.session.activeRateLast = nil
    dashx.session.servoCount = nil
    dashx.session.servoOverride = nil
    dashx.session.clockSet = nil
    dashx.session.lastLabel = nil
    dashx.session.tailMode = nil
    dashx.session.swashMode = nil
    dashx.session.formLineCnt = nil
    dashx.session.rateProfile = nil
    dashx.session.governorMode = nil
    dashx.session.servoOverride = nil
    dashx.session.ethosRunningVersion = nil
    dashx.session.lcdWidth = nil
    dashx.session.lcdHeight = nil
    dashx.session.mspSignature = nil
    dashx.session.telemetryState = nil
    dashx.session.telemetryType = nil
    dashx.session.telemetryTypeChanged = nil
    dashx.session.telemetrySensor = nil
    dashx.session.repairSensors = false
    dashx.session.locale = system.getLocale()
    dashx.session.lastMemoryUsage = nil
    dashx.session.mcu_id = nil
    dashx.session.isConnected = false
    dashx.session.isArmed = false
    dashx.session.bblSize = nil
    dashx.session.bblUsed = nil
    dashx.session.batteryConfig = nil

    dashx.session.modelPreferences = nil
    dashx.session.modelPreferencesFile = nil
    dashx.session.dashboardEditingTheme = nil
    dashx.session.timer = {}
    dashx.session.timer.start = nil
    dashx.session.timer.live = nil
    dashx.session.timer.lifetime = nil
    dashx.session.timer.session = 0
    dashx.session.flightCounted = false
    dashx.session.onConnect = {}
    dashx.session.onConnect.high = false
    dashx.session.onConnect.low = false
    dashx.session.onConnect.medium = false
    dashx.session.rx = {}
    dashx.session.rx.map = {}
    dashx.session.rx.values = {}
end

function utils.rxmapReady()

    if dashx.session.rx and dashx.session.rx.map and (dashx.session.rx.map.collective or dashx.session.rx.map.elevator or dashx.session.rx.map.throttle or dashx.session.rx.map.rudder) then return true end
    return false
end

function utils.inFlight()
    if dashx.flightmode.current == "inflight" then return true end
    return false
end

function utils.msp_version_array_to_indexed()
    local arr = {}
    local tbl = dashx.config.supportedMspApiVersion or {"12.06", "12.07", "12.08"}
    for i, v in ipairs(tbl) do arr[#arr + 1] = {v, i} end
    return arr
end

function utils.armingDisableFlagsToString(flags)

    local ARMING_DISABLE_FLAG_TAG = {
        [0] = "@i18n(app.modules.fblstatus.arming_disable_flag_0):upper()@",
        [1] = "@i18n(app.modules.fblstatus.arming_disable_flag_1):upper()@",
        [2] = "@i18n(app.modules.fblstatus.arming_disable_flag_2):upper()@",
        [3] = "@i18n(app.modules.fblstatus.arming_disable_flag_3):upper()@",
        [4] = "@i18n(app.modules.fblstatus.arming_disable_flag_4):upper()@",
        [5] = "@i18n(app.modules.fblstatus.arming_disable_flag_5):upper()@",
        [6] = "@i18n(app.modules.fblstatus.arming_disable_flag_6):upper()@",
        [7] = "@i18n(app.modules.fblstatus.arming_disable_flag_7):upper()@",
        [8] = "@i18n(app.modules.fblstatus.arming_disable_flag_8):upper()@",
        [9] = "@i18n(app.modules.fblstatus.arming_disable_flag_9):upper()@",
        [10] = "@i18n(app.modules.fblstatus.arming_disable_flag_10):upper()@",
        [11] = "@i18n(app.modules.fblstatus.arming_disable_flag_11):upper()@",
        [12] = "@i18n(app.modules.fblstatus.arming_disable_flag_12):upper()@",
        [13] = "@i18n(app.modules.fblstatus.arming_disable_flag_13):upper()@",
        [14] = "@i18n(app.modules.fblstatus.arming_disable_flag_14):upper()@",
        [15] = "@i18n(app.modules.fblstatus.arming_disable_flag_15):upper()@",
        [16] = "@i18n(app.modules.fblstatus.arming_disable_flag_16):upper()@",
        [17] = "@i18n(app.modules.fblstatus.arming_disable_flag_17):upper()@",
        [18] = "@i18n(app.modules.fblstatus.arming_disable_flag_18):upper()@",
        [19] = "@i18n(app.modules.fblstatus.arming_disable_flag_19):upper()@",
        [20] = "@i18n(app.modules.fblstatus.arming_disable_flag_20):upper()@",
        [21] = "@i18n(app.modules.fblstatus.arming_disable_flag_21):upper()@",
        [22] = "@i18n(app.modules.fblstatus.arming_disable_flag_22):upper()@",
        [23] = "@i18n(app.modules.fblstatus.arming_disable_flag_23):upper()@",
        [24] = "@i18n(app.modules.fblstatus.arming_disable_flag_24):upper()@",
        [25] = "@i18n(app.modules.fblstatus.arming_disable_flag_25):upper()@"
    }

    if flags == nil or flags == 0 then return "@i18n(app.modules.fblstatus.ok):upper()@" end

    local names = {}
    for i = 0, 25 do
        if (flags & (1 << i)) ~= 0 then
            local name = ARMING_DISABLE_FLAG_TAG[i]
            if name and name ~= "" then names[#names + 1] = name end
        end
    end

    if #names == 0 then return "@i18n(app.modules.fblstatus.ok):upper()@" end

    return table.concat(names, ", ")
end

function utils.getGovernorState(value)

    local returnvalue

    if not dashx.tasks.telemetry then return "@i18n(widgets.governor.UNKNOWN)@" end

    local map = {
        [0] = "@i18n(widgets.governor.OFF)@",
        [1] = "@i18n(widgets.governor.IDLE)@",
        [2] = "@i18n(widgets.governor.SPOOLUP)@",
        [3] = "@i18n(widgets.governor.RECOVERY)@",
        [4] = "@i18n(widgets.governor.ACTIVE)@",
        [5] = "@i18n(widgets.governor.THROFF)@",
        [6] = "@i18n(widgets.governor.LOSTHS)@",
        [7] = "@i18n(widgets.governor.AUTOROT)@",
        [8] = "@i18n(widgets.governor.BAILOUT)@",
        [100] = "@i18n(widgets.governor.DISABLED)@",
        [101] = "@i18n(widgets.governor.DISARMED)@"
    }

    if dashx.session and dashx.session.apiVersion and dashx.session.apiVersion > 12.07 then
        local armflags = dashx.tasks.telemetry.getSensor("armflags")
        if armflags == 0 or armflags == 2 then value = 101 end
    end

    if map[value] then
        returnvalue = map[value]
    else
        returnvalue = "@i18n(widgets.governor.UNKNOWN)@"
    end

    local armdisableflags = dashx.tasks.telemetry.getSensor("armdisableflags")
    if armdisableflags ~= nil then
        armdisableflags = math.floor(armdisableflags)
        local armstring = utils.armingDisableFlagsToString(armdisableflags)
        if armstring ~= "OK" then returnvalue = armstring end
    end

    return returnvalue
end

function utils.createCacheFile(tbl, path, options)

    os.mkdir("cache")

    path = "cache/" .. path

    local f, err = io.open(path, "w")
    if not f then
        dashx.utils.log("Error creating cache file: " .. err, "info")
        return
    end

    local function serialize(value, indent)
        indent = indent or ""
        local t = type(value)

        if t == "string" then
            return string.format("%q", value)
        elseif t == "number" or t == "boolean" then
            return tostring(value)
        elseif t == "table" then
            local result = "{\n"
            for k, v in pairs(value) do
                local keyStr
                if type(k) == "string" and k:match("^%a[%w_]*$") then
                    keyStr = k .. " = "
                else
                    keyStr = "[" .. serialize(k) .. "] = "
                end
                result = result .. indent .. "  " .. keyStr .. serialize(v, indent .. "  ") .. ",\n"
            end
            result = result .. indent .. "}"
            return result
        else
            error("Cannot serialize type: " .. t)
        end
    end

    f:write("return ", serialize(tbl), "\n")
    f:close()
end

function utils.sanitize_filename(str)
    if not str then return nil end
    return str:match("^%s*(.-)%s*$"):gsub('[\\/:"*?<>|]', '')
end

function utils.dir_exists(base, name)
    base = base or "./"
    local list = system.listFiles(base)
    if list == nil then return false end
    for i = 1, #list do if list[i] == name then return true end end
    return false
end

function utils.file_exists(name)
    local f = io.open(name, "r")
    if f then
        io.close(f)
        return true
    end
    return false
end

function utils.playFile(pkg, file)

    local av = system.getAudioVoice():gsub("SD:", ""):gsub("RADIO:", ""):gsub("AUDIO:", ""):gsub("VOICE[1-4]:", ""):gsub("audio/", "")

    if av:sub(1, 1) == "/" then av = av:sub(2) end

    local wavUser = "SCRIPTS:/dashx.user/audio/user/" .. pkg .. "/" .. file
    local wavLocale = "SCRIPTS:/dashx.user/audio/" .. av .. "/" .. pkg .. "/" .. file
    local wavDefault = "SCRIPTS:/dashx/audio/en/default/" .. pkg .. "/" .. file

    local path
    if dashx.utils.file_exists(wavUser) then
        path = wavUser
    elseif dashx.utils.file_exists(wavLocale) then
        path = wavLocale
    else
        path = wavDefault
    end

    system.playFile(path)
end

function utils.playFileCommon(file) system.playFile("audio/" .. file) end

function utils.getCurrentProfile()

    local pidProfile = dashx.tasks.telemetry.getSensor("pid_profile")
    local rateProfile = dashx.tasks.telemetry.getSensor("rate_profile")

    if (pidProfile ~= nil and rateProfile ~= nil) then

        dashx.session.activeProfileLast = dashx.session.activeProfile
        local p = pidProfile
        if p ~= nil then
            dashx.session.activeProfile = math.floor(p)
        else
            dashx.session.activeProfile = nil
        end

        dashx.session.activeRateProfileLast = dashx.session.activeRateProfile
        local r = rateProfile
        if r ~= nil then
            dashx.session.activeRateProfile = math.floor(r)
        else
            dashx.session.activeRateProfile = nil
        end

    end
end

function utils.ethosVersionAtLeast(targetVersion)
    local env = system.getVersion()
    local currentVersion = {env.major, env.minor, env.revision}

    if targetVersion == nil then
        if dashx and dashx.config and dashx.config.ethosVersion then
            targetVersion = dashx.config.ethosVersion
        else

            return false
        end
    elseif type(targetVersion) == "number" then
        dashx.utils.log("WARNING: utils.ethosVersionAtLeast() called with a number instead of a table (" .. targetVersion .. ")", 2)
        return false
    end

    for i = 1, 3 do targetVersion[i] = targetVersion[i] or 0 end

    for i = 1, 3 do
        if currentVersion[i] > targetVersion[i] then
            return true
        elseif currentVersion[i] < targetVersion[i] then
            return false
        end
    end

    return true
end

function utils.titleCase(str) return str:gsub("(%a)([%w_']*)", function(first, rest) return first:upper() .. rest:lower() end) end

function utils.stringInArray(array, s)
    for i, value in ipairs(array) do if value == s then return true end end
    return false
end

function utils.round(num, places)
    if num == nil then return nil end

    local places = places or 2
    if places == 0 then
        return math.floor(num + 0.5)
    else
        local mult = 10 ^ places
        return math.floor(num * mult + 0.5) / mult
    end
end

function utils.roughlyEqual(a, b, tolerance) return math.abs(a - b) < (tolerance or 0.0001) end

function utils.getWindowSize() return lcd.getWindowSize() end

function utils.joinTableItems(tbl, delimiter)
    if not tbl or #tbl == 0 then return "" end

    delimiter = delimiter or ""
    local startIndex = tbl[0] and 0 or 1

    local paddedTable = {}
    for i = startIndex, #tbl do paddedTable[i] = tostring(tbl[i]) .. string.rep(" ", math.max(0, 3 - #tostring(tbl[i]))) end

    return table.concat(paddedTable, delimiter, startIndex, #tbl)
end

function utils.log(msg, level) if dashx.tasks and dashx.tasks.logger then dashx.tasks.logger.add(msg, level or "debug") end end

function utils.print_r(node, maxDepth, currentDepth)
    maxDepth = maxDepth or 5
    currentDepth = currentDepth or 0

    if currentDepth > maxDepth then return "{...} -- Max Depth Reached" end

    if type(node) ~= "table" then return tostring(node) .. " (" .. type(node) .. ")" end

    local result = {}

    table.insert(result, "{")

    for k, v in pairs(node) do
        local key = type(k) == "string" and ('["' .. k .. '"]') or ("[" .. tostring(k) .. "]")
        local value

        if type(v) == "table" then
            value = utils.print_r(v, maxDepth, currentDepth + 1)
        else
            value = tostring(v)
            if type(v) == "string" then value = '"' .. value .. '"' end
        end

        table.insert(result, key .. " = " .. value .. ",")
    end

    table.insert(result, "}")

    return print(table.concat(result, " "))
end

function utils.findModules()
    local modulesList = {}

    local moduledir = "app/modules/"
    local modules_path = moduledir

    for _, v in pairs(system.listFiles(modules_path)) do

        if v ~= ".." and v ~= "." and not v:match("%.%a+$") then
            local init_path = modules_path .. v .. '/init.lua'

            local func, err = loadfile(init_path)
            if not func then
                dashx.utils.log("Failed to load module init " .. init_path .. ": " .. err, "info")
            else
                local ok, mconfig = pcall(func)
                if not ok then
                    dashx.utils.log("Error executing " .. init_path .. ": " .. mconfig, "info")
                elseif type(mconfig) ~= "table" or not mconfig.script then
                    dashx.utils.log("Invalid configuration in " .. init_path, "info")
                else
                    dashx.utils.log("Loading module " .. v, "debug")
                    mconfig.folder = v
                    table.insert(modulesList, mconfig)
                end
            end

        end
    end

    return modulesList
end

function utils.findWidgets()
    local widgetsList = {}

    local widgetdir = "widgets/"
    local widgets_path = widgetdir

    for _, v in pairs(system.listFiles(widgets_path)) do

        if v ~= ".." and v ~= "." and not v:match("%.%a+$") then
            local init_path = widgets_path .. v .. '/init.lua'

            local func, err = loadfile(init_path)
            if not func then
                dashx.utils.log("Failed to load widget init " .. init_path .. ": " .. err, "debug")
            else
                local ok, wconfig = pcall(func)
                if not ok then
                    dashx.utils.log("Error executing widget init " .. init_path .. ": " .. wconfig, "debug")
                elseif type(wconfig) ~= "table" or not wconfig.key then
                    dashx.utils.log("Invalid configuration in " .. init_path, "debug")
                else
                    wconfig.folder = v
                    table.insert(widgetsList, wconfig)
                end
            end
        end
    end

    return widgetsList
end

utils._imagePathCache = {}
utils._imageBitmapCache = {}
function utils.loadImage(image1, image2, image3)

    local function getCachedBitmap(key, tryPaths)

        if not key then return nil end

        if utils._imageBitmapCache[key] then return utils._imageBitmapCache[key] end

        local path = utils._imagePathCache[key]
        if not path then
            for _, p in ipairs(tryPaths) do
                if dashx.utils.file_exists(p) then
                    path = p
                    break
                end
            end
            utils._imagePathCache[key] = path
        end

        if not path then return nil end
        local bmp = lcd.loadBitmap(path)
        utils._imageBitmapCache[key] = bmp
        return bmp
    end

    local function candidates(img)
        if type(img) ~= "string" then return {} end
        local out = {img, "BITMAPS:" .. img, "SYSTEM:" .. img}
        if img:match("%.png$") then

            out[#out + 1] = img:gsub("%.png$", ".bmp")
        elseif img:match("%.bmp$") then
            out[#out + 1] = img:gsub("%.bmp$", ".png")
        end
        return out
    end

    return getCachedBitmap(image1, candidates(image1)) or getCachedBitmap(image2, candidates(image2)) or getCachedBitmap(image3, candidates(image3))
end

function utils.simSensors(id)
    os.mkdir("LOGS:")
    os.mkdir("LOGS:/dashx")
    os.mkdir("LOGS:/dashx/sensors")

    if id == nil then return 0 end

    local filepath = "sim/sensors/" .. id .. ".lua"

    local chunk, err = loadfile(filepath)
    if not chunk then
        print("Error loading telemetry file: " .. err)
        return 0
    end

    local success, result = pcall(chunk)
    if not success then
        print("Error executing telemetry file: " .. result)
        return 0
    end

    return result
end

function utils.splitString(input, sep)
    local result = {}

    for item in input:gmatch("([^" .. sep .. "]+)") do table.insert(result, item) end

    return result
end

function utils.logMsp(cmd, rwState, buf, err)
    if dashx.preferences.developer.logmsp then
        local payload = dashx.utils.joinTableItems(buf, ", ")
        dashx.utils.log(rwState .. " [" .. cmd .. "]" .. " {" .. payload .. "}", "info")
        if err then dashx.utils.log("Error: " .. err, "info") end
    end
end

function utils.truncateText(str, maxWidth)
    lcd.font(bestFont)
    local tsizeW, _ = lcd.getTextSize(str)

    if tsizeW <= maxWidth then return str end

    local ellipsis = "..."
    local truncatedStr = str
    while tsizeW > maxWidth and #truncatedStr > 1 do
        truncatedStr = string.sub(truncatedStr, 1, #truncatedStr - 1)
        tsizeW, _ = lcd.getTextSize(truncatedStr .. ellipsis)
    end
    return truncatedStr .. ellipsis
end

function utils.reportMemoryUsage(location)

    if dashx.preferences.developer.memstats == false then return end

    local currentMemoryUsage = system.getMemoryUsage().luaRamAvailable / 1024

    local lastMemoryUsage = dashx.session.lastMemoryUsage

    location = location or "Unknown"

    local logMessage

    if lastMemoryUsage then
        lastMemoryUsage = lastMemoryUsage / 1024
        local difference = currentMemoryUsage - lastMemoryUsage
        if difference > 0 then
            logMessage = string.format("[%s] Memory usage decreased by %.2f KB (Current: %.2f KB)", location, difference, currentMemoryUsage)
        elseif difference < 0 then
            logMessage = string.format("[%s] Memory usage increased by %.2f KB (Current: %.2f KB)", location, -difference, currentMemoryUsage)
        else
            logMessage = string.format("[%s] Memory usage unchanged (Current: %.2f KB)", location, currentMemoryUsage)
        end
    else
        logMessage = string.format("[%s] Initial memory usage: %.2f KB", location, currentMemoryUsage)
    end

    dashx.utils.log(logMessage, "info")

    dashx.session.lastMemoryUsage = system.getMemoryUsage().luaRamAvailable
end

function utils.onReboot()
    dashx.session.resetSensors = true
    dashx.session.resetTelemetry = true
    dashx.session.resetMSP = true
    dashx.session.resetMSPSensors = true
end

function utils.splitVersionStringToNumbers(versionString)
    if not versionString then return nil end

    local parts = {0}
    for num in versionString:gmatch("%d+") do table.insert(parts, tonumber(num)) end
    return parts
end

function utils.keys(tbl)
    local keys = {}
    for k in pairs(tbl) do table.insert(keys, k) end
    return keys
end

return utils
