-- create 16 servos in disabled state
local servoTable = {}
servoTable = {}
servoTable['sections'] = {}

local triggerOverRide = false
local triggerOverRideAll = false
local lastServoCountTime = os.clock()
local i18n = neuronsuite.i18n.get
local function buildServoTable()

    for i = 1, neuronsuite.session.servoCount do
        servoTable[i] = {}
        servoTable[i] = {}
        servoTable[i]['title'] = i18n("app.modules.servos.servo_prefix") .. i
        servoTable[i]['image'] = "servo" .. i .. ".png"
        servoTable[i]['disabled'] = true
    end

    for i = 1, neuronsuite.session.servoCount do
        -- enable actual number of servos
        servoTable[i]['disabled'] = false

        if neuronsuite.session.swashMode == 0 then
            -- we do nothing as we cannot determine any servo names
        elseif neuronsuite.session.swashMode == 1 then
            -- servo mode is direct - only servo for sure we know name of is tail
            if neuronsuite.session.tailMode == 0 then
                servoTable[4]['title'] = i18n("app.modules.servos.tail")
                servoTable[4]['image'] = "tail.png"
                servoTable[4]['section'] = 1
            end
        elseif neuronsuite.session.swashMode == 2 or neuronsuite.session.swashMode == 3 or neuronsuite.session.swashMode == 4 then
            -- servo mode is cppm - 
            servoTable[1]['title'] = i18n("app.modules.servos.cyc_pitch")
            servoTable[1]['image'] = "cpitch.png"

            servoTable[2]['title'] = i18n("app.modules.servos.cyc_left")
            servoTable[2]['image'] = "cleft.png"

            servoTable[3]['title'] = i18n("app.modules.servos.cyc_right")
            servoTable[3]['image'] = "cright.png"

            if neuronsuite.session.tailMode == 0 then
                -- this is because when swiching models this may or may not have
                -- been created.
                if servoTable[4] == nil then servoTable[4] = {} end
                servoTable[4]['title'] = i18n("app.modules.servos.tail")
                servoTable[4]['image'] = "tail.png"
            else
                -- servoTable[4]['disabled'] = true
            end
        elseif neuronsuite.session.swashMode == 5 or neuronsuite.session.swashMode == 6 then
            -- servo mode is fpm 90
            -- servoTable[3]['disabled'] = true 
            if neuronsuite.session.tailMode == 0 then
                servoTable[4]['title'] = i18n("app.modules.servos.tail")
                servoTable[4]['image'] = "tail.png"
            else
                -- servoTable[4]['disabled'] = true                
            end
        end
    end
end

local function swashMixerType()
    local txt
    if neuronsuite.session.swashMode == 0 then
        txt = "NONE"
    elseif neuronsuite.session.swashMode == 1 then
        txt = "DIRECT"
    elseif neuronsuite.session.swashMode == 2 then
        txt = "CPPM 120°"
    elseif neuronsuite.session.swashMode == 3 then
        txt = "CPPM 135°"
    elseif neuronsuite.session.swashMode == 4 then
        txt = "CPPM 140°"
    elseif neuronsuite.session.swashMode == 5 then
        txt = "FPPM 90° L"
    elseif neuronsuite.session.swashMode == 6 then
        txt = "FPPM 90° R"
    else
        txt = "UNKNOWN"
    end

    return txt
