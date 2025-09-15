local labels = {}
local fields = {}
local i18n = neuronsuite.i18n.get
local triggerOverRide = false
local inOverRide = false
local lastChangeTime = os.clock()
local currentRollTrim
local currentRollTrimLast
local currentPitchTrim
local currentPitchTrimLast
local currentCollectiveTrim
local currentCollectiveTrimLast
local currentYawTrim
local currentYawTrimLast
local currentIdleThrottleTrim
local currentIdleThrottleTrimLast
local clear2send = true


local apidata = {
    api = {
        [1] = "MIXER_CONFIG",
    },
    formdata = {
        labels = {
        },
        fields = {
            {t = i18n("app.modules.trim.roll_trim"),         mspapi = 1, apikey = "swash_trim_0"},
            {t = i18n("app.modules.trim.pitch_trim"),        mspapi = 1, apikey = "swash_trim_1"},
            {t = i18n("app.modules.trim.collective_trim"),   mspapi = 1, apikey = "swash_trim_2"},
            {t = i18n("app.modules.trim.tail_motor_idle"),   mspapi = 1, apikey = "tail_motor_idle", enablefunction = function() return (neuronsuite.session.tailMode >= 1) end},
            {t = i18n("app.modules.trim.yaw_trim"),          mspapi = 1, apikey = "tail_center_trim", enablefunction = function() return (neuronsuite.session.tailMode == 0) end }
        }
    }                 
}



local function saveData()
    clear2send = true
    neuronsuite.app.triggers.triggerSaveNoProgress = true
end

local function mixerOn(self)

    neuronsuite.app.audio.playMixerOverideEnable = true

    for i = 1, 4 do
        local message = {
            command = 191, -- MSP_SET_MIXER_OVERRIDE
            payload = {i}
        }

        neuronsuite.tasks.msp.mspHelper.writeU16(message.payload, 0)
        neuronsuite.tasks.msp.mspQueue:add(message)

        if neuronsuite.preferences.developer.logmsp then
            local logData = "mixerOn: {" .. neuronsuite.utils.joinTableItems(message.payload, ", ") .. "}"
            neuronsuite.utils.log(logData,"info")
        end

    end



    neuronsuite.app.triggers.isReady = true
    neuronsuite.app.triggers.closeProgressLoader = true
end

local function mixerOff(self)

    neuronsuite.app.audio.playMixerOverideDisable = true

    for i = 1, 4 do
        local message = {
            command = 191, -- MSP_SET_MIXER_OVERRIDE
            payload = {i}
        }
        neuronsuite.tasks.msp.mspHelper.writeU16(message.payload, 2501)
        neuronsuite.tasks.msp.mspQueue:add(message)

        if neuronsuite.preferences.developer.logmsp then
            local logData = "mixerOff: {" .. neuronsuite.utils.joinTableItems(message.payload, ", ") .. "}"
            neuronsuite.utils.log(logData,"info")
        end

    end



    neuronsuite.app.triggers.isReady = true
    neuronsuite.app.triggers.closeProgressLoader = true
end

local function postLoad(self)

    if neuronsuite.session.tailMode == nil then
        local v = neuronsuite.app.Page.values['MIXER_CONFIG']["tail_rotor_mode"]
        neuronsuite.session.tailMode = math.floor(v)
        neuronsuite.app.triggers.reload = true
        return
    end

    -- existing
    currentRollTrim = neuronsuite.app.Page.fields[1].value
    currentPitchTrim = neuronsuite.app.Page.fields[2].value
    currentCollectiveTrim = neuronsuite.app.Page.fields[3].value

    if neuronsuite.session.tailModeActive == 1 or neuronsuite.session.tailModeActive == 2 then currentIdleThrottleTrim = neuronsuite.app.Page.fields[4].value end

    if neuronsuite.session.tailModeActive == 0 then currentYawTrim = neuronsuite.app.Page.fields[4].value end
    neuronsuite.app.triggers.closeProgressLoader = true
end

