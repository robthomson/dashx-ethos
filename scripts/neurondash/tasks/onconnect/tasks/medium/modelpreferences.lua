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
        idleswitch = false,
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
    if neurondash.session.apiVersion == nil then return end    

    --- check if we have a mcu_id
    if not neurondash.session.mcu_id then
        return
    end
  

    if (neurondash.session.modelPreferences == nil)  then
             -- populate the model preferences variable

        if neurondash.config.preferences and neurondash.session.mcu_id then

            local modelpref_file = "SCRIPTS:/" .. neurondash.config.preferences .. "/models/" .. neurondash.session.mcu_id ..".ini"
            neurondash.utils.log("Preferences file: " .. modelpref_file, "info")

            os.mkdir("SCRIPTS:/" .. neurondash.config.preferences)
            os.mkdir("SCRIPTS:/" .. neurondash.config.preferences .. "/models")


            local slave_ini = modelpref_defaults
            local master_ini  = neurondash.ini.load_ini_file(modelpref_file) or {}


            local updated_ini = neurondash.ini.merge_ini_tables(master_ini, slave_ini)
            neurondash.session.modelPreferences = updated_ini
            neurondash.session.modelPreferencesFile = modelpref_file

            if not neurondash.ini.ini_tables_equal(master_ini, slave_ini) then
                neurondash.ini.save_ini_file(modelpref_file, updated_ini)
            end      
                   
        end
    end

end

function modelpreferences.reset()
    neurondash.session.modelPreferences = nil
end

function modelpreferences.isComplete()
    if neurondash.session.modelPreferences ~= nil  then
        return true
    end
end

return modelpreferences