end

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

    neuronsuite.app.ui.fieldHeader(i18n("app.modules.servos.name"))

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

    if neuronsuite.app.gfx_buttons["servos"] == nil then neuronsuite.app.gfx_buttons["servos"] = {} end
    if neuronsuite.preferences.menulastselected["servos"] == nil then neuronsuite.preferences.menulastselected["servos"] = 1 end

    if neuronsuite.app.gfx_buttons["servos"] == nil then neuronsuite.app.gfx_buttons["servos"] = {} end
    if neuronsuite.preferences.menulastselected["servos"] == nil then neuronsuite.preferences.menulastselected["servos"] = 1 end

    for pidx, pvalue in ipairs(servoTable) do

        if pvalue.disabled ~= true then

            if pvalue.section == "swash" and lc == 0 then
                local headerLine = form.addLine("")
                local headerLineText = form.addStaticText(headerLine, {x = 0, y = neuronsuite.app.radio.linePaddingTop, w = neuronsuite.app.lcdWidth, h = neuronsuite.app.radio.navbuttonHeight}, headerLineText())
            end

            if pvalue.section == "tail" then
                local headerLine = form.addLine("")
                local headerLineText = form.addStaticText(headerLine, {x = 0, y = neuronsuite.app.radio.linePaddingTop, w = neuronsuite.app.lcdWidth, h = neuronsuite.app.radio.navbuttonHeight}, i18n("app.modules.servos.tail"))
            end

            if pvalue.section == "other" then
                local headerLine = form.addLine("")
                local headerLineText = form.addStaticText(headerLine, {x = 0, y = neuronsuite.app.radio.linePaddingTop, w = neuronsuite.app.lcdWidth, h = neuronsuite.app.radio.navbuttonHeight}, i18n("app.modules.servos.tail"))
            end

            if lc == 0 then
                if neuronsuite.preferences.general.iconsize == 0 then y = form.height() + neuronsuite.app.radio.buttonPaddingSmall end
                if neuronsuite.preferences.general.iconsize == 1 then y = form.height() + neuronsuite.app.radio.buttonPaddingSmall end
                if neuronsuite.preferences.general.iconsize == 2 then y = form.height() + neuronsuite.app.radio.buttonPadding end
            end

            if lc >= 0 then bx = (buttonW + padding) * lc end

            if neuronsuite.preferences.general.iconsize ~= 0 then
                if neuronsuite.app.gfx_buttons["servos"][pidx] == nil then neuronsuite.app.gfx_buttons["servos"][pidx] = lcd.loadMask("app/modules/servos/gfx/" .. pvalue.image) end
            else
                neuronsuite.app.gfx_buttons["servos"][pidx] = nil
            end

            neuronsuite.app.formFields[pidx] = form.addButton(nil, {x = bx, y = y, w = buttonW, h = buttonH}, {
                text = pvalue.title,
                icon = neuronsuite.app.gfx_buttons["servos"][pidx],
                options = FONT_S,
                paint = function()
                end,
                press = function()
                    neuronsuite.preferences.menulastselected["servos"] = pidx
                    neuronsuite.currentServoIndex = pidx
                    neuronsuite.app.ui.progressDisplay()
                    neuronsuite.app.ui.openPage(pidx, pvalue.title, "servos/servos_tool.lua", servoTable)
                end
            })

            if pvalue.disabled == true then neuronsuite.app.formFields[pidx]:enable(false) end

            if neuronsuite.preferences.menulastselected["servos"] == pidx then neuronsuite.app.formFields[pidx]:focus() end

            lc = lc + 1

            if lc == numPerRow then lc = 0 end
        end
    end

    neuronsuite.app.triggers.closeProgressLoader = true
    collectgarbage()
    return
end

local function getServoCount(callback, callbackParam)
    local message = {
        command = 120, -- MSP_SERVO_CONFIGURATIONS
        processReply = function(self, buf)
            local servoCount = neuronsuite.tasks.msp.mspHelper.readU8(buf)

            -- update master one in case changed
            neuronsuite.session.servoCountNew = servoCount

            if callback then callback(callbackParam) end
        end,
        -- 2 servos
        -- simulatorResponse = {
        --        2,
        --        220, 5, 68, 253, 188, 2, 244, 1, 244, 1, 77, 1, 0, 0, 0, 0,
        --        221, 5, 68, 253, 188, 2, 244, 1, 244, 1, 77, 1, 0, 0, 0, 0
        -- }
        -- 4 servos
        simulatorResponse = {4, 180, 5, 12, 254, 244, 1, 244, 1, 244, 1, 144, 0, 0, 0, 1, 0, 160, 5, 12, 254, 244, 1, 244, 1, 244, 1, 144, 0, 0, 0, 1, 0, 14, 6, 12, 254, 244, 1, 244, 1, 244, 1, 144, 0, 0, 0, 0, 0, 120, 5, 212, 254, 44, 1, 244, 1, 244, 1, 77, 1, 0, 0, 0, 0}
    }
    neuronsuite.tasks.msp.mspQueue:add(message)
end

local function openPageInit(pidx, title, script)

    if neuronsuite.session.servoCount ~= nil then
        buildServoTable()
        openPage(pidx, title, script)
    else
        local message = {
            command = 120, -- MSP_SERVO_CONFIGURATIONS
            processReply = function(self, buf)
                if #buf >= 10 then
                    local servoCount = neuronsuite.tasks.msp.mspHelper.readU8(buf)

                    -- update master one in case changed
                    neuronsuite.session.servoCount = servoCount
                end
            end,
            simulatorResponse = {4, 180, 5, 12, 254, 244, 1, 244, 1, 244, 1, 144, 0, 0, 0, 1, 0, 160, 5, 12, 254, 244, 1, 244, 1, 244, 1, 144, 0, 0, 0, 1, 0, 14, 6, 12, 254, 244, 1, 244, 1, 244, 1, 144, 0, 0, 0, 0, 0, 120, 5, 212, 254, 44, 1, 244, 1, 244, 1, 77, 1, 0, 0, 0, 0}
        }
        neuronsuite.tasks.msp.mspQueue:add(message)

        local message = {
            command = 192, -- MSP_SERVO_OVERIDE
            processReply = function(self, buf)
                if #buf >= 10 then

                    for i = 0, neuronsuite.session.servoCount do
                        buf.offset = i
                        local servoOverride = neuronsuite.tasks.msp.mspHelper.readU8(buf)
                        if servoOverride == 0 then
                            neuronsuite.utils.log("Servo override: true","debug")
                            neuronsuite.session.servoOverride = true
                        end
                    end
                end
                if neuronsuite.session.servoOverride == nil then neuronsuite.session.servoOverride = false end
            end,
            simulatorResponse = {209, 7, 209, 7, 209, 7, 209, 7, 209, 7, 209, 7, 209, 7, 209, 7}
        }
        neuronsuite.tasks.msp.mspQueue:add(message)

    end
