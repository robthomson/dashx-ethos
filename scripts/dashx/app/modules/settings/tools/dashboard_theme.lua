--[[
  Copyright (C) 2025 Rob Thomson
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local dashx = require("dashx")
local settings = {}
local settings_model = {}

local themeList = dashx.widgets.dashboard.listThemes()
local formattedThemes = {}
local formattedThemesModel = {}

local enableWakeup = false
local prevConnectedState = nil

local function generateThemeList()

    settings = dashx.preferences.dashboard

    if dashx.session.modelPreferences then
        settings_model = dashx.session.modelPreferences.dashboard
    else
        settings_model = {}
    end

    for i, theme in ipairs(themeList) do table.insert(formattedThemes, {theme.name, theme.idx}) end

    table.insert(formattedThemesModel, {"@i18n(app.modules.settings.dashboard_theme_panel_model_disabled)@", 0})
    for i, theme in ipairs(themeList) do table.insert(formattedThemesModel, {theme.name, theme.idx}) end
end

local function openPage(pageIdx, title, script)
    enableWakeup = true
    dashx.app.triggers.closeProgressLoader = true
    form.clear()

    dashx.app.lastIdx = pageIdx
    dashx.app.lastTitle = title
    dashx.app.lastScript = script

    dashx.app.ui.fieldHeader("@i18n(app.modules.settings.name)@" .. " / " .. "@i18n(app.modules.settings.dashboard)@" .. " / " .. "@i18n(app.modules.settings.dashboard_theme)@")
    dashx.app.formLineCnt = 0

    local formFieldCount = 0

    generateThemeList()

    local global_panel = form.addExpansionPanel("@i18n(app.modules.settings.dashboard_theme_panel_global)@")
    global_panel:open(true)

    formFieldCount = formFieldCount + 1
    dashx.app.formLineCnt = dashx.app.formLineCnt + 1
    dashx.app.formLines[dashx.app.formLineCnt] = global_panel:addLine("@i18n(app.modules.settings.dashboard_theme_preflight)@")

    dashx.app.formFields[formFieldCount] = form.addChoiceField(dashx.app.formLines[dashx.app.formLineCnt], nil, formattedThemes, function()
        if dashx.preferences and dashx.preferences.dashboard then
            local folderName = settings.theme_preflight
            for _, theme in ipairs(themeList) do if (theme.source .. "/" .. theme.folder) == folderName then return theme.idx end end
        end
        return nil
    end, function(newValue)
        if dashx.preferences and dashx.preferences.dashboard then
            local theme = themeList[newValue]
            if theme then settings.theme_preflight = theme.source .. "/" .. theme.folder end
        end
    end)

    formFieldCount = formFieldCount + 1
    dashx.app.formLineCnt = dashx.app.formLineCnt + 1
    dashx.app.formLines[dashx.app.formLineCnt] = global_panel:addLine("@i18n(app.modules.settings.dashboard_theme_inflight)@")

    dashx.app.formFields[formFieldCount] = form.addChoiceField(dashx.app.formLines[dashx.app.formLineCnt], nil, formattedThemes, function()
        if dashx.preferences and dashx.preferences.dashboard then
            local folderName = settings.theme_inflight
            for _, theme in ipairs(themeList) do if (theme.source .. "/" .. theme.folder) == folderName then return theme.idx end end
        end
        return nil
    end, function(newValue)
        if dashx.preferences and dashx.preferences.dashboard then
            local theme = themeList[newValue]
            if theme then settings.theme_inflight = theme.source .. "/" .. theme.folder end
        end
    end)

    formFieldCount = formFieldCount + 1
    dashx.app.formLineCnt = dashx.app.formLineCnt + 1
    dashx.app.formLines[dashx.app.formLineCnt] = global_panel:addLine("@i18n(app.modules.settings.dashboard_theme_postflight)@")

    dashx.app.formFields[formFieldCount] = form.addChoiceField(dashx.app.formLines[dashx.app.formLineCnt], nil, formattedThemes, function()
        if dashx.preferences and dashx.preferences.dashboard then
            local folderName = settings.theme_postflight
            for _, theme in ipairs(themeList) do if (theme.source .. "/" .. theme.folder) == folderName then return theme.idx end end
        end
        return nil
    end, function(newValue)
        if dashx.preferences and dashx.preferences.dashboard then
            local theme = themeList[newValue]
            if theme then settings.theme_postflight = theme.source .. "/" .. theme.folder end
        end
    end)

    local model_panel = form.addExpansionPanel("@i18n(app.modules.settings.dashboard_theme_panel_model)@")
    model_panel:open(false)

    formFieldCount = formFieldCount + 1
    dashx.app.formLineCnt = dashx.app.formLineCnt + 1
    dashx.app.formLines[dashx.app.formLineCnt] = model_panel:addLine("@i18n(app.modules.settings.dashboard_theme_preflight)@")

    dashx.app.formFields[formFieldCount] = form.addChoiceField(dashx.app.formLines[dashx.app.formLineCnt], nil, formattedThemesModel, function()
        if dashx.session.modelPreferences and dashx.session.modelPreferences then
            local folderName = settings_model.theme_preflight
            for _, theme in ipairs(themeList) do if (theme.source .. "/" .. theme.folder) == folderName then return theme.idx end end
        end
        return nil
    end, function(newValue)
        if dashx.session.modelPreferences and dashx.session.modelPreferences then
            local theme = themeList[newValue]
            if theme then
                settings_model.theme_preflight = theme.source .. "/" .. theme.folder
            else
                settings_model.theme_preflight = "nil"
            end
        end
    end)
    dashx.app.formFields[formFieldCount]:enable(false)

    formFieldCount = formFieldCount + 1
    dashx.app.formLineCnt = dashx.app.formLineCnt + 1
    dashx.app.formLines[dashx.app.formLineCnt] = model_panel:addLine("@i18n(app.modules.settings.dashboard_theme_inflight)@")

    dashx.app.formFields[formFieldCount] = form.addChoiceField(dashx.app.formLines[dashx.app.formLineCnt], nil, formattedThemesModel, function()
        if dashx.session.modelPreferences and dashx.session.modelPreferences then
            local folderName = settings_model.theme_inflight
            for _, theme in ipairs(themeList) do if (theme.source .. "/" .. theme.folder) == folderName then return theme.idx end end
        end
        return nil
    end, function(newValue)
        if dashx.session.modelPreferences and dashx.session.modelPreferences then
            local theme = themeList[newValue]
            if theme then
                settings_model.theme_inflight = theme.source .. "/" .. theme.folder
            else
                settings_model.theme_inflight = "nil"
            end
        end
    end)
    dashx.app.formFields[formFieldCount]:enable(false)

    formFieldCount = formFieldCount + 1
    dashx.app.formLineCnt = dashx.app.formLineCnt + 1
    dashx.app.formLines[dashx.app.formLineCnt] = model_panel:addLine("@i18n(app.modules.settings.dashboard_theme_postflight)@")

    dashx.app.formFields[formFieldCount] = form.addChoiceField(dashx.app.formLines[dashx.app.formLineCnt], nil, formattedThemesModel, function()
        if dashx.session.modelPreferences and dashx.session.modelPreferences then
            local folderName = settings_model.theme_postflight
            for _, theme in ipairs(themeList) do if (theme.source .. "/" .. theme.folder) == folderName then return theme.idx end end
        end
        return nil
    end, function(newValue)
        if dashx.preferences and dashx.preferences.dashboard then
            local theme = themeList[newValue]
            if theme then
                settings_model.theme_postflight = theme.source .. "/" .. theme.folder
            else
                settings_model.theme_postflight = "nil"
            end
        end
    end)
    dashx.app.formFields[formFieldCount]:enable(false)

end

local function onNavMenu()
    dashx.app.ui.progressDisplay(nil, nil, true)
    dashx.app.ui.openPage(pageIdx, "@i18n(app.modules.settings.dashboard)@", "settings/tools/dashboard.lua")
    return true
end

local function onSaveMenu()
    local buttons = {
        {
            label = "@i18n(app.btn_ok_long)@",
            action = function()
                local msg = "@i18n(app.modules.profile_select.save_prompt_local)@"
                dashx.app.ui.progressDisplaySave(msg:gsub("%?$", "."))

                for key, value in pairs(settings) do dashx.preferences.dashboard[key] = value end
                dashx.ini.save_ini_file("SCRIPTS:/" .. dashx.config.preferences .. "/preferences.ini", dashx.preferences)

                if dashx.session.isConnected and dashx.session.mcu_id and dashx.session.modelPreferencesFile then
                    for key, value in pairs(settings_model) do dashx.session.modelPreferences.dashboard[key] = value end
                    dashx.ini.save_ini_file(dashx.session.modelPreferencesFile, dashx.session.modelPreferences)
                end

                dashx.widgets.dashboard.reload_themes(true)

                dashx.app.triggers.closeSave = true
                return true
            end
        }, {label = "@i18n(app.modules.profile_select.cancel)@", action = function() return true end}
    }

    form.openDialog({width = nil, title = "@i18n(app.modules.profile_select.save_settings)@", message = "@i18n(app.modules.profile_select.save_prompt_local)@", buttons = buttons, wakeup = function() end, paint = function() end, options = TEXT_LEFT})
end

local function event(widget, category, value, x, y)

    if category == EVT_CLOSE and value == 0 or value == 35 then
        dashx.app.ui.openPage(pageIdx, "@i18n(app.modules.settings.dashboard)@", "settings/tools/dashboard.lua")
        return true
    end
end

local function wakeup()
    if not enableWakeup then return end

    local currState = (dashx.session.isConnected and dashx.session.mcu_id) and true or false

    if currState ~= prevConnectedState then

        if currState then
            generateThemeList()
            for i = 4, 6 do dashx.app.formFields[i]:values(formattedThemesModel) end
        end

        for i = 4, 6 do dashx.app.formFields[i]:enable(currState) end

        prevConnectedState = currState
    end
end

return {event = event, openPage = openPage, wakeup = wakeup, onNavMenu = onNavMenu, onSaveMenu = onSaveMenu, navButtons = {menu = true, save = true, reload = false, tool = false, help = false}, API = {}}
