--[[
 * Copyright (C) dashx Project
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

function battery.wakeup()
    -- quick exit if no apiVersion
    if dashx.session.apiVersion == nil then return end    

    if (dashx.session.batteryConfig == nil and dashx.session.mcu_id ) then



            local modelpref_file = "SCRIPTS:/" .. dashx.config.preferences .. "/models/" .. dashx.session.mcu_id ..".ini"


            os.mkdir("SCRIPTS:/" .. dashx.config.preferences)
            os.mkdir("SCRIPTS:/" .. dashx.config.preferences .. "/models")
            local master_ini  = dashx.ini.load_ini_file(modelpref_file) or {}
            local preferences = master_ini.battery or {}



            dashx.session.batteryConfig = {}
            dashx.session.batteryConfig.batteryCapacity = preferences.batteryCapacity 
            dashx.session.batteryConfig.batteryCellCount = preferences.batteryCellCount
            dashx.session.batteryConfig.vbatwarningcellvoltage = preferences.vbatwarningcellvoltage/10
            dashx.session.batteryConfig.vbatmincellvoltage = preferences.vbatmincellvoltage/10
            dashx.session.batteryConfig.vbatmaxcellvoltage = preferences.vbatmaxcellvoltage/10
            dashx.session.batteryConfig.vbatfullcellvoltage = preferences.vbatfullcellvoltage/10
            dashx.session.batteryConfig.lvcPercentage = preferences.lvcPercentage
            dashx.session.batteryConfig.consumptionWarningPercentage = preferences.consumptionWarningPercentage



    end    

end

function battery.reset()
    dashx.session.batteryConfig = nil
end

function battery.isComplete()
    if dashx.session.batteryConfig ~= nil then
        return true
    end
end

return battery