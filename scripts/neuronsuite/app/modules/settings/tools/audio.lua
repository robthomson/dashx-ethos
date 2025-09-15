

local i18n = neuronsuite.i18n.get

local S_PAGES = {
    {name = i18n("app.modules.settings.txt_audio_events"), script = "audio_events.lua", image = "audio_events.png"},
    {name = i18n("app.modules.settings.txt_audio_switches"), script = "audio_switches.lua", image = "audio_switches.png"},
    {name = i18n("app.modules.settings.txt_audio_timer"), script = "audio_timer.lua", image = "audio_timer.png"},
}

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
        if i ~= "settings_dashboard_audio" then
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
        i18n(i18n("app.modules.settings.name") .. " / " .. i18n("app.modules.settings.audio"))
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


    if neuronsuite.app.gfx_buttons["settings_dashboard_audio"] == nil then neuronsuite.app.gfx_buttons["settings_dashboard_audio"] = {} end
    if neuronsuite.preferences.menulastselected["settings_dashboard_audio"] == nil then neuronsuite.preferences.menulastselected["settings_dashboard_audio"] = 1 end


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
            if neuronsuite.app.gfx_buttons["settings_dashboard_audio"][pidx] == nil then neuronsuite.app.gfx_buttons["settings_dashboard_audio"][pidx] = lcd.loadMask("app/modules/settings/gfx/" .. pvalue.image) end
        else
            neuronsuite.app.gfx_buttons["settings_dashboard_audio"][pidx] = nil
        end

        neuronsuite.app.formFields[pidx] = form.addButton(line, {x = bx, y = y, w = buttonW, h = buttonH}, {
            text = pvalue.name,
            icon = neuronsuite.app.gfx_buttons["settings_dashboard_audio"][pidx],
            options = FONT_S,
            paint = function()
            end,
            press = function()
                neuronsuite.preferences.menulastselected["settings_dashboard_audio"] = pidx
                neuronsuite.app.ui.progressDisplay(nil,nil,true)
                neuronsuite.app.ui.openPage(pidx, pvalue.folder, "settings/tools/" .. pvalue.script)
            end
        })

        if pvalue.disabled == true then neuronsuite.app.formFields[pidx]:enable(false) end

        if neuronsuite.preferences.menulastselected["settings_dashboard_audio"] == pidx then neuronsuite.app.formFields[pidx]:focus() end

        lc = lc + 1

        if lc == numPerRow then lc = 0 end

    end

    neuronsuite.app.triggers.closeProgressLoader = true
    collectgarbage()
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

neuronsuite.app.uiState = neuronsuite.app.uiStatus.pages

return {
    pages = pages, 
    openPage = openPage,
    onNavMenu = onNavMenu,
    API = {},
    event = event,
    navButtons = {
        menu   = true,
        save   = false,
        reload = false,
        tool   = false,
        help   = false,
    },    
}
