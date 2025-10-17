--[[
  Copyright (C) 2025 Rob Thomson
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local dashx = require("dashx")

local rxmap = {}

function rxmap.wakeup()

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

function rxmap.isComplete() return dashx.utils.rxmapReady() end

return rxmap
