--[[
  Copyright (C) 2025 Rob Thomson
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local dashx = require("dashx")

local utils = dashx.widgets.dashboard.utils
local boxes_cache = nil
local themeconfig = nil
local lastScreenW = nil

local darkMode = {
    textcolor = "white",
    titlecolor = "white",
    bgcolor = "black",
    fillcolor = "green",
    fillbgcolor = "darkgrey",
    accentcolor = "white",
    rssifillcolor = "green",
    rssifillbgcolor = "darkgrey",
    txaccentcolor = "grey",
    txfillcolor = "green",
    txbgfillcolor = "darkgrey",
    bgcolortop = lcd.RGB(10, 10, 10)
}

local lightMode = {
    textcolor = "black",
    titlecolor = "black",
    bgcolor = "white",
    fillcolor = "green",
    fillbgcolor = "lightgrey",
    accentcolor = "darkgrey",
    rssifillcolor = "green",
    rssifillbgcolor = "grey",
    txaccentcolor = "darkgrey",
    txfillcolor = "green",
    txbgfillcolor = "grey",
    bgcolortop = "grey"
}

local function getUserVoltageOverride(which)
    local prefs = dashx.session and dashx.session.modelPreferences
    if prefs and prefs["system/@default"] then
        local v = tonumber(prefs["system/@default"][which])

        if which == "v_min" and v and math.abs(v - 18.0) > 0.05 then return v end
        if which == "v_max" and v and math.abs(v - 25.2) > 0.05 then return v end
    end
    return nil
end

local colorMode = lcd.darkMode() and darkMode or lightMode

local theme_section = "system/@default"

local THEME_DEFAULTS = {rpm_min = 0, rpm_max = 3000, bec_min = 3.0, bec_max = 13.0, esctemp_warn = 90, esctemp_max = 140, tx_min = 7.2, tx_warn = 7.4, tx_max = 8.4}

local function getThemeOptionKey(W)
    if W == 800 then
        return "ls_full"
    elseif W == 784 then
        return "ls_std"
    elseif W == 640 then
        return "ss_full"
    elseif W == 630 then
        return "ss_std"
    elseif W == 480 then
        return "ms_full"
    elseif W == 472 then
        return "ms_std"
    end
end

local themeOptions = {

    ls_full = {font = "FONT_XXL", advfont = "FONT_M", thickness = 35, batteryframethickness = 4, titlepaddingbottom = 15, valuepaddingleft = 25, valuepaddingtop = 20, valuepaddingbottom = 25, gaugepaddingtop = 20, gaugepadding = 20},

    ls_std = {font = "FONT_XL", advfont = "FONT_M", thickness = 35, batteryframethickness = 4, titlepaddingbottom = 0, valuepaddingleft = 75, valuepaddingtop = 5, valuepaddingbottom = 25, gaugepaddingtop = 5, gaugepadding = 10},

    ms_full = {font = "FONT_XXL", advfont = "FONT_M", thickness = 27, batteryframethickness = 4, titlepaddingbottom = 0, valuepaddingleft = 20, valuepaddingtop = 5, valuepaddingbottom = 15, gaugepaddingtop = 5, gaugepadding = 10},

    ms_std = {font = "FONT_XL", advfont = "FONT_S", thickness = 20, batteryframethickness = 2, titlepaddingbottom = 0, valuepaddingleft = 20, valuepaddingtop = 10, valuepaddingbottom = 25, gaugepaddingtop = 5, gaugepadding = 5},

    ss_full = {font = "FONT_XL", advfont = "FONT_M", thickness = 25, batteryframethickness = 4, titlepaddingbottom = 0, valuepaddingleft = 20, valuepaddingtop = 5, valuepaddingbottom = 15, gaugepaddingtop = 5, gaugepadding = 10},

    ss_std = {font = "FONT_XL", advfont = "FONT_S", thickness = 22, batteryframethickness = 2, titlepaddingbottom = 0, valuepaddingleft = 20, valuepaddingtop = 10, valuepaddingbottom = 25, gaugepaddingtop = 5, gaugepadding = 10}
}

local function getThemeValue(key)
    if dashx and dashx.session and dashx.session.modelPreferences and dashx.session.modelPreferences[theme_section] then
        local val = dashx.session.modelPreferences[theme_section][key]
        val = tonumber(val)
        if val ~= nil then return val end
    end
    return THEME_DEFAULTS[key]
end

local lastScreenW = nil
local boxes_cache = nil
local themeconfig = nil
local headeropts = utils.getHeaderOptions()

local layout = {cols = 4, rows = 14, padding = 1}

local header_layout = {height = headeropts.height, cols = 7, rows = 1, padding = 0}

local function buildBoxes(W)

    local opts = themeOptions[getThemeOptionKey(W)] or themeOptions.unknown

    return {

        {
            type = "gauge",
            subtype = "arc",
            col = 1,
            row = 1,
            rowspan = 12,
            colspan = 2,
            source = "voltage",
            thickness = opts.thickness,
            font = opts.font,
            arcbgcolor = colorMode.arcbgcolor,
            title = "VOLTAGE",
            titlepos = "bottom",
            bgcolor = colorMode.bgcolor,
            gaugepadding = opts.gaugepadding,
            valuepaddingtop = opts.valuepaddingtop,
            min = function()
                local cfg = dashx.session.batteryConfig
                local cells = (cfg and cfg.batteryCellCount) or 3
                local minV = (cfg and cfg.vbatmincellvoltage) or 3.0
                return math.max(0, cells * minV)
            end,

            max = function()
                local cfg = dashx.session.batteryConfig
                local cells = (cfg and cfg.batteryCellCount) or 3
                local maxV = (cfg and cfg.vbatfullcellvoltage) or 4.2
                return math.max(0, cells * maxV)
            end,

            thresholds = {
                {
                    value = function(box)

                        local raw_gm = utils.getParam(box, "min")
                        if type(raw_gm) == "function" then raw_gm = raw_gm(box) end

                        local raw_gM = utils.getParam(box, "max")
                        if type(raw_gM) == "function" then raw_gM = raw_gM(box) end

                        return raw_gm + 0.30 * (raw_gM - raw_gm)
                    end,
                    fillcolor = "red",
                    textcolor = colorMode.textcolor
                }, {
                    value = function(box)
                        local raw_gm = utils.getParam(box, "min")
                        if type(raw_gm) == "function" then raw_gm = raw_gm(box) end

                        local raw_gM = utils.getParam(box, "max")
                        if type(raw_gM) == "function" then raw_gM = raw_gM(box) end

                        return raw_gm + 0.50 * (raw_gM - raw_gm)
                    end,
                    fillcolor = "orange",
                    textcolor = colorMode.textcolor
                }, {
                    value = function(box)
                        local raw_gM = utils.getParam(box, "max")
                        if type(raw_gM) == "function" then raw_gM = raw_gM(box) end

                        return raw_gM
                    end,
                    fillcolor = colorMode.fillcolor,
                    textcolor = colorMode.textcolor
                }
            }
        }, {
            type = "gauge",
            subtype = "arc",
            col = 3,
            row = 1,
            rowspan = 12,
            thickness = opts.thickness,
            colspan = 2,
            source = "smartfuel",
            transform = "floor",
            min = 0,
            max = 140,
            font = opts.font,
            arcbgcolor = colorMode.arcbgcolor,
            title = "FUEL",
            titlepos = "bottom",
            bgcolor = colorMode.bgcolor,
            titlecolor = colorMode.titlecolor,
            textcolor = colorMode.titlecolor,
            gaugepadding = opts.gaugepadding,
            valuepaddingtop = opts.valuepaddingtop,
            thresholds = {{value = 30, fillcolor = "red", textcolor = colorMode.textcolor}, {value = 50, fillcolor = "orange", textcolor = colorMode.textcolor}, {value = 140, fillcolor = colorMode.fillcolor, textcolor = colorMode.textcolor}}
        }, {col = 1, row = 13, rowspan = 2, type = "text", subtype = "telemetry", nosource = "-", source = "temp_esc", transform = "floor", bgcolor = colorMode.bgcolor, titlecolor = colorMode.titlecolor, textcolor = colorMode.titlecolor},
        {col = 4, row = 13, rowspan = 2, type = "time", subtype = "flight", bgcolor = colorMode.bgcolor, titlecolor = colorMode.titlecolor, textcolor = colorMode.titlecolor},
        {col = 3, row = 13, rowspan = 2, type = "text", subtype = "telemetry", source = "rpm", nosource = "-", unit = "rpm", transform = "floor", bgcolor = colorMode.bgcolor, titlecolor = colorMode.titlecolor, textcolor = colorMode.titlecolor},
        {col = 2, row = 13, rowspan = 2, type = "text", subtype = "telemetry", source = "rssi", nosource = "-", unit = "dB", transform = "floor", bgcolor = colorMode.bgcolor, titlecolor = colorMode.titlecolor, textcolor = colorMode.titlecolor}

    }
end

local header_boxes = {

    {col = 1, row = 1, colspan = 2, type = "text", subtype = "craftname", font = headeropts.font, valuealign = "left", valuepaddingleft = 5, bgcolor = colorMode.bgcolortop, titlecolor = colorMode.titlecolor, textcolor = colorMode.textcolor},

    {col = 3, row = 1, colspan = 3, type = "image", subtype = "image", bgcolor = colorMode.bgcolortop}, {
        col = 6,
        row = 1,
        type = "gauge",
        subtype = "bar",
        source = "txbatt",
        font = headeropts.font,
        battery = true,
        batteryframe = true,
        hidevalue = true,
        valuealign = "left",
        batterysegments = 4,
        batteryspacing = 1,
        batteryframethickness = 2,
        batterysegmentpaddingtop = headeropts.batterysegmentpaddingtop,
        batterysegmentpaddingbottom = headeropts.batterysegmentpaddingbottom,
        batterysegmentpaddingleft = headeropts.batterysegmentpaddingleft,
        batterysegmentpaddingright = headeropts.batterysegmentpaddingright,
        gaugepaddingright = headeropts.gaugepaddingright,
        gaugepaddingleft = headeropts.gaugepaddingleft,
        gaugepaddingbottom = headeropts.gaugepaddingbottom,
        gaugepaddingtop = headeropts.gaugepaddingtop,
        fillbgcolor = colorMode.txbgfillcolor,
        bgcolor = colorMode.bgcolortop,
        accentcolor = colorMode.txaccentcolor,
        textcolor = colorMode.textcolor,
        min = getThemeValue("tx_min"),
        max = getThemeValue("tx_max"),
        thresholds = {{value = getThemeValue("tx_warn"), fillcolor = "orange"}, {value = getThemeValue("tx_max"), fillcolor = colorMode.txfillcolor}}
    }, {
        col = 7,
        row = 1,
        type = "gauge",
        subtype = "step",
        source = "rssi",
        font = "FONT_XS",
        stepgap = 2,
        stepcount = 5,
        decimals = 0,
        valuealign = "left",
        barpaddingleft = headeropts.barpaddingleft,
        barpaddingright = headeropts.barpaddingright,
        barpaddingbottom = headeropts.barpaddingbottom,
        barpaddingtop = headeropts.barpaddingtop,
        valuepaddingleft = headeropts.valuepaddingleft,
        valuepaddingbottom = headeropts.valuepaddingbottom,
        bgcolor = colorMode.bgcolortop,
        textcolor = colorMode.textcolor,
        fillcolor = colorMode.rssifillcolor,
        fillbgcolor = colorMode.rssifillbgcolor
    }
}

local function boxes()
    local config = dashx and dashx.session and dashx.session.modelPreferences and dashx.session.modelPreferences[theme_section]
    local W = lcd.getWindowSize()
    if boxes_cache == nil or themeconfig ~= config or lastScreenW ~= W then
        boxes_cache = buildBoxes(W)
        themeconfig = config
        lastScreenW = W
    end
    return boxes_cache
end

return {layout = layout, boxes = boxes, header_boxes = header_boxes, header_layout = header_layout, scheduler = {spread_scheduling = true, spread_scheduling_paint = false, spread_ratio = 0.5}}