local function wakeup(self)

    -- filter changes to mixer - essentially preventing queue getting flooded	
    if inOverRide == true then

        currentRollTrim = neuronsuite.app.Page.fields[1].value
        local now = os.clock()
        local settleTime = 0.85
        if ((now - lastChangeTime) >= settleTime) and neuronsuite.tasks.msp.mspQueue:isProcessed() and clear2send == true then
            if currentRollTrim ~= currentRollTrimLast then
                currentRollTrimLast = currentRollTrim
                lastChangeTime = now
                neuronsuite.utils.log("save trim","debug")
                self.saveData(self)
            end
        end

        currentPitchTrim = neuronsuite.app.Page.fields[2].value
        local now = os.clock()
        local settleTime = 0.85
        if ((now - lastChangeTime) >= settleTime) and neuronsuite.tasks.msp.mspQueue:isProcessed() and clear2send == true then
            if currentPitchTrim ~= currentPitchTrimLast then
                currentPitchTrimLast = currentPitchTrim
                lastChangeTime = now
                self.saveData(self)
            end
        end

        currentCollectiveTrim = neuronsuite.app.Page.fields[3].value
        local now = os.clock()
        local settleTime = 0.85
        if ((now - lastChangeTime) >= settleTime) and neuronsuite.tasks.msp.mspQueue:isProcessed() and clear2send == true then
            if currentCollectiveTrim ~= currentCollectiveTrimLast then
                currentCollectiveTrimLast = currentCollectiveTrim
                lastChangeTime = now
                self.saveData(self)
            end
        end

        if neuronsuite.session.tailMode == 1 or neuronsuite.session.tailMode == 2 then
            currentIdleThrottleTrim = neuronsuite.app.Page.fields[4].value
            local now = os.clock()
            local settleTime = 0.85
            if ((now - lastChangeTime) >= settleTime) and neuronsuite.tasks.msp.mspQueue:isProcessed() and clear2send == true then
                if currentIdleThrottleTrim ~= currentIdleThrottleTrimLast then
                    currentIdleThrottleTrimLast = currentIdleThrottleTrim
                    lastChangeTime = now
                    self.saveData(self)
                end
            end
        end

        if neuronsuite.session.tailMode == 0 then
            currentYawTrim = neuronsuite.app.Page.fields[4].value
            local now = os.clock()
            local settleTime = 0.85
            if ((now - lastChangeTime) >= settleTime) and neuronsuite.tasks.msp.mspQueue:isProcessed() then
                if currentYawTrim ~= currentYawTrimLast then
                    currentYawTrimLast = currentYawTrim
                    lastChangeTime = now
                    self.saveData(self)
                end
            end
        end

    end

    if triggerOverRide == true then
        triggerOverRide = false

        if inOverRide == false then

            neuronsuite.app.audio.playMixerOverideEnable = true

            neuronsuite.app.ui.progressDisplay(i18n("app.modules.trim.mixer_override"), i18n("app.modules.trim.mixer_override_enabling"))

            neuronsuite.app.Page.mixerOn(self)
            inOverRide = true
        else

            neuronsuite.app.audio.playMixerOverideDisable = true

            neuronsuite.app.ui.progressDisplay(i18n("app.modules.trim.mixer_override"), i18n("app.modules.trim.mixer_override_disabling"))

            neuronsuite.app.Page.mixerOff(self)
            inOverRide = false
        end
    end

end

local function onToolMenu(self)

    local buttons = {{
        label = i18n("app.btn_ok"),
        action = function()

            -- we cant launch the loader here to se rely on the modules
            -- wakup function to do this
            triggerOverRide = true
            return true
        end
    }, {
        label = i18n("app.btn_cancel"),
        action = function()
            return true
        end
    }}
    local message
    local title
    if inOverRide == false then
        title = i18n("app.modules.trim.enable_mixer_override")
        message = i18n("app.modules.trim.enable_mixer_message")
    else
        title = i18n("app.modules.trim.disable_mixer_override")
        message = i18n("app.modules.trim.disable_mixer_message")
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

local function onNavMenu(self)

    if inOverRide == true or inFocus == true then
        neuronsuite.app.audio.playMixerOverideDisable = true

        inOverRide = false
        inFocus = false

        neuronsuite.app.ui.progressDisplay(i18n("app.modules.trim.mixer_override"), i18n("app.modules.trim.mixer_override_disabling"))

        mixerOff(self)
        neuronsuite.app.triggers.closeProgressLoader = true
    end

    if  neuronsuite.app.lastMenu == nil then
        neuronsuite.app.ui.openMainMenu()
    else
        neuronsuite.app.ui.openMainMenuSub(neuronsuite.app.lastMenu)
    end

end

return {
    apidata = apidata,
    eepromWrite = true,
    reboot = false,
    mixerOff = mixerOff,
    mixerOn = mixerOn,
    postLoad = postLoad,
    onToolMenu = onToolMenu,
    onNavMenu = onNavMenu,
    wakeup = wakeup,
    saveData = saveData,
    navButtons = {
        menu = true,
        save = true,
        reload = true,
        tool = true,
        help = true
    },
    API = {},
}
