--[[

 * Copyright (C) dashx Project
 * License GPLv3: https://www.gnu.org/licenses/gpl-3.0.en.html

 * MSP Sensor Table Structure
 *
 * msp_sensors: A table defining APIs to be polled via MSP and how to map their values to telemetry sensors.
 * Each top-level key is the MSP API name (e.g., "DATAFLASH_SUMMARY").
 * Each entry must include polling intervals and a 'fields' table containing telemetry sensor configs.
 *
 * Structure:
 * {
 *   API_NAME = {
 *     interval_armed: <number>         -- Interval (in seconds) to poll this API when the model is armed (-1 for no polling)
 *     interval_disarmed: <number>      -- Interval (in seconds) when disarmed (-1 for no polling)
 *     interval_admin: <number>         -- Interval (in seconds) when admin module loaded (-1 for no polling)
 *
 *     fields = {
 *       field_key = {
 *         sensorname: <string>         -- Label shown in radio telemetry menu
 *         sessionname: <string>        -- Optional session variable name to update
 *         appId: <number>              -- Unique sensor ID (must be unique across all sensors)
 *         unit: <constant>             -- Telemetry unit (e.g., UNIT_RAW, UNIT_VOLT, etc.)
 *         minimum: <number>            -- Optional minimum value (default: -1e9)
 *         maximum: <number>            -- Optional maximum value (default: 1e9)
 *         transform: <function>        -- Optional value processing function before display
 *       },
 *       ...
 *     }
 *   },
 *   ...
 * }

 * Possible sensor ids we can use are.
 * 0x5FE1   - smartfuel
 * 0x5FE0   - armed
 * 0x5FDF   - idleup
 * 0x5FDE   - smartconsumption
 * 0x5FDD
 * 0x5FDC
 * 0x5FDB
 * 0x5FDA
 * 0x5FD9
 * 0x5FD8
 * 0x5FD7
 * 0x5FD6
 * 0x5FD5
 * 0x5FD4
 * 0x5FD3
 * 0x5FD2
 * 0x5FD1
 * 0x5FD0
 * 0x5FCF
 * 0x5FCE

]]

local smart = {}

local smartfuel = assert(dashx.compiler.loadfile("tasks/sensors/lib/smartfuel.lua"))()
local smartfuelvoltage = assert(dashx.compiler.loadfile("tasks/sensors/lib/smartfuelvoltage.lua"))()

-- container vars
local log
local tasks 

local interval = 1 
local lastWake = os.clock()

local firstWakeup = true


local function calculateFuel()
    -- work out what type of sensor we are running and use 
    -- the appropriate calculation method
    if dashx.session.modelPreferences and dashx.session.modelPreferences.battery and dashx.session.modelPreferences.battery.calc_local then
        -- if we dont have a consumption.. fallback to voltage
         if dashx.session.modelPreferences.battery.calc_local == 1 or not dashx.tasks.telemetry.getSensorSource("consumption") then
            return smartfuelvoltage.calculate()
         else
            return smartfuel.calculate()
         end
    else
            return smartfuel.calculate()
    end

end

local function calculateConsumption()
            -- If smartvoltage is enabled, calculate mAh used based on capacity
            if dashx.session.modelPreferences and dashx.session.modelPreferences.battery and dashx.session.modelPreferences.battery.calc_local then
                if dashx.session.modelPreferences.battery.calc_local == 1 or not dashx.tasks.telemetry.getSensorSource("consumption") then
                    local capacity = (dashx.session.batteryConfig and dashx.session.batteryConfig.batteryCapacity) or 1000 -- Default to 1000mAh if not set
                    local smartfuelPct = dashx.tasks.telemetry.getSensor("smartfuel")
                    local warningPercentage = (dashx.session.batteryConfig and dashx.session.batteryConfig.consumptionWarningPercentage) or 30
                    if smartfuelPct then
                        local usableCapacity = capacity * (1 - warningPercentage / 100)
                        local usedPercent = 100 - smartfuelPct -- how much has been used
                        return (usedPercent / 100) * usableCapacity
                    end
                else
                    -- fallback to FC "consumption"
                    return dashx.tasks.telemetry.getSensor("consumption") or 0
                end
            else
                -- No battery prefs — fallback to FC "consumption"
                return dashx.tasks.telemetry.getSensor("consumption") or 0
            end
