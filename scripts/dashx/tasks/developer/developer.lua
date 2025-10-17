--[[
  Copyright (C) 2025 Rob Thomson
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local dashx = require("dashx")

local ENABLE_TASK = false

local arg = {...}

local developer = {}

function developer.wakeup()

    if ENABLE_TASK == false then return end

    dashx.utils.log("API Debug Task: TELEMETRY_CONFIG", "info")
    local API = dashx.tasks.msp.api.load("TELEMETRY_CONFIG")
    API.setCompleteHandler(function(self, buf) end)
    API.setUUID("123e4567-e89b-12d3-a456-426614174000")
    API.read()

end

return developer
