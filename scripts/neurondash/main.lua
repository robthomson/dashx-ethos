--[[

 * Copyright (C) neurondash Project
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
neurondash = {}
neurondash.session = {}

-- initialise legacy font if not already set (ethos 1.6 vs 1.7)
if not FONT_M then FONT_M = FONT_STD end


-- RotorFlight + ETHOS LUA configuration
local config = {}

-- Configuration settings for the neurondash Lua Ethos Suite
config.toolName = "NEURON"                                                     -- name of the tool 
config.icon = lcd.loadMask("app/gfx/icon.png")                                      -- icon
config.icon_logtool = lcd.loadMask("app/gfx/icon_logtool.png")          -- icon
config.icon_unsupported = lcd.loadMask("app/gfx/unsupported.png")                   -- icon
config.version = {major = 2, minor = 3, revision = 0, suffix = "DEV"}               -- version of the script
config.ethosVersion = {1, 6, 2}                                                      -- min version of ethos supported by this script                                                     
config.supportedMspApiVersion = {"12.07","12.08","12.09"}                          -- supported msp versions
config.baseDir = "neurondash"                                                          -- base directory for the suite. This is only used by msp api to ensure correct path
config.preferences = config.baseDir .. ".user"                                      -- user preferences folder location
config.defaultRateProfile = 4 -- ACTUAL                                             -- default rate table [default = 4]
config.watchdogParam = 10                                                           -- watchdog timeout for progress boxes [default = 10]

neurondash.config = config

--[[
    Loads and updates user preferences from an INI file.

    Steps:
    1. Retrieves the user preferences file path from the configuration.
    2. Sets `slave_ini` to the default user preferences.
    3. Initializes `master_ini` as an empty table.
    4. If the user preferences file exists, loads its contents into `master_ini`.
    5. Merges `master_ini` (existing preferences) with `slave_ini` (defaults) to ensure all default values are present.
    6. Assigns the merged preferences to `neurondash.preferences`.
    7. If the loaded preferences differ from the defaults, saves the updated preferences back to the file and logs the update.

    This ensures that any missing default preferences are added to the user's preferences file without overwriting existing values.
]]
neurondash.ini = assert(loadfile("lib/ini.lua"))(config) -- self contantained and never compiled

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
    },
    switches = {
    },
    developer = {
        compile = true,             -- compile the script
        devtools = false,           -- show dev tools menu
        logtofile = false,          -- log to file
        loglevel = "off",           -- off, info, debug
        logmsp = false,             -- print msp byte stream to log  
        logmspQueue = false,        -- periodic print the msp queue size
        memstats = false,           -- perioid print memory usage 
        mspexpbytes = 8,
        apiversion = 2,             -- msp api version to use for simulator    
    },
    menulastselected = {}
}

os.mkdir("SCRIPTS:/" .. neurondash.config.preferences)
local userpref_file = "SCRIPTS:/" .. neurondash.config.preferences .. "/preferences.ini"
local slave_ini = userpref_defaults
local master_ini = neurondash.ini.load_ini_file(userpref_file) or {}

local updated_ini = neurondash.ini.merge_ini_tables(master_ini, slave_ini)
neurondash.preferences = updated_ini

if not neurondash.ini.ini_tables_equal(master_ini, slave_ini) then
    neurondash.ini.save_ini_file(userpref_file, updated_ini)
end 

-- tasks
neurondash.config.bgTaskName = neurondash.config.toolName .. " [Background]"              -- background task name for msp services etc
neurondash.config.bgTaskKey = "nrdshbg"                                          -- key id used for msp services

-- main
-- neurondash: Main table for the omp-neurondash-dashboard script.
-- neurondash.config: Configuration table for the suite.
-- neurondash.session: Session table for the suite.
-- neurondash.app: Application module loaded from "app/app.lua" with the provided configuration.
neurondash.compiler = assert(loadfile("lib/compile.lua"))(neurondash.config) 


-- library with utility functions used throughou the suite
neurondash.utils = assert(neurondash.compiler.loadfile("lib/utils.lua"))(neurondash.config)

