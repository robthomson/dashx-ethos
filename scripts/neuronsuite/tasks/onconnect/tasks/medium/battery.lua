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

local battery = {}

local mspCallMade = false

function battery.wakeup()
    -- quick exit if no apiVersion
    if neuronsuite.session.apiVersion == nil then return end    

    if (neuronsuite.session.batteryConfig == nil) and mspCallMade == false then
        mspCallMade = true

        local API = neuronsuite.tasks.msp.api.load("BATTERY_CONFIG")
        API.setCompleteHandler(function(self, buf)
            local batteryCapacity = API.readValue("batteryCapacity")
            local batteryCellCount = API.readValue("batteryCellCount")
            local vbatwarningcellvoltage = API.readValue("vbatwarningcellvoltage")/100
            local vbatmincellvoltage = API.readValue("vbatmincellvoltage")/100
            local vbatmaxcellvoltage = API.readValue("vbatmaxcellvoltage")/100
            local vbatfullcellvoltage = API.readValue("vbatfullcellvoltage")/100
            local lvcPercentage = API.readValue("lvcPercentage")
            local consumptionWarningPercentage = API.readValue("consumptionWarningPercentage")

            neuronsuite.session.batteryConfig = {}
            neuronsuite.session.batteryConfig.batteryCapacity = batteryCapacity
            neuronsuite.session.batteryConfig.batteryCellCount = batteryCellCount
            neuronsuite.session.batteryConfig.vbatwarningcellvoltage = vbatwarningcellvoltage
            neuronsuite.session.batteryConfig.vbatmincellvoltage = vbatmincellvoltage
            neuronsuite.session.batteryConfig.vbatmaxcellvoltage = vbatmaxcellvoltage
            neuronsuite.session.batteryConfig.vbatfullcellvoltage = vbatfullcellvoltage
            neuronsuite.session.batteryConfig.lvcPercentage = lvcPercentage
            neuronsuite.session.batteryConfig.consumptionWarningPercentage = consumptionWarningPercentage
            -- we also get a volage scale factor stored in this table - but its in pilot config

            neuronsuite.utils.log("Capacity: " .. batteryCapacity .. "mAh","info")
            neuronsuite.utils.log("Cell Count: " .. batteryCellCount,"info")
            neuronsuite.utils.log("Warning Voltage: " .. vbatwarningcellvoltage .. "V","info")
            neuronsuite.utils.log("Min Voltage: " .. vbatmincellvoltage .. "V","info")
            neuronsuite.utils.log("Max Voltage: " .. vbatmaxcellvoltage .. "V","info")
            neuronsuite.utils.log("Full Cell Voltage: " .. vbatfullcellvoltage .. "V", "info")
            neuronsuite.utils.log("LVC Percentage: " .. lvcPercentage .. "%","info")
            neuronsuite.utils.log("Consumption Warning Percentage: " .. consumptionWarningPercentage .. "%","info")
            neuronsuite.utils.log("Battery Config Complete","info")
        end)
        API.setUUID("a3f9c2b4-5d7e-4e8a-9c3b-2f6d8e7a1b2d")
        API.read()
    end    

end

function battery.reset()
    neuronsuite.session.batteryConfig = nil
    mspCallMade = false
end

function battery.isComplete()
    if neuronsuite.session.batteryConfig ~= nil then
        return true
    end
end

return battery