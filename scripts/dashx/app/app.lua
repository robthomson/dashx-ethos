local dashx = require("dashx")
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
local app = {}

app.initialized = false

local utils = dashx.utils
local log = utils.log
local compile = loadfile

local arg = {...}

local config = arg[1]

-- Function to invalidate the pages variable.
-- Typically called after writing MSP data.
-- Resets the app.Page to nil, sets app.pageState to app.pageStatus.display,
-- and initializes app.saveTS to 0.
local function invalidatePages()
    app.Page = nil
    app.pageState = app.pageStatus.display
    app.saveTS = 0
    collectgarbage()
end


--[[
    Updates the current telemetry state. This function is called frequently to check the telemetry status.
    
    - If the system is not in simulation mode:
        - Sets telemetry state to `noSensor` if the RSSI sensor is not available.
        - Sets telemetry state to `noTelemetry` if the RSSI value is 0.
        - Sets telemetry state to `ok` if the RSSI value is valid.
    - If the system is in simulation mode, sets telemetry state to `ok`.
]]
function app.updateTelemetryState()

    if system:getVersion().simulation ~= true then
        if not dashx.session.telemetrySensor then
            app.triggers.telemetryState = app.telemetryStatus.noSensor
        elseif app.utils.getRSSI() == 0 then
            app.triggers.telemetryState = app.telemetryStatus.noTelemetry
        else
            app.triggers.telemetryState = app.telemetryStatus.ok
        end
    else
        app.triggers.telemetryState = app.telemetryStatus.noTelemetry
    end


end

-- Function: app.paint
-- Description: Calls the paint method of the current page if it exists.
-- Note: This function is triggered by lcd.refresh and is not a wakeup function.
function app.paint()
    if app.Page and app.Page.paint then
        app.Page.paint(app.Page)
    end
end