end    


local switchCache = {}

local smart_sensors = {
    armed = {
        name = "Armed",
        appId = 0x5FE0, -- Unique sensor ID
        unit = UNIT_RAW, -- Telemetry unit
        minimum = 0,
        maximum = 1,
        value = function()
            if dashx.preferences.model then
                local settings = dashx.preferences.model
                if settings.armswitch then
                    local category, member, options = settings.armswitch:match("([^:]+):([^:]+):([^:]+)")
                    
                    if not switchCache["armed"] then
                        switchCache["armed"] = system.getSource({category = category, member = member, options = options})
                    end
                    local state = switchCache["armed"]:state()

                    return(state and 0 or 1)
                end    
            end
            return false     
        end,
    },
    idleup = {
        name = "Idle up",
        appId = 0x5FDF, -- Unique sensor ID
        unit = UNIT_RAW, -- Telemetry unit
        minimum = 0,
        maximum = 1,
        value = function()
            if dashx.preferences.model then
                local settings = dashx.preferences.model
                if settings.idleswitch then
                    local category, member, options = settings.idleswitch:match("([^:]+):([^:]+):([^:]+)")
                    
                    if not switchCache["idleup"] then
                        switchCache["idleup"] = system.getSource({category = category, member = member, options = options})
                    end
                    local state = switchCache["idleup"]:state()
                    return(state and 0 or 1)
                end
            end    
            return false
        end,
    },    
    smartfuel = {
        name = "Smart Fuel",
        appId = 0x5FE1, -- Unique sensor ID
        unit = UNIT_PERCENT, -- Telemetry unit
        minimum = 0,
        maximum = 100,
        value = calculateFuel,
    },   
    
    smartconsumption = {
        name = "Smart Consumption",
        appId = 0x5FDE, -- Unique sensor ID
        unit = UNIT_MILLIAMPERE_HOUR, -- Telemetry unit
        minimum = 0,
        maximum = 1000000000,
        value = calculateConsumption,
    },      
}

smart.sensors = msp_sensors
local sensorCache = {}

local function createOrUpdateSensor(appId, fieldMeta, value)
    if not sensorCache[appId] then
        local existingSensor = system.getSource({ category = CATEGORY_TELEMETRY_SENSOR, appId = appId })

        if existingSensor then
            sensorCache[appId] = existingSensor
        else
            local sensor = model.createSensor({type=SENSOR_TYPE_DIY})
            sensor:name(fieldMeta.name)
            sensor:appId(appId)
            sensor:physId(0)
            sensor:module(dashx.session.telemetrySensor:module())

            if fieldMeta.unit then
                sensor:unit(fieldMeta.unit)
                sensor:protocolUnit(fieldMeta.unit)
            end
            sensor:minimum(fieldMeta.minimum or -1000000000)
            sensor:maximum(fieldMeta.maximum or 1000000000)

            sensorCache[appId] = sensor
        end
    end

    if value then
        sensorCache[appId]:value(value)
    else
        sensorCache[appId]:reset()    
    end
end


local lastWakeupTime = 0
function smart.wakeup()

    if firstWakeup then
        log = dashx.utils.log
        tasks = dashx.tasks
        firstWakeup = false
    end

    -- rate-limit: bail out until interval has elapsed
    if (os.clock() - lastWake) < interval then
        return
    end
    lastWake = os.clock()

    for name, meta in pairs(smart_sensors) do
        local value
        if type(meta.value) == "function" then
            value = meta.value()
        else
            value = meta.value  -- Assume value is already calculated
        end    
        createOrUpdateSensor(meta.appId, meta, value)
    end
end

function smart.reset()
    sensorCache = {}
    switchCache = {}
end

return smart
