local dashx = require("dashx")
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

local rxmap = {}

function rxmap.wakeup()
    
    -- quick exit if no apiVersion
    if dashx.session.apiVersion == nil then return end    

    if not dashx.utils.rxmapReady() then

            dashx.session.rx.map.aileron = 0
            dashx.session.rx.map.elevator = 1
            dashx.session.rx.map.collective = 2
            dashx.session.rx.map.rudder = 3
            dashx.session.rx.map.arm = 4
            dashx.session.rx.map.throttle = 5
            dashx.session.rx.map.mode = 6
            dashx.session.rx.map.headspeed = 7


    end    

end

function rxmap.reset()
    dashx.session.rxmap = {}
    dashx.session.rxvalues = {}    
end

function rxmap.isComplete()
    return dashx.utils.rxmapReady()
end

return rxmap