--[[
app._uiTasks

A table containing a sequence of functions, each representing a logical UI update or task for the dashx Ethos Suite application. These tasks are executed in order to manage UI state, handle dialogs, process telemetry, and respond to user or system triggers.

Each function in the table is responsible for a specific aspect of the application's UI logic, including but not limited to:

1. Exiting the application and cleaning up resources.
2. Managing the progress loader dialog and its closure.
3. Handling the save loader dialog and its closure.
4. Simulating save progress in a simulator environment.
5. Detecting profile or rate changes and triggering UI reloads as needed.
6. Enabling or disabling main menu icons based on connection state and API version.
7. Displaying a "no-link" dialog when telemetry is lost or not established.
8. Updating the "no-link" progress and message based on connection diagnostics.
9. Monitoring save operation timeouts and handling failures.
10. Monitoring progress operation timeouts and handling failures.
11. Triggering save dialogs and handling user confirmation.
12. Triggering reload dialogs and handling user confirmation.
13. Displaying saving progress and managing save state transitions.
14. Warning the user if attempting to save while the system is armed.
15. Updating telemetry state and page readiness.
16. Triggering page retrieval when required.
17. Performing reload actions for the current or full page.
18. Playing pending audio alerts for various events.
19. Invoking page-specific wakeup functions if defined.

Each task function typically checks relevant triggers or state variables before performing its logic, ensuring that UI updates occur only when necessary. This modular approach allows for clear separation of concerns and easier maintenance of the UI update logic.
]]
app._uiTasks = {
  -- 1. Exit App
  function()
    if app.triggers.exitAPP then
      app.triggers.exitAPP = false
      form.invalidate()
      system.exit()
      utils.reportMemoryUsage("Exit App")
    end
  end,


  -- 4. No-Link Initial Trigger
  function()
    if app.triggers.telemetryState == 1 or app.triggers.disableRssiTimeout then return end
    if not app.dialogs.nolinkDisplay and not app.triggers.wasConnected then
      if app.dialogs.progressDisplay then app.ui.progressDisplayClose() end
      if app.dialogs.saveDisplay then app.ui.progressDisplaySaveClose() end
      if app.ui then app.ui.progressNolinkDisplay() end
      app.dialogs.nolinkDisplay = true
    end
  end,

  -- 5. Save Timeout Watchdog
  function()
    if not app.dialogs.saveDisplay or not app.dialogs.saveWatchDog then return end
    local timeout = tonumber(5)
    if (os.clock() - app.dialogs.saveWatchDog) > timeout
       or (app.dialogs.saveProgressCounter > 120 ) then
      app.audio.playTimeout = true
      app.ui.progressDisplaySaveMessage("@i18n(app.error_timed_out)@")
      app.ui.progressDisplaySaveCloseAllowed(true)
      app.dialogs.save:value(100)
      app.dialogs.saveProgressCounter = 0
      app.dialogs.saveDisplay = false
      app.triggers.isSaving = false
      app.Page = app.PageTmp
      app.PageTmp = nil
    end
  end,

  -- 6. Progress Timeout Watchdog
  function()
    if not app.dialogs.progressDisplay or not app.dialogs.progressWatchDog then return end
    app.dialogs.progressCounter = app.dialogs.progressCounter + (app.Page and app.Page.progressCounter or 1.5)
    app.ui.progressDisplayValue(app.dialogs.progressCounter)
    if (os.clock() - app.dialogs.progressWatchDog) > 5 then
      app.audio.playTimeout = true
      app.ui.progressDisplayMessage("@i18n(app.error_timed_out)@")
      app.ui.progressDisplayCloseAllowed(true)
      app.Page = app.PageTmp
      app.PageTmp = nil
      app.dialogs.progressCounter = 0
      app.dialogs.progressDisplay = false
    end
  end,

  -- 7. Trigger Save Dialogs
  function()
    if app.triggers.triggerSave then
      app.triggers.triggerSave = false
      form.openDialog({
        width   = nil,
        title   = "@i18n(app.msg_save_settings)@",
        message = (app.Page.extraMsgOnSave and
                   "@i18n(app.msg_save_current_page)@".."\n\n"..app.Page.extraMsgOnSave or
                   "@i18n(app.msg_save_current_page)@"),
        buttons = {{ label="@i18n(app.btn_ok)@", action=function()
          app.PageTmp = app.Page

          app.triggers.isSaving = true
          saveSettings()
          return true
        end },{ label="@i18n(app.btn_cancel)@",action=function() return true end }},
        wakeup = function() end,
        paint  = function() end,
        options= TEXT_LEFT
      })
    elseif app.triggers.triggerSaveNoProgress then
      app.triggers.triggerSaveNoProgress = false
      app.PageTmp = app.Page
      saveSettings()
    end
  end,

  -- 8. Trigger Reload Dialogs
  function()
    if app.triggers.triggerReloadNoPrompt then
      app.triggers.triggerReloadNoPrompt = false
      app.triggers.reload = true
      return
    end
    if app.triggers.triggerReload then
      app.triggers.triggerReload = false
      form.openDialog({
        title   = "@i18n(reload)@",
        message = "@i18n(app.msg_reload_settings)@",
        buttons = {{ label="@i18n(app.btn_ok)@", action=function() app.triggers.reload = true; return true end },
                   { label="@i18n(app.btn_cancel)@", action=function() return true end }},
        options = TEXT_LEFT
      })
    elseif app.triggers.triggerReloadFull then
      app.triggers.triggerReloadFull = false
      form.openDialog({
        title   = "@i18n(reload)@",
        message = "@i18n(app.msg_reload_settings)@",
        buttons = {{ label="@i18n(app.btn_ok)@", action=function() app.triggers.reloadFull = true; return true end },
                   { label="@i18n(app.btn_cancel)@", action=function() return true end }},
        options = TEXT_LEFT
      })
    end
  end,

  -- 9. Saving Progress Display
  function()
    if app.triggers.isSaving then
      app.dialogs.saveProgressCounter = app.dialogs.saveProgressCounter + 10
      if app.pageState >= app.pageStatus.saving then
        if not app.dialogs.saveDisplay then
          app.triggers.saveFailed          = false
          app.dialogs.saveProgressCounter  = 0
          app.ui.progressDisplaySave()
          dashx.tasks.msp.mspQueue.retryCount = 0
        end

        app.ui.progressDisplaySaveValue(app.dialogs.saveProgressCounter, "@i18n(app.pageStatus.saving)")
      else
        app.triggers.isSaving      = false
        app.dialogs.saveDisplay    = false
        app.dialogs.saveWatchDog   = nil
      end
    elseif app.triggers.isSavingFake then
      app.triggers.isSavingFake = false
      app.triggers.closeSaveFake = true
    end
  end,


  -- 11. Telemetry & Page State Updates
  function()
    app.updateTelemetryState()
    if app.uiState == app.uiStatus.mainMenu then
      invalidatePages()
    elseif app.triggers.isReady and dashx.tasks.msp.mspQueue:isProcessed()
           and app.Page and app.Page.values then
      app.triggers.isReady           = false
      app.triggers.closeProgressLoader = true
    end
  end,

  -- 12. Page Retrieval Trigger
  function()
    if app.uiState == app.uiStatus.pages then
      if not app.Page and app.PageTmp then app.Page = app.PageTmp end
      if app.Page and app.Page.apidata and app.pageState == app.pageStatus.display
         and not app.triggers.isReady then
        requestPage()
      end
    end
  end,

  -- 13. Perform Reload Actions
  function()
    if app.triggers.reload then
      app.triggers.reload = false
      app.ui.progressDisplay()
      app.ui.openPageRefresh(app.lastIdx, app.lastTitle, app.lastScript)
    end
    if app.triggers.reloadFull then
      app.triggers.reloadFull = false
      app.ui.progressDisplay()
      app.ui.openPage(app.lastIdx, app.lastTitle, app.lastScript)
    end
  end,

  -- 14. Play Pending Audio Alerts
  function()
    local a = app.audio
    if a.playEraseFlash         then utils.playFile("app","eraseflash.wav");            a.playEraseFlash = false end
    if a.playTimeout            then utils.playFile("app","timeout.wav");               a.playTimeout = false end
    if a.playEscPowerCycle      then utils.playFile("app","powercycleesc.wav");        a.playEscPowerCycle = false end
    if a.playServoOverideEnable then utils.playFile("app","soverideen.wav");           a.playServoOverideEnable = false end
    if a.playServoOverideDisable then utils.playFile("app","soveridedis.wav");        a.playServoOverideDisable = false end
    if a.playMixerOverideEnable then utils.playFile("app","moverideen.wav");           a.playMixerOverideEnable = false end
    if a.playMixerOverideDisable then utils.playFile("app","moveridedis.wav");        a.playMixerOverideDisable = false end
    if a.playSaveArmed          then utils.playFileCommon("warn.wav");                  a.playSaveArmed = false end
    if a.playBufferWarn         then utils.playFileCommon("warn.wav");                  a.playBufferWarn = false end
  end,

  -- 15. Wakeup UI Tasks
  function()
        if app.Page and app.uiState == app.uiStatus.pages and app.Page.wakeup then
            -- run the pages wakeup function if it exists
            app.Page.wakeup(app.Page)
        end
  end,
}

