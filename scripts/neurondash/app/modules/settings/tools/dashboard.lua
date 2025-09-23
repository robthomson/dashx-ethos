


local S_PAGES = {
    {name = "@i18n(app.modules.settings.dashboard_theme)@", script = "dashboard_theme.lua", image = "dashboard_theme.png"},
    {name = "@i18n(app.modules.settings.dashboard_settings)@", script = "dashboard_settings.lua", image = "dashboard_settings.png"},
}

local function openPage(pidx, title, script)



    neurondash.app.triggers.isReady = false
    neurondash.app.uiState = neurondash.app.uiStatus.mainMenu

    form.clear()

    neurondash.app.lastIdx = idx
    neurondash.app.lastTitle = title
    neurondash.app.lastScript = script

    ESC = {}

    -- size of buttons
    if neurondash.preferences.general.iconsize == nil or neurondash.preferences.general.iconsize == "" then
        neurondash.preferences.general.iconsize = 1
    else
        neurondash.preferences.general.iconsize = tonumber(neurondash.preferences.general.iconsize)
    end

    local w, h = neurondash.utils.getWindowSize()
    local windowWidth = w
    local windowHeight = h
    local padding = neurondash.app.radio.buttonPadding

    local sc
    local panel


    buttonW = 100
    local x = windowWidth - buttonW - 10

    neurondash.app.ui.fieldHeader(
        "@i18n(app.modules.settings.name)@" .. " / " .. "@i18n(app.modules.settings.dashboard)@"
    )


    local buttonW
    local buttonH
    local padding
    local numPerRow

    -- TEXT ICONS
    -- TEXT ICONS
    if neurondash.preferences.general.iconsize == 0 then
        padding = neurondash.app.radio.buttonPaddingSmall
        buttonW = (neurondash.session.lcdWidth - padding) / neurondash.app.radio.buttonsPerRow - padding
        buttonH = neurondash.app.radio.navbuttonHeight
        numPerRow = neurondash.app.radio.buttonsPerRow
    end
    -- SMALL ICONS
    if neurondash.preferences.general.iconsize == 1 then

        padding = neurondash.app.radio.buttonPaddingSmall
        buttonW = neurondash.app.radio.buttonWidthSmall
        buttonH = neurondash.app.radio.buttonHeightSmall
        numPerRow = neurondash.app.radio.buttonsPerRowSmall
    end
    -- LARGE ICONS
    if neurondash.preferences.general.iconsize == 2 then

        padding = neurondash.app.radio.buttonPadding
        buttonW = neurondash.app.radio.buttonWidth
        buttonH = neurondash.app.radio.buttonHeight
        numPerRow = neurondash.app.radio.buttonsPerRow
    end


    if neurondash.app.gfx_buttons["settings_dashboard"] == nil then neurondash.app.gfx_buttons["settings_dashboard"] = {} end
    if neurondash.preferences.menulastselected["settings_dashboard"] == nil then neurondash.preferences.menulastselected["settings_dashboard"] = 1 end


    local Menu = assert(neurondash.compiler.loadfile("app/modules/" .. script))()
    local pages = S_PAGES
    local lc = 0
    local bx = 0



    for pidx, pvalue in ipairs(S_PAGES) do

        if lc == 0 then
            if neurondash.preferences.general.iconsize == 0 then y = form.height() + neurondash.app.radio.buttonPaddingSmall end
            if neurondash.preferences.general.iconsize == 1 then y = form.height() + neurondash.app.radio.buttonPaddingSmall end
            if neurondash.preferences.general.iconsize == 2 then y = form.height() + neurondash.app.radio.buttonPadding end
        end

        if lc >= 0 then bx = (buttonW + padding) * lc end

        if neurondash.preferences.general.iconsize ~= 0 then
            if neurondash.app.gfx_buttons["settings_dashboard"][pidx] == nil then neurondash.app.gfx_buttons["settings_dashboard"][pidx] = lcd.loadMask("app/modules/settings/gfx/" .. pvalue.image) end
        else
            neurondash.app.gfx_buttons["settings_dashboard"][pidx] = nil
        end

        neurondash.app.formFields[pidx] = form.addButton(line, {x = bx, y = y, w = buttonW, h = buttonH}, {
            text = pvalue.name,
            icon = neurondash.app.gfx_buttons["settings_dashboard"][pidx],
            options = FONT_S,
            paint = function()
            end,
            press = function()
                neurondash.preferences.menulastselected["settings_dashboard"] = pidx
                neurondash.app.ui.progressDisplay()
                neurondash.app.ui.openPage(pidx, pvalue.folder, "settings/tools/" .. pvalue.script)
            end
        })

        if pvalue.disabled == true then neurondash.app.formFields[pidx]:enable(false) end

        if neurondash.preferences.menulastselected["settings_dashboard"] == pidx then neurondash.app.formFields[pidx]:focus() end

        lc = lc + 1

        if lc == numPerRow then lc = 0 end

    end

    neurondash.app.triggers.closeProgressLoader = true
    collectgarbage()
    return
end

local function event(widget, category, value, x, y)
    -- if close event detected go to section home page
    if category == EVT_CLOSE and value == 0 or value == 35 then
        neurondash.app.ui.openPage(
            pageIdx,
            "@i18n(app.modules.settings.name)@",
            "settings/settings.lua"
        )
        return true
    end
end


local function onNavMenu()
    neurondash.app.ui.progressDisplay()
        neurondash.app.ui.openPage(
            pageIdx,
            "@i18n(app.modules.settings.name)@",
            "settings/settings.lua"
        )
        return true
end

neurondash.app.uiState = neurondash.app.uiStatus.pages

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
