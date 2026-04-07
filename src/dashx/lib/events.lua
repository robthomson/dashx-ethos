--[[
  Copyright (C) 2026 Rob Thomson
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local dashx = require("dashx")

local events = {}

local lastEventTimes = {}
local lastValues = {}

local function telemetry()
    return dashx.telemetry
end

local eventTable = {
    {
        key = "voltage",
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
        interval = 10,
        getter = function()
            local source = telemetry()
            return source and (source.getSensor("smartfuel") or source.getSensor("fuel")) or nil
        end,
        event = function(value)
            if value and value <= 10 then
                dashx.utils.playFile("events", "alerts/lowfuel.wav")
            end
        end
    },
    {
        key = "armed",
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
end

function events.wakeup()
    local enabledEvents = dashx.preferences and dashx.preferences.events or {}
    local now = os.clock()

    for _, item in ipairs(eventTable) do
        if not enabledEvents[item.key] then
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

return events