--- Handles periodic execution of UI tasks in a round-robin fashion.
-- This function is intended to be called regularly (e.g., on each system wakeup or tick).
-- It distributes the execution of tasks in `app._uiTasks` based on the configured percentage (`app._uiTaskPercent`),
-- ensuring that at least one task is executed per tick. The function uses an accumulator to handle fractional
-- task execution rates and maintains the index of the next task to execute in `app._nextUiTask`.
-- Tasks are executed in order, wrapping around to the beginning of the list as needed.
app._nextUiTask         = 1   -- accumulator for fractional tasks per tick
app._taskAccumulator    = 0   -- desired throughput percentage of total tasks per tick (0-100)
app._uiTaskPercent      = 100  -- e.g., 100% of tasks each tick
function app.wakeup()


  local total = #app._uiTasks
  local tasksThisTick = math.max(1, (total * app._uiTaskPercent) / 100)

  app._taskAccumulator = app._taskAccumulator + tasksThisTick

  while app._taskAccumulator >= 1 do
    local idx = app._nextUiTask
    app._uiTasks[idx]()
    app._nextUiTask = (idx % total) + 1
    app._taskAccumulator = app._taskAccumulator - 1
  end

end


--[[
    Creates the log tool for the application.
    This function initializes various configurations and settings for the log tool,
    including disabling buffer warnings, setting the environment version, 
    determining the LCD dimensions, loading the radio configuration, 
    and setting the initial UI state. It also checks for developer mode, 
    updates the menu selection, displays the progress, and opens the logs page in offline mode.
]]
function app.create_logtool()
    triggers.showUnderUsedBufferWarning = false
    triggers.showOverUsedBufferWarning = false

    -- dashx.session.apiVersion = nil
    config.environment = system.getVersion()
    config.ethosRunningVersion = {config.environment.major, config.environment.minor, config.environment.revision}

    dashx.session.lcdWidth, dashx.session.lcdHeight = utils.getWindowSize()
    app.radio = assert(compile("app/radios.lua"))()

    app.uiState = app.uiStatus.init

    dashx.preferences.menulastselected["mainmenu"] = pidx
    dashx.app.ui.progressDisplay()

    dashx.app.offlineMode = true
    dashx.app.ui.openPage(1, "Logs", "logs/logs.lua", 1) -- final param says to load in standalone mode
