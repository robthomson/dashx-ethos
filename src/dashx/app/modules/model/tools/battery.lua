--[[
  Copyright (C) 2025 Rob Thomson
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local dashx = require("dashx")
local settings = {}
local enableWakeup = false

local function boolFieldValueToFlag(value)
    if value == true or tonumber(value) == 1 then
        return 1
    end
    return 0
end

local function openPage(pageIdx, title, script)
    enableWakeup = true
    dashx.app.triggers.closeProgressLoader = true
    form.clear()

    dashx.app.lastIdx = pageIdx
    dashx.app.lastTitle = title
    dashx.app.lastScript = script

    dashx.app.ui.fieldHeader("@i18n(app.modules.model.name)@" .. " / " .. "@i18n(app.modules.model.triggers)@")

    local formFieldCount = 0
    local formLineCnt = 0
    dashx.app.formLines = {}
    dashx.app.formFields = {}

    formFieldCount = formFieldCount + 1
    formLineCnt = formLineCnt + 1
    dashx.app.formLines[formLineCnt] = form.addLine("@i18n(app.modules.model.calcfuel_using)@")
    dashx.app.formFields[formFieldCount] = form.addChoiceField(dashx.app.formLines[formLineCnt], nil, {{"@i18n(app.modules.model.calcfuel_current)@", 0}, {"@i18n(app.modules.model.calcfuel_voltage)@", 1}}, function()
        if dashx.session.modelPreferences then return dashx.session.modelPreferences.battery.calc_local end
        return nil
    end, function(newValue) if dashx.session.modelPreferences then dashx.session.modelPreferences.battery.calc_local = newValue end end)

    formFieldCount = formFieldCount + 1
    formLineCnt = formLineCnt + 1
    dashx.app.formLines[formLineCnt] = form.addLine("@i18n(app.modules.model.battery_capacity)@")
    dashx.app.formFields[formFieldCount] = form.addNumberField(dashx.app.formLines[formLineCnt], nil, 0, 10000000, function()
        if dashx.session.modelPreferences and settings then return dashx.session.modelPreferences.battery.batteryCapacity end
        return nil
    end, function(newValue) if dashx.session.modelPreferences then dashx.session.modelPreferences.battery.batteryCapacity = newValue end end)
    dashx.app.formFields[formFieldCount]:suffix("mAh")
    dashx.app.formFields[formFieldCount]:default(2200)

    formFieldCount = formFieldCount + 1
    formLineCnt = formLineCnt + 1
    dashx.app.formLines[formLineCnt] = form.addLine("@i18n(app.modules.model.battery_cells)@")
    dashx.app.formFields[formFieldCount] = form.addNumberField(dashx.app.formLines[formLineCnt], nil, 1, 24, function()
        if dashx.session.modelPreferences and dashx.session.modelPreferences.battery then return dashx.session.modelPreferences.battery.batteryCellCount end
        return nil
    end, function(newValue) if dashx.session.modelPreferences then dashx.session.modelPreferences.battery.batteryCellCount = newValue end end)

    dashx.app.formFields[formFieldCount]:default(3)

    formFieldCount = formFieldCount + 1
    formLineCnt = formLineCnt + 1
    dashx.app.formLines[formLineCnt] = form.addLine("@i18n(app.modules.model.battery_warning_voltage)@")
    dashx.app.formFields[formFieldCount] = form.addNumberField(dashx.app.formLines[formLineCnt], nil, 5, 600, function()
        if dashx.session.modelPreferences and dashx.session.modelPreferences.battery then return dashx.session.modelPreferences.battery.vbatwarningcellvoltage end
        return nil
    end, function(newValue) if dashx.session.modelPreferences then dashx.session.modelPreferences.battery.vbatwarningcellvoltage = newValue end end)
    dashx.app.formFields[formFieldCount]:suffix("v")
    dashx.app.formFields[formFieldCount]:default(35)
    dashx.app.formFields[formFieldCount]:decimals(1)

    formFieldCount = formFieldCount + 1
    formLineCnt = formLineCnt + 1
    dashx.app.formLines[formLineCnt] = form.addLine("@i18n(app.modules.model.battery_min_voltage)@")
    dashx.app.formFields[formFieldCount] = form.addNumberField(dashx.app.formLines[formLineCnt], nil, 5, 600, function()
        if dashx.session.modelPreferences and dashx.session.modelPreferences.battery then return dashx.session.modelPreferences.battery.vbatmincellvoltage end
        return nil
    end, function(newValue) if dashx.session.modelPreferences then dashx.session.modelPreferences.battery.vbatmincellvoltage = newValue end end)
    dashx.app.formFields[formFieldCount]:suffix("v")
    dashx.app.formFields[formFieldCount]:default(33)
    dashx.app.formFields[formFieldCount]:decimals(1)

    formFieldCount = formFieldCount + 1
    formLineCnt = formLineCnt + 1
    dashx.app.formLines[formLineCnt] = form.addLine("@i18n(app.modules.model.battery_max_voltage)@")
    dashx.app.formFields[formFieldCount] = form.addNumberField(dashx.app.formLines[formLineCnt], nil, 5, 600, function()
        if dashx.session.modelPreferences and dashx.session.modelPreferences.battery then return dashx.session.modelPreferences.battery.vbatmaxcellvoltage end
        return nil
    end, function(newValue) if dashx.session.modelPreferences then dashx.session.modelPreferences.battery.vbatmaxcellvoltage = newValue end end)
    dashx.app.formFields[formFieldCount]:suffix("v")
    dashx.app.formFields[formFieldCount]:default(43)
    dashx.app.formFields[formFieldCount]:decimals(1)

    formFieldCount = formFieldCount + 1
    formLineCnt = formLineCnt + 1
    dashx.app.formLines[formLineCnt] = form.addLine("@i18n(app.modules.model.battery_full_voltage)@")
    dashx.app.formFields[formFieldCount] = form.addNumberField(dashx.app.formLines[formLineCnt], nil, 5, 600, function()
        if dashx.session.modelPreferences and dashx.session.modelPreferences.battery then return dashx.session.modelPreferences.battery.vbatfullcellvoltage end
        return nil
    end, function(newValue) if dashx.session.modelPreferences then dashx.session.modelPreferences.battery.vbatfullcellvoltage = newValue end end)
    dashx.app.formFields[formFieldCount]:suffix("v")
    dashx.app.formFields[formFieldCount]:default(41)
    dashx.app.formFields[formFieldCount]:decimals(1)

    formFieldCount = formFieldCount + 1
    formLineCnt = formLineCnt + 1
    dashx.app.formLines[formLineCnt] = form.addLine("@i18n(app.modules.model.battery_consumption_warning_percentage)@")
    dashx.app.formFields[formFieldCount] = form.addNumberField(dashx.app.formLines[formLineCnt], nil, 0, 100, function()
        if dashx.session.modelPreferences and dashx.session.modelPreferences.battery then return dashx.session.modelPreferences.battery.consumptionWarningPercentage end
        return nil
    end, function(newValue) if dashx.session.modelPreferences then dashx.session.modelPreferences.battery.consumptionWarningPercentage = newValue end end)
    dashx.app.formFields[formFieldCount]:suffix("%")
    dashx.app.formFields[formFieldCount]:default(30)

    formFieldCount = formFieldCount + 1
    formLineCnt = formLineCnt + 1
    dashx.app.formLines[formLineCnt] = form.addLine("@i18n(app.modules.model.enable_fuel_countdown)@")
    dashx.app.formFields[formFieldCount] = form.addBooleanField(dashx.app.formLines[formLineCnt], nil, function()
        if dashx.session.modelPreferences and dashx.session.modelPreferences.battery then
            return (tonumber(dashx.session.modelPreferences.battery.fuelCountdownEnabled) or 0) == 1
        end
        return false
    end, function(newValue)
        if dashx.session.modelPreferences then
            dashx.session.modelPreferences.battery.fuelCountdownEnabled = boolFieldValueToFlag(newValue)
        end
    end)

    formFieldCount = formFieldCount + 1
    formLineCnt = formLineCnt + 1
    dashx.app.formLines[formLineCnt] = form.addLine("@i18n(app.modules.model.fuel_countdown_start)@")
    dashx.app.formFields[formFieldCount] = form.addNumberField(dashx.app.formLines[formLineCnt], nil, 1, 100, function()
        if dashx.session.modelPreferences and dashx.session.modelPreferences.battery then return dashx.session.modelPreferences.battery.fuelCountdownStart end
        return nil
    end, function(newValue) if dashx.session.modelPreferences then dashx.session.modelPreferences.battery.fuelCountdownStart = newValue end end)
    dashx.app.formFields[formFieldCount]:suffix("%")
    dashx.app.formFields[formFieldCount]:default(50)

    formFieldCount = formFieldCount + 1
    formLineCnt = formLineCnt + 1
    dashx.app.formLines[formLineCnt] = form.addLine("@i18n(app.modules.model.fuel_countdown_minimum)@")
    dashx.app.formFields[formFieldCount] = form.addNumberField(dashx.app.formLines[formLineCnt], nil, 0, 100, function()
        if dashx.session.modelPreferences and dashx.session.modelPreferences.battery then return dashx.session.modelPreferences.battery.fuelCountdownMin end
        return nil
    end, function(newValue) if dashx.session.modelPreferences then dashx.session.modelPreferences.battery.fuelCountdownMin = newValue end end)
    dashx.app.formFields[formFieldCount]:suffix("%")
    dashx.app.formFields[formFieldCount]:default(10)

    formFieldCount = formFieldCount + 1
    formLineCnt = formLineCnt + 1
    dashx.app.formLines[formLineCnt] = form.addLine("@i18n(app.modules.model.fuel_countdown_step)@")
    dashx.app.formFields[formFieldCount] = form.addNumberField(dashx.app.formLines[formLineCnt], nil, 1, 50, function()
        if dashx.session.modelPreferences and dashx.session.modelPreferences.battery then return dashx.session.modelPreferences.battery.fuelCountdownStep end
        return nil
    end, function(newValue) if dashx.session.modelPreferences then dashx.session.modelPreferences.battery.fuelCountdownStep = newValue end end)
    dashx.app.formFields[formFieldCount]:suffix("%")
    dashx.app.formFields[formFieldCount]:default(10)

    formFieldCount = formFieldCount + 1
    formLineCnt = formLineCnt + 1
    dashx.app.formLines[formLineCnt] = form.addLine("@i18n(app.modules.model.consumption_scale)@")
    dashx.app.formFields[formFieldCount] = form.addNumberField(dashx.app.formLines[formLineCnt], nil, 50, 200, function()
        if dashx.session.modelPreferences and dashx.session.modelPreferences.battery then return dashx.session.modelPreferences.battery.consumptionScale end
        return nil
    end, function(newValue) if dashx.session.modelPreferences then dashx.session.modelPreferences.battery.consumptionScale = newValue end end)
    dashx.app.formFields[formFieldCount]:suffix("%")
    dashx.app.formFields[formFieldCount]:default(100)

    enableWakeup = true

end

local function onNavMenu()
    dashx.app.ui.progressDisplay()
    dashx.app.ui.openPage(pageIdx, "@i18n(app.modules.model.name)@", "model/model.lua")
end

local function onSaveMenu()
    local buttons = {
        {
            label = "@i18n(app.btn_ok_long)@",
            action = function()
                local msg = "@i18n(app.modules.profile_select.save_prompt_local)@"
                dashx.app.ui.progressDisplaySave(msg:gsub("%?$", "."))

                if dashx.session.mcu_id and dashx.session.modelPreferencesFile then
                    for key, value in pairs(settings) do dashx.session.modelPreferences.battery[key] = value end

                    dashx.ini.save_ini_file(dashx.session.modelPreferencesFile, dashx.session.modelPreferences)
                end

                dashx.app.triggers.closeSave = true

                if dashx.tasks and dashx.tasks.sensors then dashx.tasks.sensors.reset() end

                return true
            end
        }, {label = "@i18n(app.modules.profile_select.cancel)@", action = function() return true end}
    }

    form.openDialog({width = nil, title = "@i18n(app.modules.profile_select.save_settings)@", message = "@i18n(app.modules.profile_select.save_prompt_local)@", buttons = buttons, wakeup = function() end, paint = function() end, options = TEXT_LEFT})
end

local function event(widget, category, value, x, y)

    if (category == EVT_CLOSE and value == 0) or value == 35 then
        dashx.app.ui.openPage(pageIdx, "@i18n(app.modules.model.name)@", "model/model.lua")
        return true
    end
end

local function wakeup()
    if enableWakeup then

        if not dashx.tasks.telemetry.getSensorSource("consumption") then
            dashx.session.modelPreferences.battery.calc_local = 1
            dashx.app.formFields[1]:enable(false)
        end

        if not dashx.session.isConnected then dashx.app.ui.openMainMenu() end

    end
end

return {event = event, openPage = openPage, wakeup = wakeup, onNavMenu = onNavMenu, onSaveMenu = onSaveMenu, navButtons = {menu = true, save = true, reload = false, tool = false, help = false}, API = {}}