neurondash.app = assert(neurondash.compiler.loadfile("app/app.lua"))(neurondash.config)


-- 
-- This script initializes the `neurondash` tasks and background task.
-- 
-- The `neurondash.tasks` table is created to hold various tasks.
-- The `neurondash.tasks` is assigned the result of executing the "tasks/tasks.lua" file with the `config` parameter.
-- The `neurondash.compiler.loadfile` function is used to load the "tasks/tasks.lua" file, and `assert` ensures that the file is loaded successfully.
-- The loaded file is then executed with the `config` parameter, and its return value is assigned to `neurondash.tasks`.
-- tasks
neurondash.tasks = assert(neurondash.compiler.loadfile("tasks/tasks.lua"))(neurondash.config)

-- LuaFormatter off

-- configure the flight mode
neurondash.flightmode = {}
neurondash.flightmode.current = "preflight"

-- Reset the session state
neurondash.utils.session()

-- when running in sim mode we can trigger events in tasks/simevent/simevent.lua
-- this is used to trigger events in the simulator that are hard to do without a physical radio
neurondash.simevent = {}
neurondash.simevent.telemetry_state = true

--- Retrieves the version information of the neurondash module.
--- 
--- This function constructs a version string and returns a table containing
--- detailed version information, including the major, minor, revision, and suffix
--- components.
---
--- @return table A table containing the following fields:
---   - `version` (string): The full version string in the format "X.Y.Z-SUFFIX".
---   - `major` (number): The major version number.
---   - `minor` (number): The minor version number.
---   - `revision` (number): The revision version number.
---   - `suffix` (string): The version suffix (e.g., "alpha", "beta").
function neurondash.version()
    local version = neurondash.config.version.major .. "." .. neurondash.config.version.minor .. "." .. neurondash.config.version.revision .. "-" .. neurondash.config.version.suffix
    return {
        version = version,
        major = neurondash.config.version.major,
        minor = neurondash.config.version.minor,
        revision = neurondash.config.version.revision,
        suffix = neurondash.config.version.suffix
    }
end


