--[[
 * Copyright (C) Rotorflight Project
 *
 *
 * License GPLv3: https://www.gnu.org/licenses/gpl-3.0.en.html
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 
 * Note.  Some icons have been sourced from https://www.flaticon.com/
 * 

]] --
local fields = {}
local labels = {}
local fcStatus = {}
local dataflashSummary = {}
local wakeupScheduler = os.clock()
local status = {}
local summary = {}
local triggerEraseDataFlash = false
local enableWakeup = false
local i18n = neuronsuite.i18n.get
local displayType = 0
local disableType = false

local w, h = lcd.getWindowSize()
local buttonW = 100
local buttonWs = buttonW - (buttonW * 20) / 100
local x = w - 15

local displayPos = {x = x - buttonW - buttonWs - 5 - buttonWs, y = neuronsuite.app.radio.linePaddingTop, w = 200, h = neuronsuite.app.radio.navbuttonHeight}


local apidata = {
    api = {
        [1] = nil,
    },
    formdata = {
        labels = {
        },
        fields = {
            {t = i18n("app.modules.fblstatus.arming_flags"), value = "-", type = displayType, disable = disableType, position = displayPos},
            {t = i18n("app.modules.fblstatus.dataflash_free_space"), value = "-", type = displayType, disable = disableType, position = displayPos},
            {t = i18n("app.modules.fblstatus.real_time_load"), value = "-", type = displayType, disable = disableType, position = displayPos},
            {t = i18n("app.modules.fblstatus.cpu_load"), value = "-", type = displayType, disable = disableType, position = displayPos}
        }
    }                 
}

local function getStatus()
    local message = {
        command = 101, -- MSP_STATUS
        processReply = function(self, buf)

            buf.offset = 12
            status.realTimeLoad = neuronsuite.tasks.msp.mspHelper.readU16(buf)
            status.cpuLoad = neuronsuite.tasks.msp.mspHelper.readU16(buf)
            buf.offset = 18
            status.armingDisableFlags = neuronsuite.tasks.msp.mspHelper.readU32(buf)
            buf.offset = 24
            status.profile = neuronsuite.tasks.msp.mspHelper.readU8(buf)
            buf.offset = 26
            status.rateProfile = neuronsuite.tasks.msp.mspHelper.readU8(buf)


        end,
        simulatorResponse = {240, 1, 124, 0, 35, 0, 0, 0, 0, 0, 0, 224, 1, 10, 1, 0, 26, 0, 0, 0, 0, 0, 2, 0, 6, 0, 6, 1, 4, 1}
    }

    neuronsuite.tasks.msp.mspQueue:add(message)
end

local function getDataflashSummary()
    local message = {
        command = 70, -- MSP_DATAFLASH_SUMMARY
        processReply = function(self, buf)

            local flags = neuronsuite.tasks.msp.mspHelper.readU8(buf)
            summary.ready = (flags & 1) ~= 0
            summary.supported = (flags & 2) ~= 0
            summary.sectors = neuronsuite.tasks.msp.mspHelper.readU32(buf)
            summary.totalSize = neuronsuite.tasks.msp.mspHelper.readU32(buf)
            summary.usedSize = neuronsuite.tasks.msp.mspHelper.readU32(buf)

        end,
        simulatorResponse = {3, 1, 0, 0, 0, 0, 4, 0, 0, 0, 3, 0, 0}
    }
    neuronsuite.tasks.msp.mspQueue:add(message)
end

local function eraseDataflash()
    local message = {
        command = 72, -- MSP_DATAFLASH_ERASE
        processReply = function(self, buf)

            summary = {}

            -- blank out vars so that we actually are aware that it updated
            neuronsuite.app.formFields[1]:value("")
            neuronsuite.app.formFields[2]:value("")
            neuronsuite.app.formFields[3]:value("")
            neuronsuite.app.formFields[4]:value("")
        end,
        simulatorResponse = {}
    }
    neuronsuite.tasks.msp.mspQueue:add(message)
