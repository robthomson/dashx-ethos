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

local rxmap = {}

local mspCallMade = false

function rxmap.wakeup()
    
    -- quick exit if no apiVersion
    if neuronsuite.session.apiVersion == nil then return end    

    if not neuronsuite.utils.rxmapReady() and mspCallMade == false then
        mspCallMade = true
        local API = neuronsuite.tasks.msp.api.load("RX_MAP")
        API.setCompleteHandler(function(self, buf)

            local aileron = API.readValue("aileron")
            local elevator = API.readValue("elevator")
            local rudder = API.readValue("rudder")
            local collective = API.readValue("collective")
            local throttle = API.readValue("throttle")
            local aux1 = API.readValue("aux1")
            local aux2 = API.readValue("aux2")
            local aux3 = API.readValue("aux3")

            
            neuronsuite.session.rx.map.aileron = aileron
            neuronsuite.session.rx.map.elevator = elevator
            neuronsuite.session.rx.map.rudder = rudder
            neuronsuite.session.rx.map.collective = collective
            neuronsuite.session.rx.map.throttle = throttle
            neuronsuite.session.rx.map.aux1 = aux1
            neuronsuite.session.rx.map.aux2 = aux2
            neuronsuite.session.rx.map.aux3 = aux3

            neuronsuite.utils.log(
                "RX Map: Aileron: " .. aileron ..
                ", Elevator: " .. elevator ..
                ", Rudder: " .. rudder ..
                ", Collective: " .. collective ..
                ", Throttle: " .. throttle ..
                ", Aux1: " .. aux1 ..
                ", Aux2: " .. aux2 ..
                ", Aux3: " .. aux3,
                "info"
            )

        end)
        API.setUUID("b3e5c8a4-5f3e-4e2c-9f7d-2e7a1c4b8f21")
        API.read()
    end    

end

function rxmap.reset()
    if neuronsuite.session.rx and neuronsuite.session.rx.map then
        for _, key in ipairs({
            "aileron", "elevator", "rudder", "collective", "throttle",
            "aux1", "aux2", "aux3"
        }) do
            neuronsuite.session.rx.map[key] = nil
        end
    end
    neuronsuite.session.rxmap = {}
    neuronsuite.session.rxvalues = {}    
    mspCallMade = false
end

function rxmap.isComplete()
    return neuronsuite.utils.rxmapReady()
end

return rxmap