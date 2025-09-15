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

local apiversion = {}

local mspCallMade = false

function apiversion.wakeup()
    if neuronsuite.session.apiVersion == nil and mspCallMade == false then

        mspCallMade = true

        local API = neuronsuite.tasks.msp.api.load("API_VERSION")
        API.setCompleteHandler(function(self, buf)
            local version = API.readVersion()

            if version then
                local apiVersionString = tostring(version)
                if not neuronsuite.utils.stringInArray(neuronsuite.config.supportedMspApiVersion, apiVersionString) then
                    neuronsuite.utils.log("Incompatible API version detected: " .. apiVersionString, "info")
                    neuronsuite.session.apiVersionInvalid = true
                    return
                end
            end

            neuronsuite.session.apiVersion = version
            neuronsuite.session.apiVersionInvalid = false

            if neuronsuite.session.apiVersion  then
                neuronsuite.utils.log("API version: " .. neuronsuite.session.apiVersion, "info")
            end
        end)
        API.setUUID("22a683cb-db0e-439f-8d04-04687c9360f3")
        API.read()
    end    
end

function apiversion.reset()
    neuronsuite.session.apiVersion = nil
    neuronsuite.session.apiVersionInvalid = nil
    mspCallMade = false
end

function apiversion.isComplete()
    if neuronsuite.session.apiVersion ~= nil then
        return true
    end
end

return apiversion