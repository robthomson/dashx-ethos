

local themesBasePath = "SCRIPTS:/" .. neurondash.config.baseDir .. "/widgets/dashboard/themes/"
local themesUserPath = "SCRIPTS:/" .. neurondash.config.preferences .. "/dashboard/"

local function openPage(pidx, title, script)
    -- Get the installed themes
    local themeList = neurondash.widgets.dashboard.listThemes()

    neurondash.session.dashboardEditingTheme = nil
    enableWakeup = true
    neurondash.app.triggers.closeProgressLoader = true
    form.clear()


    neurondash.app.lastIdx    = pageIdx
    neurondash.app.lastTitle  = title
    neurondash.app.lastScript = script

    neurondash.app.ui.fieldHeader(
        "@i18n(app.modules.settings.name)@" .. " / " .. "@i18n(app.modules.settings.dashboard)@" .. " / " .. "@i18n(app.modules.settings.dashboard_settings)@"
    )

    -- Icon/button layout settings
    local buttonW, buttonH, padding, numPerRow
    if neurondash.preferences.general.iconsize == 0 then
        padding = neurondash.app.radio.buttonPaddingSmall
        buttonW = (neurondash.session.lcdWidth - padding) / neurondash.app.radio.buttonsPerRow - padding
        buttonH = neurondash.app.radio.navbuttonHeight
        numPerRow = neurondash.app.radio.buttonsPerRow
    elseif neurondash.preferences.general.iconsize == 1 then
        padding = neurondash.app.radio.buttonPaddingSmall
        buttonW = neurondash.app.radio.buttonWidthSmall
        buttonH = neurondash.app.radio.buttonHeightSmall
        numPerRow = neurondash.app.radio.buttonsPerRowSmall
    else
        padding = neurondash.app.radio.buttonPadding
        buttonW = neurondash.app.radio.buttonWidth
        buttonH = neurondash.app.radio.buttonHeight
        numPerRow = neurondash.app.radio.buttonsPerRow
    end

    -- Image cache table for theme icons
    if neurondash.app.gfx_buttons["settings_dashboard_themes"] == nil then
        neurondash.app.gfx_buttons["settings_dashboard_themes"] = {}
    end
    if neurondash.preferences.menulastselected["settings_dashboard_themes"] == nil then
        neurondash.preferences.menulastselected["settings_dashboard_themes"] = 1
    end

    local lc, bx, y = 0, 0, 0
    
    for idx, theme in ipairs(themeList) do

        if theme.configure then

            if lc == 0 then
                if neurondash.preferences.general.iconsize == 0 then y = form.height() + neurondash.app.radio.buttonPaddingSmall end
                if neurondash.preferences.general.iconsize == 1 then y = form.height() + neurondash.app.radio.buttonPaddingSmall end
                if neurondash.preferences.general.iconsize == 2 then y = form.height() + neurondash.app.radio.buttonPadding end
            end
            if lc >= 0 then bx = (buttonW + padding) * lc end

            -- Only load image once per theme index
            if neurondash.app.gfx_buttons["settings_dashboard_themes"][idx] == nil then

                local icon  
                if theme.source == "system" then
                    icon = themesBasePath .. theme.folder .. "/icon.png"
                else 
                    icon = themesUserPath .. theme.folder .. "/icon.png"
                end    
                neurondash.app.gfx_buttons["settings_dashboard_themes"][idx] = lcd.loadMask(icon)
            end

            neurondash.app.formFields[idx] = form.addButton(nil, {x = bx, y = y, w = buttonW, h = buttonH}, {
                text = theme.name,
                icon = neurondash.app.gfx_buttons["settings_dashboard_themes"][idx],
                options = FONT_S,
                paint = function() end,
                press = function()
                    -- Optional: your action when pressing a theme
                    -- Example: neurondash.app.ui.loadTheme(theme.folder)
                    neurondash.preferences.menulastselected["settings_dashboard_themes"] = idx
                neurondash.app.ui.progressDisplay()
                    local configure = theme.configure
                    local source = theme.source
                    local folder = theme.folder

                    local themeScript
                    if theme.source == "system" then
                        themeScript = themesBasePath .. folder .. "/" .. configure 
                    else 
                        themeScript = themesUserPath .. folder .. "/" .. configure 
                    end    

                    neurondash.app.ui.openPageDashboard(idx, theme.name,themeScript, source, folder)               
                end
            })

            if not theme.configure then
                neurondash.app.formFields[idx]:enable(false)
            end

            if neurondash.preferences.menulastselected["settings_dashboard_themes"] == idx then
                neurondash.app.formFields[idx]:focus()
            end

            lc = lc + 1
            if lc == numPerRow then lc = 0 end
        end   
    end

    if lc == 0 then
        local w, h = neurondash.utils.getWindowSize()
        local msg = "@i18n(app.modules.settings.no_themes_available_to_configure)@"
        local tw, th = lcd.getTextSize(msg)
        local x = w / 2 - tw / 2
        local y = h / 2 - th / 2
        local btnH = neurondash.app.radio.navbuttonHeight
        form.addStaticText(nil, { x = x, y = y, w = tw, h = btnH }, msg)
    end

    neurondash.app.triggers.closeProgressLoader = true
    collectgarbage()
    return
end


neurondash.app.uiState = neurondash.app.uiStatus.pages

local function event(widget, category, value, x, y)
    -- if close event detected go to section home page
    if category == EVT_CLOSE and value == 0 or value == 35 then
        neurondash.app.ui.openPage(
            pageIdx,
            "@i18n(app.modules.settings.dashboard)@",
            "settings/tools/dashboard.lua"
        )
        return true
    end
end

local function onNavMenu()
    neurondash.app.ui.progressDisplay()
        neurondash.app.ui.openPage(
            pageIdx,
            "@i18n(app.modules.settings.dashboard)@",
            "settings/tools/dashboard.lua"
        )
        return true
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
}
