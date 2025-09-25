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

local modelpreferences = {}

local modelpref_defaults ={
    dashboard = {
        theme_preflight = "nil",
        theme_inflight = "nil",
        theme_postflight = "nil",
    },
    general ={
        flightcount = 0,
        totalflighttime = 0,
        lastflighttime = 0,
    },
    model = {
        armswitch = false,
        inflightswitch = false,
        inflightswitch_delay = 10,
        rateswitch = false,
    },
    battery = {
            calc_local = 0,
            batteryCapacity = 2200,
            batteryCellCount = 3,
            vbatwarningcellvoltage = 35,
            vbatmincellvoltage = 33,
            vbatmaxcellvoltage = 43,
            vbatfullcellvoltage = 41,
            lvcPercentage = 30,
            consumptionWarningPercentage = 30   
    }
}

function modelpreferences.wakeup()

    -- quick exit if no apiVersion
    if dashx.session.apiVersion == nil then return end    

    --- check if we have a mcu_id
    if not dashx.session.mcu_id then
        return
    end
  

    if (dashx.session.modelPreferences == nil)  then
             -- populate the model preferences variable

        if dashx.config.preferences and dashx.session.mcu_id then

            local modelpref_file = "SCRIPTS:/" .. dashx.config.preferences .. "/models/" .. dashx.session.mcu_id ..".ini"
            dashx.utils.log("Preferences file: " .. modelpref_file, "info")

            os.mkdir("SCRIPTS:/" .. dashx.config.preferences)
            os.mkdir("SCRIPTS:/" .. dashx.config.preferences .. "/models")


            local slave_ini = modelpref_defaults
            local master_ini  = dashx.ini.load_ini_file(modelpref_file) or {}


            local updated_ini = dashx.ini.merge_ini_tables(master_ini, slave_ini)
            dashx.session.modelPreferences = updated_ini
            dashx.session.modelPreferencesFile = modelpref_file

            if not dashx.ini.ini_tables_equal(master_ini, slave_ini) then
                dashx.ini.save_ini_file(modelpref_file, updated_ini)
            end      
                   
        end
    end

end

function modelpreferences.reset()
    dashx.session.modelPreferences = nil
end

function modelpreferences.isComplete()
    if dashx.session.modelPreferences ~= nil  then
        return true
    end
end

return modelpreferences