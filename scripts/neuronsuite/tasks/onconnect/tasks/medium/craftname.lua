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

local craftname = {}

local mspCallMade = false

function craftname.wakeup()
    -- quick exit if no apiVersion
    if neuronsuite.session.apiVersion == nil then return end    

    if (neuronsuite.session.craftName == nil) and (mspCallMade == false) then
        mspCallMade = true
        local API = neuronsuite.tasks.msp.api.load("NAME")
        API.setCompleteHandler(function(self, buf)
            neuronsuite.session.craftName = API.readValue("name")
            if neuronsuite.preferences.general.syncname == true and model.name and neuronsuite.session.craftName ~= nil then
                neuronsuite.utils.log("Setting model name to: " .. neuronsuite.session.craftName, "info")
                model.name(neuronsuite.session.craftName)
                lcd.invalidate()
            end
            if neuronsuite.session.craftName and neuronsuite.session.craftName ~= "" then
                neuronsuite.utils.log("Craft name: " .. neuronsuite.session.craftName, "info")
            else
                neuronsuite.session.craftName = model.name()    
            end
        end)
        API.setUUID("37163617-1486-4886-8b81-6a1dd6d7edd1")
        API.read()
    end     

end

function craftname.reset()
    neuronsuite.session.craftName = nil
    mspCallMade = false
end

function craftname.isComplete()
    if neuronsuite.session.craftName ~= nil then
        return true
    end
end

return craftname