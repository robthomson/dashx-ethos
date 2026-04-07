--[[
  Copyright (C) 2026 Rob Thomson
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local dashx = require("dashx")

local sensors = {}

local smartfuel = assert(loadfile("lib/smartfuel.lua"))()
local smartfuelvoltage = assert(loadfile("lib/smartfuelvoltage.lua"))()
local useRawValue = dashx.utils.ethosVersionAtLeast({26, 1, 0})

local cachedSensors = {}
local createRetryAt = {}
local cacheExpireTime = 30
local lastCacheFlushTime = os.clock()
local wakeupInterval = 1
local lastWakeupTime = 0
local switchCache = {}

local derivedDefinitions = {
    armed = {name = "Armed", appId = 0x5FE0, unit = UNIT_RAW, minimum = 0, maximum = 1},
    inflight = {name = "Inflight", appId = 0x5FDF, unit = UNIT_RAW, minimum = 0, maximum = 1},
    smartfuel = {name = "Smart Fuel", appId = 0x5FE1, unit = UNIT_PERCENT, minimum = 0, maximum = 100},
    smartconsumption = {name = "Smart Consumption", appId = 0x5FDE, unit = UNIT_MILLIAMPERE_HOUR, minimum = 0, maximum = 1000000000}
}

local function sourceExists(source)
    return source ~= nil
end

local function telemetry()
    return dashx.telemetry
end

local function getModuleId(rootSource)
    if rootSource and rootSource.module then
        return rootSource:module()
    end
    if system.getVersion().simulation then
        return 0
    end
    if dashx.session.telemetrySensor and dashx.session.telemetrySensor.module then
        return dashx.session.telemetrySensor:module()
    end
    return nil
end

local function callSensorMethod(sensor, methodName, ...)
    if not sensor then
        return false
    end

    local method = sensor[methodName]
    if type(method) ~= "function" then
        return false
    end

    local ok, result = pcall(method, sensor, ...)
    if not ok then
        return false, result
    end

    return true, result
end

local function ensureSensor(definition, rootSource)
    local appId = definition.appId
    local existing = cachedSensors[appId]
    if sourceExists(existing) then
        return existing
    end

    existing = system.getSource({category = CATEGORY_TELEMETRY_SENSOR, appId = appId})
    if sourceExists(existing) then
        cachedSensors[appId] = existing
        return existing
    end

    local moduleId = getModuleId(rootSource)
    if moduleId == nil then
        return nil
    end

    local now = os.clock()
    if createRetryAt[appId] and now < createRetryAt[appId] then
        return nil
    end

    if not model.createSensor then
        createRetryAt[appId] = now + 5
        return nil
    end

    local sensor = model.createSensor({type = SENSOR_TYPE_DIY})
    if not sensor then
        createRetryAt[appId] = now + 5
        return nil
    end

    sensor:name(definition.name)
    sensor:appId(appId)
    sensor:physId(0)
    sensor:module(moduleId)
    sensor:minimum(definition.minimum or -1000000000)
    sensor:maximum(definition.maximum or 1000000000)

    if definition.decimals and definition.decimals >= 1 then
        sensor:decimals(definition.decimals)
        sensor:protocolDecimals(definition.decimals)
    end

    if definition.unit then
        sensor:unit(definition.unit)
        sensor:protocolUnit(definition.unit)
    end

    cachedSensors[appId] = sensor
    createRetryAt[appId] = nil
    return sensor
end

local function setSensorValue(definition, value, rootSource)
    local sensor = ensureSensor(definition, rootSource)
    if not sensor then
        return
    end

    if value == nil then
        if sensor.reset then
            sensor:reset()
        end
        return
    end

    if useRawValue and sensor.rawValue then
        sensor:rawValue(value)
    else
        sensor:value(value)
    end
end

local function parseSwitchSpec(spec)
    if type(spec) ~= "string" or spec == "" or spec == "false" then
        return nil
    end

    local category, member, options = spec:match("([^:]+):([^:]+):([^:]+)")
    if not category or not member then
        return nil
    end

    return {
        category = tonumber(category) or category,
        member = tonumber(member) or member,
        options = tonumber(options) or options
    }
end

local function getSwitchSource(key, spec)
    if not spec or spec == false then
        switchCache[key] = nil
        return nil
    end

    local cached = switchCache[key]
    if cached and cached.spec == spec then
        return cached.source
    end

    local query = parseSwitchSpec(spec)
    if not query then
        switchCache[key] = nil
        return nil
    end

    local source = system.getSource(query)
    switchCache[key] = {spec = spec, source = source}
    return source
end

local function readSwitchState(key, spec)
    local source = getSwitchSource(key, spec)
    if not source or type(source.state) ~= "function" then
        return nil
    end

    local ok, state = pcall(source.state, source)
    if not ok then
        return nil
    end

    if type(state) == "boolean" then
        return state
    end

    if type(state) == "number" then
        return state ~= 0
    end

    return nil
end

local function rpmBinaryValue()
    local telemetryModule = telemetry()
    local rpm = telemetryModule and telemetryModule.getSensor("rpm") or 0
    return rpm > 1000 and 0 or 1
end

local function deriveArmedValue()
    local modelPrefs = dashx.session.modelPreferences and dashx.session.modelPreferences.model or {}
    local state = readSwitchState("armed", modelPrefs.armswitch)
    if state ~= nil then
        return state and 0 or 1
    end
    return rpmBinaryValue()
end

local function deriveInflightValue()
    local modelPrefs = dashx.session.modelPreferences and dashx.session.modelPreferences.model or {}
    local state = readSwitchState("inflight", modelPrefs.inflightswitch)
    if state ~= nil then
        return state and 0 or 1
    end
    return rpmBinaryValue()
end

local function shouldUseVoltageFuel()
    local batteryPrefs = dashx.session.modelPreferences and dashx.session.modelPreferences.battery or {}
    if tonumber(batteryPrefs.calc_local) == 1 then
        return true
    end

    local telemetryModule = telemetry()
    return not (telemetryModule and telemetryModule.getSensorSource and telemetryModule.getSensorSource("consumption"))
end

local function calculateFuel()
    if shouldUseVoltageFuel() then
        return smartfuelvoltage.calculate()
    end
    return smartfuel.calculate()
end

local function calculateConsumption()
    if shouldUseVoltageFuel() then
        local capacity = (dashx.session.batteryConfig and dashx.session.batteryConfig.batteryCapacity) or 1000
        local smartfuelPercent = telemetry() and telemetry().getSensor and telemetry().getSensor("smartfuel") or nil
        local warningPercentage = (dashx.session.batteryConfig and dashx.session.batteryConfig.consumptionWarningPercentage) or 30
        if smartfuelPercent then
            local usableCapacity = capacity * (1 - warningPercentage / 100)
            local usedPercent = 100 - smartfuelPercent
            return (usedPercent / 100) * usableCapacity
        end
    end

    return telemetry() and telemetry().getSensor and telemetry().getSensor("consumption") or 0
end

local function updateDerivedSensors(rootSource)
    local armed = deriveArmedValue()
    local inflight = deriveInflightValue()
    dashx.session.isArmed = armed == 0

    setSensorValue(derivedDefinitions.armed, armed, rootSource)
    setSensorValue(derivedDefinitions.inflight, inflight, rootSource)
    setSensorValue(derivedDefinitions.smartfuel, calculateFuel(), rootSource)
    setSensorValue(derivedDefinitions.smartconsumption, calculateConsumption(), rootSource)
end

function sensors.reset()
    cachedSensors = {}
    createRetryAt = {}
    lastCacheFlushTime = os.clock()
    lastWakeupTime = 0
    switchCache = {}
    smartfuel.reset()
    smartfuelvoltage.reset()
end

function sensors.wakeup(protocol, rootSource)
    if not protocol then
        return
    end

    local now = os.clock()
    if now - lastWakeupTime < wakeupInterval then
        return
    end
    lastWakeupTime = now

    if now - lastCacheFlushTime >= cacheExpireTime then
        cachedSensors = {}
        lastCacheFlushTime = now
    end

    updateDerivedSensors(rootSource)
end

return sensors
