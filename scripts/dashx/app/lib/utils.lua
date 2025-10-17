--[[
  Copyright (C) 2025 Rob Thomson
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local dashx = require("dashx")

local utils = {}

local arg = {...}
local config = arg[1]

function utils.getRSSI()

    if dashx.simevent.rflink == 1 then return 0 end

    if dashx.app.offlineMode == true then return 100 end

    if dashx.session.telemetryState then
        return 100
    else
        return 0
    end
end

function utils.getWindowSize() return lcd.getWindowSize() end

function utils.convertPageValueTable(tbl, inc)
    local thetable = {}

    if inc == nil then inc = 0 end

    if tbl[0] ~= nil then
        thetable[0] = {}
        thetable[0][1] = tbl[0]
        thetable[0][2] = 0
    end
    for idx, value in ipairs(tbl) do
        thetable[idx] = {}
        thetable[idx][1] = value
        thetable[idx][2] = idx + inc
    end

    return thetable
end

function utils.getFieldValue(f)
    local v = f.value or 0

    if f.decimals then v = dashx.utils.round(v * dashx.app.utils.decimalInc(f.decimals), 2) end

    if f.offset then v = v + f.offset end

    if f.mult then v = math.floor(v * f.mult + 0.5) end

    return v
end

function utils.saveFieldValue(f, value)
    if value then
        if f.offset then value = value - f.offset end
        if f.decimals then
            f.value = value / dashx.app.utils.decimalInc(f.decimals)
        else
            f.value = value
        end
        if f.postEdit then f.postEdit(dashx.app.Page) end
    end

    if f.mult then f.value = f.value / f.mult end

    return f.value
end

function utils.scaleValue(value, f)
    if not value then return nil end
    local v = value * dashx.app.utils.decimalInc(f.decimals)
    if f.scale then v = v / f.scale end
    return dashx.utils.round(v)
end

function utils.decimalInc(dec)
    if dec == nil then
        return 1
    elseif dec > 0 and dec <= 10 then
        return 10 ^ dec
    else
        return nil
    end
end

function utils.getInlinePositions(f, lPage)

    local inline_size = utils.getInlineSize(f.label, lPage) * dashx.app.radio.inlinesize_mult

    local w, h = dashx.utils.getWindowSize()

    local padding = 5
    local fieldW = (w * inline_size) / 100
    local eW = fieldW - padding
    local eH = dashx.app.radio.navbuttonHeight
    local eY = dashx.app.radio.linePaddingTop

    f.t = f.t or ""
    lcd.font(FONT_M)
    local tsizeW, tsizeH = lcd.getTextSize(f.t)

    local multipliers = {[1] = 1, [2] = 3, [3] = 5, [4] = 7, [5] = 9}
    local m = multipliers[f.inline] or 1

    local textPadding = (f.inline == 1) and (2 * padding) or padding

    local posTextX = w - fieldW * m - tsizeW - textPadding
    local posFieldX = w - fieldW * m - ((f.inline == 1) and padding or 0)

    local posText = {x = posTextX, y = eY, w = tsizeW, h = eH}
    local posField = {x = posFieldX, y = eY, w = eW, h = eH}

    return {posText = posText, posField = posField}
end

function utils.getInlineSize(id, lPage)
    if not id then return 13.6 end
    for i = 1, #lPage.labels do if lPage.labels[i].label == id then return lPage.labels[i].inline_size or 13.6 end end
    return 13.6
end

return utils

