--[[
 * Copyright (C) Rotorflight Project
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
 *
 * Note. Some icons have been sourced from https://www.flaticon.com/
]]

-- Global namespace for the suite
neuronsuite = {}
neuronsuite.session = {}

-- Ensure legacy font (ethos 1.6 vs 1.7)
if not FONT_M then FONT_M = FONT_STD end

--======================
-- Configuration
--======================
local config = {
  toolName = "Rotorflight",
  icon = lcd.loadMask("app/gfx/icon.png"),
  icon_logtool = lcd.loadMask("app/gfx/icon_logtool.png"),
  icon_unsupported = lcd.loadMask("app/gfx/unsupported.png"),
  version = { major = 2, minor = 3, revision = 0, suffix = "20250731" },
  ethosVersion = { 1, 6, 2 }, -- min supported Ethos version
  supportedMspApiVersion = { "12.07", "12.08", "12.09" },
  baseDir = "neuronsuite",
  preferences = "neuronsuite.user", -- user preferences folder location
  defaultRateProfile = 4, -- ACTUAL
  watchdogParam = 10, -- progress box timeout
}

-- Pre-format minimum version string once
config.ethosVersionString = string.format("ETHOS < V%d.%d.%d", table.unpack(config.ethosVersion))

neuronsuite.config = config

--======================
-- Preferences / INI
--======================
neuronsuite.ini = assert(loadfile("lib/ini.lua"))(config) -- self-contained; never compiled

local userpref_defaults = {
  general = {
    iconsize = 2,
    syncname = false,
    gimbalsupression = 0.85,
    txbatt_type = 0,
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
    armflags = true,
    voltage = true,
    governor = true,
    pid_profile = true,
    rate_profile = true,
    esc_temp = false,
    escalertvalue = 90,
    smartfuel = true,
    smartfuelcallout = 0,
    smartfuelrepeats = 1,
    smartfuelhaptic = false,
    adj_v = false,
    adj_f = false,
  },
  switches = {},
  developer = {
    compile = true, -- compile the script
    devtools = false, -- show dev tools menu
    logtofile = false, -- log to file
    loglevel = "off", -- off, info, debug
    logmsp = false, -- print msp byte stream
    logobjprof = false, -- periodic print object references
    logmspQueue = false, -- periodic print the msp queue size
    memstats = false, -- periodic print memory usage
    taskprofiler = false, -- periodic print task profile
    mspexpbytes = 8,
    apiversion = 2, -- msp api version to use for simulator
    overlaystats = false, -- show cpu load in overlay
    overlaygrid = false, -- show overlay grid
  },
  timer = {
    timeraudioenable = false,
    elapsedalertmode = 0,
    prealerton = false,
    postalerton = false,
    prealertinterval = 10,
    prealertperiod = 30,
    postalertinterval = 10,
    postalertperiod = 30,
  },
  menulastselected = {},
}

-- Build paths once
local prefs_dir = "SCRIPTS:/" .. neuronsuite.config.preferences
os.mkdir(prefs_dir)
local userpref_file = prefs_dir .. "/preferences.ini"

-- Load and merge
local master_ini = neuronsuite.ini.load_ini_file(userpref_file) or {}
local updated_ini = neuronsuite.ini.merge_ini_tables(master_ini, userpref_defaults)
neuronsuite.preferences = updated_ini

-- Save only if the merged result differs from the on-disk data
if not neuronsuite.ini.ini_tables_equal(master_ini, updated_ini) then
  neuronsuite.ini.save_ini_file(userpref_file, updated_ini)
end

--======================
-- Core modules
--======================
neuronsuite.config.bgTaskName = neuronsuite.config.toolName .. " [Background]"
neuronsuite.config.bgTaskKey = "rf2bg"

neuronsuite.compiler = assert(loadfile("lib/compile.lua"))(neuronsuite.config)

neuronsuite.i18n = assert(neuronsuite.compiler.loadfile("lib/i18n.lua"))(neuronsuite.config)
neuronsuite.i18n.load()

neuronsuite.utils = assert(neuronsuite.compiler.loadfile("lib/utils.lua"))(neuronsuite.config)

neuronsuite.app = assert(neuronsuite.compiler.loadfile("app/app.lua"))(neuronsuite.config)

