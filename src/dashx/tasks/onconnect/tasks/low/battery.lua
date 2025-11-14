--[[
  Copyright (C) 2025 Rob Thomson
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local dashx = require("dashx")

local battery = {}

function battery.wakeup()

    if dashx.session.apiVersion == nil then return end

    if (dashx.session.batteryConfig == nil and dashx.session.mcu_id) then

        local modelpref_file = "SCRIPTS:/" .. dashx.config.preferences .. "/models/" .. dashx.session.mcu_id .. ".ini"

        os.mkdir("SCRIPTS:/" .. dashx.config.preferences)
        os.mkdir("SCRIPTS:/" .. dashx.config.preferences .. "/models")
        local master_ini = dashx.ini.load_ini_file(modelpref_file) or {}
        local preferences = master_ini.battery or {}

        dashx.session.batteryConfig = {}
        dashx.session.batteryConfig.batteryCapacity = preferences.batteryCapacity
        dashx.session.batteryConfig.batteryCellCount = preferences.batteryCellCount
        dashx.session.batteryConfig.vbatwarningcellvoltage = preferences.vbatwarningcellvoltage / 10
        dashx.session.batteryConfig.vbatmincellvoltage = preferences.vbatmincellvoltage / 10
        dashx.session.batteryConfig.vbatmaxcellvoltage = preferences.vbatmaxcellvoltage / 10
        dashx.session.batteryConfig.vbatfullcellvoltage = preferences.vbatfullcellvoltage / 10
        dashx.session.batteryConfig.lvcPercentage = preferences.lvcPercentage
        dashx.session.batteryConfig.consumptionWarningPercentage = preferences.consumptionWarningPercentage

    end

end

function battery.reset() dashx.session.batteryConfig = nil end

function battery.isComplete() if dashx.session.batteryConfig ~= nil then return true end end

return battery
