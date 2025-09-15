

local i18n = neuronsuite.i18n.get
local S_PAGES = {
    [1] = {name = i18n("app.modules.settings.dashboard_theme"), script = "dashboard_theme.lua", image = "dashboard_theme.png"},
    [2] = {name = i18n("app.modules.settings.dashboard_settings"), script = "dashboard_settings.lua", image = "dashboard_settings.png"},
}

local enableWakeup = false
local prevConnectedState = nil
local initTime = os.clock()

local function openPage(pidx, title, script)


    neuronsuite.tasks.msp.protocol.mspIntervalOveride = nil


    neuronsuite.app.triggers.isReady = false
    neuronsuite.app.uiState = neuronsuite.app.uiStatus.mainMenu

    form.clear()

    neuronsuite.app.lastIdx = idx
    neuronsuite.app.lastTitle = title
    neuronsuite.app.lastScript = script

    -- Clear old icons
    for i in pairs(neuronsuite.app.gfx_buttons) do
        if i ~= "settings_dashboard" then
            neuronsuite.app.gfx_buttons[i] = nil
        end
    end    

    ESC = {}

    -- size of buttons
    if neuronsuite.preferences.general.iconsize == nil or neuronsuite.preferences.general.iconsize == "" then
        neuronsuite.preferences.general.iconsize = 1
    else
        neuronsuite.preferences.general.iconsize = tonumber(neuronsuite.preferences.general.iconsize)
    end

    local w, h = lcd.getWindowSize()
    local windowWidth = w
    local windowHeight = h
    local padding = neuronsuite.app.radio.buttonPadding

    local sc
    local panel


    buttonW = 100
    local x = windowWidth - buttonW - 10

    neuronsuite.app.ui.fieldHeader(
        i18n(i18n("app.modules.settings.name") .. " / " .. i18n("app.modules.settings.dashboard"))
    )


    local buttonW
    local buttonH
    local padding
    local numPerRow

    -- TEXT ICONS
    -- TEXT ICONS
    if neuronsuite.preferences.general.iconsize == 0 then
        padding = neuronsuite.app.radio.buttonPaddingSmall
        buttonW = (neuronsuite.app.lcdWidth - padding) / neuronsuite.app.radio.buttonsPerRow - padding
        buttonH = neuronsuite.app.radio.navbuttonHeight
        numPerRow = neuronsuite.app.radio.buttonsPerRow
    end
    -- SMALL ICONS
    if neuronsuite.preferences.general.iconsize == 1 then

        padding = neuronsuite.app.radio.buttonPaddingSmall
        buttonW = neuronsuite.app.radio.buttonWidthSmall
        buttonH = neuronsuite.app.radio.buttonHeightSmall
        numPerRow = neuronsuite.app.radio.buttonsPerRowSmall
    end
    -- LARGE ICONS
    if neuronsuite.preferences.general.iconsize == 2 then

        padding = neuronsuite.app.radio.buttonPadding
        buttonW = neuronsuite.app.radio.buttonWidth
        buttonH = neuronsuite.app.radio.buttonHeight
        numPerRow = neuronsuite.app.radio.buttonsPerRow
    end


    if neuronsuite.app.gfx_buttons["settings_dashboard"] == nil then neuronsuite.app.gfx_buttons["settings_dashboard"] = {} end
    if neuronsuite.preferences.menulastselected["settings_dashboard"] == nil then neuronsuite.preferences.menulastselected["settings_dashboard"] = 1 end


    local Menu = assert(neuronsuite.compiler.loadfile("app/modules/" .. script))()
    local pages = S_PAGES
    local lc = 0
    local bx = 0



    for pidx, pvalue in ipairs(S_PAGES) do

        if lc == 0 then
            if neuronsuite.preferences.general.iconsize == 0 then y = form.height() + neuronsuite.app.radio.buttonPaddingSmall end
            if neuronsuite.preferences.general.iconsize == 1 then y = form.height() + neuronsuite.app.radio.buttonPaddingSmall end
            if neuronsuite.preferences.general.iconsize == 2 then y = form.height() + neuronsuite.app.radio.buttonPadding end
        end

        if lc >= 0 then bx = (buttonW + padding) * lc end

        if neuronsuite.preferences.general.iconsize ~= 0 then
            if neuronsuite.app.gfx_buttons["settings_dashboard"][pidx] == nil then neuronsuite.app.gfx_buttons["settings_dashboard"][pidx] = lcd.loadMask("app/modules/settings/gfx/" .. pvalue.image) end
        else
            neuronsuite.app.gfx_buttons["settings_dashboard"][pidx] = nil
        end

        neuronsuite.app.formFields[pidx] = form.addButton(line, {x = bx, y = y, w = buttonW, h = buttonH}, {
            text = pvalue.name,
            icon = neuronsuite.app.gfx_buttons["settings_dashboard"][pidx],
            options = FONT_S,
            paint = function()
            end,
            press = function()
                neuronsuite.preferences.menulastselected["settings_dashboard"] = pidx
                neuronsuite.app.ui.progressDisplay(nil,nil,true)
                neuronsuite.app.ui.openPage(pidx, pvalue.folder, "settings/tools/" .. pvalue.script)
            end
        })

        if pvalue.disabled == true then neuronsuite.app.formFields[pidx]:enable(false) end

        local currState = (neuronsuite.session.isConnected and neuronsuite.session.mcu_id) and true or false
            
        if neuronsuite.preferences.menulastselected["settings_dashboard"] == pidx then neuronsuite.app.formFields[pidx]:focus() end

        lc = lc + 1

        if lc == numPerRow then lc = 0 end

    end

    neuronsuite.app.triggers.closeProgressLoader = true
    collectgarbage()
    enableWakeup = true
    return
end

local function event(widget, category, value, x, y)
    -- if close event detected go to section home page
    if category == EVT_CLOSE and value == 0 or value == 35 then
        neuronsuite.app.ui.openPage(
            pageIdx,
            i18n("app.modules.settings.name"),
            "settings/settings.lua"
        )
        return true
    end
end


local function onNavMenu()
    neuronsuite.app.ui.progressDisplay(nil,nil,true)
    neuronsuite.app.ui.openPage(
        pageIdx,
        i18n("app.modules.settings.name"),
        "settings/settings.lua"
    )
        return true
end


local function wakeup()
    if not enableWakeup then
        return
    end

    -- Exit if less than 0.25 second since init
    -- This prevents the icon getting trashed due to being disabled before rendering
    if os.clock() - initTime < 0.25 then
        return
    end

    -- current combined state: true only if both are truthy
    local currState = (neuronsuite.session.isConnected and neuronsuite.session.mcu_id) and true or false

    -- only update if state has changed
    if currState ~= prevConnectedState then
        -- toggle all three fields together
        neuronsuite.app.formFields[2]:enable(currState)

        if not currState then
            neuronsuite.app.formNavigationFields['menu']:focus()
        end

        -- remember for next time
        prevConnectedState = currState
    end
end


neuronsuite.app.uiState = neuronsuite.app.uiStatus.pages

return {
    pages = pages, 
    openPage = openPage,
    onNavMenu = onNavMenu,
    event = event,
    wakeup = wakeup,
    API = {},
        navButtons = {
        menu   = true,
        save   = false,
        reload = false,
        tool   = false,
        help   = false,
    },    
}
