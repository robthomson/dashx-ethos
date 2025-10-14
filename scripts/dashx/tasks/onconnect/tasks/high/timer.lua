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

local timer = {}

local runOnce = false

function timer.wakeup()
        dashx.session.timer = {}
        dashx.session.timer.start = nil -- this is used to store the start time of the timer
        dashx.session.timer.live = nil -- this is used to store the live timer value while inflight
        dashx.session.timer.lifetime = nil -- this is used to store the total flight time of a model and store it in the user ini file
        dashx.session.timer.session = 0 -- this is used to track flight time for the session
        runOnce = true

end

function timer.reset()
    runOnce = false
end

function timer.isComplete()
    return runOnce
end

return timer