neuronsuite.tasks = assert(neuronsuite.compiler.loadfile("tasks/tasks.lua"))(neuronsuite.config)

-- Flight mode & session
neuronsuite.flightmode = { current = "preflight" }
neuronsuite.utils.session() -- reset session state

-- Simulator hooks
neuronsuite.simevent = { telemetry_state = true }

--======================
-- Public: version API
--======================
function neuronsuite.version()
  local v = neuronsuite.config.version
  return {
    version = string.format("%d.%d.%d-%s", v.major, v.minor, v.revision, v.suffix),
    major = v.major,
    minor = v.minor,
    revision = v.revision,
    suffix = v.suffix,
  }
end

--======================
-- Init / Registration
--======================
local function unsupported_tool()
  return {
    name = neuronsuite.config.toolName,
    icon = neuronsuite.config.icon_unsupported,
    create = function() end,
    wakeup = function()
      lcd.invalidate()
    end,
    paint = function()
      local w, h = lcd.getWindowSize()
      lcd.color(lcd.RGB(255, 255, 255, 1))
      lcd.font(FONT_M)
      local msg = neuronsuite.config.ethosVersionString
      local tw, th = lcd.getTextSize(msg)
      lcd.drawText((w - tw) / 2, (h - th) / 2, msg)
    end,
    close = function() end,
  }
end

local function register_main_tool()
  system.registerSystemTool({
    event = neuronsuite.app.event,
    name = neuronsuite.config.toolName,
    icon = neuronsuite.config.icon,
    create = neuronsuite.app.create,
    wakeup = neuronsuite.app.wakeup,
    paint = neuronsuite.app.paint,
    close = neuronsuite.app.close,
  })
end

local function register_bg_task()
  system.registerTask({
    name = neuronsuite.config.bgTaskName,
    key = neuronsuite.config.bgTaskKey,
    wakeup = neuronsuite.tasks.wakeup,
    event = neuronsuite.tasks.event,
    init = neuronsuite.tasks.init,
    read = neuronsuite.tasks.read,
    write = neuronsuite.tasks.write,
  })
end

local function load_widget_cache(cachePath)
  local loadf, loadErr = neuronsuite.compiler.loadfile(cachePath)
  if not loadf then
    neuronsuite.utils.log("[cache] loadfile failed: " .. tostring(loadErr), "info")
    return nil
  end
  local ok, cached = pcall(loadf)
  if not ok then
    neuronsuite.utils.log("[cache] execution failed: " .. tostring(cached), "info")
    return nil
  end
  if type(cached) ~= "table" then
    neuronsuite.utils.log("[cache] unexpected content; rebuilding", "info")
    return nil
  end
  neuronsuite.utils.log("[cache] Loaded widget list from cache", "info")
  return cached
end

local function build_widget_cache(widgetList, cacheFile)
  neuronsuite.utils.createCacheFile(widgetList, cacheFile, true)
  neuronsuite.utils.log("[cache] Created new widgets cache file", "info")
end

local function register_widgets(widgetList)
  neuronsuite.widgets = {}
  local dupCount = {}

  for _, v in ipairs(widgetList) do
    if v.script then
      local path = "widgets/" .. v.folder .. "/" .. v.script
      local scriptModule = assert(neuronsuite.compiler.loadfile(path))(config)

      local base = v.varname or v.script:gsub("%.lua$", "")
      if neuronsuite.widgets[base] then
        dupCount[base] = (dupCount[base] or 0) + 1
        base = string.format("%s_dup%02d", base, dupCount[base])
      end
      neuronsuite.widgets[base] = scriptModule

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
        title = scriptModule.title,
      })
    end
  end
end

local function init()
  local cfg = neuronsuite.config

  -- Bail early if Ethos is too old
  if not neuronsuite.utils.ethosVersionAtLeast() then
    system.registerSystemTool(unsupported_tool())
    return
  end

  register_main_tool()
  register_bg_task()

  -- Widgets: try cache, else rebuild
  local cacheFile = "widgets.lua"
  local cachePath = "cache/" .. cacheFile
  local widgetList = load_widget_cache(cachePath)

  if not widgetList then
    widgetList = neuronsuite.utils.findWidgets()
    build_widget_cache(widgetList, cacheFile)
  end

  register_widgets(widgetList)
end

return { init = init }