end

--[[
    Function: app.create

    Initializes the application by setting up the environment configuration, 
    determining the LCD dimensions, loading the radio configuration, 
    setting the initial UI state, and checking for developer mode.

    Steps:
    1. Sets the environment configuration using the system version.
    2. Retrieves and sets the LCD width and height.
    3. Loads the radio configuration from "app/radios.lua".
    4. Sets the initial UI state to 'init'.
    5. Checks for the existence of a developer mode file and enables developer mode if found.
    6. Opens the main menu UI.
]]
function app.create()

    if not app.initialized then

      -- dashx.session.apiVersion = nil
      config.environment = system.getVersion()
      config.ethosRunningVersion = {config.environment.major, config.environment.minor, config.environment.revision}

      dashx.session.lcdWidth, dashx.session.lcdHeight = utils.getWindowSize()

      app.triggers = {}
      app.triggers.exitAPP = false
      app.triggers.noRFMsg = false
      app.triggers.triggerSave = false
      app.triggers.triggerSaveNoProgress = false
      app.triggers.triggerReload = false
      app.triggers.triggerReloadFull = false
      app.triggers.triggerReloadNoPrompt = false
      app.triggers.reloadFull = false
      app.triggers.isReady = false
      app.triggers.isSaving = false
      app.triggers.isSavingFake = false
      app.triggers.saveFailed = false
      app.triggers.telemetryState = nil
      app.triggers.profileswitchLast = nil
      app.triggers.rateswitchLast = nil
      app.triggers.closeSave = false
      app.triggers.closeSaveFake = false
      app.triggers.badMspVersion = false
      app.triggers.badMspVersionDisplay = false
      app.triggers.closeProgressLoader = false
      app.triggers.mspBusy = false
      app.triggers.disableRssiTimeout = false
      app.triggers.timeIsSet = false
      app.triggers.invalidConnectionSetup = false
      app.triggers.wasConnected = false
      app.triggers.isArmed = false
      app.triggers.showSaveArmedWarning = false

      app.sensors = {}
      app.formFields = {}
      app.formNavigationFields = {}
      app.PageTmp = {}
      app.Page = {}
      app.saveTS = 0
      app.lastPage = nil
      app.lastSection = nil
      app.lastIdx = nil
      app.lastTitle = nil
      app.lastScript = nil
      app.gfx_buttons = {}
      app.uiStatus = {init = 1, mainMenu = 2, pages = 3, confirm = 4}
      app.pageStatus = {display = 1, editing = 2, saving = 3, eepromWrite = 4, rebooting = 5}
      app.telemetryStatus = {ok = 1, noSensor = 2, noTelemetry = 3}
      app.uiState = app.uiStatus.init
      app.pageState = app.pageStatus.display
      app.lastLabel = nil
      app.NewRateTable = nil
      app.RateTable = nil
      app.fieldHelpTxt = nil
      app.radio = {}
      app.sensor = {}
      app.init = nil
      app.guiIsRunning = false
      app.adjfunctions = nil
      app.profileCheckScheduler = os.clock()
      app.offlineMode = false


      app.audio = {}
      app.audio.playTimeout = false
      app.audio.playEscPowerCycle = false
      app.audio.playServoOverideDisable = false
      app.audio.playServoOverideEnable = false
      app.audio.playMixerOverideDisable = false
      app.audio.playMixerOverideEnable = false
      app.audio.playEraseFlash = false

      app.dialogs = {}
      app.dialogs.progress = false
      app.dialogs.progressDisplay = false
      app.dialogs.progressWatchDog = nil
      app.dialogs.progressCounter = 0
      app.dialogs.progressRateLimit = os.clock()
      app.dialogs.progressRate = 0.25 


      app.dialogs.progressESC = false
      app.dialogs.progressDisplayEsc = false
      app.dialogs.progressWatchDogESC = nil
      app.dialogs.progressCounterESC = 0
      app.dialogs.progressESCRateLimit = os.clock()
      app.dialogs.progressESCRate = 2.5 

      app.dialogs.save = false
      app.dialogs.saveDisplay = false
      app.dialogs.saveWatchDog = nil
      app.dialogs.saveProgressCounter = 0
      app.dialogs.saveRateLimit = os.clock()
      app.dialogs.saveRate = 0.25

      app.dialogs.nolink = false
      app.dialogs.nolinkDisplay = false
      app.dialogs.nolinkValueCounter = 0
      app.dialogs.nolinkRateLimit = os.clock()
      app.dialogs.nolinkRate = 0.25


      app.dialogs.badversion = false
      app.dialogs.badversionDisplay = false

      app.radio = assert(compile("app/radios.lua"))()

      app.MainMenu  = assert(compile("app/modules/init.lua"))()

      app.ui = assert(compile("app/lib/ui.lua"))(config)

      app.utils = assert(compile("app/lib/utils.lua"))(config)
  
      app.initialized = true
    end  

    app.ui.openMainMenu()

