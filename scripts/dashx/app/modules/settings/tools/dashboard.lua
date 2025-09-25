


local S_PAGES = {
    {name = "@i18n(app.modules.settings.dashboard_theme)@", script = "dashboard_theme.lua", image = "dashboard_theme.png"},
    {name = "@i18n(app.modules.settings.dashboard_settings)@", script = "dashboard_settings.lua", image = "dashboard_settings.png"},
}

local function openPage(pidx, title, script)



    dashx.app.triggers.isReady = false
    dashx.app.uiState = dashx.app.uiStatus.mainMenu

    form.clear()

    dashx.app.lastIdx = idx
    dashx.app.lastTitle = title
    dashx.app.lastScript = script

    ESC = {}

    -- size of buttons
    if dashx.preferences.general.iconsize == nil or dashx.preferences.general.iconsize == "" then
        dashx.preferences.general.iconsize = 1
    else
        dashx.preferences.general.iconsize = tonumber(dashx.preferences.general.iconsize)
    end

    local w, h = dashx.utils.getWindowSize()
    local windowWidth = w
    local windowHeight = h
    local padding = dashx.app.radio.buttonPadding

    local sc
    local panel


    buttonW = 100
    local x = windowWidth - buttonW - 10

    dashx.app.ui.fieldHeader(
        "@i18n(app.modules.settings.name)@" .. " / " .. "@i18n(app.modules.settings.dashboard)@"
    )


    local buttonW
    local buttonH
    local padding
    local numPerRow

    -- TEXT ICONS
    -- TEXT ICONS
    if dashx.preferences.general.iconsize == 0 then
        padding = dashx.app.radio.buttonPaddingSmall
        buttonW = (dashx.session.lcdWidth - padding) / dashx.app.radio.buttonsPerRow - padding
        buttonH = dashx.app.radio.navbuttonHeight
        numPerRow = dashx.app.radio.buttonsPerRow
    end
    -- SMALL ICONS
    if dashx.preferences.general.iconsize == 1 then

        padding = dashx.app.radio.buttonPaddingSmall
        buttonW = dashx.app.radio.buttonWidthSmall
        buttonH = dashx.app.radio.buttonHeightSmall
        numPerRow = dashx.app.radio.buttonsPerRowSmall
    end
    -- LARGE ICONS
    if dashx.preferences.general.iconsize == 2 then

        padding = dashx.app.radio.buttonPadding
        buttonW = dashx.app.radio.buttonWidth
        buttonH = dashx.app.radio.buttonHeight
        numPerRow = dashx.app.radio.buttonsPerRow
    end


    if dashx.app.gfx_buttons["settings_dashboard"] == nil then dashx.app.gfx_buttons["settings_dashboard"] = {} end
    if dashx.preferences.menulastselected["settings_dashboard"] == nil then dashx.preferences.menulastselected["settings_dashboard"] = 1 end


    local Menu = assert(dashx.compiler.loadfile("app/modules/" .. script))()
    local pages = S_PAGES
    local lc = 0
    local bx = 0



    for pidx, pvalue in ipairs(S_PAGES) do

        if lc == 0 then
            if dashx.preferences.general.iconsize == 0 then y = form.height() + dashx.app.radio.buttonPaddingSmall end
            if dashx.preferences.general.iconsize == 1 then y = form.height() + dashx.app.radio.buttonPaddingSmall end
            if dashx.preferences.general.iconsize == 2 then y = form.height() + dashx.app.radio.buttonPadding end
        end

        if lc >= 0 then bx = (buttonW + padding) * lc end

        if dashx.preferences.general.iconsize ~= 0 then
            if dashx.app.gfx_buttons["settings_dashboard"][pidx] == nil then dashx.app.gfx_buttons["settings_dashboard"][pidx] = lcd.loadMask("app/modules/settings/gfx/" .. pvalue.image) end
        else
            dashx.app.gfx_buttons["settings_dashboard"][pidx] = nil
        end

        dashx.app.formFields[pidx] = form.addButton(line, {x = bx, y = y, w = buttonW, h = buttonH}, {
            text = pvalue.name,
            icon = dashx.app.gfx_buttons["settings_dashboard"][pidx],
            options = FONT_S,
            paint = function()
            end,
            press = function()
                dashx.preferences.menulastselected["settings_dashboard"] = pidx
                dashx.app.ui.progressDisplay()
                dashx.app.ui.openPage(pidx, pvalue.folder, "settings/tools/" .. pvalue.script)
            end
        })

        if pvalue.disabled == true then dashx.app.formFields[pidx]:enable(false) end

        if dashx.preferences.menulastselected["settings_dashboard"] == pidx then dashx.app.formFields[pidx]:focus() end

        lc = lc + 1

        if lc == numPerRow then lc = 0 end

    end

    dashx.app.triggers.closeProgressLoader = true
    collectgarbage()
    return
end

local function event(widget, category, value, x, y)
    -- if close event detected go to section home page
    if category == EVT_CLOSE and value == 0 or value == 35 then
        dashx.app.ui.openPage(
            pageIdx,
            "@i18n(app.modules.settings.name)@",
            "settings/settings.lua"
        )
        return true
    end
end


local function onNavMenu()
    dashx.app.ui.progressDisplay()
        dashx.app.ui.openPage(
            pageIdx,
            "@i18n(app.modules.settings.name)@",
            "settings/settings.lua"
        )
        return true
end

dashx.app.uiState = dashx.app.uiStatus.pages

return {
    pages = pages, 
    openPage = openPage,
    onNavMenu = onNavMenu,
    event = event,
    API = {},
        navButtons = {
        menu   = true,
        save   = false,
        reload = false,
        tool   = false,
        help   = false,
    },    
}
