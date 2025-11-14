--[[
  Copyright (C) 2025 Rob Thomson
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local dashx = require("dashx")

local timer = {}

local runOnce = false

function timer.wakeup()
    dashx.session.timer = {}
    dashx.session.timer.start = nil
    dashx.session.timer.live = nil
    dashx.session.timer.lifetime = nil
    dashx.session.timer.session = 0
    runOnce = true

end

function timer.reset() runOnce = false end

function timer.isComplete() return runOnce end

return timer