end

--[[
Handles various events for the app, including key presses and page events.

Parameters:
- widget: The widget triggering the event.
- category: The category of the event.
- value: The value associated with the event.
- x: The x-coordinate of the event.
- y: The y-coordinate of the event.

Returns:
- 0 if a rapid exit is triggered.
- The return value of the page event handler if it handles the event.
- true if the event is handled by the generic event handler.
- false if the event is not handled.
]]
function app.event(widget, category, value, x, y)

    -- long press on return at any point will force an rapid exit
    if value == KEY_RTN_LONG then
        log("KEY_RTN_LONG", "info")
        invalidatePages()
        system.exit()
        return 0
    end

    -- the page has its own event system.  we should use it.
    if app.Page and (app.uiState == app.uiStatus.pages or app.uiState == app.uiStatus.mainMenu) then
        if app.Page.event then
            log("USING PAGES EVENTS", "debug")
            local ret = app.Page.event(widget, category, value, x, y)
            if ret ~= nil then
                return ret
            end    
        end
    end

    -- generic events handler for most pages
    if app.uiState == app.uiStatus.pages then

        -- close button (top menu) should go back to main menu
        if category == EVT_CLOSE and value == 0 or value == 35 then
            log("EVT_CLOSE", "info")
            if app.dialogs.progressDisplay then app.ui.progressDisplayClose() end
            if app.dialogs.saveDisplay then app.ui.progressDisplaySaveClose() end
            if app.Page.onNavMenu then app.Page.onNavMenu(app.Page) end
            app.ui.openMainMenu()
            return true
        end

        -- long press on enter should result in a save dialog box
        if value == KEY_ENTER_LONG then
            if dashx.app.Page.navButtons and dashx.app.Page.navButtons.save == false then
                return true
            end
            log("EVT_ENTER_LONG (PAGES)", "info")
            if app.dialogs.progressDisplay then app.ui.progressDisplayClose() end
            if app.dialogs.saveDisplay then app.ui.progressDisplaySaveClose() end
            if dashx.app.Page and dashx.app.Page.onSaveMenu then
                dashx.app.Page.onSaveMenu(dashx.app.Page)
            else
                dashx.app.triggers.triggerSave = true
            end
            system.killEvents(KEY_ENTER_BREAK)
            return true
        end
    end

    -- catch all to stop lock press on main menu doing anything
    if app.uiState == app.uiStatus.mainMenu and value == KEY_ENTER_LONG then
         log("EVT_ENTER_LONG (MAIN MENU)", "info")
         if app.dialogs.progressDisplay then app.ui.progressDisplayClose() end
         if app.dialogs.saveDisplay then app.ui.progressDisplaySaveClose() end
         system.killEvents(KEY_ENTER_BREAK)
         return true
    end

    return false