--[[
    Initializes the main script for the omp-neurondash-dashboard.

    This function performs the following tasks:
    1. Checks if the Ethos version is supported using `neurondash.utils.ethosVersionAtLeast()`.
       If the version is not supported, it raises an error and stops execution.
    2. Registers system tools using `system.registerSystemTool()` with configurations from `config`.
    3. Registers a background task using `system.registerTask()` with configurations from `config`.
    4. Dynamically loads and registers widgets:
       - Finds widget scripts using `neurondash.utils.findWidgets()`.
       - Loads each widget script dynamically using `neurondash.compiler.loadfile()`.
       - Assigns the loaded script to a variable inside the `neurondash` table.
       - Registers each widget with `system.registerWidget()` using the dynamically assigned module.

    Note:
    - Assumes `v.name` is a valid Lua identifier-like string (without spaces or special characters).
    - Each widget script is expected to have functions like `event`, `create`, `paint`, `wakeup`, `close`, `configure`, `read`, `write`, and optionally `persistent` and `menu`.

    Throws:
    - Error if the Ethos version is not supported.

    Dependencies:
    - `neurondash.utils.ethosVersionAtLeast()`
    - `system.registerSystemTool()`
    - `system.registerTask()`
    - `neurondash.utils.findWidgets()`
    - `neurondash.compiler.loadfile()`
    - `system.registerWidget()`
]]
local function init()

    -- prevent this even getting close to running if version is not good
    if not neurondash.utils.ethosVersionAtLeast() then

        system.registerSystemTool({
            name = neurondash.config.toolName,
            icon = neurondash.config.icon_unsupported ,
            create = function () end,
            wakeup = function () 
                        lcd.invalidate()
                        return
                     end,
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

    -- Registers the main system tool with the specified configuration.
    -- This tool handles events, creation, wakeup, painting, and closing.
    system.registerSystemTool({
        event = neurondash.app.event,
        name = neurondash.config.toolName,
        icon = neurondash.config.icon,
        create = neurondash.app.create,
        wakeup = neurondash.app.wakeup,
        paint = neurondash.app.paint,
        close = neurondash.app.close
    })

    -- Registers the log tool with the specified configuration.
    -- This tool handles events, creation, wakeup, painting, and closing.
 -- disabled for now as can be reached via main tool - tbd
 --   system.registerSystemTool({
 --       event = neurondash.app.event,
 --       name = config.toolName,
 --       icon = config.icon_logtool,
 --       create = neurondash.app.create_logtool,
 --       wakeup = neurondash.app.wakeup,
 --       paint = neurondash.app.paint,
 --       close = neurondash.app.close
 --   })

    -- Registers a background task with the specified configuration.
    -- This task handles wakeup and event processing.
    system.registerTask({
        name = neurondash.config.bgTaskName,
        key = neurondash.config.bgTaskKey,
        wakeup = neurondash.tasks.wakeup,
        event = neurondash.tasks.event,
        init = neurondash.tasks.init
    })

    -- widgets are loaded dynamically
    local cacheFile = "widgets.lua"
    local cachePath = "cache/" .. cacheFile
    local widgetList
    
    -- Try loading cache if it exists
    local loadf, loadErr = neurondash.compiler.loadfile(cachePath)
    if loadf then
        local ok, cached = pcall(loadf)
        if ok and type(cached) == "table" then
            widgetList = cached
            neurondash.utils.log("[cache] Loaded widget list from cache","info")
        else
            neurondash.utils.log("[cache] Bad cache, rebuilding: "..tostring(cached),"info")
        end
    end
    
    -- If no valid cache, build and write new one
    if not widgetList then
        widgetList = neurondash.utils.findWidgets()
        neurondash.utils.createCacheFile(widgetList, cacheFile, true)
        neurondash.utils.log("[cache] Created new widgets cache file","info")
    end

    -- Iterates over the widgetList table and dynamically loads and registers widget scripts.
    -- For each widget in the list:
    -- 1. Checks if the widget has a script defined.
    -- 2. Loads the script file from the specified folder and assigns it to a variable inside the neurondash table.
    -- 3. Uses the script name (or a provided variable name) as a key to store the loaded script module in the neurondash table.
    -- 4. Registers the widget with the system using the dynamically assigned module's functions and properties.
    -- 
    -- Parameters:
    -- widgetList - A table containing widget definitions. Each widget should have the following fields:
    --   - script: The filename of the widget script to load.
    --   - folder: The folder where the widget script is located.
    --   - name: The name of the widget.
    --   - key: A unique key for the widget.
    --   - varname (optional): A custom variable name to use for storing the script module in the neurondash table.
    -- 
    -- The loaded script module should define the following functions and properties (if applicable):
    --   - event: Function to handle events.
    --   - create: Function to create the widget.
    --   - paint: Function to paint the widget.
    --   - wakeup: Function to handle wakeup events.
    --   - close: Function to handle widget closure.
    --   - configure: Function to configure the widget.
    --   - read: Function to read data.
    --   - write: Function to write data.
    --   - persistent: Boolean indicating if the widget is persistent (default is false).
    --   - menu: Menu definition for the widget.
    --   - title: Title of the widget.
    neurondash.widgets = {}

        for i, v in ipairs(widgetList) do
            if v.script then
                -- Load the script dynamically
                local scriptModule = assert(neurondash.compiler.loadfile("widgets/" .. v.folder .. "/" .. v.script))(config)
        
                -- Use the script filename (without .lua) as the key, or v.varname if provided
                local varname = v.varname or v.script:gsub("%.lua$", "")
        
                -- Store the module inside neurondash.widgets
                if neurondash.widgets[varname] then
                    math.randomseed(os.time())
                    local rand = math.random()
                    neurondash.widgets[varname .. rand] = scriptModule
                else
                    neurondash.widgets[varname] = scriptModule
                end    
        
                -- Register the widget with the system
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

-- LuaFormatter on

return {init = init}
