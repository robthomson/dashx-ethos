--[[
  Copyright (C) 2026 Rob Thomson
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local dashx = {
    session = {},
    widgets = {},
    tools = {},
    theme = {version = 0},
    flightmode = {current = "preflight"},
    app = {guiIsRunning = false}
}

package.loaded.dashx = dashx

if not FONT_M then
    FONT_M = FONT_STD
end

dashx.config = {
    toolName = "DashX",
    baseDir = "dashx",
    preferences = "dashx.user",
    version = {major = 2, minor = 3, revision = 0, suffix = "DEV"},
    ethosVersion = {1, 6, 2},
    supportedMspApiVersion = {"12.07", "12.08", "12.09"}
}

local userPreferenceDefaults = {
    general = {
        iconsize = 2,
        syncname = false,
        gimbalsupression = 0.85
    },
    localizations = {
        temperature_unit = 0,
        altitude_unit = 0
    },
    dashboard = {
        theme_preflight = "system/default",
        theme_inflight = "system/default",
        theme_postflight = "system/default"
    },
    events = {
        armed = true,
        voltage = true,
        fuel = true,
        profile = true,
        inflight = true
    },
    switches = {},
    developer = {
        compile = true,
        devtools = false,
        logtofile = false,
        loglevel = "off",
        logmsp = false,
        logmspQueue = false,
        memstats = false,
        mspexpbytes = 8,
        apiversion = 2,
        overlaygrid = false,
        overlaystats = false,
        logobjprof = false,
        telemetrytrace = false
    },
    menulastselected = {}
}

local function ensureSharedModules()
    if not dashx.ini then
        dashx.ini = assert(loadfile("lib/ini.lua"))()
    end

    if not dashx.utils then
        dashx.utils = assert(loadfile("lib/utils.lua"))(dashx.config)
    end

    if not dashx._sessionInitialized then
        dashx.utils.session()
        dashx._sessionInitialized = true
    end

    if not dashx.preferences then
        local prefDir = "SCRIPTS:/" .. dashx.config.preferences
        local prefFile = prefDir .. "/preferences.ini"
        os.mkdir(prefDir)

        local existing = dashx.ini.load_ini_file(prefFile) or {}
        local merged = dashx.ini.merge_ini_tables(existing, userPreferenceDefaults)
        dashx.preferences = merged

        if not dashx.ini.ini_tables_equal(existing, merged) then
            dashx.ini.save_ini_file(prefFile, merged)
        end
    end
end

local function ensureWidgetModules()
    ensureSharedModules()

    dashx.tasks = dashx.tasks or {}

    if not dashx.telemetry then
        dashx.telemetry = assert(loadfile("lib/telemetry.lua"))(dashx.config)
    end
    dashx.tasks.telemetry = dashx.telemetry

    if not dashx.logging then
        dashx.logging = assert(loadfile("lib/logging.lua"))(dashx.config)
    end
    dashx.tasks.logging = dashx.logging

    if not dashx.sensors then
        dashx.sensors = assert(loadfile("lib/sensors.lua"))(dashx.config)
    end

    if not dashx.events then
        dashx.events = assert(loadfile("lib/events.lua"))(dashx.config)
    end

    if not dashx.runtime then
        dashx.runtime = assert(loadfile("lib/runtime.lua"))(dashx.config)
    end

    if not dashx.widgets.dashboard then
        dashx.widgets.dashboard = assert(loadfile("widgets/dashboard/dashboard.lua"))(dashx.config)
    end

    if not dashx.widgets.dashboardConfigure then
        dashx.widgets.dashboardConfigure = assert(loadfile("widgets/dashboard/configure.lua"))(dashx.config)
    end
end

local function ensureLogsTool()
    ensureSharedModules()

    if not dashx.logs then
        dashx.logs = assert(loadfile("lib/logs.lua"))(dashx.config)
    end

    if not dashx.tools.logs then
        dashx.tools.logs = assert(loadfile("tools/logs.lua"))(dashx.config)
    end
end

function dashx.version()
    local version = dashx.config.version
    return {
        version = string.format("%d.%d.%d-%s", version.major, version.minor, version.revision, version.suffix),
        major = version.major,
        minor = version.minor,
        revision = version.revision,
        suffix = version.suffix
    }
end

local function callWidget(method, ...)
    ensureWidgetModules()
    return dashx.widgets.dashboard[method](...)
end

local function callWidgetConfigure(method, ...)
    ensureWidgetModules()
    return dashx.widgets.dashboardConfigure[method](...)
end

local function callLogsTool(method, ...)
    ensureLogsTool()
    local tool = dashx.tools.logs
    local handler = tool and tool[method]
    if handler then
        return handler(...)
    end
end

local function closeLogsTool(...)
    local tool = dashx.tools and dashx.tools.logs
    if tool and tool.close then
        return tool.close(...)
    end
end

local function loadToolIcon(path)
    if not lcd or not path then
        return nil
    end

    local candidates = {
        path,
        "SCRIPTS:/" .. dashx.config.baseDir .. "/" .. path
    }

    for _, candidate in ipairs(candidates) do
        if lcd.loadMask then
            local ok, loaded = pcall(lcd.loadMask, candidate)
            if ok and loaded then
                return loaded
            end
        end

        if lcd.loadBitmap then
            local ok, loaded = pcall(lcd.loadBitmap, candidate)
            if ok and loaded then
                return loaded
            end
        end
    end

    return nil
end

local function registerWidget()
    system.registerWidget({
        key = "dshxdsh",
        name = "DashX",
        create = function(...)
            return callWidget("create", ...)
        end,
        configure = function(...)
            return callWidgetConfigure("configure", ...)
        end,
        paint = function(...)
            return callWidget("paint", ...)
        end,
        event = function(...)
            return callWidget("event", ...)
        end,
        menu = function(...)
            return callWidget("menu", ...)
        end,
        wakeup = function(...)
            return callWidget("wakeup", ...)
        end,
        read = function(...)
            return callWidgetConfigure("read", ...)
        end,
        write = function(...)
            return callWidgetConfigure("write", ...)
        end,
        title = false,
        persistent = false
    })
end

local function registerLogsTool()
    if not system.registerSystemTool then
        return
    end

    system.registerSystemTool({
        name = "DashX Logs",
        icon = loadToolIcon("app/gfx/icon.png"),
        create = function(...)
            return callLogsTool("create", ...)
        end,
        wakeup = function(...)
            return callLogsTool("wakeup", ...)
        end,
        paint = function(...)
            return callLogsTool("paint", ...)
        end,
        event = function(...)
            return callLogsTool("event", ...)
        end,
        close = function(...)
            return closeLogsTool(...)
        end
    })
end

local function init()
    ensureSharedModules()
    dashx.simevent = dashx.simevent or {telemetry_state = true}
    registerWidget()
    registerLogsTool()
end

return {init = init}
