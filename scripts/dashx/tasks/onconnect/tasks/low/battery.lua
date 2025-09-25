--[[
 * Copyright (C) neurondash Project
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
    if neurondash.session.apiVersion == nil then return end    

    if (neurondash.session.batteryConfig == nil and neurondash.session.mcu_id ) then



            local modelpref_file = "SCRIPTS:/" .. neurondash.config.preferences .. "/models/" .. neurondash.session.mcu_id ..".ini"


            os.mkdir("SCRIPTS:/" .. neurondash.config.preferences)
            os.mkdir("SCRIPTS:/" .. neurondash.config.preferences .. "/models")
            local master_ini  = neurondash.ini.load_ini_file(modelpref_file) or {}
            local preferences = master_ini.battery or {}



            neurondash.session.batteryConfig = {}
            neurondash.session.batteryConfig.batteryCapacity = preferences.batteryCapacity 
            neurondash.session.batteryConfig.batteryCellCount = preferences.batteryCellCount
            neurondash.session.batteryConfig.vbatwarningcellvoltage = preferences.vbatwarningcellvoltage/10
            neurondash.session.batteryConfig.vbatmincellvoltage = preferences.vbatmincellvoltage/10
            neurondash.session.batteryConfig.vbatmaxcellvoltage = preferences.vbatmaxcellvoltage/10
            neurondash.session.batteryConfig.vbatfullcellvoltage = preferences.vbatfullcellvoltage/10
            neurondash.session.batteryConfig.lvcPercentage = preferences.lvcPercentage
            neurondash.session.batteryConfig.consumptionWarningPercentage = preferences.consumptionWarningPercentage



    end    

end

function battery.reset()
    neurondash.session.batteryConfig = nil
end

function battery.isComplete()
    if neurondash.session.batteryConfig ~= nil then
        return true
    end
end

return battery