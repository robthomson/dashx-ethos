--[[
 * Copyright (C) dashx Project
 *
 * License GPLv3: https://www.gnu.org/licenses/gpl-3.0.en.html
]]

-- Keep the namespace local (no globals)
local dashx = {}
dashx.session = {}

-- Shared environment so every chunk sees `dashx` without touching _G
local ENV = setmetatable({ dashx = dashx }, {
  __index = _G,
  -- Uncomment to forbid accidental globals from modules:
   __newindex = function(_, k) error("attempt to create global '"..tostring(k).."'", 2) end
})

-- initialise legacy font if not already set (ethos 1.6 vs 1.7)
if not FONT_M then FONT_M = FONT_STD end

-- RotorFlight + ETHOS LUA configuration
local config = {}

-- Configuration settings for the dashx Lua Ethos Suite
config.toolName = "DashX"
config.icon = lcd.loadMask("app/gfx/icon.png")
config.icon_logtool = lcd.loadMask("app/gfx/icon_logtool.png")
config.icon_unsupported = lcd.loadMask("app/gfx/unsupported.png")
config.version = {major = 2, minor = 3, revision = 0, suffix = "DEV"}
config.ethosVersion = {1, 6, 2}
config.supportedMspApiVersion = {"12.07","12.08","12.09"}
config.baseDir = "dashx"
config.preferences = config.baseDir .. ".user"
config.defaultRateProfile = 4
config.watchdogParam = 10

dashx.config = config

-- INI utilities (never compiled) loaded inside ENV
dashx.ini = assert(loadfile("lib/ini.lua", "t", ENV))(config)

-- set defaults for user preferences
local userpref_defaults ={
  general ={
    iconsize = 2,
    syncname = false,
    gimbalsupression = 0.85
  },
  localizations = {
    temperature_unit = 0, -- 0 = Celsius, 1 = Fahrenheit
    altitude_unit = 0, -- 0 = meters, 1 = feet
  },
  dashboard = {
    theme_preflight = "system/default",
    theme_inflight = "system/default",
    theme_postflight = "system/default",
  },
  events = {
    armed = true,
    voltage = true,
    fuel = true,
    profile = true,
    inflight = true,
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
  },
  menulastselected = {}
}

-- Preferences path
os.mkdir("SCRIPTS:/" .. dashx.config.preferences)
local userpref_file = "SCRIPTS:/" .. dashx.config.preferences .. "/preferences.ini"
local slave_ini = userpref_defaults
local master_ini = dashx.ini.load_ini_file(userpref_file) or {}

local updated_ini = dashx.ini.merge_ini_tables(master_ini, slave_ini)
dashx.preferences = updated_ini

if not dashx.ini.ini_tables_equal(master_ini, slave_ini) then
  dashx.ini.save_ini_file(userpref_file, updated_ini)
end

-- tasks
dashx.config.bgTaskName = dashx.config.toolName .. " [Background]"
dashx.config.bgTaskKey = "dshxbg"

-- compiler (loaded into ENV so it can load the rest into the same ENV)
dashx.compiler = assert(loadfile("lib/compile.lua","t",ENV))(dashx.config)

-- library with utility functions used throughout the suite
dashx.utils = assert(dashx.compiler.loadfile("lib/utils.lua"))(dashx.config)

-- main app
dashx.app = assert(dashx.compiler.loadfile("app/app.lua"))(dashx.config)

-- tasks
dashx.tasks = assert(dashx.compiler.loadfile("tasks/tasks.lua"))(dashx.config)

-- configure the flight mode
dashx.flightmode = { current = "preflight" }

-- Reset the session state
dashx.utils.session()

-- simulator hooks
dashx.simevent = { telemetry_state = true }

--- Retrieves the version information of the dashx module.
function dashx.version()
  local v = dashx.config.version
  return {
    version = string.format("%d.%d.%d-%s", v.major, v.minor, v.revision, v.suffix),
    major = v.major,
    minor = v.minor,
    revision = v.revision,
    suffix = v.suffix
  }
end

local function init()
  -- prevent this running if version is not supported
  if not dashx.utils.ethosVersionAtLeast() then
    system.registerSystemTool({
      name = dashx.config.toolName,
      icon = dashx.config.icon_unsupported ,
      create = function () end,
      wakeup = function () lcd.invalidate(); return end,
      paint = function ()
        local w, h = lcd.getWindowSize()
        local textColor = lcd.RGB(255, 255, 255, 1)
        lcd.color(textColor)
        lcd.font(FONT_M)
        local badVersionMsg = string.format("ETHOS < V%d.%d.%d", table.unpack(config.ethosVersion))
        local textWidth, textHeight = lcd.getTextSize(badVersionMsg)
        local x = (w - textWidth) / 2
        local y = (h - textHeight) / 2
        lcd.drawText(x, y, badVersionMsg)
        return
      end,
      close = function () end,
    })
    return
  end

  -- main system tool
  system.registerSystemTool({
    event = dashx.app.event,
    name = dashx.config.toolName,
    icon = dashx.config.icon,
    create = dashx.app.create,
    wakeup = dashx.app.wakeup,
    paint = dashx.app.paint,
    close = dashx.app.close
  })

  -- background task
  system.registerTask({
    name = dashx.config.bgTaskName,
    key = dashx.config.bgTaskKey,
    wakeup = dashx.tasks.wakeup,
    event = dashx.tasks.event,
    init = dashx.tasks.init
  })

  -- widgets: use cache if valid; else rebuild
  local cacheFile = "widgets.lua"
  local cachePath = "cache/" .. cacheFile
  local widgetList

  local loadf, loadErr = dashx.compiler.loadfile(cachePath)
  if loadf then
    local ok, cached = pcall(loadf)
    if ok and type(cached) == "table" then
      widgetList = cached
      dashx.utils.log("[cache] Loaded widget list from cache","info")
    else
      dashx.utils.log("[cache] Bad cache, rebuilding: "..tostring(cached),"info")
    end
  end

  if not widgetList then
    widgetList = dashx.utils.findWidgets()
    dashx.utils.createCacheFile(widgetList, cacheFile, true)
    dashx.utils.log("[cache] Created new widgets cache file","info")
  end

  -- load and register widgets
  dashx.widgets = {}
  for _, v in ipairs(widgetList) do
    if v.script then
      local scriptModule = assert(dashx.compiler.loadfile("widgets/" .. v.folder .. "/" .. v.script))(config)
      local varname = v.varname or v.script:gsub("%.lua$", "")
      if dashx.widgets[varname] then
        math.randomseed(os.time())
        local rand = math.random()
        dashx.widgets[varname .. rand] = scriptModule
      else
        dashx.widgets[varname] = scriptModule
      end

      system.registerWidget({
        name = v.name,
        key = v.key,
        event = scriptModule.event,
        create = scriptModule.create,
        paint = scriptModule.paint,
        wakeup = scriptModule.wakeup,
        build = scriptModule.build,
        close = scriptModule.close,
        configure = scriptModule.configure,
        read = scriptModule.read,
        write = scriptModule.write,
        persistent = scriptModule.persistent or false,
        menu = scriptModule.menu,
        title = scriptModule.title
      })
    end
  end
end

return { init = init }
