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

local rxmap = {}

function rxmap.wakeup()
    
    -- quick exit if no apiVersion
    if neurondash.session.apiVersion == nil then return end    

    if not neurondash.utils.rxmapReady() then

            neurondash.session.rx.map.aileron = 0
            neurondash.session.rx.map.elevator = 1
            neurondash.session.rx.map.collective = 2
            neurondash.session.rx.map.rudder = 3
            neurondash.session.rx.map.arm = 4
            neurondash.session.rx.map.throttle = 5
            neurondash.session.rx.map.mode = 6
            neurondash.session.rx.map.headspeed = 7


    end    

end

function rxmap.reset()
    neurondash.session.rxmap = {}
    neurondash.session.rxvalues = {}    
end

function rxmap.isComplete()
    return neurondash.utils.rxmapReady()
end

return rxmap