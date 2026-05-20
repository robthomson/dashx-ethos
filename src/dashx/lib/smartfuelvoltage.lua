--[[
  Copyright (C) 2025 Rob Thomson
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local dashx = require("dashx")

local batteryConfigCache = nil
local lastVoltages = {}
local maxVoltageSamples = 5
local voltageStableTime = nil
local voltageStabilised = false
local stabilizeNotBefore = nil
local voltageThreshold = 0.15
local preStabiliseDelay = 1.5

local telemetry
local lastSensorMode

local lastFuelPercent = nil
local lastFuelTimestamp = nil

local DEFAULT_MAX_FUEL_DROP_PER_SECOND = 1
local DEFAULT_MAX_FALL_PER_CELL_PER_SEC = 0.05
local DEFAULT_SAG_COMPENSATION = 0.7
local lastFilteredVoltage = nil
local lastRpm = nil

local function clamp(value, minimum, maximum)
    if value < minimum then
        return minimum
    end
    if value > maximum then
        return maximum
    end
    return value
end

local function fallingLimitedFilter(current_v, prev_v, dt, cellCount, maxFallPerCellPerSecond)
    if not prev_v then return current_v end
    local max_drop = dt * maxFallPerCellPerSecond * (cellCount or 1)
    if current_v >= prev_v then
        return current_v
    else
        return math.max(current_v, prev_v - max_drop)
    end
end

local dischargeCurveTable = {}
for i = 0, 100 do
    local v = 3.30 + i * 0.01
    local percent = (v - 3.30) / (4.20 - 3.30) * 100
    dischargeCurveTable[i + 1] = math.floor(math.min(100, math.max(0, percent)) + 0.5)
end

local function resetVoltageTracking()
    lastVoltages = {}
    voltageStableTime = nil
    voltageStabilised = false
end

local function resetFuelTracking()
    lastFuelPercent = nil
    lastFuelTimestamp = nil
    lastFilteredVoltage = nil
    lastRpm = nil
end

local function resetState()
    batteryConfigCache = nil
    lastSensorMode = nil
    stabilizeNotBefore = nil
    resetFuelTracking()
    resetVoltageTracking()
end

local function isVoltageStable()
    if #lastVoltages < maxVoltageSamples then return false end
    local vmin, vmax = lastVoltages[1], lastVoltages[1]
    for _, v in ipairs(lastVoltages) do
        if v < vmin then vmin = v end
        if v > vmax then vmax = v end
    end
    return (vmax - vmin) <= voltageThreshold
end

local function getControlLoadFactor()
    local rx = dashx.session.rx and dashx.session.rx.values
    if not rx then return 0 end

    local sum = math.abs(rx.aileron or 0) + math.abs(rx.elevator or 0) + math.abs(rx.rudder or 0)
    return math.min(1.0, sum / 3000)
end

local function getRpmDropFactor()
    local rpm = telemetry and telemetry.getSensor and telemetry.getSensor("rpm") or nil
    if not rpm or rpm < 100 then return 0 end
    if not lastRpm then
        lastRpm = rpm;
        return 0
    end
    local drop = (lastRpm - rpm) / lastRpm
    lastRpm = rpm
    return math.max(0, drop)

end

local function applySagCompensation(voltage)
    if dashx.flightmode.current ~= "inflight" then return voltage end
    local bc = dashx.session.batteryConfig or {}
    local multiplier = clamp((tonumber(bc.smartFuelSagCompensation) or (DEFAULT_SAG_COMPENSATION * 100)) / 100, 0, 2)
    local sagFactor = math.max(getControlLoadFactor(), getRpmDropFactor())

    local compensationScale = multiplier ^ 1.5
    return voltage + (compensationScale * sagFactor * 0.5)
end

local function fuelPercentageCalcByVoltage(voltage, cellCount)
    local bc = dashx.session.batteryConfig
    local minV = bc.vbatmincellvoltage or 3.30
    local fullV = bc.vbatfullcellvoltage or 4.10
    local reserve = bc.consumptionWarningPercentage or 30

    local usableRange = fullV - minV
    local adjustedMinV = minV + (usableRange * (reserve / 100)) * 1.4

    local voltagePerCell = voltage / cellCount

    voltagePerCell = math.max(3.30, math.min(fullV, voltagePerCell))

    local sigmoidMin, sigmoidMax = 3.30, 4.20
    local scaledV = sigmoidMin + (voltagePerCell - adjustedMinV) / (fullV - adjustedMinV) * (sigmoidMax - sigmoidMin)

    local tableIndex = math.floor((scaledV - sigmoidMin) / 0.01) + 1
    tableIndex = math.max(1, math.min(#dischargeCurveTable, tableIndex))

    return dischargeCurveTable[tableIndex]
end

local function smartFuelCalc()
    if not telemetry then telemetry = dashx.telemetry end

    if not dashx.session.isConnected or not dashx.session.batteryConfig then
        resetVoltageTracking()
        resetFuelTracking()
        return nil
    end

    if dashx.session.modelPreferences and dashx.session.modelPreferences.battery and dashx.session.modelPreferences.battery.calc_local then
        if lastSensorMode ~= dashx.session.modelPreferences.battery.calc_local then
            resetVoltageTracking()
            resetFuelTracking()
            lastSensorMode = dashx.session.modelPreferences.battery.calc_local
        end
    end

    local bc = dashx.session.batteryConfig
    local configSig = table.concat({
        bc.batteryCellCount,
        bc.batteryCapacity,
        bc.consumptionWarningPercentage,
        bc.vbatmaxcellvoltage,
        bc.vbatmincellvoltage,
        bc.vbatfullcellvoltage,
        bc.smartFuelSagCompensation,
        bc.smartFuelVoltageFallRate,
        bc.smartFuelDropRate
    }, ":")

    if configSig ~= batteryConfigCache then
        batteryConfigCache = configSig
        resetVoltageTracking()
        resetFuelTracking()
        stabilizeNotBefore = os.clock() + preStabiliseDelay
    end

    local voltage = telemetry and telemetry.getSensor and telemetry.getSensor("voltage") or nil
    if not voltage or voltage < 2 then
        resetVoltageTracking()
        resetFuelTracking()
        stabilizeNotBefore = nil
        return nil
    end

    if stabilizeNotBefore and os.clock() < stabilizeNotBefore then return nil end

    table.insert(lastVoltages, voltage)
    if #lastVoltages > maxVoltageSamples then table.remove(lastVoltages, 1) end

    if not voltageStabilised then
        if isVoltageStable() then
            dashx.utils.log("Voltage stabilized at: " .. voltage, "info")
            voltageStabilised = true
        else
            dashx.utils.log("Waiting for voltage to stabilize...", "info")
            return nil
        end
    end

    if #lastVoltages >= 2 and dashx.flightmode.current == "preflight" then
        local prev = lastVoltages[#lastVoltages - 1]
        if voltage > prev + voltageThreshold then
            dashx.utils.log("Voltage increased after stabilization – resetting...", "info")
            resetVoltageTracking()
            resetFuelTracking()
            stabilizeNotBefore = os.clock() + preStabiliseDelay
            return nil
        end
    end

    local now = os.clock()
    local dt = lastFuelTimestamp and math.max(0, now - lastFuelTimestamp) or 0
    local maxFallPerCellPerSecond = clamp((tonumber(bc.smartFuelVoltageFallRate) or (DEFAULT_MAX_FALL_PER_CELL_PER_SEC * 100)) / 100, 0.01, 1)
    local filteredVoltage = fallingLimitedFilter(voltage, lastFilteredVoltage, dt, bc.batteryCellCount, maxFallPerCellPerSecond)
    lastFilteredVoltage = filteredVoltage

    local compensatedVoltage = applySagCompensation(filteredVoltage / bc.batteryCellCount) * bc.batteryCellCount
    local percent = fuelPercentageCalcByVoltage(compensatedVoltage, bc.batteryCellCount)
    if (dashx.flightmode.current == "inflight" or dashx.flightmode.current == "postflight") and lastFuelPercent and lastFuelTimestamp then

        local maxFuelDropPerSecond = clamp(tonumber(bc.smartFuelDropRate) or DEFAULT_MAX_FUEL_DROP_PER_SECOND, 0.1, 20)
        local maxDrop = dt * maxFuelDropPerSecond

        if percent < lastFuelPercent then
            percent = math.max(percent, lastFuelPercent - maxDrop)
        elseif percent > lastFuelPercent then
            percent = lastFuelPercent
        end
    end

    lastFuelPercent = percent
    lastFuelTimestamp = now

    return percent
end

return {calculate = smartFuelCalc, reset = resetState}
