-- create 16 servos in disabled state
local SBUS_FUNCTIONMASK = 262144
local triggerOverRide = false
local triggerOverRideAll = false
local lastServoCountTime = os.clock()
local enableWakeup = false
local wakeupScheduler = os.clock()
local validSerialConfig = false
local i18n = neuronsuite.i18n.get
local function openPage(pidx, title, script)


    neuronsuite.tasks.msp.protocol.mspIntervalOveride = nil

    neuronsuite.app.triggers.isReady = false
    neuronsuite.app.uiState = neuronsuite.app.uiStatus.pages

    form.clear()

    neuronsuite.app.lastIdx = idx
    neuronsuite.app.lastTitle = title
    neuronsuite.app.lastScript = script

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

    neuronsuite.app.ui.fieldHeader(i18n("app.modules.sbusout.title") .. "")

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

    local lc = 0
    local bx = 0

    if neuronsuite.app.gfx_buttons["sbuschannel"] == nil then neuronsuite.app.gfx_buttons["sbuschannel"] = {} end
    if neuronsuite.preferences.menulastselected["sbuschannel"] == nil then neuronsuite.preferences.menulastselected["sbuschannel"] = 0 end
    if neuronsuite.currentSbusServoIndex == nil then neuronsuite.currentSbusServoIndex = 0 end

    for pidx = 0, 15 do

        if lc == 0 then
            if neuronsuite.preferences.general.iconsize == 0 then y = form.height() + neuronsuite.app.radio.buttonPaddingSmall end
            if neuronsuite.preferences.general.iconsize == 1 then y = form.height() + neuronsuite.app.radio.buttonPaddingSmall end
            if neuronsuite.preferences.general.iconsize == 2 then y = form.height() + neuronsuite.app.radio.buttonPadding end
        end

        if lc >= 0 then bx = (buttonW + padding) * lc end

        if neuronsuite.preferences.general.iconsize ~= 0 then
            if neuronsuite.app.gfx_buttons["sbuschannel"][pidx] == nil then neuronsuite.app.gfx_buttons["sbuschannel"][pidx] = lcd.loadMask("app/modules/sbusout/gfx/ch" .. tostring(pidx + 1) .. ".png") end
        else
            neuronsuite.app.gfx_buttons["sbuschannel"][pidx] = nil
        end

        neuronsuite.app.formFields[pidx] = form.addButton(nil, {x = bx, y = y, w = buttonW, h = buttonH}, {
            text = i18n("app.modules.sbusout.channel_prefix") .. "" .. tostring(pidx + 1),
            icon = neuronsuite.app.gfx_buttons["sbuschannel"][pidx],
            options = FONT_S,
            paint = function()
            end,
            press = function()
                neuronsuite.preferences.menulastselected["sbuschannel"] = pidx
                neuronsuite.currentSbusServoIndex = pidx
                neuronsuite.app.ui.progressDisplay()
                neuronsuite.app.ui.openPage(pidx, i18n("app.modules.sbusout.channel_page") .. "" .. tostring(neuronsuite.currentSbusServoIndex + 1), "sbusout/sbusout_tool.lua")
            end
        })

        neuronsuite.app.formFields[pidx]:enable(false)

        lc = lc + 1
        if lc == numPerRow then lc = 0 end

    end

    neuronsuite.app.triggers.closeProgressLoader = true
    neuronsuite.app.triggers.closeProgressLoaderNoisProcessed = true

    enableWakeup = true
    collectgarbage()
    return
end

local function processSerialConfig(data)

    for i, v in ipairs(data) do if v.functionMask == SBUS_FUNCTIONMASK then validSerialConfig = true end end

end

local function getSerialConfig()
    local message = {
        command = 54,
        processReply = function(self, buf)
            local data = {}

            buf.offset = 1
            for i = 1, 6 do
                data[i] = {}
                data[i].identifier = neuronsuite.tasks.msp.mspHelper.readU8(buf)
                data[i].functionMask = neuronsuite.tasks.msp.mspHelper.readU32(buf)
                data[i].msp_baudrateIndex = neuronsuite.tasks.msp.mspHelper.readU8(buf)
                data[i].gps_baudrateIndex = neuronsuite.tasks.msp.mspHelper.readU8(buf)
                data[i].telemetry_baudrateIndex = neuronsuite.tasks.msp.mspHelper.readU8(buf)
                data[i].blackbox_baudrateIndex = neuronsuite.tasks.msp.mspHelper.readU8(buf)
            end

            processSerialConfig(data)
        end,
        simulatorResponse = {20, 1, 0, 0, 0, 5, 4, 0, 5, 0, 0, 0, 4, 0, 5, 4, 0, 5, 1, 0, 0, 4, 0, 5, 4, 0, 5, 2, 0, 0, 0, 0, 5, 4, 0, 5, 3, 0, 0, 0, 0, 5, 4, 0, 5, 4, 64, 0, 0, 0, 5, 4, 0, 5}
    }
    neuronsuite.tasks.msp.mspQueue:add(message)
end


local function wakeup()

    if enableWakeup == true and validSerialConfig == false then

        local now = os.clock()
        if (now - wakeupScheduler) >= 0.5 then
            wakeupScheduler = now

            getSerialConfig()

        end
    elseif enableWakeup == true and validSerialConfig == true then
        for pidx = 0, 15 do
            neuronsuite.app.formFields[pidx]:enable(true)
            if neuronsuite.preferences.menulastselected["sbuschannel"] == neuronsuite.currentSbusServoIndex then neuronsuite.app.formFields[neuronsuite.currentSbusServoIndex]:focus() end
        end
        -- close the progressDisplay
    end

end

-- not changing to api for this module due to the unusual read/write scenario.
-- its not worth the effort
return {
    title = "Sbus Out",
    openPage = openPage,
    wakeup = wakeup,
    navButtons = {
        menu = true,
        save = false,
        reload = false,
        tool = false,
        help = true
    },
    API = {},
}
