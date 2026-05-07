--[[
  Copyright (C) 2026 Rob Thomson
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local dashx = require("dashx")

local configui = {}

local function clamp(value, minimum, maximum)
    if value < minimum then
        return minimum
    end
    if value > maximum then
        return maximum
    end
    return value
end

local function addLine(parent, label)
    if parent and parent.addLine then
        return parent:addLine(label)
    end
    return form.addLine(label)
end

local function ensureWidgetDefaults(widget)
    dashx.runtime.readWidgetSettings(widget)
end

local function getModelThemeValue(widget)
    local value = widget.theme_preflight
    if value == nil or value == false or value == "nil" then
        return "system/default"
    end
    return value
end

local function buildModelThemeChoices(themeList)
    local choices = {}
    local byValue = {}

    for _, theme in ipairs(themeList or {}) do
        local value = theme.source .. "/" .. theme.folder
        if value == "system/default" or value == "system/@rt-rc" then
            local label = value == "system/default" and "Default" or "RT-RC"
            choices[#choices + 1] = {label, theme.idx}
            byValue[value] = theme.idx
        end
    end

    return choices, byValue
end

local function encodeModelThemeChoice(widget, byValue)
    local storedValue = getModelThemeValue(widget)
    return byValue[storedValue] or byValue["system/default"]
end

local function applyModelThemeChoice(widget, themeList, selectedValue)
    local value = "system/default"

    for _, theme in ipairs(themeList or {}) do
        if theme.idx == selectedValue then
            value = theme.source .. "/" .. theme.folder
            break
        end
    end

    widget.theme_preflight = value
    widget.theme_inflight = value
    widget.theme_postflight = value
end

local function decodeSwitchSpec(spec)
    if type(spec) ~= "string" or spec == "" or spec == "false" then
        return nil
    end

    local category, member, options = spec:match("([^:]+):([^:]+):([^:]+)")
    if not category or not member then
        return nil
    end

    return system.getSource({
        category = tonumber(category) or category,
        member = tonumber(member) or member,
        options = tonumber(options) or options
    })
end

local function encodeSwitchSource(source)
    if not source then
        return false
    end

    return table.concat({source:category(), source:member(), source:options()}, ":")
end

function configui.read(widget)
    ensureWidgetDefaults(widget)
    return true
end

function configui.write(widget)
    return dashx.runtime.writeWidgetSettings(widget)
end

function configui.configure(widget)
    ensureWidgetDefaults(widget)

    local themeLine = addLine(nil, "Theme for this model")
    local themeList = dashx.widgets.dashboard.listThemes()
    local themeChoices, themeValueMap = buildModelThemeChoices(themeList)
    form.addChoiceField(themeLine, nil, themeChoices, function()
        return encodeModelThemeChoice(widget, themeValueMap)
    end, function(value)
        applyModelThemeChoice(widget, themeList, value)
    end)

    local batteryPanel = form.addExpansionPanel("@i18n(app.modules.model.battery)@")
    batteryPanel:open(true)

    local fuelModeLine = addLine(batteryPanel, "@i18n(app.modules.model.calcfuel_using)@")
    form.addChoiceField(fuelModeLine, nil, {
        {"@i18n(app.modules.model.calcfuel_current)@", 0},
        {"@i18n(app.modules.model.calcfuel_voltage)@", 1}
    }, function()
        return clamp(math.floor(tonumber(widget.calc_local) or 0), 0, 1)
    end, function(value)
        widget.calc_local = clamp(math.floor(tonumber(value) or 0), 0, 1)
    end)

    local capacityLine = addLine(batteryPanel, "@i18n(app.modules.model.battery_capacity)@")
    local capacityField = form.addNumberField(capacityLine, nil, 0, 10000000, function()
        return math.floor(tonumber(widget.batteryCapacity) or 2200)
    end, function(value)
        widget.batteryCapacity = clamp(math.floor(tonumber(value) or 2200), 0, 10000000)
    end)
    if capacityField and capacityField.suffix then
        capacityField:suffix("mAh")
    end

    local cellsLine = addLine(batteryPanel, "@i18n(app.modules.model.battery_cells)@")
    local cellsField = form.addNumberField(cellsLine, nil, 1, 24, function()
        return math.floor(tonumber(widget.batteryCellCount) or 3)
    end, function(value)
        widget.batteryCellCount = clamp(math.floor(tonumber(value) or 3), 1, 24)
    end)
    if cellsField and cellsField.suffix then
        cellsField:suffix("S")
    end

    local warnLine = addLine(batteryPanel, "@i18n(app.modules.model.battery_warning_voltage)@")
    local warnField = form.addNumberField(warnLine, nil, 5, 600, function()
        return math.floor(tonumber(widget.vbatwarningcellvoltage) or 35)
    end, function(value)
        widget.vbatwarningcellvoltage = clamp(math.floor(tonumber(value) or 35), 5, 600)
    end)
    if warnField then
        warnField:suffix("v")
        warnField:decimals(1)
    end

    local minLine = addLine(batteryPanel, "@i18n(app.modules.model.battery_min_voltage)@")
    local minField = form.addNumberField(minLine, nil, 5, 600, function()
        return math.floor(tonumber(widget.vbatmincellvoltage) or 33)
    end, function(value)
        widget.vbatmincellvoltage = clamp(math.floor(tonumber(value) or 33), 5, 600)
    end)
    if minField then
        minField:suffix("v")
        minField:decimals(1)
    end

    local maxLine = addLine(batteryPanel, "@i18n(app.modules.model.battery_max_voltage)@")
    local maxField = form.addNumberField(maxLine, nil, 5, 600, function()
        return math.floor(tonumber(widget.vbatmaxcellvoltage) or 43)
    end, function(value)
        widget.vbatmaxcellvoltage = clamp(math.floor(tonumber(value) or 43), 5, 600)
    end)
    if maxField then
        maxField:suffix("v")
        maxField:decimals(1)
    end

    local fullLine = addLine(batteryPanel, "@i18n(app.modules.model.battery_full_voltage)@")
    local fullField = form.addNumberField(fullLine, nil, 5, 600, function()
        return math.floor(tonumber(widget.vbatfullcellvoltage) or 41)
    end, function(value)
        widget.vbatfullcellvoltage = clamp(math.floor(tonumber(value) or 41), 5, 600)
    end)
    if fullField then
        fullField:suffix("v")
        fullField:decimals(1)
    end

    local reserveLine = addLine(batteryPanel, "@i18n(app.modules.model.battery_consumption_warning_percentage)@")
    local reserveField = form.addNumberField(reserveLine, nil, 0, 100, function()
        return math.floor(tonumber(widget.consumptionWarningPercentage) or 30)
    end, function(value)
        widget.consumptionWarningPercentage = clamp(math.floor(tonumber(value) or 30), 0, 100)
    end)
    if reserveField and reserveField.suffix then
        reserveField:suffix("%")
    end

    local scaleLine = addLine(batteryPanel, "@i18n(app.modules.model.consumption_scale)@")
    local scaleField = form.addNumberField(scaleLine, nil, 50, 200, function()
        return math.floor(tonumber(widget.consumptionScale) or 100)
    end, function(value)
        widget.consumptionScale = clamp(math.floor(tonumber(value) or 100), 50, 200)
    end)
    if scaleField and scaleField.suffix then
        scaleField:suffix("%")
    end

    local triggersPanel = form.addExpansionPanel("@i18n(app.modules.model.triggers)@")
    triggersPanel:open(false)

    local armLine = addLine(triggersPanel, "@i18n(app.modules.model.model_armswitch)@")
    form.addSwitchField(armLine, nil, function()
        return decodeSwitchSpec(widget.armswitch)
    end, function(newValue)
        widget.armswitch = encodeSwitchSource(newValue)
    end)

    local inflightLine = addLine(triggersPanel, "@i18n(app.modules.model.model_inflightswitch)@")
    form.addSwitchField(inflightLine, nil, function()
        return decodeSwitchSpec(widget.inflightswitch)
    end, function(newValue)
        widget.inflightswitch = encodeSwitchSource(newValue)
    end)

    local delayLine = addLine(triggersPanel, "@i18n(app.modules.model.model_inflightswitch_delay)@")
    local delayField = form.addNumberField(delayLine, nil, 0, 120, function()
        return math.floor(tonumber(widget.inflightswitch_delay) or 10)
    end, function(value)
        widget.inflightswitch_delay = clamp(math.floor(tonumber(value) or 10), 0, 120)
    end)
    if delayField and delayField.suffix then
        delayField:suffix("s")
    end
end

return configui
