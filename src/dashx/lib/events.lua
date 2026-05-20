--[[
  Copyright (C) 2026 Rob Thomson
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local dashx = require("dashx")

local events = {}

local lastEventTimes = {}
local lastValues = {}
local nextFuelCountdown = nil

local function telemetry()
    return dashx.telemetry
end

local function getFuelPercent()
    local source = telemetry()
    return source and (source.getSensor("smartfuel") or source.getSensor("fuel")) or nil
end

local function getFuelCountdownConfig()
    local battery = dashx.session and dashx.session.batteryConfig or {}
    local enabled = (tonumber(battery.fuelCountdownEnabled) or 0) == 1

    local start = math.floor(tonumber(battery.fuelCountdownStart) or 50)
    if start < 1 then
        start = 1
    elseif start > 100 then
        start = 100
    end

    local minimum = math.floor(tonumber(battery.fuelCountdownMin) or 10)
    if minimum < 0 then
        minimum = 0
    elseif minimum > 100 then
        minimum = 100
    end

    if minimum > start then
        minimum = start
    end

    local step = math.floor(tonumber(battery.fuelCountdownStep) or 10)
    if step < 1 then
        step = 1
    elseif step > 50 then
        step = 50
    end

    return enabled, start, minimum, step
end

local function isEventEnabled(item, enabledEvents)
    if item.key == "fuel_countdown" then
        local enabled = getFuelCountdownConfig()
        return enabled
    end

    return enabledEvents[item.key] == true
end

local eventTable = {
    {
        key = "voltage",
        sensor = "voltage",
        interval = 10,
        getter = function()
            local source = telemetry()
            return source and source.getSensor("voltage") or nil
        end,
        event = function(value)
            local battery = dashx.session and dashx.session.batteryConfig or {}
            local cellCount = battery.batteryCellCount
            local warnVoltage = battery.vbatwarningcellvoltage
            local minVoltage = battery.vbatmincellvoltage

            if not (cellCount and warnVoltage and minVoltage) then
                return
            end

            local cellVoltage = value / cellCount
            if cellVoltage >= 0 and cellVoltage < (minVoltage / 2) then
                return
            end

            if cellVoltage < warnVoltage then
                dashx.utils.playFile("events", "alerts/lowvoltage.wav")
            end
        end
    },
    {
        key = "fuel",
        sensor = "fuel",
        interval = 10,
        getter = getFuelPercent,
        event = function(value)
            if value and value <= 10 then
                dashx.utils.playFile("events", "alerts/lowfuel.wav")
            end
        end
    },
    {
        key = "fuel_countdown",
        sensor = "fuel",
        hidden = true,
        interval = 1,
        getter = getFuelPercent,
        event = function(value)
            local mode = dashx.flightmode and dashx.flightmode.current or "preflight"
            if mode ~= "inflight" and mode ~= "postflight" then
                nextFuelCountdown = nil
                return
            end

            local fuel = tonumber(value)
            if not fuel then
                return
            end

            local enabled, start, minimum, step = getFuelCountdownConfig()
            if not enabled then
                nextFuelCountdown = nil
                return
            end

            if fuel > start then
                nextFuelCountdown = start
                return
            end

            if nextFuelCountdown == nil then
                local firstThreshold = math.floor((math.min(fuel, start) - 1) / step) * step
                if firstThreshold >= minimum then
                    nextFuelCountdown = firstThreshold
                else
                    return
                end
            end

            if fuel > nextFuelCountdown then
                return
            end

            local announcement = nextFuelCountdown
            nextFuelCountdown = nextFuelCountdown - step
            if nextFuelCountdown < minimum then
                nextFuelCountdown = nil
            end

            if system.playNumber then
                system.playNumber(announcement, UNIT_PERCENT, 0)
            else
                dashx.utils.playFile("events", "alerts/lowfuel.wav")
            end
        end
    },
    {
        key = "armed",
        sensor = "armed",
        debounce = 0.25,
        getter = function()
            local source = telemetry()
            return source and source.getSensor("armed") or nil
        end,
        event = function(value)
            if value == 0 then
                dashx.utils.playFile("events", "alerts/armed.wav")
            elseif value == 1 then
                dashx.utils.playFile("events", "alerts/disarmed.wav")
            end
        end
    }
}

function events.reset()
    lastEventTimes = {}
    lastValues = {}
    nextFuelCountdown = nil
end

function events.wakeup()
    local enabledEvents = dashx.preferences and dashx.preferences.events or {}
    local now = os.clock()

    for _, item in ipairs(eventTable) do
        if not isEventEnabled(item, enabledEvents) then
            goto continue
        end

        local value = item.getter and item.getter() or nil
        if value == nil then
            goto continue
        end

        local lastValue = lastValues[item.key]
        if lastValue ~= nil and value == lastValue then
            goto continue
        end

        local lastTime = lastEventTimes[item.key] or 0
        local debounce = item.debounce or 0
        local interval = item.interval or 0

        if debounce > 0 and (now - lastTime) < debounce then
            goto continue
        end

        if interval > 0 and (now - lastTime) < interval then
            goto continue
        end

        item.event(value)
        lastValues[item.key] = value
        lastEventTimes[item.key] = now

        ::continue::
    end
end

events.eventTable = eventTable

return events
