

local S_PAGES = {
    {name = "@i18n(app.modules.settings.txt_general)@", script = "general.lua", image = "general.png"},
    {name = "@i18n(app.modules.settings.dashboard)@", script = "dashboard.lua", image = "dashboard.png"},
    {name = "@i18n(app.modules.settings.localizations)@", script = "localizations.lua", image = "localizations.png"},
    {name = "@i18n(app.modules.settings.audio)@", script = "audio.lua", image = "audio.png"},
    {name = "@i18n(app.modules.settings.txt_development)@", script = "development.lua", image = "development.png"},
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

    form.addLine(title)

    buttonW = 100
    local x = windowWidth - buttonW - 10

    neurondash.app.formNavigationFields['menu'] = form.addButton(line, {x = x, y = neurondash.app.radio.linePaddingTop, w = buttonW, h = neurondash.app.radio.navbuttonHeight}, {
        text = "MENU",
        icon = nil,
        options = FONT_S,
        paint = function()
        end,
        press = function()
            neurondash.app.lastIdx = nil
            neurondash.session.lastPage = nil

            if neurondash.app.Page and neurondash.app.Page.onNavMenu then neurondash.app.Page.onNavMenu(neurondash.app.Page) end

            neurondash.app.ui.openMainMenu()
        end
    })
    neurondash.app.formNavigationFields['menu']:focus()

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


    if neurondash.app.gfx_buttons["settings"] == nil then neurondash.app.gfx_buttons["settings"] = {} end
    if neurondash.preferences.menulastselected["settings"] == nil then neurondash.preferences.menulastselected["settings"] = 1 end


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
            if neurondash.app.gfx_buttons["settings"][pidx] == nil then neurondash.app.gfx_buttons["settings"][pidx] = lcd.loadMask("app/modules/settings/gfx/" .. pvalue.image) end
        else
            neurondash.app.gfx_buttons["settings"][pidx] = nil
        end

        neurondash.app.formFields[pidx] = form.addButton(line, {x = bx, y = y, w = buttonW, h = buttonH}, {
            text = pvalue.name,
            icon = neurondash.app.gfx_buttons["settings"][pidx],
            options = FONT_S,
            paint = function()
            end,
            press = function()
                neurondash.preferences.menulastselected["settings"] = pidx
                neurondash.app.ui.progressDisplay()
                neurondash.app.ui.openPage(pidx, pvalue.folder, "settings/tools/" .. pvalue.script)
            end
        })

        if pvalue.disabled == true then neurondash.app.formFields[pidx]:enable(false) end

        if neurondash.preferences.menulastselected["settings"] == pidx then neurondash.app.formFields[pidx]:focus() end

        lc = lc + 1

        if lc == numPerRow then lc = 0 end

    end

    neurondash.app.triggers.closeProgressLoader = true
    collectgarbage()
    return
end

neurondash.app.uiState = neurondash.app.uiStatus.pages

return {
    pages = pages, 
    openPage = openPage,
    API = {},
}