end

local function postLoad(self)

    getStatus()
    getDataflashSummary()
    neuronsuite.app.triggers.isReady = true
    enableWakeup = true

    neuronsuite.app.triggers.closeProgressLoader = true
end

local function postRead(self)
    neuronsuite.utils.log("postRead","debug")
end

local function getFreeDataflashSpace()
    if not summary.supported then return i18n("app.modules.fblstatus.unsupported") end
    local freeSpace = summary.totalSize - summary.usedSize
    return string.format("%.1f " .. i18n("app.modules.fblstatus.megabyte"), freeSpace / (1024 * 1024))
end

local function wakeup()

    -- prevent wakeup running until after initialised
    if enableWakeup == false then return end

    if triggerEraseDataFlash == true then
        neuronsuite.app.audio.playEraseFlash = true
        triggerEraseDataFlash = false

        neuronsuite.app.ui.progressDisplay(i18n("app.modules.fblstatus.erasing"), i18n("app.modules.fblstatus.erasing_dataflash"))
        neuronsuite.app.Page.eraseDataflash()
        neuronsuite.app.triggers.isReady = true
    end

    if triggerEraseDataFlash == false then
        local now = os.clock()
        if (now - wakeupScheduler) >= 2 then
            wakeupScheduler = now
            firstRun = false
            if neuronsuite.tasks.msp.mspQueue:isProcessed() then

                getStatus()
                getDataflashSummary()

                if status.armingDisableFlags ~= nil then
                    local value = neuronsuite.utils.armingDisableFlagsToString(status.armingDisableFlags)
                    neuronsuite.app.formFields[1]:value(value)
                end

                if summary.supported == true then
                    local value = getFreeDataflashSpace()
                    neuronsuite.app.formFields[2]:value(value)
                end

                if status.realTimeLoad ~= nil then
                    local value = math.floor(status.realTimeLoad / 10)
                    neuronsuite.app.formFields[3]:value(tostring(value) .. "%")
                    if value >= 60 then neuronsuite.app.formFields[4]:color(RED) end
                end
                if status.cpuLoad ~= nil then
                    local value = status.cpuLoad / 10
                    neuronsuite.app.formFields[4]:value(tostring(value) .. "%")
                    if value >= 60 then neuronsuite.app.formFields[4]:color(RED) end
                end

            end
        end
        if (now - wakeupScheduler) >= 1 then
            neuronsuite.app.triggers.closeProgressLoader = true
        end
    end

end

local function onToolMenu(self)

    local buttons = {{
        label = i18n("app.btn_ok_long"),
        action = function()

            -- we cant launch the loader here to se rely on the modules
            -- wakup function to do this
            triggerEraseDataFlash = true
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

    title = i18n("app.modules.fblstatus.erase")
    message = i18n("app.modules.fblstatus.erase_prompt")

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

local function event(widget, category, value, x, y)
    -- if close event detected go to section home page
    if category == EVT_CLOSE and value == 0 or value == 35 then
        neuronsuite.app.ui.openPage(
            pageIdx,
            i18n("app.modules.diagnostics.name"),
            "diagnostics/diagnostics.lua"
        )
        return true
    end
end


local function onNavMenu()
    neuronsuite.app.ui.progressDisplay(nil,nil,true)
    neuronsuite.app.ui.openPage(
        pageIdx,
        i18n("app.modules.diagnostics.name"),
        "diagnostics/diagnostics.lua"
    )
end

return {
    apidata = apidata,
    reboot = false,
    eepromWrite = false,
    minBytes = 0,
    wakeup = wakeup,
    refreshswitch = false,
    simulatorResponse = {},
    postLoad = postLoad,
    postRead = postRead,
    eraseDataflash = eraseDataflash,
    onToolMenu = onToolMenu,
    onNavMenu = onNavMenu,
    event = event,
    navButtons = {
        menu = true,
        save = false,
        reload = false,
        tool = true,
        help = false
    },
    API = {},
}