end

--[[
Closes the application and performs necessary cleanup operations.

This function sets the application state to indicate that the GUI is no longer running
and that the application is not in offline mode. It then checks if there is an active
page and if the current UI state is either in pages or main menu, and if so, it calls
the close method of the active page.

Additionally, it closes any open progress, save, or no-link dialogs. It then invalidates
the pages, resets the application state, and exits the system.

Returns:
    true: Always returns true to indicate successful closure.
]]
function app.close()

    dashx.utils.reportMemoryUsage("closing application: start")

    -- save user preferences
    local userpref_file = "SCRIPTS:/" .. dashx.config.preferences .. "/preferences.ini"
    dashx.ini.save_ini_file(userpref_file, dashx.preferences)

    app.guiIsRunning = false
    app.offlineMode = false
    app.uiState = app.uiStatus.init

    if app.Page and (app.uiState == app.uiStatus.pages or app.uiState == app.uiStatus.mainMenu) and app.Page.close then
        app.Page.close()
    end

    if app.ui then
    if app.dialogs.progress then app.ui.progressDisplayClose() end
    if app.dialogs.save then app.ui.progressDisplaySaveClose() end
    if app.dialogs.noLink then app.ui.progressNolinkDisplayClose() end
    end


    -- Reset configuration and compiler flags
    config.useCompiler = true
    dashx.config.useCompiler = true

    -- Reset page and navigation state
    app.Page = {}
    app.formFields = {}
    app.formNavigationFields = {}
    app.gfx_buttons = {}
    app.formLines = nil
    app.formNavigationFields = {}
    app.PageTmp = nil
    app.moduleList = nil


    -- Reset triggers
    app.triggers.exitAPP = false
    app.triggers.noRFMsg = false
    app.triggers.telemetryState = nil
    app.triggers.wasConnected = false
    app.triggers.invalidConnectionSetup = false
    app.triggers.disableRssiTimeout = false

    -- Reset dialogs
    app.dialogs.nolinkDisplay = false
    app.dialogs.nolinkValueCounter = 0
    app.dialogs.progressDisplayEsc = false

    -- Reset audio
    app.audio = {}


    -- Reset profile/rate state
    dashx.app.triggers.profileswitchLast = nil
    dashx.session.activeProfileLast = nil
    dashx.session.activeProfile = nil
    dashx.session.activeRateProfile = nil
    dashx.session.activeRateProfileLast = nil
    dashx.session.activeRateTable = nil

    -- Cleanup
    collectgarbage()
    invalidatePages()

    dashx.utils.reportMemoryUsage("closing application: end")    

    system.exit()
    return true
end

return app
