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
local version = neuronsuite.version().version
local ethosVersion = neuronsuite.config.environment.major .. "." .. neuronsuite.config.environment.minor .. "." .. neuronsuite.config.environment.revision
local apiVersion = neuronsuite.session.apiVersion
local fcVersion = neuronsuite.session.fcVersion 
local rfVersion = neuronsuite.session.rfVersion
local mspTransport = (neuronsuite.tasks and neuronsuite.tasks.msp and neuronsuite.tasks.msp.protocol and neuronsuite.tasks.msp.protocol.mspProtocol) or "-"
local closeProgressLoader = true
local simulation

local i18n = neuronsuite.i18n.get

local supportedMspVersion = ""
for i, v in ipairs(neuronsuite.config.supportedMspApiVersion) do
    if i == 1 then
        supportedMspVersion = v
    else
        supportedMspVersion = supportedMspVersion .. "," .. v
    end
end

if system.getVersion().simulation == true then
    simulation = "ON"
else
    simulation = "OFF"
end

local displayType = 0
local disableType = false
local displayPos
local w, h = lcd.getWindowSize()
local buttonW = 100
local buttonWs = buttonW - (buttonW * 20) / 100
local x = w - 15

displayPos = {x = x - buttonW - buttonWs - 5 - buttonWs, y = neuronsuite.app.radio.linePaddingTop, w = 300, h = neuronsuite.app.radio.navbuttonHeight}


local apidata = {
    api = {
        [1] = nil,
    },
    formdata = {
        labels = {
        },
        fields = {
            {t = i18n("app.modules.info.version"), value = version, type = displayType, disable = disableType, position = displayPos},
            {t = i18n("app.modules.info.ethos_version"), value = ethosVersion, type = displayType, disable = disableType, position = displayPos},
            {t = i18n("app.modules.info.rf_version"), value = rfVersion, type = displayType, disable = disableType, position = displayPos},
            {t = i18n("app.modules.info.fc_version"), value = fcVersion, type = displayType, disable = disableType, position = displayPos},
            {t = i18n("app.modules.info.msp_version"), value = apiVersion, type = displayType, disable = disableType, position = displayPos},
            {t = i18n("app.modules.info.msp_transport"), value = string.upper(mspTransport), type = displayType, disable = disableType, position = displayPos},
            {t = i18n("app.modules.info.supported_versions"), value = supportedMspVersion, type = displayType, disable = disableType, position = displayPos},
            {t = i18n("app.modules.info.simulation"), value = simulation, type = displayType, disable = disableType, position = displayPos}
        }
    }
}

local function wakeup()
    if closeProgressLoader == false then
        neuronsuite.app.triggers.closeProgressLoader = true
        closeProgressLoader = true
    end    
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
    onNavMenu = onNavMenu,
    event = event,
    navButtons = {
        menu = true,
        save = false,
        reload = false,
        tool = false,
        help = false
    },
    API = {},
}