end

local function event(widget, category, value, x, y)


end

local function onToolMenu(self)

    local buttons
    if neuronsuite.session.servoOverride == false then
        buttons = {{
            label = i18n("app.btn_ok_long"),
            action = function()

                -- we cant launch the loader here to se rely on the modules
                -- wakeup function to do this
                triggerOverRide = true
                triggerOverRideAll = true
                return true
            end
        }, {
            label = "CANCEL",
            action = function()
                return true
            end
        }}
    else
        buttons = {{
            label = i18n("app.btn_ok_long"),
            action = function()

                -- we cant launch the loader here to se rely on the modules
                -- wakeup function to do this
                triggerOverRide = true
                return true
            end
        }, {
            label = i18n("app.btn_cancel"),
            action = function()
                return true
            end
        }}
    end
    local message
    local title
    if neuronsuite.session.servoOverride == false then
        title = i18n("app.modules.servos.enable_servo_override")
        message = i18n("app.modules.servos.enable_servo_override_msg")
    else
        title = i18n("app.modules.servos.disable_servo_override")
        message = i18n("app.modules.servos.disable_servo_override_msg")
    end

    form.openDialog({
        width = nil,
        title = title,
        message = message,
        buttons = buttons,
        wakeup = function()
        end,
        paint = function()
        end,
        options = TEXT_LEFT
    })

end

local function wakeup()
    if triggerOverRide == true then
        triggerOverRide = false

        if neuronsuite.session.servoOverride == false then
            neuronsuite.app.audio.playServoOverideEnable = true
            neuronsuite.app.ui.progressDisplay(i18n("app.modules.servos.servo_override"), i18n("app.modules.servos.enabling_servo_override"))
            neuronsuite.app.Page.servoCenterFocusAllOn(self)
            neuronsuite.session.servoOverride = true
        else
            neuronsuite.app.audio.playServoOverideDisable = true
            neuronsuite.app.ui.progressDisplay(i18n("app.modules.servos.servo_override"), i18n("app.modules.servos.disabling_servo_override"))
            neuronsuite.app.Page.servoCenterFocusAllOff(self)
            neuronsuite.session.servoOverride = false
        end
    end

    local now = os.clock()
    if ((now - lastServoCountTime) >= 2) and neuronsuite.tasks.msp.mspQueue:isProcessed() then
        lastServoCountTime = now

        getServoCount()

        if neuronsuite.session.servoCountNew ~= nil then if neuronsuite.session.servoCountNew ~= neuronsuite.session.servoCount then neuronsuite.app.triggers.triggerReloadNoPrompt = true end end

    end

end

local function servoCenterFocusAllOn(self)

    neuronsuite.app.audio.playServoOverideEnable = true

    for i = 0, #servoTable do
        local message = {
            command = 193, -- MSP_SET_SERVO_OVERRIDE
            payload = {i}
        }
        neuronsuite.tasks.msp.mspHelper.writeU16(message.payload, 0)
        neuronsuite.tasks.msp.mspQueue:add(message)
    end
    neuronsuite.app.triggers.isReady = true
    neuronsuite.app.triggers.closeProgressLoader = true
end

local function servoCenterFocusAllOff(self)

    for i = 0, #servoTable do
        local message = {
            command = 193, -- MSP_SET_SERVO_OVERRIDE
            payload = {i}
        }
        neuronsuite.tasks.msp.mspHelper.writeU16(message.payload, 2001)
        neuronsuite.tasks.msp.mspQueue:add(message)
    end
    neuronsuite.app.triggers.isReady = true
    neuronsuite.app.triggers.closeProgressLoader = true
end

local function onNavMenu(self)

    if neuronsuite.session.servoOverride == true or inFocus == true then
        neuronsuite.app.audio.playServoOverideDisable = true
        neuronsuite.session.servoOverride = false
        inFocus = false
        neuronsuite.app.ui.progressDisplay(i18n("app.modules.servos.servo_override"), i18n("app.modules.servos.disabling_servo_override"))
        neuronsuite.app.Page.servoCenterFocusAllOff(self)
        neuronsuite.app.triggers.closeProgressLoader = true
    end
    -- neuronsuite.app.ui.progressDisplay()
    if  neuronsuite.app.lastMenu == nil then
        neuronsuite.app.ui.openMainMenu()
    else
        neuronsuite.app.ui.openMainMenuSub(neuronsuite.app.lastMenu)
    end

end

local function onReloadMenu()
    neuronsuite.app.triggers.triggerReloadFull = true
end

-- not changing to custom api at present due to complexity of read/write scenario in these modules
return {
    event = event,
    openPage = openPageInit,
    onToolMenu = onToolMenu,
    onNavMenu = onNavMenu,
    servoCenterFocusAllOn = servoCenterFocusAllOn,
    servoCenterFocusAllOff = servoCenterFocusAllOff,
    wakeup = wakeup,
    navButtons = {
        menu = true,
        save = false,
        reload = true,
        tool = true,
        help = true
    },
    onReloadMenu = onReloadMenu,    
    API = {},
}
