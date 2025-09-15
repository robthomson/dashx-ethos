local i18n = neuronsuite.i18n.get

local themesBasePath = "SCRIPTS:/" .. neuronsuite.config.baseDir .. "/widgets/dashboard/themes/"
local themesUserPath = "SCRIPTS:/" .. neuronsuite.config.preferences .. "/dashboard/"

local enableWakeup = false
local prevConnectedState = nil

local function openPage(pidx, title, script)
    -- Get the installed themes
    local themeList = neuronsuite.widgets.dashboard.listThemes()

    neuronsuite.app.dashboardEditingTheme = nil
    enableWakeup = true
    neuronsuite.app.triggers.closeProgressLoader = true
    form.clear()

    -- Clear old icons
    for i in pairs(neuronsuite.app.gfx_buttons) do
        if i ~= "settings_dashboard_themes" then
            neuronsuite.app.gfx_buttons[i] = nil
        end
    end   


    neuronsuite.app.lastIdx    = pageIdx
    neuronsuite.app.lastTitle  = title
    neuronsuite.app.lastScript = script

    neuronsuite.app.ui.fieldHeader(
        i18n("app.modules.settings.name") .. " / " .. i18n("app.modules.settings.dashboard") .. " / " .. i18n("app.modules.settings.dashboard_settings")
    )

    -- Icon/button layout settings
    local buttonW, buttonH, padding, numPerRow
    if neuronsuite.preferences.general.iconsize == 0 then
        padding = neuronsuite.app.radio.buttonPaddingSmall
        buttonW = (neuronsuite.app.lcdWidth - padding) / neuronsuite.app.radio.buttonsPerRow - padding
        buttonH = neuronsuite.app.radio.navbuttonHeight
        numPerRow = neuronsuite.app.radio.buttonsPerRow
    elseif neuronsuite.preferences.general.iconsize == 1 then
        padding = neuronsuite.app.radio.buttonPaddingSmall
        buttonW = neuronsuite.app.radio.buttonWidthSmall
        buttonH = neuronsuite.app.radio.buttonHeightSmall
        numPerRow = neuronsuite.app.radio.buttonsPerRowSmall
    else
        padding = neuronsuite.app.radio.buttonPadding
        buttonW = neuronsuite.app.radio.buttonWidth
        buttonH = neuronsuite.app.radio.buttonHeight
        numPerRow = neuronsuite.app.radio.buttonsPerRow
    end

    -- Image cache table for theme icons
    if neuronsuite.app.gfx_buttons["settings_dashboard_themes"] == nil then
        neuronsuite.app.gfx_buttons["settings_dashboard_themes"] = {}
    end
    if neuronsuite.preferences.menulastselected["settings_dashboard_themes"] == nil then
        neuronsuite.preferences.menulastselected["settings_dashboard_themes"] = 1
    end

    local lc, bx, y = 0, 0, 0

    local n  = 0
    
    for idx, theme in ipairs(themeList) do

        if theme.configure then

            if lc == 0 then
                if neuronsuite.preferences.general.iconsize == 0 then y = form.height() + neuronsuite.app.radio.buttonPaddingSmall end
                if neuronsuite.preferences.general.iconsize == 1 then y = form.height() + neuronsuite.app.radio.buttonPaddingSmall end
                if neuronsuite.preferences.general.iconsize == 2 then y = form.height() + neuronsuite.app.radio.buttonPadding end
            end
            if lc >= 0 then bx = (buttonW + padding) * lc end

            -- Only load image once per theme index
            if neuronsuite.app.gfx_buttons["settings_dashboard_themes"][idx] == nil then

                local icon  
                if theme.source == "system" then
                    icon = themesBasePath .. theme.folder .. "/icon.png"
                else 
                    icon = themesUserPath .. theme.folder .. "/icon.png"
                end    
                neuronsuite.app.gfx_buttons["settings_dashboard_themes"][idx] = lcd.loadMask(icon)
            end

            neuronsuite.app.formFields[idx] = form.addButton(nil, {x = bx, y = y, w = buttonW, h = buttonH}, {
                text = theme.name,
                icon = neuronsuite.app.gfx_buttons["settings_dashboard_themes"][idx],
                options = FONT_S,
                paint = function() end,
                press = function()
                    -- Optional: your action when pressing a theme
                    -- Example: neuronsuite.app.ui.loadTheme(theme.folder)
                    neuronsuite.preferences.menulastselected["settings_dashboard_themes"] = idx
                neuronsuite.app.ui.progressDisplay(nil,nil,true)
                    local configure = theme.configure
                    local source = theme.source
                    local folder = theme.folder

                    local themeScript
                    if theme.source == "system" then
                        themeScript = themesBasePath .. folder .. "/" .. configure 
                    else 
                        themeScript = themesUserPath .. folder .. "/" .. configure 
                    end    

                    local wrapperScript = "settings/tools/dashboard_settings_theme.lua"

                    neuronsuite.app.ui.openPage(idx, theme.name, wrapperScript, source, folder,themeScript)               
                end
            })

            if not theme.configure then
                neuronsuite.app.formFields[idx]:enable(false)
            end


            --local currState = (neuronsuite.session.isConnected and neuronsuite.session.mcu_id) and true or false 
            if neuronsuite.preferences.menulastselected["settings_dashboard_themes"] == idx then
                neuronsuite.app.formFields[idx]:focus()
            end

            lc = lc + 1
            n = lc + 1
            if lc == numPerRow then lc = 0 end
        end   
    end

    if n == 0 then
        local w, h = lcd.getWindowSize()
        local msg = i18n("app.modules.settings.no_themes_available_to_configure")
        local tw, th = lcd.getTextSize(msg)
        local x = w / 2 - tw / 2
        local y = h / 2 - th / 2
        local btnH = neuronsuite.app.radio.navbuttonHeight
        form.addStaticText(nil, { x = x, y = y, w = tw, h = btnH }, msg)
    end

    neuronsuite.app.triggers.closeProgressLoader = true
    collectgarbage()
    enableWakeup = true
    return
end


neuronsuite.app.uiState = neuronsuite.app.uiStatus.pages

local function event(widget, category, value, x, y)
    -- if close event detected go to section home page
    if category == EVT_CLOSE and value == 0 or value == 35 then
        neuronsuite.app.ui.openPage(
            pageIdx,
            i18n("app.modules.settings.dashboard"),
            "settings/tools/dashboard.lua"
        )
        return true
    end
end

local function onNavMenu()
    neuronsuite.app.ui.progressDisplay(nil,nil,true)
    neuronsuite.app.ui.openPage(
        pageIdx,
        i18n("app.modules.settings.dashboard"),
        "settings/tools/dashboard.lua"
    )
        return true
end

local function wakeup()
    if not enableWakeup then
        return
    end

    -- current combined state: true only if both are truthy
    local currState = (neuronsuite.session.isConnected and neuronsuite.session.mcu_id) and true or false

    -- only update if state has changed
    if currState ~= prevConnectedState then
        -- we cant be here anymore... jump to previous page
        if currState == false then
            onNavMenu()
        end
        -- remember for next time
        prevConnectedState = currState
    end
end

return {
    pages = pages, 
    openPage = openPage,
    API = {},
    navButtons = {
        menu   = true,
        save   = false,
        reload = false,
        tool   = false,
        help   = false,
    }, 
    event = event,
    onNavMenu = onNavMenu,
    wakeup = wakeup,
}
