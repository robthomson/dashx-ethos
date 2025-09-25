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

local apiversion = {}

function apiversion.wakeup()
    dashx.session.apiVersion = 12.07
end

function apiversion.reset()
    dashx.session.apiVersion = nil
end

function apiversion.isComplete()
    if dashx.session.apiVersion ~= nil then
        return true
    end
end

return apiversion