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
        batterylocalcalculation = 1,
    },
    battery = {
        sag_multiplier = 0.5,
        calc_local = 0,
        alert_type = 0,
        becalertvalue = 6.5,
        rxalertvalue = 7.5,
        flighttime = 300,
    }
}

function modelpreferences.wakeup()

    -- quick exit if no apiVersion
    if neuronsuite.session.apiVersion == nil then
        neuronsuite.session.modelPreferences = nil 
        return 
    end    

    --- check if we have a mcu_id
    if not neuronsuite.session.mcu_id then
        neuronsuite.session.modelPreferences = nil
        return
    end
  

    if (neuronsuite.session.modelPreferences == nil)  then
             -- populate the model preferences variable

        if neuronsuite.config.preferences and neuronsuite.session.mcu_id then

            local modelpref_file = "SCRIPTS:/" .. neuronsuite.config.preferences .. "/models/" .. neuronsuite.session.mcu_id ..".ini"
            neuronsuite.utils.log("Preferences file: " .. modelpref_file, "info")

            os.mkdir("SCRIPTS:/" .. neuronsuite.config.preferences)
            os.mkdir("SCRIPTS:/" .. neuronsuite.config.preferences .. "/models")


            local slave_ini = modelpref_defaults
            local master_ini  = neuronsuite.ini.load_ini_file(modelpref_file) or {}


            local updated_ini = neuronsuite.ini.merge_ini_tables(master_ini, slave_ini)
            neuronsuite.session.modelPreferences = updated_ini
            neuronsuite.session.modelPreferencesFile = modelpref_file

            if not neuronsuite.ini.ini_tables_equal(master_ini, slave_ini) then
                neuronsuite.ini.save_ini_file(modelpref_file, updated_ini)
            end      
                   
        end
    end

end

function modelpreferences.reset()
    neuronsuite.session.modelPreferences = nil
    neuronsuite.session.modelPreferencesFile = nil
end

function modelpreferences.isComplete()
    if neuronsuite.session.modelPreferences ~= nil  then
        return true
    end
end

return modelpreferences