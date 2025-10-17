--[[
  Copyright (C) 2025 Rob Thomson
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local dashx = require("dashx")

local arg = {...}
local config = arg[1]

local timer = {}
local lastFlightMode = nil

function timer.reset()
    dashx.utils.log("Resetting flight timers", "info")
    lastFlightMode = nil

    local timerSession = {}
    dashx.session.timer = timerSession
    dashx.session.flightCounted = false

    timerSession.baseLifetime = tonumber(dashx.ini.getvalue(dashx.session.modelPreferences, "general", "totalflighttime")) or 0

    timerSession.session = 0
    timerSession.lifetime = timerSession.baseLifetime
end

function timer.save()
    local prefs = dashx.session.modelPreferences
    local prefsFile = dashx.session.modelPreferencesFile

    if not prefsFile then
        dashx.utils.log("No model preferences file set, cannot save flight timers", "info")
        return
    end

    dashx.utils.log("Saving flight timers to INI: " .. prefsFile, "info")

    if prefs then
        dashx.ini.setvalue(prefs, "general", "totalflighttime", dashx.session.timer.baseLifetime or 0)
        dashx.ini.setvalue(prefs, "general", "lastflighttime", dashx.session.timer.session or 0)
        dashx.ini.save_ini_file(prefsFile, prefs)
    end
end

local function finalizeFlightSegment(now)
    local timerSession = dashx.session.timer
    local prefs = dashx.session.modelPreferences

    local segment = now - timerSession.start
    timerSession.session = (timerSession.session or 0) + segment
    timerSession.start = nil

    if timerSession.baseLifetime == nil then timerSession.baseLifetime = tonumber(dashx.ini.getvalue(prefs, "general", "totalflighttime")) or 0 end

    timerSession.baseLifetime = timerSession.baseLifetime + segment
    timerSession.lifetime = timerSession.baseLifetime

    timer.save()
end

function timer.wakeup()
    local now = os.time()
    local timerSession = dashx.session.timer
    local prefs = dashx.session.modelPreferences
    local flightMode = dashx.flightmode.current

    lastFlightMode = flightMode

    if flightMode == "inflight" then
        if not timerSession.start then timerSession.start = now end

        local currentSegment = now - timerSession.start
        timerSession.live = (timerSession.session or 0) + currentSegment

        local computedLifetime = (timerSession.baseLifetime or 0) + currentSegment
        timerSession.lifetime = computedLifetime

        if prefs then dashx.ini.setvalue(prefs, "general", "totalflighttime", computedLifetime) end

        if timerSession.live >= 25 and not dashx.session.flightCounted then
            dashx.session.flightCounted = true

            if prefs and dashx.ini.section_exists(prefs, "general") then
                local count = dashx.ini.getvalue(prefs, "general", "flightcount") or 0
                dashx.ini.setvalue(prefs, "general", "flightcount", count + 1)
                dashx.ini.save_ini_file(dashx.session.modelPreferencesFile, prefs)
            end
        end

    else
        timerSession.live = timerSession.session or 0
    end

    if flightMode == "postflight" and timerSession.start then finalizeFlightSegment(now) end
end

return timer
