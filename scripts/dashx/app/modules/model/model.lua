

local S_PAGES = {
    {name = "@i18n(app.modules.model.triggers)@", script = "triggers.lua", image = "triggers.png"},
    {name = "@i18n(app.modules.model.battery)@", script = "battery.lua", image = "battery.png"},
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

    form.addLine(title)

    buttonW = 100
    local x = windowWidth - buttonW - 10

    dashx.app.formNavigationFields['menu'] = form.addButton(line, {x = x, y = dashx.app.radio.linePaddingTop, w = buttonW, h = dashx.app.radio.navbuttonHeight}, {
        text = "MENU",
        icon = nil,
        options = FONT_S,
        paint = function()
        end,
        press = function()
            dashx.app.lastIdx = nil
            dashx.session.lastPage = nil

            if dashx.app.Page and dashx.app.Page.onNavMenu then dashx.app.Page.onNavMenu(dashx.app.Page) end

            dashx.app.ui.openMainMenu()
        end
    })
    dashx.app.formNavigationFields['menu']:focus()

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


    if dashx.app.gfx_buttons["model"] == nil then dashx.app.gfx_buttons["model"] = {} end
    if dashx.preferences.menulastselected["model"] == nil then dashx.preferences.menulastselected["model"] = 1 end


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
            if dashx.app.gfx_buttons["model"][pidx] == nil then dashx.app.gfx_buttons["model"][pidx] = lcd.loadMask("app/modules/model/gfx/" .. pvalue.image) end
        else
            dashx.app.gfx_buttons["model"][pidx] = nil
        end

        dashx.app.formFields[pidx] = form.addButton(line, {x = bx, y = y, w = buttonW, h = buttonH}, {
            text = pvalue.name,
            icon = dashx.app.gfx_buttons["model"][pidx],
            options = FONT_S,
            paint = function()
            end,
            press = function()
                dashx.preferences.menulastselected["model"] = pidx
                dashx.app.ui.progressDisplay()
                dashx.app.ui.openPage(pidx, pvalue.folder, "model/tools/" .. pvalue.script)
            end
        })

        if pvalue.disabled == true then dashx.app.formFields[pidx]:enable(false) end

        if dashx.preferences.menulastselected["model"] == pidx then dashx.app.formFields[pidx]:focus() end

        lc = lc + 1

        if lc == numPerRow then lc = 0 end

    end

    dashx.app.triggers.closeProgressLoader = true
    collectgarbage()
    return
end

dashx.app.uiState = dashx.app.uiStatus.pages

return {
    pages = pages, 
    openPage = openPage,
    API = {},
}
