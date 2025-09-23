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

    if (neurondash.session.batteryConfig == nil) then


            neurondash.session.batteryConfig = {}
            neurondash.session.batteryConfig.batteryCapacity = 750
            neurondash.session.batteryConfig.batteryCellCount = 3
            neurondash.session.batteryConfig.vbatwarningcellvoltage = 3.5
            neurondash.session.batteryConfig.vbatmincellvoltage = 3.3
            neurondash.session.batteryConfig.vbatmaxcellvoltage = 4.3
            neurondash.session.batteryConfig.vbatfullcellvoltage = 4.1
            neurondash.session.batteryConfig.lvcPercentage = 30
            neurondash.session.batteryConfig.consumptionWarningPercentage = 30

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