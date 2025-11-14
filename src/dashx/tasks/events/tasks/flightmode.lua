--[[
  Copyright (C) 2025 Rob Thomson
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local dashx = require("dashx")

local arg = {...}
local config = arg[1]

local flightmode = {}
local lastFlightMode = nil
local hasBeenInFlight = false
local inflight_start_time = nil

function flightmode.inFlight()
    local telemetry = dashx.tasks.telemetry

    if not telemetry.active() then return false end

    local inflight = telemetry.getSensor("inflight")
    local armed = telemetry.getSensor("armed")
    local delay = dashx.session.modelPreferences.model.inflightswitch_delay or 10

    if armed == 0 and inflight == 0 then
        if not inflight_start_time then

            inflight_start_time = os.time()
            print("Starting inflight timer")
        elseif os.difftime(os.time(), inflight_start_time) >= delay then

            print("In flight confirmed after delay")
            return true
        end
    else

        inflight_start_time = nil
    end

    return false
end

function flightmode.reset()
    lastFlightMode = nil
    hasBeenInFlight = false
    inflight_start_time = nil
end

local function determineMode()
    if dashx.flightmode.current == "inflight" and not dashx.session.isConnected then
        hasBeenInFlight = false
        return "postflight"
    end
    if flightmode.inFlight() then
        print("In flight")
        hasBeenInFlight = true
        return "inflight"
    end

    return hasBeenInFlight and "postflight" or "preflight"
end

function flightmode.wakeup()
    local mode = determineMode()

    if lastFlightMode ~= mode then
        dashx.utils.log("Flight mode: " .. mode, "info")
        dashx.flightmode.current = mode
        lastFlightMode = mode
    end
end

return flightmode
