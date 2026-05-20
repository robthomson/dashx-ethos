--[[
  Copyright (C) 2026 Rob Thomson
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local dashx = require("dashx")

local runtime = {}

local trackedStats = {"rssi", "voltage", "rpm", "current", "temp_esc", "consumption", "smartconsumption", "smartfuel"}
local FLIGHT_COUNT_MIN_SECONDS = 10

local modelPreferenceDefaults = {
    dashboard = {
        theme_preflight = "nil",
        theme_inflight = "nil",
        theme_postflight = "nil"
    },
    general = {
        flightcount = 0,
        totalflighttime = 0,
        lastflighttime = 0
    },
    model = {
        armswitch = false,
        inflightswitch = false,
        inflightswitch_delay = 10,
        rateswitch = false
    },
    battery = {
        calc_local = 0,
        batteryCapacity = 2200,
        batteryCellCount = 3,
        vbatwarningcellvoltage = 35,
        vbatmincellvoltage = 33,
        vbatmaxcellvoltage = 43,
        vbatfullcellvoltage = 41,
        lvcPercentage = 30,
        consumptionWarningPercentage = 30,
        consumptionScale = 100,
        fuelCountdownEnabled = 0,
        fuelCountdownStart = 50,
        fuelCountdownMin = 10,
        fuelCountdownStep = 10
    }
}

local currentModelKey = nil
local currentFlightMode = "preflight"
local currentTelemetryType = nil
local hasBeenInFlight = false
local lastStatsAt = 0
local inflightStartTime = nil
local channelSources = {}

local function telemetry()
    return dashx.telemetry
end

local function copyTable(input)
    local output = {}
    for key, value in pairs(input or {}) do
        if type(value) == "table" then
            output[key] = copyTable(value)
        else
            output[key] = value
        end
    end
    return output
end

local function clamp(value, minimum, maximum)
    if value < minimum then
        return minimum
    end
    if value > maximum then
        return maximum
    end
    return value
end

local function getModelKey()
    local path = model.path and model.path() or ""
    local name = model.name and model.name() or ""
    local raw = path ~= "" and path or name
    return dashx.utils.sanitize_filename(raw)
end

local function resolvePreferencePaths(modelKey)
    local prefDir = "SCRIPTS:/" .. dashx.config.preferences
    local modelsDir = prefDir .. "/models"
    local prefFile = modelsDir .. "/" .. modelKey .. ".ini"

    os.mkdir(prefDir)
    os.mkdir(modelsDir)

    return prefFile
end

local function loadModelPreferencesData(modelKey)
    local prefFile = resolvePreferencePaths(modelKey)
    local existing = dashx.ini.load_ini_file(prefFile) or {}
    local merged = dashx.ini.merge_ini_tables(existing, modelPreferenceDefaults)

    if not dashx.ini.ini_tables_equal(existing, merged) then
        dashx.ini.save_ini_file(prefFile, merged)
    end

    return merged, prefFile
end

local function buildBatteryConfig(prefs)
    local battery = prefs and prefs.battery or {}

    return {
        calc_local = tonumber(battery.calc_local) or 0,
        batteryCapacity = tonumber(battery.batteryCapacity) or 2200,
        batteryCellCount = tonumber(battery.batteryCellCount) or 3,
        vbatwarningcellvoltage = (tonumber(battery.vbatwarningcellvoltage) or 35) / 10,
        vbatmincellvoltage = (tonumber(battery.vbatmincellvoltage) or 33) / 10,
        vbatmaxcellvoltage = (tonumber(battery.vbatmaxcellvoltage) or 43) / 10,
        vbatfullcellvoltage = (tonumber(battery.vbatfullcellvoltage) or 41) / 10,
        lvcPercentage = tonumber(battery.lvcPercentage) or 30,
        consumptionWarningPercentage = tonumber(battery.consumptionWarningPercentage) or 30,
        consumptionScale = tonumber(battery.consumptionScale) or 100,
        fuelCountdownEnabled = tonumber(battery.fuelCountdownEnabled) or 0,
        fuelCountdownStart = tonumber(battery.fuelCountdownStart) or 50,
        fuelCountdownMin = tonumber(battery.fuelCountdownMin) or 10,
        fuelCountdownStep = tonumber(battery.fuelCountdownStep) or 10
    }
end

local function loadModelPreferences(modelKey)
    local prefs, prefFile = loadModelPreferencesData(modelKey)
    dashx.session.modelPreferences = prefs
    dashx.session.modelPreferencesFile = prefFile
    dashx.session.batteryConfig = buildBatteryConfig(prefs)
end

local function resetTimer()
    local total = 0
    if dashx.session.modelPreferences then
        total = tonumber(dashx.ini.getvalue(dashx.session.modelPreferences, "general", "totalflighttime")) or 0
    end

    dashx.session.timer = {
        start = nil,
        live = 0,
        session = 0,
        lifetime = total,
        baseLifetime = total
    }
    dashx.session.flightCounted = false
end

local function saveTimerTotals()
    local prefs = dashx.session.modelPreferences
    local prefFile = dashx.session.modelPreferencesFile

    if not prefs or not prefFile then
        return
    end

    dashx.ini.setvalue(prefs, "general", "totalflighttime", dashx.session.timer.baseLifetime or 0)
    dashx.ini.setvalue(prefs, "general", "lastflighttime", dashx.session.timer.session or 0)
    dashx.ini.save_ini_file(prefFile, prefs)
end

local function initializeRxMap()
    dashx.session.rx = dashx.session.rx or {map = {}, values = {}}
    dashx.session.rx.map = dashx.session.rx.map or {}
    dashx.session.rx.values = dashx.session.rx.values or {}

    local map = dashx.session.rx.map
    map.aileron = 0
    map.elevator = 1
    map.collective = 2
    map.rudder = 3
    map.arm = 4
    map.throttle = 5
    map.mode = 6
    map.headspeed = 7

    channelSources = {}
end

local function updateRxValues(protocol)
    if protocol == nil or protocol == "sim" then
        return
    end

    if not dashx.utils.rxmapReady() then
        initializeRxMap()
    end

    local map = dashx.session.rx and dashx.session.rx.map or nil
    if not map then
        return
    end

    for name, member in pairs(map) do
        if channelSources[name] == nil and member ~= nil then
            channelSources[name] = system.getSource({category = CATEGORY_CHANNEL, member = member, options = 0})
        end
    end

    for name, source in pairs(channelSources) do
        if source and source.value then
            local value = source:value()
            if value ~= nil then
                dashx.session.rx.values[name] = value
            end
        end
    end
end

local function initializeModel(modelKey)
    dashx.utils.session()
    dashx.session.mcu_id = modelKey
    dashx.session.craftName = model.name and model.name() or "Model"

    loadModelPreferences(modelKey)
    resetTimer()

    if telemetry() and telemetry().reset then
        telemetry().reset()
    end
    if dashx.sensors and dashx.sensors.reset then
        dashx.sensors.reset()
    end
    if dashx.events and dashx.events.reset then
        dashx.events.reset()
    end

    dashx.flightmode.current = "preflight"
    currentFlightMode = "preflight"
    currentTelemetryType = nil
    hasBeenInFlight = false
    inflightStartTime = nil
    lastStatsAt = 0
    channelSources = {}
    initializeRxMap()
end

local function detectProtocol()
    if system.getVersion().simulation then
        local internalModule = model.getModule and model.getModule(0) or nil
        local rootSource = system.getSource({appId = 0xF101, subId = 0}) or system.getSource({appId = 0xF101}) or system.getSource("RSSI")
        return "sim", rootSource, internalModule
    end

    local internalModule = model.getModule and model.getModule(0) or nil
    local externalModule = model.getModule and model.getModule(1) or nil

    if internalModule and internalModule.enable and internalModule:enable() then
        local sportSource = system.getSource({appId = 0xF101, subId = 0}) or system.getSource({appId = 0xF101})
        if sportSource then
            return "sport", sportSource, internalModule
        end
    end

    if externalModule and externalModule.enable and externalModule:enable() then
        local crsfSource = system.getSource({crsfId = 0x14, subIdStart = 0, subIdEnd = 1})
        if crsfSource then
            return "crsf", crsfSource, externalModule
        end

        local sportSource = system.getSource({appId = 0xF101, subId = 0}) or system.getSource({appId = 0xF101})
        if sportSource then
            return "sport", sportSource, externalModule
        end

        local spektrumSource = system.getSource("Tx RSSI")
        if spektrumSource then
            return "spektrum", spektrumSource, externalModule
        end
    end

    return nil, nil, nil
end

local function updateTelemetryState()
    local protocol, rootSource, moduleRef = detectProtocol()
    local sessionProtocol = protocol == "sim" and "sport" or protocol
    local changed = sessionProtocol ~= currentTelemetryType

    if changed then
        currentTelemetryType = sessionProtocol
        if telemetry() and telemetry().reset then
            telemetry().reset()
        end
        if dashx.sensors and dashx.sensors.reset then
            dashx.sensors.reset()
        end
        if dashx.events and dashx.events.reset then
            dashx.events.reset()
        end
        channelSources = {}
    end

    local available = protocol == "sim" or (sessionProtocol ~= nil and rootSource ~= nil)

    dashx.session.telemetryTypeChanged = changed
    dashx.session.telemetryType = sessionProtocol
    dashx.session.telemetryProtocol = protocol
    dashx.session.telemetrySensor = rootSource
    dashx.session.telemetryModule = moduleRef
    dashx.session.telemetryState = available
    dashx.session.isConnected = available
    dashx.session.isConnectedHigh = available
    dashx.session.isConnectedMedium = available
    dashx.session.isConnectedLow = available

    if not available then
        dashx.session.isArmed = false
    end

    return protocol, changed
end

local function determineFlightMode()
    local telemetryModule = telemetry()
    local rpm = telemetryModule and telemetryModule.getSensor("rpm") or 0
    local armed = telemetryModule and telemetryModule.getSensor("armed") or nil
    local inflight = telemetryModule and telemetryModule.getSensor("inflight") or nil
    local delay = tonumber(dashx.ini.getvalue(dashx.session.modelPreferences, "model", "inflightswitch_delay")) or 10

    if armed == nil then
        armed = rpm > 1000 and 0 or 1
    end

    if inflight == nil then
        inflight = rpm > 1000 and 0 or 1
    end

    if currentFlightMode == "inflight" and not dashx.session.isConnected then
        hasBeenInFlight = true
        inflightStartTime = nil
    end

    if armed == 0 and inflight == 0 then
        if not inflightStartTime then
            inflightStartTime = os.time()
        elseif os.difftime(os.time(), inflightStartTime) >= delay then
            hasBeenInFlight = true
            return "inflight"
        end
    else
        inflightStartTime = nil
    end

    if hasBeenInFlight then
        return "postflight"
    end

    return "preflight"
end

local function updateTimer()
    local timer = dashx.session.timer
    if not timer then
        resetTimer()
        timer = dashx.session.timer
    end

    local now = os.time()
    if currentFlightMode == "inflight" then
        if not timer.start then
            timer.start = now
        end

        local currentSegment = now - timer.start
        timer.live = (timer.session or 0) + currentSegment
        timer.lifetime = (timer.baseLifetime or 0) + currentSegment

        if dashx.session.modelPreferences then
            dashx.ini.setvalue(dashx.session.modelPreferences, "general", "totalflighttime", timer.lifetime)
        end

        if timer.live >= FLIGHT_COUNT_MIN_SECONDS and not dashx.session.flightCounted and dashx.session.modelPreferences then
            dashx.session.flightCounted = true
            local count = tonumber(dashx.ini.getvalue(dashx.session.modelPreferences, "general", "flightcount")) or 0
            dashx.ini.setvalue(dashx.session.modelPreferences, "general", "flightcount", count + 1)
            dashx.ini.save_ini_file(dashx.session.modelPreferencesFile, dashx.session.modelPreferences)
        end
    else
        timer.live = timer.session or 0
    end

    if currentFlightMode == "postflight" and timer.start then
        local segment = now - timer.start
        timer.session = (timer.session or 0) + segment
        timer.start = nil
        timer.baseLifetime = (timer.baseLifetime or 0) + segment
        timer.lifetime = timer.baseLifetime
        saveTimerTotals()
    end
end

local function updateStats()
    local telemetryModule = telemetry()
    if not telemetryModule or currentFlightMode ~= "inflight" or not dashx.session.isConnected then
        return
    end

    local now = os.clock()
    if now - lastStatsAt < 0.25 then
        return
    end
    lastStatsAt = now

    telemetryModule.sensorStats = telemetryModule.sensorStats or {}

    for _, sensorKey in ipairs(trackedStats) do
        local value = telemetryModule.getSensor(sensorKey)
        if type(value) == "number" then
            local stats = telemetryModule.sensorStats[sensorKey]
            if not stats then
                stats = {min = math.huge, max = -math.huge, sum = 0, count = 0, avg = 0}
                telemetryModule.sensorStats[sensorKey] = stats
            end

            stats.min = math.min(stats.min, value)
            stats.max = math.max(stats.max, value)
            stats.sum = stats.sum + value
            stats.count = stats.count + 1
            stats.avg = stats.sum / stats.count
        end
    end
end

local function normalizeSwitchValue(value)
    if type(value) == "string" then
        return value ~= "" and value or false
    end

    if type(value) == "boolean" or value == nil then
        return false
    end

    if value.category and value.member and value.options then
        local category = value:category()
        local member = value:member()
        local options = value:options()
        return table.concat({category, member, options}, ":")
    end

    return false
end

local function normalizeThemeValue(value)
    if value == nil or value == false or value == "" or value == "nil" then
        return "nil"
    end

    if value == "Default" then
        return "system/default"
    end

    if value == "RT-RC" or value == "@RT-RC" then
        return "system/@rt-rc"
    end

    if value == "system/rt-rc" then
        return "system/@rt-rc"
    end

    return value
end

local function normalizeWidgetSettings(widget)
    widget.theme_preflight = normalizeThemeValue(widget.theme_preflight)
    widget.theme_inflight = normalizeThemeValue(widget.theme_inflight)
    widget.theme_postflight = normalizeThemeValue(widget.theme_postflight)

    widget.calc_local = clamp(math.floor(tonumber(widget.calc_local) or 0), 0, 1)
    widget.batteryCapacity = clamp(math.floor(tonumber(widget.batteryCapacity) or 2200), 0, 10000000)
    widget.batteryCellCount = clamp(math.floor(tonumber(widget.batteryCellCount) or 3), 1, 24)
    widget.vbatwarningcellvoltage = clamp(math.floor(tonumber(widget.vbatwarningcellvoltage) or 35), 5, 600)
    widget.vbatmincellvoltage = clamp(math.floor(tonumber(widget.vbatmincellvoltage) or 33), 5, 600)
    widget.vbatmaxcellvoltage = clamp(math.floor(tonumber(widget.vbatmaxcellvoltage) or 43), 5, 600)
    widget.vbatfullcellvoltage = clamp(math.floor(tonumber(widget.vbatfullcellvoltage) or 41), 5, 600)
    widget.consumptionWarningPercentage = clamp(math.floor(tonumber(widget.consumptionWarningPercentage) or 30), 0, 100)
    widget.consumptionScale = clamp(math.floor(tonumber(widget.consumptionScale) or 100), 50, 200)
    widget.fuelCountdownEnabled = clamp(math.floor(tonumber(widget.fuelCountdownEnabled) or 0), 0, 1)
    widget.fuelCountdownStart = clamp(math.floor(tonumber(widget.fuelCountdownStart) or 50), 1, 100)
    widget.fuelCountdownMin = clamp(math.floor(tonumber(widget.fuelCountdownMin) or 10), 0, 100)
    widget.fuelCountdownStep = clamp(math.floor(tonumber(widget.fuelCountdownStep) or 10), 1, 50)
    if widget.fuelCountdownMin > widget.fuelCountdownStart then
        widget.fuelCountdownMin = widget.fuelCountdownStart
    end
    widget.inflightswitch_delay = clamp(math.floor(tonumber(widget.inflightswitch_delay) or 10), 0, 120)
    widget.armswitch = normalizeSwitchValue(widget.armswitch)
    widget.inflightswitch = normalizeSwitchValue(widget.inflightswitch)
end

function runtime.readWidgetSettings(widget)
    local modelKey = getModelKey()
    local prefs, prefFile = loadModelPreferencesData(modelKey)
    local dashboardPrefs = prefs.dashboard or {}
    local modelPrefs = prefs.model or {}
    local batteryPrefs = prefs.battery or {}

    if widget then
        widget.theme_preflight = dashboardPrefs.theme_preflight or "nil"
        widget.theme_inflight = dashboardPrefs.theme_inflight or "nil"
        widget.theme_postflight = dashboardPrefs.theme_postflight or "nil"
        widget.calc_local = tonumber(batteryPrefs.calc_local) or 0
        widget.batteryCapacity = tonumber(batteryPrefs.batteryCapacity) or 2200
        widget.batteryCellCount = tonumber(batteryPrefs.batteryCellCount) or 3
        widget.vbatwarningcellvoltage = tonumber(batteryPrefs.vbatwarningcellvoltage) or 35
        widget.vbatmincellvoltage = tonumber(batteryPrefs.vbatmincellvoltage) or 33
        widget.vbatmaxcellvoltage = tonumber(batteryPrefs.vbatmaxcellvoltage) or 43
        widget.vbatfullcellvoltage = tonumber(batteryPrefs.vbatfullcellvoltage) or 41
        widget.consumptionWarningPercentage = tonumber(batteryPrefs.consumptionWarningPercentage) or 30
        widget.consumptionScale = tonumber(batteryPrefs.consumptionScale) or 100
        widget.fuelCountdownEnabled = tonumber(batteryPrefs.fuelCountdownEnabled) or 0
        widget.fuelCountdownStart = tonumber(batteryPrefs.fuelCountdownStart) or 50
        widget.fuelCountdownMin = tonumber(batteryPrefs.fuelCountdownMin) or 10
        widget.fuelCountdownStep = tonumber(batteryPrefs.fuelCountdownStep) or 10
        widget.armswitch = modelPrefs.armswitch or false
        widget.inflightswitch = modelPrefs.inflightswitch or false
        widget.inflightswitch_delay = tonumber(modelPrefs.inflightswitch_delay) or 10
        widget._modelKey = modelKey
        widget._preferencesFile = prefFile
        normalizeWidgetSettings(widget)
    end

    if currentModelKey == modelKey then
        dashx.session.modelPreferences = prefs
        dashx.session.modelPreferencesFile = prefFile
        dashx.session.batteryConfig = buildBatteryConfig(prefs)
    end

    return prefs, prefFile, modelKey
end

function runtime.writeWidgetSettings(widget)
    local modelKey = widget and widget._modelKey or getModelKey()
    local prefs, prefFile = loadModelPreferencesData(modelKey)

    widget = widget or {}
    normalizeWidgetSettings(widget)

    prefs.dashboard = prefs.dashboard or {}
    prefs.model = prefs.model or {}
    prefs.battery = prefs.battery or {}

    prefs.dashboard.theme_preflight = widget.theme_preflight
    prefs.dashboard.theme_inflight = widget.theme_inflight
    prefs.dashboard.theme_postflight = widget.theme_postflight

    prefs.model.armswitch = widget.armswitch
    prefs.model.inflightswitch = widget.inflightswitch
    prefs.model.inflightswitch_delay = widget.inflightswitch_delay

    prefs.battery.calc_local = widget.calc_local
    prefs.battery.batteryCapacity = widget.batteryCapacity
    prefs.battery.batteryCellCount = widget.batteryCellCount
    prefs.battery.vbatwarningcellvoltage = widget.vbatwarningcellvoltage
    prefs.battery.vbatmincellvoltage = widget.vbatmincellvoltage
    prefs.battery.vbatmaxcellvoltage = widget.vbatmaxcellvoltage
    prefs.battery.vbatfullcellvoltage = widget.vbatfullcellvoltage
    prefs.battery.consumptionWarningPercentage = widget.consumptionWarningPercentage
    prefs.battery.consumptionScale = widget.consumptionScale
    prefs.battery.fuelCountdownEnabled = widget.fuelCountdownEnabled
    prefs.battery.fuelCountdownStart = widget.fuelCountdownStart
    prefs.battery.fuelCountdownMin = widget.fuelCountdownMin
    prefs.battery.fuelCountdownStep = widget.fuelCountdownStep

    dashx.ini.save_ini_file(prefFile, prefs)

    if currentModelKey == modelKey then
        dashx.session.modelPreferences = prefs
        dashx.session.modelPreferencesFile = prefFile
        dashx.session.batteryConfig = buildBatteryConfig(prefs)
        if dashx.sensors and dashx.sensors.reset then
            dashx.sensors.reset()
        end
        dashx.session.dashboardThemeReloadPending = true
    end

    return true
end

function runtime.resetFlight()
    hasBeenInFlight = false
    inflightStartTime = nil
    currentFlightMode = "preflight"
    dashx.flightmode.current = "preflight"
    lastStatsAt = 0

    local telemetryModule = telemetry()
    if telemetryModule then
        telemetryModule.sensorStats = {}
    end
    resetTimer()

    if dashx.events and dashx.events.reset then
        dashx.events.reset()
    end

    return true
end

function runtime.wakeup()
    local modelKey = getModelKey()
    local modelChanged = modelKey ~= currentModelKey

    if modelChanged then
        currentModelKey = modelKey
        initializeModel(modelKey)
    end

    dashx.session.craftName = model.name and model.name() or dashx.session.craftName

    local protocol, telemetryChanged = updateTelemetryState()
    updateRxValues(protocol)

    if dashx.sensors and dashx.sensors.wakeup then
        dashx.sensors.wakeup(protocol, dashx.session.telemetrySensor)
    end

    local telemetryModule = telemetry()
    if protocol == "sim" and not dashx.session.telemetrySensor and telemetryModule and telemetryModule.getSensorSource then
        dashx.session.telemetrySensor = telemetryModule.getSensorSource("rssi") or telemetryModule.getSensorSource("voltage")
    end

    if telemetryModule and telemetryModule.wakeup then
        telemetryModule.wakeup()
    end

    if dashx.logging and dashx.logging.wakeup then
        dashx.logging.wakeup()
    end

    if dashx.events and dashx.events.wakeup then
        dashx.events.wakeup()
    end

    local nextFlightMode = determineFlightMode()
    local flightModeChanged = nextFlightMode ~= currentFlightMode
    currentFlightMode = nextFlightMode
    dashx.flightmode.current = nextFlightMode

    updateTimer()
    updateStats()

    dashx.session.telemetryTypeChanged = false

    return {
        model_changed = modelChanged,
        telemetry_changed = telemetryChanged,
        flightmode_changed = flightModeChanged
    }
end

return runtime
