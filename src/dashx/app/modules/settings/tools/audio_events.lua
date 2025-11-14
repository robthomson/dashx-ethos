--[[
  Copyright (C) 2025 Rob Thomson
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local dashx = require("dashx")
local settings = {}
local enableWakeup = false

local function sensorNameMap(sensorList)
    local nameMap = {}
    for _, sensor in ipairs(sensorList) do nameMap[sensor.key] = sensor.name end
    return nameMap
end

local function openPage(pageIdx, title, script)
    enableWakeup = true
    dashx.app.triggers.closeProgressLoader = true
    form.clear()

    dashx.app.lastIdx = pageIdx
    dashx.app.lastTitle = title
    dashx.app.lastScript = script

    dashx.app.ui.fieldHeader("@i18n(app.modules.settings.name)@" .. " / " .. "@i18n(app.modules.settings.audio)@" .. " / " .. "@i18n(app.modules.settings.txt_audio_events)@")
    dashx.session.formLineCnt = 0

    local formFieldCount = 0

    local eventList = dashx.tasks.events.telemetry.eventTable
    local eventNames = sensorNameMap(dashx.tasks.telemetry.listSensors())

    settings = dashx.preferences.events

    for i, v in ipairs(eventList) do
        formFieldCount = formFieldCount + 1
        dashx.session.formLineCnt = dashx.session.formLineCnt + 1
        dashx.app.formLines[dashx.session.formLineCnt] = form.addLine(eventNames[v.sensor] or "unknown")
        dashx.app.formFields[formFieldCount] = form.addBooleanField(dashx.app.formLines[dashx.session.formLineCnt], nil, function() if dashx.preferences and dashx.preferences.events then return settings[v.sensor] end end,
                                                   function(newValue) if dashx.preferences and dashx.preferences.events then settings[v.sensor] = newValue end end)
    end

end

local function onNavMenu()
    dashx.app.ui.progressDisplay()
    dashx.app.ui.openPage(pageIdx, "@i18n(app.modules.settings.name)@", "settings/tools/audio.lua")
end

local function onSaveMenu()
    local buttons = {
        {
            label = "@i18n(app.btn_ok_long)@",
            action = function()
                local msg = "@i18n(app.modules.profile_select.save_prompt_local)@"
                dashx.app.ui.progressDisplaySave(msg:gsub("%?$", "."))
                for key, value in pairs(settings) do dashx.preferences.events[key] = value end
                dashx.ini.save_ini_file("SCRIPTS:/" .. dashx.config.preferences .. "/preferences.ini", dashx.preferences)
                dashx.app.triggers.closeSave = true
                return true
            end
        }, {label = "@i18n(app.modules.profile_select.cancel)@", action = function() return true end}
    }

    form.openDialog({width = nil, title = "@i18n(app.modules.profile_select.save_settings)@", message = "@i18n(app.modules.profile_select.save_prompt_local)@", buttons = buttons, wakeup = function() end, paint = function() end, options = TEXT_LEFT})
end

local function event(widget, category, value, x, y)

    if category == EVT_CLOSE and value == 0 or value == 35 then
        dashx.app.ui.openPage(pageIdx, "@i18n(app.modules.settings.name)@", "settings/tools/audio.lua")
        return true
    end
end

return {event = event, openPage = openPage, wakeup = wakeup, onNavMenu = onNavMenu, onSaveMenu = onSaveMenu, navButtons = {menu = true, save = true, reload = false, tool = false, help = false}, API = {}}
