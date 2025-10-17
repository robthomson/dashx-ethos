--[[
  Copyright (C) 2025 Rob Thomson
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local dashx = require("dashx")

local themesBasePath = "SCRIPTS:/" .. dashx.config.baseDir .. "/widgets/dashboard/themes/"
local themesUserPath = "SCRIPTS:/" .. dashx.config.preferences .. "/dashboard/"
local enableWakeup = false

local function openPage(pidx, title, script)

    local themeList = dashx.widgets.dashboard.listThemes()

    dashx.session.dashboardEditingTheme = nil
    enableWakeup = true
    dashx.app.triggers.closeProgressLoader = true
    form.clear()

    dashx.app.lastIdx = pageIdx
    dashx.app.lastTitle = title
    dashx.app.lastScript = script

    dashx.app.ui.fieldHeader("@i18n(app.modules.settings.name)@" .. " / " .. "@i18n(app.modules.settings.dashboard)@" .. " / " .. "@i18n(app.modules.settings.dashboard_settings)@")

    local buttonW, buttonH, padding, numPerRow
    if dashx.preferences.general.iconsize == 0 then
        padding = dashx.app.radio.buttonPaddingSmall
        buttonW = (dashx.session.lcdWidth - padding) / dashx.app.radio.buttonsPerRow - padding
        buttonH = dashx.app.radio.navbuttonHeight
        numPerRow = dashx.app.radio.buttonsPerRow
    elseif dashx.preferences.general.iconsize == 1 then
        padding = dashx.app.radio.buttonPaddingSmall
        buttonW = dashx.app.radio.buttonWidthSmall
        buttonH = dashx.app.radio.buttonHeightSmall
        numPerRow = dashx.app.radio.buttonsPerRowSmall
    else
        padding = dashx.app.radio.buttonPadding
        buttonW = dashx.app.radio.buttonWidth
        buttonH = dashx.app.radio.buttonHeight
        numPerRow = dashx.app.radio.buttonsPerRow
    end

    if dashx.app.gfx_buttons["settings_dashboard_themes"] == nil then dashx.app.gfx_buttons["settings_dashboard_themes"] = {} end
    if dashx.preferences.menulastselected["settings_dashboard_themes"] == nil then dashx.preferences.menulastselected["settings_dashboard_themes"] = 1 end

    local lc, bx, y = 0, 0, 0

    for idx, theme in ipairs(themeList) do

        if theme.configure then

            if lc == 0 then
                if dashx.preferences.general.iconsize == 0 then y = form.height() + dashx.app.radio.buttonPaddingSmall end
                if dashx.preferences.general.iconsize == 1 then y = form.height() + dashx.app.radio.buttonPaddingSmall end
                if dashx.preferences.general.iconsize == 2 then y = form.height() + dashx.app.radio.buttonPadding end
            end
            if lc >= 0 then bx = (buttonW + padding) * lc end

            if dashx.app.gfx_buttons["settings_dashboard_themes"][idx] == nil then

                local icon
                if theme.source == "system" then
                    icon = themesBasePath .. theme.folder .. "/icon.png"
                else
                    icon = themesUserPath .. theme.folder .. "/icon.png"
                end
                dashx.app.gfx_buttons["settings_dashboard_themes"][idx] = lcd.loadMask(icon)
            end

            dashx.app.formFields[idx] = form.addButton(nil, {x = bx, y = y, w = buttonW, h = buttonH}, {
                text = theme.name,
                icon = dashx.app.gfx_buttons["settings_dashboard_themes"][idx],
                options = FONT_S,
                paint = function() end,
                press = function()

                    dashx.preferences.menulastselected["settings_dashboard_themes"] = idx
                    dashx.app.ui.progressDisplay()
                    local configure = theme.configure
                    local source = theme.source
                    local folder = theme.folder

                    local themeScript
                    if theme.source == "system" then
                        themeScript = themesBasePath .. folder .. "/" .. configure
                    else
                        themeScript = themesUserPath .. folder .. "/" .. configure
                    end

                    dashx.app.ui.openPageDashboard(idx, theme.name, themeScript, source, folder)
                end
            })

            if not theme.configure then dashx.app.formFields[idx]:enable(false) end

            if dashx.preferences.menulastselected["settings_dashboard_themes"] == idx then dashx.app.formFields[idx]:focus() end

            lc = lc + 1
            if lc == numPerRow then lc = 0 end
        end
    end

    if lc == 0 then
        local w, h = dashx.utils.getWindowSize()
        local msg = "@i18n(app.modules.settings.no_themes_available_to_configure)@"
        local tw, th = lcd.getTextSize(msg)
        local x = w / 2 - tw / 2
        local y = h / 2 - th / 2
        local btnH = dashx.app.radio.navbuttonHeight
        form.addStaticText(nil, {x = x, y = y, w = tw, h = btnH}, msg)
    end

    dashx.app.triggers.closeProgressLoader = true
    collectgarbage()
    return
end

dashx.app.uiState = dashx.app.uiStatus.pages

local function event(widget, category, value, x, y)

    if category == EVT_CLOSE and value == 0 or value == 35 then
        dashx.app.ui.openPage(pageIdx, "@i18n(app.modules.settings.dashboard)@", "settings/tools/dashboard.lua")
        return true
    end
end

local function onNavMenu()
    dashx.app.ui.progressDisplay()
    dashx.app.ui.openPage(pageIdx, "@i18n(app.modules.settings.dashboard)@", "settings/tools/dashboard.lua")
    return true
end

return {pages = pages, openPage = openPage, API = {}, navButtons = {menu = true, save = false, reload = false, tool = false, help = false}, event = event, onNavMenu = onNavMenu}
