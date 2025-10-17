--[[
  Copyright (C) 2025 Rob Thomson
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local dashx = require("dashx")

local sensorstats = {}

local runOnce = false

function sensorstats.wakeup()
    if dashx.tasks.telemetry then
        dashx.tasks.telemetry.sensorStats = {}
        runOnce = true
    end
end

function sensorstats.reset() runOnce = false end

function sensorstats.isComplete() return runOnce end

return sensorstats
