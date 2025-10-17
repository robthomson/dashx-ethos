--[[
  Copyright (C) 2025 Rob Thomson
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local dashx = require("dashx")
local settings = {}
local enableWakeup = false

local function openPage(pageIdx, title, script)
    enableWakeup = true
    dashx.app.triggers.closeProgressLoader = true
    form.clear()

    dashx.app.lastIdx = pageIdx
    dashx.app.lastTitle = title
    dashx.app.lastScript = script

    dashx.app.ui.fieldHeader("@i18n(app.modules.settings.name)@" .. " / " .. "@i18n(app.modules.settings.txt_development)@")
    dashx.session.formLineCnt = 0

    local formFieldCount = 0

    settings = dashx.preferences.developer

    formFieldCount = formFieldCount + 1
    dashx.session.formLineCnt = dashx.session.formLineCnt + 1
    dashx.app.formLines[dashx.session.formLineCnt] = form.addLine("@i18n(app.modules.settings.txt_devtools)@")
    dashx.app.formFields[formFieldCount] = form.addBooleanField(dashx.app.formLines[dashx.session.formLineCnt], nil, function() if dashx.preferences and dashx.preferences.developer then return settings['devtools'] end end,
                                               function(newValue) if dashx.preferences and dashx.preferences.developer then settings.devtools = newValue end end)

    local logpanel = form.addExpansionPanel("@i18n(app.modules.settings.txt_logging)@")
    logpanel:open(false)

    formFieldCount = formFieldCount + 1
    dashx.session.formLineCnt = dashx.session.formLineCnt + 1
    dashx.app.formLines[dashx.session.formLineCnt] = logpanel:addLine("@i18n(app.modules.settings.txt_loglocation)@")
    dashx.app.formFields[formFieldCount] = form.addChoiceField(dashx.app.formLines[dashx.session.formLineCnt], nil, {{"@i18n(app.modules.settings.txt_console)@", 0}, {"@i18n(app.modules.settings.txt_consolefile)@", 1}}, function()
        if dashx.preferences and dashx.preferences.developer then
            if dashx.preferences.developer.logtofile == false then
                return 0
            else
                return 1
            end
        end
    end, function(newValue)
        if dashx.preferences and dashx.preferences.developer then
            local value
            if newValue == 0 then
                value = false
            else
                value = true
            end
            settings.logtofile = value
        end
    end)

    formFieldCount = formFieldCount + 1
    dashx.session.formLineCnt = dashx.session.formLineCnt + 1
    dashx.app.formLines[dashx.session.formLineCnt] = logpanel:addLine("@i18n(app.modules.settings.txt_loglevel)@")
    dashx.app.formFields[formFieldCount] = form.addChoiceField(dashx.app.formLines[dashx.session.formLineCnt], nil, {{"@i18n(app.modules.settings.txt_off)@", 0}, {"@i18n(app.modules.settings.txt_info)@", 1}, {"@i18n(app.modules.settings.txt_debug)@", 2}}, function()
        if dashx.preferences and dashx.preferences.developer then
            if settings['loglevel'] == "off" then
                return 0
            elseif settings['loglevel'] == "info" then
                return 1
            else
                return 2
            end
        end
    end, function(newValue)
        if dashx.preferences and dashx.preferences.developer then
            local value
            if newValue == 0 then
                value = "off"
            elseif newValue == 1 then
                value = "info"
            else
                value = "debug"
            end
            settings['loglevel'] = value
        end
    end)

    formFieldCount = formFieldCount + 1
    dashx.session.formLineCnt = dashx.session.formLineCnt + 1
    dashx.app.formLines[dashx.session.formLineCnt] = logpanel:addLine("@i18n(app.modules.settings.txt_memusage)@")
    dashx.app.formFields[formFieldCount] = form.addBooleanField(dashx.app.formLines[dashx.session.formLineCnt], nil, function() if dashx.preferences and dashx.preferences.developer then return settings['memstats'] end end,
                                               function(newValue) if dashx.preferences and dashx.preferences.developer then settings.memstats = newValue end end)

end

local function onNavMenu()
    dashx.app.ui.progressDisplay()
    dashx.app.ui.openPage(pageIdx, "@i18n(app.modules.settings.name)@", "settings/settings.lua")
end

local function onSaveMenu()
    local buttons = {
        {
            label = "@i18n(app.btn_ok_long)@",
            action = function()
                local msg = "@i18n(app.modules.profile_select.save_prompt_local)@"
                dashx.app.ui.progressDisplaySave(msg:gsub("%?$", "."))
                for key, value in pairs(settings) do dashx.preferences.developer[key] = value end
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
        dashx.app.ui.openPage(pageIdx, "@i18n(app.modules.settings.name)@", "settings/settings.lua")
        return true
    end
end

return {event = event, openPage = openPage, wakeup = wakeup, onNavMenu = onNavMenu, onSaveMenu = onSaveMenu, navButtons = {menu = true, save = true, reload = false, tool = false, help = false}, API = {}}
