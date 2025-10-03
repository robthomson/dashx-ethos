--[[
 * Copyright (C) dashx Project
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
 *
 * Note: Some icons have been sourced from https://www.flaticon.com/
]]--

local arg = { ... }
local config = arg[1]

local flightmode = {}
local lastFlightMode = nil
local hasBeenInFlight = false
local inflight_start_time = nil


--- Determines if the flight mode is considered "in flight".
-- This function checks two main conditions to decide if the model is in flight:
-- 1. If the governor sensor is active (highest priority).
-- 2. If the throttle has been above zero for a sustained period.
-- The function also ensures telemetry is active and the session is armed before proceeding.
-- @return boolean True if the model is considered in flight, false otherwise.
function flightmode.inFlight()
    local telemetry = dashx.tasks.telemetry

    if not telemetry.active() then
        return false
    end

    local inflight = telemetry.getSensor("inflight")
    local armed = telemetry.getSensor("armed")
    local delay = dashx.session.modelPreferences.model.inflightswitch_delay or 10

    -- Both sensors indicate "not armed" and "not inflight"
    if armed == 0 and inflight == 0 then
        if not inflight_start_time then
            -- Start the timer
            inflight_start_time = os.time()
            print("Starting inflight timer")
        elseif os.difftime(os.time(), inflight_start_time) >= delay then
            -- Delay has passed
            print("In flight confirmed after delay")
            return true
        end
    else
        -- Reset timer if condition is broken
        inflight_start_time = nil
    end

    return false
end

--- Resets the flight mode state.
-- This function clears the last flight mode, resets the flight status,
-- and clears the throttle start time. It is typically used to reinitialize
-- the flight mode tracking variables to their default states.
function flightmode.reset()
    lastFlightMode = nil
    hasBeenInFlight = false
     inflight_start_time = nil
end

--- Determines the current flight mode based on session state and flight status.
-- This function checks the current session's flight mode and connection status,
-- as well as the result of `flightmode.inFlight()`, to decide whether the mode
-- should be "preflight", "inflight", or "postflight".
-- It also manages the `hasBeenInFlight` flag to track if the system has ever been in flight.
-- @return string The determined flight mode: "preflight", "inflight", or "postflight".
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

--- Wakes up the flight mode task and updates the current flight mode if it has changed.
-- Determines the current flight mode using `determineMode()`. If the mode has changed since the last check,
-- logs the new flight mode, updates the session's flight mode, and stores the new mode as the last known mode.
function flightmode.wakeup()
    local mode = determineMode()

    if lastFlightMode ~= mode then
        dashx.utils.log("Flight mode: " .. mode, "info")
        dashx.flightmode.current = mode
        lastFlightMode = mode
    end
end

return flightmode
