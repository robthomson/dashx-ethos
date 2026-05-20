--[[
  Copyright (C) 2025 Rob Thomson
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local dashx = require("dashx")

local utils = {}

local imageCache = {}
local fontCache
local COLOR_WHITE = lcd.RGB(255, 255, 255)
local COLOR_BLACK = lcd.RGB(0, 0, 0)
local GAUGE_TRAFFIC_GREEN = lcd.RGB(0, 188, 4)
local GAUGE_TRAFFIC_AMBER = lcd.RGB(255, 170, 0)
local GAUGE_TRAFFIC_RED = lcd.RGB(224, 64, 64)

local THEME_SIGNATURE_MOD = 2147483647
local ETHOS_THEME_MIN_VERSION = {26, 1, 0}
local THEME_STATE_KEYS = {
    {key = "defaultColor", constant = "THEME_DEFAULT_COLOR"},
    {key = "defaultBgColor", constant = "THEME_DEFAULT_BGCOLOR"},
    {key = "focusBgColor", constant = "THEME_FOCUS_BGCOLOR"},
    {key = "focusColor", constant = "THEME_FOCUS_COLOR"},
    {key = "primaryColor", constant = "THEME_PRIMARY_COLOR"},
    {key = "primaryBgColor", constant = "THEME_PRIMARY_BGCOLOR"},
    {key = "secondaryColor", constant = "THEME_SECONDARY_COLOR"},
    {key = "secondaryBgColor", constant = "THEME_SECONDARY_BGCOLOR"},
    {key = "highlightColor", constant = "THEME_HIGHLIGHT_COLOR"},
    {key = "highlightInvertColor", constant = "THEME_HIGHLIGHT_INVERT_COLOR"},
    {key = "disableColor", constant = "THEME_DISABLE_COLOR"},
    {key = "warningColor", constant = "THEME_WARNING_COLOR"},
    {key = "activeColor", constant = "THEME_ACTIVE_COLOR"},
    {key = "inactiveColor", constant = "THEME_INACTIVE_COLOR"},
    {key = "buttonBorderActiveColor", constant = "THEME_BUTTON_BORDER_ACTIVE_COLOR"},
    {key = "buttonBorderColor", constant = "THEME_BUTTON_BORDER_COLOR"},
    {key = "mixerOutputColor", constant = "THEME_MIXER_OUTPUT_COLOR"},
    {key = "pageBgColor", constant = "THEME_PAGE_BGCOLOR"},
    {key = "topLcdBgColor", constant = "THEME_TOPLCD_BGCOLOR"}
}
local LEGACY_THEME_STATE = {
    dark = {
        defaultColor = lcd.RGB(255, 255, 255),
        defaultBgColor = lcd.RGB(35, 35, 35),
        primaryColor = lcd.RGB(255, 255, 255),
        primaryBgColor = lcd.RGB(0, 0, 0),
        secondaryColor = lcd.RGB(185, 185, 185),
        secondaryBgColor = lcd.RGB(40, 40, 40),
        focusBgColor = lcd.RGB(40, 40, 40),
        focusColor = lcd.RGB(255, 255, 255),
        highlightColor = lcd.RGB(255, 255, 255),
        highlightInvertColor = lcd.RGB(0, 0, 0),
        disableColor = lcd.RGB(90, 90, 90),
        warningColor = lcd.RGB(255, 0, 0),
        activeColor = lcd.RGB(0, 188, 4),
        inactiveColor = lcd.RGB(255, 0, 0),
        buttonBorderActiveColor = lcd.RGB(255, 255, 255),
        buttonBorderColor = lcd.RGB(90, 90, 90),
        mixerOutputColor = lcd.RGB(0, 188, 4),
        pageBgColor = lcd.RGB(16, 16, 16),
        topLcdBgColor = lcd.RGB(35, 35, 35)
    },
    light = {
        defaultColor = lcd.RGB(0, 0, 0),
        defaultBgColor = lcd.RGB(230, 230, 230),
        primaryColor = lcd.RGB(0, 0, 0),
        primaryBgColor = lcd.RGB(255, 255, 255),
        secondaryColor = lcd.RGB(90, 90, 90),
        secondaryBgColor = lcd.RGB(211, 211, 211),
        focusBgColor = lcd.RGB(211, 211, 211),
        focusColor = lcd.RGB(0, 0, 0),
        highlightColor = lcd.RGB(90, 90, 90),
        highlightInvertColor = lcd.RGB(255, 255, 255),
        disableColor = lcd.RGB(185, 185, 185),
        warningColor = lcd.RGB(255, 0, 0),
        activeColor = lcd.RGB(0, 188, 4),
        inactiveColor = lcd.RGB(255, 0, 0),
        buttonBorderActiveColor = lcd.RGB(90, 90, 90),
        buttonBorderColor = lcd.RGB(185, 185, 185),
        mixerOutputColor = lcd.RGB(0, 188, 4),
        pageBgColor = lcd.RGB(209, 208, 208),
        topLcdBgColor = lcd.RGB(230, 230, 230)
    }
}
local LEGACY_CHROME_THEME = {
    dark = {
        background = lcd.RGB(10, 14, 18),
        panel = lcd.RGB(22, 28, 34),
        panelAlt = lcd.RGB(17, 22, 27),
        button = lcd.RGB(36, 36, 39),
        buttonDisabled = lcd.RGB(24, 24, 27),
        text = lcd.RGB(245, 246, 247),
        muted = lcd.RGB(166, 174, 182),
        accent = lcd.RGB(231, 116, 58),
        accentSoft = lcd.RGB(72, 44, 30),
        accentText = lcd.RGB(245, 246, 247),
        accentBorder = lcd.RGB(231, 116, 58),
        border = lcd.RGB(86, 96, 106)
    },
    light = {
        background = lcd.RGB(246, 247, 249),
        panel = lcd.RGB(255, 255, 255),
        panelAlt = lcd.RGB(240, 242, 245),
        button = lcd.RGB(232, 234, 237),
        buttonDisabled = lcd.RGB(242, 244, 246),
        text = lcd.RGB(28, 34, 40),
        muted = lcd.RGB(108, 116, 124),
        accent = lcd.RGB(215, 98, 38),
        accentSoft = lcd.RGB(255, 226, 210),
        accentText = lcd.RGB(28, 34, 40),
        accentBorder = lcd.RGB(215, 98, 38),
        border = lcd.RGB(196, 202, 208)
    }
}
local LEGACY_TOOLBAR_THEME = {
    dark = {
        background = lcd.RGB(18, 22, 26),
        panel = lcd.RGB(28, 34, 40),
        accent = lcd.RGB(231, 116, 58),
        accentText = lcd.RGB(28, 34, 40),
        text = lcd.RGB(245, 246, 247),
        muted = lcd.RGB(160, 168, 176),
        border = lcd.RGB(72, 82, 90)
    },
    light = {
        background = lcd.RGB(245, 246, 248),
        panel = lcd.RGB(255, 255, 255),
        accent = lcd.RGB(215, 98, 38),
        accentText = lcd.RGB(255, 255, 255),
        text = lcd.RGB(32, 38, 44),
        muted = lcd.RGB(108, 116, 124),
        border = lcd.RGB(196, 202, 208)
    }
}
local cachedThemeSignature
local cachedThemeState
local cachedDashboardTheme
local cachedChromeTheme
local cachedToolbarTheme

local function isLegacyDarkMode()
    return lcd.darkMode and lcd.darkMode() or false
end

local _supportsThemeChecked = false
local _supportsTheme = false

local function supportsSystemThemeColors()
    if not _supportsThemeChecked and dashx and dashx.utils and dashx.utils.ethosVersionAtLeast then
        _supportsTheme = dashx.utils.ethosVersionAtLeast(ETHOS_THEME_MIN_VERSION) == true
        _supportsThemeChecked = true
    end
    return _supportsTheme
end

local function resolveSystemThemeColor(constantName)
    if not supportsSystemThemeColors() then
        return nil
    end

    local themeColor = lcd.themeColor
    if type(themeColor) ~= "function" then
        return nil
    end

    local constant = _G[constantName]
    if constant == nil then
        return nil
    end

    return themeColor(constant)
end

local function copyThemeMap(target, source)
    for key, value in pairs(source) do
        target[key] = value
    end
end

local ensureThemeColorContrast

local function resolveDashboardSurfaceBg(themeState)
    local pageBg = themeState and themeState.pageBgColor or nil
    local surfaceBg = themeState and themeState.secondaryBgColor or nil
    if surfaceBg == pageBg then surfaceBg = themeState and themeState.buttonBorderColor or nil end
    if surfaceBg == pageBg then surfaceBg = themeState and themeState.primaryBgColor or nil end
    if surfaceBg == nil then surfaceBg = pageBg or (themeState and themeState.primaryBgColor or nil) end
    return surfaceBg
end

local function resolveDashboardHeaderBg(themeState, surfaceBg)
    local headerBg = themeState and (themeState.topLcdBgColor or themeState.defaultBgColor or themeState.focusBgColor or themeState.secondaryBgColor) or nil
    if headerBg == nil then return surfaceBg end
    return headerBg
end

local function resolveDashboardHeaderTextColor(themeState, headerBg)
    local headerText = themeState and (themeState.defaultColor or themeState.primaryColor or themeState.focusColor) or nil
    if headerText == nil then return nil end
    return ensureThemeColorContrast(headerText, headerBg, 3.0)
end

local function resolveToolbarDividerColor(themeState, background)
    local divider = themeState and themeState.buttonBorderColor or nil
    if divider == background then divider = themeState and themeState.secondaryColor or nil end
    if divider == background then divider = themeState and themeState.primaryColor or nil end
    return divider or background
end

local function clampColorByte(value)
    return math.max(0, math.min(255, math.floor(value + 0.5)))
end

local function normalizeThemeColor(color)
    if type(color) ~= "number" then return nil end
    if color > 0xFFFF then
        local upper = (color >> 16) & 0xFFFF
        if upper ~= 0 then return upper end
    end
    return color & 0xFFFF
end

local function rgb565ToRgb888(color)
    local packed = normalizeThemeColor(color)
    if not packed then return nil end
    local r5 = (packed >> 11) & 0x1F
    local g6 = (packed >> 5) & 0x3F
    local b5 = packed & 0x1F
    return (r5 * 527 + 23) >> 6, (g6 * 259 + 33) >> 6, (b5 * 527 + 23) >> 6
end

local function blendThemeColors(colorA, colorB, factor)
    local r1, g1, b1 = rgb565ToRgb888(colorA)
    local r2, g2, b2 = rgb565ToRgb888(colorB)
    if r1 == nil or r2 == nil then return colorA or colorB end
    local t = type(factor) == "number" and math.max(0, math.min(1, factor)) or 0.5
    return lcd.RGB(clampColorByte(r1 + (r2 - r1) * t), clampColorByte(g1 + (g2 - g1) * t), clampColorByte(b1 + (b2 - b1) * t), 1)
end

local function relativeLuminanceChannel(channel)
    local normalized = channel / 255
    if normalized <= 0.04045 then return normalized / 12.92 end
    return ((normalized + 0.055) / 1.055) ^ 2.4
end

local function relativeLuminance(color)
    local red, green, blue = rgb565ToRgb888(color)
    if red == nil then return nil end
    return 0.2126 * relativeLuminanceChannel(red) + 0.7152 * relativeLuminanceChannel(green) + 0.0722 * relativeLuminanceChannel(blue)
end

local function contrastRatio(colorA, colorB)
    local luminanceA = relativeLuminance(colorA)
    local luminanceB = relativeLuminance(colorB)
    if luminanceA == nil or luminanceB == nil then return nil end
    local lighter = math.max(luminanceA, luminanceB)
    local darker = math.min(luminanceA, luminanceB)
    return (lighter + 0.05) / (darker + 0.05)
end

local function chooseContrastTarget(background)
    local whiteContrast = contrastRatio(COLOR_WHITE, background)
    local blackContrast = contrastRatio(COLOR_BLACK, background)
    if whiteContrast == nil then return COLOR_BLACK end
    if blackContrast == nil or whiteContrast >= blackContrast then return COLOR_WHITE end
    return COLOR_BLACK
end

ensureThemeColorContrast = function(color, background, minRatio)
    if color == nil or background == nil or minRatio == nil then return color end

    local bestColor = color
    local bestRatio = contrastRatio(color, background)
    if bestRatio == nil or bestRatio >= minRatio then return color end

    local target = chooseContrastTarget(background)
    for i = 1, 6 do
        local adjusted = blendThemeColors(color, target, i * 0.15)
        local adjustedRatio = contrastRatio(adjusted, background)
        if adjustedRatio and adjustedRatio > bestRatio then
            bestColor = adjusted
            bestRatio = adjustedRatio
        end
        if adjustedRatio and adjustedRatio >= minRatio then return adjusted end
    end

    return bestColor
end

local function resolveGaugeTrackBg(themeState, background)
    if themeState == nil then return ensureThemeColorContrast(background, background, 2.0) end

    local candidates = {
        themeState.secondaryBgColor,
        themeState.buttonBorderColor,
        themeState.focusBgColor,
        themeState.defaultBgColor,
        themeState.primaryBgColor,
        themeState.secondaryColor
    }
    local bestColor = nil
    local bestRatio = nil

    for i = 1, #candidates do
        local candidate = candidates[i]
        if candidate ~= nil and candidate ~= background then
            local ratio = contrastRatio(candidate, background)
            if ratio ~= nil then
                if ratio >= 2.0 then return candidate end
                if bestRatio == nil or ratio > bestRatio then
                    bestColor = candidate
                    bestRatio = ratio
                end
            end
        end
    end

    if bestColor ~= nil then return ensureThemeColorContrast(bestColor, background, 2.0) end
    return ensureThemeColorContrast(background, background, 2.0)
end

local function resolveGaugeThresholdPalette(themeState, background)
    local fillcolor = themeState.activeColor or themeState.mixerOutputColor or GAUGE_TRAFFIC_GREEN
    local fillwarncolor = GAUGE_TRAFFIC_AMBER
    local fillcritcolor = GAUGE_TRAFFIC_RED
    background = background or themeState.secondaryBgColor or themeState.primaryBgColor or themeState.pageBgColor
    fillcolor = ensureThemeColorContrast(fillcolor, background, 2.2)
    fillwarncolor = ensureThemeColorContrast(fillwarncolor, background, 2.2)
    fillcritcolor = ensureThemeColorContrast(fillcritcolor, background, 2.4)
    return fillcolor, fillwarncolor, fillcritcolor
end

function utils.standardHeaderLayout(headeropts) return {height = headeropts.height, cols = 7, rows = 1} end

function utils.standardHeaderBoxes(i18n, colorMode, headeropts, txbatt_type)
    local txbatt_min, txbatt_max = utils.getTxBatteryVoltageRange()
    local txbatt_warn = txbatt_min + 0.2
    txbatt_type = tonumber(txbatt_type) or 0

    local txBox
    if txbatt_type == 2 then
        txBox = txDigitalBox(colorMode, headeropts, txbatt_min, txbatt_max, txbatt_warn)
    elseif txbatt_type == 1 then
        txBox = txTextBox(colorMode, headeropts, txbatt_min, txbatt_max, txbatt_warn)
    else
        txBox = utils.getTxBox(colorMode, headeropts, txbatt_min, txbatt_max, txbatt_warn)
    end

    return {

        {col = 1, row = 1, colspan = 2, type = "text", subtype = "craftname", font = headeropts.font, valuealign = "left", valuepaddingleft = 5, bgcolor = colorMode.tbbgcolor, titlecolor = colorMode.titlecolor, textcolor = colorMode.cntextcolor},

        {col = 3, row = 1, colspan = 3, type = "image", subtype = "image", bgcolor = colorMode.tbbgcolor}, txBox, {
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
            bgcolor = colorMode.tbbgcolor,
            textcolor = colorMode.rssitextcolor,
            fillcolor = colorMode.rssifillcolor,
            fillbgcolor = colorMode.rssifillbgcolor
        }
    }
end

function utils.getTxBox(colorMode, headeropts, txbatt_min, txbatt_max, txbatt_warn)
    return {
        col = 6,
        row = 1,
        type = "gauge",
        subtype = "bar",
        source = "txbatt",
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
        cappaddingright = headeropts.cappaddingright,
        fillbgcolor = colorMode.txbgfillcolor,
        bgcolor = colorMode.tbbgcolor,
        accentcolor = colorMode.txaccentcolor,
        min = txbatt_min,
        max = txbatt_max,
        thresholds = {{value = txbatt_warn, fillcolor = colorMode.fillwarncolor}, {value = txbatt_max, fillcolor = colorMode.txfillcolor}}
    }
end

local function txTextBox(colorMode, headeropts)
    return {
        col = 6,
        row = 1,
        type = "text",
        subtype = "telemetry",
        source = "txbatt",
        title = "Tx Batt",
        titlepos = "bottom",
        titlefont = "FONT_XXS",
        valuealign = "center",
        unit = "v",
        valuepaddingtop = 8,
        valuepaddingleft = 8,
        font = headeropts.txbattfont,
        decimals = 1,
        bgcolor = colorMode.tbbgcolor,
        textcolor = colorMode.tbtextcolor
    }
end

local function txDigitalBox(colorMode, headeropts, txbatt_min, txbatt_max, txbatt_warn)
    return {
        col = 6,
        row = 1,
        type = "gauge",
        subtype = "bar",
        source = "txbatt",
        font = headeropts.txdbattfont,
        battery = false,
        roundradius = headeropts.roundradius,
        decimals = 1,
        unit = "v",
        gaugepaddingright = headeropts.txdgaugepaddingright,
        gaugepaddingleft = headeropts.txdgaugepaddingleft,
        gaugepaddingbottom = headeropts.gaugepaddingbottom,
        gaugepaddingtop = headeropts.gaugepaddingtop,
        valuepaddingleft = headeropts.txdvaluepaddingleft,
        valuepaddingtop = headeropts.txdvaluepaddingtop,
        fillbgcolor = colorMode.txbgfillcolor,
        bgcolor = colorMode.tbbgcolor,
        accentcolor = colorMode.txaccentcolor,
        textcolor = colorMode.tbtextcolor,
        min = txbatt_min,
        max = txbatt_max,
        thresholds = {{value = txbatt_warn, fillcolor = colorMode.fillwarncolor}, {value = txbatt_max, fillcolor = colorMode.txfillcolor}}
    }
end

function utils.getTxBatteryVoltageRange()
    if system and system.voltageRange then
        local ok, vmin, vmax = pcall(system.voltageRange)
        if ok and vmin and vmax and vmin < vmax then return vmin, vmax end
    end

    return 7.2, 8.4
end

function utils.isFullScreen(w, h)

    if (w == 800 and (h == 458 or h == 480)) then return true end
    if (w == 784 and (h == 294 or h == 316)) then return false end

    if (w == 480 and (h == 301 or h == 320)) then return true end
    if (w == 472 and (h == 191 or h == 210)) then return false end

    if (w == 640 and (h == 338 or h == 360)) then return true end
    if (w == 630 and (h == 236 or h == 258)) then return false end

    return nil
end

function utils.isModelPrefsReady() return dashx and dashx.session and dashx.session.modelPreferences end

function utils.resetBoxCache(box) if box._cache then for k in pairs(box._cache) do box._cache[k] = nil end end end

function utils.supportedResolution(W, H, supportedResolutions)

    for _, res in ipairs(supportedResolutions) do if W == res[1] and H == res[2] then return true end end
    return false
end

function utils.getThemeSignature()
    if not supportsSystemThemeColors() then
        return isLegacyDarkMode() and 1 or 0
    end
    local themeColorFn = lcd.themeColor
    if type(themeColorFn) ~= "function" then
        return isLegacyDarkMode() and 1 or 0
    end

    local signature = 97
    local hasThemeColors = false

    for index = 1, #THEME_STATE_KEYS do
        local constant = _G[THEME_STATE_KEYS[index].constant]
        local color = constant ~= nil and themeColorFn(constant) or nil
        if color ~= nil then
            hasThemeColors = true
            signature = (signature * 131 + (tonumber(color) or 0)) % THEME_SIGNATURE_MOD
        else
            signature = (signature * 131 + index) % THEME_SIGNATURE_MOD
        end
    end

    if not hasThemeColors then
        return isLegacyDarkMode() and 1 or 0
    end

    return signature + 2
end

local function ensureThemeCache()
    local signature = utils.getThemeSignature()
    if cachedThemeSignature == signature and cachedThemeState and cachedDashboardTheme and cachedChromeTheme and cachedToolbarTheme then
        return
    end

    local darkMode = isLegacyDarkMode()
    local baseState = darkMode and LEGACY_THEME_STATE.dark or LEGACY_THEME_STATE.light
    local themeState = cachedThemeState or {}
    local dashboardTheme = cachedDashboardTheme or {}
    local chromeTheme = cachedChromeTheme or {}
    local toolbarTheme = cachedToolbarTheme or {}
    local focusFill
    local focusText

    copyThemeMap(themeState, baseState)
    themeState.darkMode = darkMode
    themeState.usesThemeColors = false

    for index = 1, #THEME_STATE_KEYS do
        local entry = THEME_STATE_KEYS[index]
        local color = resolveSystemThemeColor(entry.constant)
        if color ~= nil then
            themeState[entry.key] = color
            themeState.usesThemeColors = true
        end
    end

    themeState.signature = signature

    local surfaceBg = resolveDashboardSurfaceBg(themeState)
    local gaugeTrackBg = resolveGaugeTrackBg(themeState, surfaceBg)
    local headerBg = gaugeTrackBg or resolveDashboardHeaderBg(themeState, surfaceBg)
    local headerText = resolveDashboardHeaderTextColor(themeState, headerBg) or themeState.primaryColor
    local headerGaugeTrackBg = resolveGaugeTrackBg(themeState, headerBg)
    local gaugeFillColor, gaugeWarnColor, gaugeCritColor = resolveGaugeThresholdPalette(themeState, surfaceBg)

    dashboardTheme.textcolor = themeState.primaryColor
    dashboardTheme.titlecolor = themeState.primaryColor
    dashboardTheme.bgcolor = surfaceBg
    dashboardTheme.fillcolor = gaugeFillColor
    dashboardTheme.fillbgcolor = gaugeTrackBg
    dashboardTheme.framecolor = themeState.buttonBorderColor or themeState.secondaryColor
    dashboardTheme.accentcolor = themeState.buttonBorderActiveColor or themeState.primaryColor
    dashboardTheme.rssifillcolor = themeState.activeColor
    dashboardTheme.rssifillbgcolor = headerGaugeTrackBg
    dashboardTheme.txaccentcolor = themeState.secondaryColor
    dashboardTheme.txfillcolor = themeState.activeColor
    dashboardTheme.txbgfillcolor = headerGaugeTrackBg
    dashboardTheme.bgcolortop = headerBg
    dashboardTheme.pagebgcolor = themeState.pageBgColor
    dashboardTheme.fillwarncolor = gaugeWarnColor
    dashboardTheme.fillcritcolor = gaugeCritColor
    dashboardTheme.tbbgcolor = headerBg
    dashboardTheme.cntextcolor = headerText
    dashboardTheme.tbtextcolor = headerText
    dashboardTheme.rssitextcolor = headerText

    if themeState.usesThemeColors then
        focusFill = themeState.focusBgColor or themeState.highlightColor or themeState.buttonBorderActiveColor or themeState.activeColor
        focusText = themeState.focusColor or themeState.highlightInvertColor or themeState.primaryColor

        chromeTheme.background = themeState.pageBgColor or themeState.primaryBgColor
        chromeTheme.panel = themeState.primaryBgColor
        chromeTheme.panelAlt = themeState.secondaryBgColor
        chromeTheme.button = themeState.secondaryBgColor
        chromeTheme.buttonDisabled = themeState.primaryBgColor
        chromeTheme.text = themeState.primaryColor
        chromeTheme.muted = themeState.secondaryColor
        chromeTheme.accent = focusFill
        chromeTheme.accentSoft = focusFill
        chromeTheme.accentText = focusText
        chromeTheme.accentBorder = themeState.buttonBorderActiveColor or focusText
        chromeTheme.border = themeState.buttonBorderColor or themeState.secondaryColor

        toolbarTheme.background = themeState.pageBgColor or themeState.primaryBgColor
        toolbarTheme.panel = themeState.secondaryBgColor
        toolbarTheme.accent = focusFill
        toolbarTheme.accentText = focusText
        toolbarTheme.text = themeState.primaryColor
        toolbarTheme.muted = themeState.secondaryColor
        toolbarTheme.border = themeState.buttonBorderColor or themeState.secondaryColor
        toolbarTheme.divider = resolveToolbarDividerColor(themeState, toolbarTheme.background)
    else
        copyThemeMap(chromeTheme, darkMode and LEGACY_CHROME_THEME.dark or LEGACY_CHROME_THEME.light)
        copyThemeMap(toolbarTheme, darkMode and LEGACY_TOOLBAR_THEME.dark or LEGACY_TOOLBAR_THEME.light)
        toolbarTheme.divider = toolbarTheme.border or toolbarTheme.text
    end

    cachedThemeSignature = signature
    cachedThemeState = themeState
    cachedDashboardTheme = dashboardTheme
    cachedChromeTheme = chromeTheme
    cachedToolbarTheme = toolbarTheme
end

function utils.themeColors()
    ensureThemeCache()
    return cachedDashboardTheme
end

function utils.getThemeState()
    ensureThemeCache()
    return cachedThemeState
end

function utils.getChromeTheme()
    ensureThemeCache()
    return cachedChromeTheme
end

function utils.getToolbarTheme()
    ensureThemeCache()
    return cachedToolbarTheme
end

function utils.drawBarNeedle(cx, cy, length, thickness, angleDeg, color)
    local angleRad = math.rad(angleDeg)
    local step = 1
    local rad_thick = thickness / 2
    lcd.color(color)
    for i = 0, length, step do
        local px = cx + i * math.cos(angleRad)
        local py = cy + i * math.sin(angleRad)
        lcd.drawFilledCircle(px, py, rad_thick)
    end
end

function utils.getFontListsForResolution()
    local version = system.getVersion()
    local LCD_W = version.lcdWidth
    local LCD_H = version.lcdHeight
    local resolution = LCD_W .. "x" .. LCD_H

    local radios = {

        ["800x480"] = {value_default = {FONT_XXS, FONT_XS, FONT_S, FONT_M, FONT_L, FONT_XL, FONT_XXL, FONT_XXXXL}, value_reduced = {FONT_XXS, FONT_XS, FONT_S, FONT_M, FONT_L}, value_title = {FONT_XXS, FONT_XS, FONT_S, FONT_M}},

        ["480x320"] = {value_default = {FONT_XXS, FONT_XS, FONT_S, FONT_M, FONT_L, FONT_XL}, value_reduced = {FONT_XXS, FONT_XS, FONT_S, FONT_M, FONT_L}, value_title = {FONT_XXS, FONT_XS, FONT_S}},

        ["480x272"] = {value_default = {FONT_XXS, FONT_XS, FONT_S, FONT_M}, value_reduced = {FONT_XXS, FONT_XS, FONT_S}, value_title = {FONT_XXS, FONT_XS, FONT_S}},

        ["640x360"] = {value_default = {FONT_XXS, FONT_XS, FONT_S, FONT_M, FONT_L, FONT_XL}, value_reduced = {FONT_XXS, FONT_XS, FONT_S, FONT_M, FONT_L}, value_title = {FONT_XXS, FONT_XS, FONT_S}}
    }
    if not radios[resolution] then
        dashx.utils.log("Unsupported resolution: " .. resolution .. ". Using default fonts.", "info")
        return radios["800x480"]
    end
    return radios[resolution]

end

function utils.getHeaderOptions()
    local W, H = lcd.getWindowSize()

    if W == 800 or W == 784 then
        return {
            height = 36,
            font = "FONT_L",
            batterysegmentpaddingtop = 4,
            batterysegmentpaddingbottom = 4,
            batterysegmentpaddingleft = 4,
            batterysegmentpaddingright = 4,
            gaugepaddingleft = 25,
            gaugepaddingright = 26,
            gaugepaddingbottom = 2,
            gaugepaddingtop = 2,
            barpaddingleft = 25,
            barpaddingright = 28,
            barpaddingbottom = 2,
            barpaddingtop = 4,
            valuepaddingleft = 20,
            valuepaddingbottom = 20
        }

    elseif W == 480 or W == 472 then
        return {
            height = 30,
            font = "FONT_L",
            batterysegmentpaddingtop = 4,
            batterysegmentpaddingbottom = 4,
            batterysegmentpaddingleft = 4,
            batterysegmentpaddingright = 4,
            gaugepaddingleft = 8,
            gaugepaddingright = 9,
            gaugepaddingbottom = 2,
            gaugepaddingtop = 2,
            barpaddingleft = 15,
            barpaddingright = 18,
            barpaddingbottom = 2,
            barpaddingtop = 2,
            valuepaddingbottom = 20
        }

    elseif W == 640 or W == 630 then
        return {
            height = 30,
            font = "FONT_L",
            batterysegmentpaddingtop = 4,
            batterysegmentpaddingbottom = 4,
            batterysegmentpaddingleft = 4,
            batterysegmentpaddingright = 4,
            gaugepaddingleft = 21,
            gaugepaddingright = 23,
            gaugepaddingbottom = 2,
            gaugepaddingtop = 2,
            barpaddingleft = 19,
            barpaddingright = 21,
            barpaddingbottom = 2,
            barpaddingtop = 2,
            valuepaddingbottom = 20
        }
    else
        return {
            height = 30,
            font = "FONT_L",
            batterysegmentpaddingtop = 4,
            batterysegmentpaddingbottom = 4,
            batterysegmentpaddingleft = 4,
            batterysegmentpaddingright = 4,
            gaugepaddingleft = 8,
            gaugepaddingright = 9,
            gaugepaddingbottom = 2,
            gaugepaddingtop = 2,
            barpaddingleft = 15,
            barpaddingright = 18,
            barpaddingbottom = 2,
            barpaddingtop = 2,
            valuepaddingbottom = 20
        }
    end
end

function utils.resetImageCache() for k in pairs(imageCache) do imageCache[k] = nil end end

function utils.screenError(msg, border, pct, padX, padY)

    if not pct then pct = 0.5 end
    if border == nil then border = true end
    if not padX then padX = 8 end
    if not padY then padY = 4 end

    local w, h = lcd.getWindowSize()
    local themeState = utils.getThemeState()

    local fonts = {FONT_XXS, FONT_XS, FONT_S, FONT_M, FONT_L, FONT_XL, FONT_XXL, FONT_XXXXL}

    local maxW, maxH = w * pct, h * pct
    local bestFont, bestW, bestH = FONT_XXS, 0, 0

    for _, font in ipairs(fonts) do
        lcd.font(font)
        local tsizeW, tsizeH = lcd.getTextSize(msg)
        if tsizeW <= maxW and tsizeH <= maxH then
            bestFont = font
            bestW, bestH = tsizeW, tsizeH
        else
            break
        end
    end

    lcd.font(bestFont)

    local textColor = themeState.primaryColor or lcd.RGB(255, 255, 255, 1)
    lcd.color(textColor)

    local x = (w - bestW) / 2
    local y = (h - bestH) / 2

    if border then lcd.drawRectangle(x - padX, y - padY, bestW + padX * 2, bestH + padY * 2) end

    lcd.drawText(x, y, msg)
end

function utils.resolveColor(value, variantFactor)

    local namedColors = {
        red = {255, 0, 0},
        green = {0, 188, 4},
        blue = {0, 122, 255},
        white = {255, 255, 255},
        black = {0, 0, 0},
        gray = {185, 185, 185},
        grey = {185, 185, 185},
        orange = {255, 165, 0},
        yellow = {255, 255, 0},
        cyan = {0, 255, 255},
        magenta = {255, 0, 255},
        pink = {255, 105, 180},
        purple = {128, 0, 128},
        violet = {143, 0, 255},
        brown = {139, 69, 19},
        lime = {0, 255, 0},
        olive = {128, 128, 0},
        gold = {255, 215, 0},
        silver = {192, 192, 192},
        teal = {0, 128, 128},
        navy = {0, 0, 128},
        maroon = {128, 0, 0},
        beige = {245, 245, 220},
        turquoise = {64, 224, 208},
        indigo = {75, 0, 130},
        coral = {255, 127, 80},
        salmon = {250, 128, 114},
        mint = {62, 180, 137},
        lightgreen = {144, 238, 144},
        darkgreen = {0, 100, 0},
        lightred = {255, 102, 102},
        darkred = {139, 0, 0},
        lightorange = {255, 200, 100},
        lightblue = {173, 216, 230},
        darkblue = {0, 0, 139},
        lightpurple = {216, 191, 216},
        darkpurple = {48, 25, 52},
        lightyellow = {255, 255, 224},
        darkyellow = {204, 204, 0},
        lightgrey = {211, 211, 211},
        lightgray = {211, 211, 211},
        darkgrey = {90, 90, 90},
        darkgray = {90, 90, 90},
        lmgrey = {80, 80, 80},
        darkwhite = {245, 245, 245}
    }

    local VARIANT_FACTOR = type(variantFactor) == "number" and math.max(0, math.min(1, variantFactor)) or 0.3

    local function clamp(v) return math.max(0, math.min(255, math.floor(v + 0.5))) end

    local function lighten(rgb) return {clamp(rgb[1] + (255 - rgb[1]) * VARIANT_FACTOR), clamp(rgb[2] + (255 - rgb[2]) * VARIANT_FACTOR), clamp(rgb[3] + (255 - rgb[3]) * VARIANT_FACTOR)} end

    local function darken(rgb) return {clamp(rgb[1] * (1 - VARIANT_FACTOR)), clamp(rgb[2] * (1 - VARIANT_FACTOR)), clamp(rgb[3] * (1 - VARIANT_FACTOR))} end

    if type(value) == "string" then
        local lower = value:lower()

        local prefix, baseName = lower:match("^(bright)(.+)"), lower:match("^bright(.+)")
        if not prefix then prefix, baseName = lower:match("^(light)(.+)"), lower:match("^light(.+)") end
        if not prefix then prefix, baseName = lower:match("^(dark)(.+)"), lower:match("^dark(.+)") end

        if prefix and baseName then
            local baseColor = namedColors[baseName]
            if baseColor then
                local rgb = (prefix == "dark") and darken(baseColor) or lighten(baseColor)
                return lcd.RGB(rgb[1], rgb[2], rgb[3], 1)
            end

        elseif namedColors[lower] then

            local c = namedColors[lower]
            return lcd.RGB(c[1], c[2], c[3], 1)
        end

    elseif type(value) == "table" and #value >= 3 then

        return lcd.RGB(value[1], value[2], value[3], 1)
    end

    return nil
end

function utils.resolveThemeColor(colorkey, value)

    if type(value) == "number" then return value end

    if type(value) == "string" and value == "transparent" then return nil end

    if type(value) == "string" then
        local resolved = utils.resolveColor(value)
        if resolved then return resolved end
    end

    local themeColors = utils.themeColors()
    if colorkey == "fillcolor" then
        return themeColors.fillcolor
    elseif colorkey == "fillbgcolor" then
        return themeColors.fillbgcolor
    elseif colorkey == "framecolor" then
        return themeColors.framecolor
    elseif colorkey == "textcolor" then
        return themeColors.textcolor
    elseif colorkey == "titlecolor" then
        return themeColors.titlecolor
    elseif colorkey == "accentcolor" then
        return themeColors.accentcolor
    elseif colorkey == "bgcolor" then
        return themeColors.bgcolor
    elseif colorkey == "bgcolortop" then
        return themeColors.bgcolortop
    elseif colorkey == "fillwarncolor" then
        return themeColors.fillwarncolor
    elseif colorkey == "fillcritcolor" then
        return themeColors.fillcritcolor
    elseif colorkey == "tbbgcolor" then
        return themeColors.tbbgcolor
    elseif colorkey == "cntextcolor" then
        return themeColors.cntextcolor
    elseif colorkey == "tbtextcolor" then
        return themeColors.tbtextcolor
    elseif colorkey == "rssitextcolor" then
        return themeColors.rssitextcolor
    elseif colorkey == "rssifillcolor" then
        return themeColors.rssifillcolor
    elseif colorkey == "rssifillbgcolor" then
        return themeColors.rssifillbgcolor
    elseif colorkey == "txaccentcolor" then
        return themeColors.txaccentcolor
    elseif colorkey == "txfillcolor" then
        return themeColors.txfillcolor
    elseif colorkey == "txbgfillcolor" then
        return themeColors.txbgfillcolor
    end

    return themeColors.bgcolor
end

function utils.resolveThemeColorArray(colorkey, arr)
    local resolved = {}
    if type(arr) == "table" then for i = 1, #arr do resolved[i] = utils.resolveThemeColor(colorkey, arr[i]) end end
    return resolved
end

function utils.box(x, y, w, h, title, titlepos, titlealign, titlefont, titlespacing, titlecolor, titlepadding, titlepaddingleft, titlepaddingright, titlepaddingtop, titlepaddingbottom, displayValue, unit, font, valuealign, textcolor, valuepadding, valuepaddingleft, valuepaddingright,
                   valuepaddingtop, valuepaddingbottom, bgcolor, image, imagewidth, imageheight, imagealign)

    local DEFAULT_TITLE_PADDING = 0
    local DEFAULT_VALUE_PADDING = 6
    local DEFAULT_TITLE_SPACING = 6

    titlepaddingleft = titlepaddingleft or titlepadding or DEFAULT_TITLE_PADDING
    titlepaddingright = titlepaddingright or titlepadding or DEFAULT_TITLE_PADDING
    titlepaddingtop = titlepaddingtop or titlepadding or DEFAULT_TITLE_PADDING
    titlepaddingbottom = titlepaddingbottom or titlepadding or DEFAULT_TITLE_PADDING

    valuepaddingleft = valuepaddingleft or valuepadding or DEFAULT_VALUE_PADDING
    valuepaddingright = valuepaddingright or valuepadding or DEFAULT_VALUE_PADDING
    valuepaddingtop = valuepaddingtop or valuepadding or DEFAULT_VALUE_PADDING
    valuepaddingbottom = valuepaddingbottom or valuepadding or DEFAULT_VALUE_PADDING

    titlespacing = titlespacing or DEFAULT_TITLE_SPACING

    if bgcolor then
        lcd.color(bgcolor)
        lcd.drawFilledRectangle(x, y, w, h)
    end

    if not fontCache then fontCache = utils.getFontListsForResolution() end

    local actualTitleFont, tsizeW, tsizeH = nil, 0, 0
    if title then
        local minValueFontH = 9999
        for _, vf in ipairs(fontCache.value_default or {FONT_M}) do
            lcd.font(vf)
            local _, vh = lcd.getTextSize("8")
            if vh < minValueFontH then minValueFontH = vh end
        end
        if titlefont and _G[titlefont] then
            actualTitleFont = _G[titlefont]
            lcd.font(actualTitleFont)
            tsizeW, tsizeH = lcd.getTextSize(title)
        else
            for _, tryFont in ipairs(fontCache.value_title or {FONT_XS}) do
                lcd.font(tryFont)
                local tW, tH = lcd.getTextSize(title)
                local remH = h - titlepaddingtop - tH - titlepaddingbottom - valuepaddingtop - valuepaddingbottom
                if tW <= w - titlepaddingleft - titlepaddingright and tH > 0 and remH >= minValueFontH then
                    actualTitleFont, tsizeW, tsizeH = tryFont, tW, tH
                    break
                end
            end
            if not actualTitleFont then
                actualTitleFont = (fontCache.value_title or {FONT_XS})[#(fontCache.value_title or {FONT_XS})]
                lcd.font(actualTitleFont)
                tsizeW, tsizeH = lcd.getTextSize(title)
            end
        end
    end

    local region_vx, region_vy, region_vw, region_vh
    if title and (titlepos or "top") == "top" then
        region_vy = y + titlepaddingtop + tsizeH + titlepaddingbottom + titlespacing + valuepaddingtop
        region_vh = h - (region_vy - y) - valuepaddingbottom
    elseif title and titlepos == "bottom" then
        region_vy = y + valuepaddingtop
        region_vh = h - tsizeH - titlepaddingtop - titlepaddingbottom - titlespacing - valuepaddingtop - valuepaddingbottom
    else
        region_vy = y + valuepaddingtop
        region_vh = h - valuepaddingtop - valuepaddingbottom
    end
    region_vx = x + valuepaddingleft
    region_vw = w - valuepaddingleft - valuepaddingright

    if image then
        local bitmapPtr = nil

        if type(image) == "string" and dashx and dashx.utils and dashx.utils.loadImage then
            imageCache = imageCache or {}
            local cacheKey = image or "default_image"
            bitmapPtr = imageCache[cacheKey]
            if not bitmapPtr then
                bitmapPtr = dashx.utils.loadImage(image, nil, "widgets/dashboard/gfx/logo.png")
                imageCache[cacheKey] = bitmapPtr
            end
        elseif type(image) == "userdata" then

            bitmapPtr = image
        end

        if bitmapPtr then

            local default_img_w = region_vw
            local default_img_h = region_vh
            local img_w = imagewidth or default_img_w
            local img_h = imageheight or default_img_h
            local align = imagealign or "center"
            local img_x, img_y = region_vx, region_vy
            if align == "center" then
                img_x = region_vx + (region_vw - img_w) / 2
            elseif align == "right" then
                img_x = region_vx + region_vw - img_w
            else
                img_x = region_vx
            end
            if align == "center" then
                img_y = region_vy + (region_vh - img_h) / 2
            elseif align == "bottom" then
                img_y = region_vy + region_vh - img_h
            else
                img_y = region_vy
            end
            lcd.drawBitmap(img_x, img_y, bitmapPtr, img_w, img_h)
        end
    elseif displayValue ~= nil then

        local value_str = tostring(displayValue) .. (unit or "")

        local value_str_calc = string.gsub(value_str, "[%%]", "W")
        value_str_calc = string.gsub(value_str, "[°]", ".")

        local valueFont, bestW, bestH = FONT_XXS, 0, 0
        if font and _G[font] then
            valueFont = _G[font]
            lcd.font(valueFont)

            bestW, bestH = lcd.getTextSize(value_str_calc)
        else
            for _, tryFont in ipairs(fontCache.value_default) do
                lcd.font(tryFont)
                local tW, tH = lcd.getTextSize(value_str_calc)
                if tW <= region_vw and tH <= region_vh then valueFont, bestW, bestH = tryFont, tW, tH end
            end
            lcd.font(valueFont)
        end

        local fudgeTitle = (title and (titlepos or "top") == "top") and -math.floor(bestH * 0.15 + 0.5) or (title and titlepos == "bottom") and math.floor(bestH * 0.15 + 0.5) or 0

        local sy = region_vy + ((region_vh - bestH) / 2) + fudgeTitle
        local align = (valuealign or "center"):lower()
        local sx
        if align == "left" then
            sx = region_vx
        elseif align == "right" then
            sx = region_vx + region_vw - bestW
        else
            sx = region_vx + (region_vw - bestW) / 2
        end
        lcd.color(textcolor)
        lcd.drawText(sx, sy, value_str)
    end

    if title then
        lcd.font(actualTitleFont)
        local region_tw = w - titlepaddingleft - titlepaddingright
        local sy = (titlepos or "top") == "bottom" and (y + h - titlepaddingbottom - tsizeH) or (y + titlepaddingtop)
        local align = (titlealign or "center"):lower()
        local sx
        if align == "left" then
            sx = x + titlepaddingleft
        elseif align == "right" then
            sx = x + titlepaddingleft + region_tw - tsizeW
        else
            sx = x + titlepaddingleft + (region_tw - tsizeW) / 2
        end
        lcd.color(titlecolor)
        lcd.drawText(sx, sy, title)
    end
end

function utils.resolveThresholdColor(value, box, colorKey, fallbackThemeKey, thresholdsOverride)
    local color = utils.resolveThemeColor(fallbackThemeKey, utils.getParam(box, colorKey))
    local thresholds = thresholdsOverride or utils.getParam(box, "thresholds")
    if thresholds and value ~= nil then
        for _, t in ipairs(thresholds) do
            local thresholdValue = t.value
            if type(thresholdValue) == "function" then thresholdValue = thresholdValue(box, value) end

            if type(value) == "string" and thresholdValue == value and t[colorKey] then
                color = utils.resolveThemeColor(colorKey, t[colorKey])
                break
            elseif type(value) == "number" and type(thresholdValue) == "number" and value <= thresholdValue and t[colorKey] then
                color = utils.resolveThemeColor(colorKey, t[colorKey])
                break
            end
        end
    end
    return color
end

function utils.transformValue(value, box)

    local transform = utils.getParam(box, "transform")

    if transform then
        if type(transform) == "function" then
            value = transform(value)
        elseif transform == "floor" then
            value = math.floor(value)
        elseif transform == "ceil" then
            value = math.ceil(value)
        elseif transform == "round" then
            value = math.floor(value + 0.5)
        end
    end
    local decimals = utils.getParam(box, "decimals")

    if decimals ~= nil and value ~= nil then
        value = string.format("%." .. decimals .. "f", value)
    elseif value ~= nil then
        value = tostring(value)
    end
    return value
end

function utils.setBackgroundColourBasedOnTheme()
    local w, h = lcd.getWindowSize()
    local themeState = utils.getThemeState()
    lcd.color(themeState.pageBgColor or themeState.primaryBgColor or lcd.RGB(16, 16, 16))
    lcd.drawFilledRectangle(0, 0, w, h)
end

function utils.getParam(box, key, ...)
    local SKIP_CALL_KEYS = {transform = true, thresholds = true, value = true}

    local v = box[key]
    if type(v) == "function" and not SKIP_CALL_KEYS[key] then
        return v(box, key, ...)
    else
        return v
    end
end

function utils.applyOffset(x, y, box)
    local ox = utils.getParam(box, "offsetx") or 0
    local oy = utils.getParam(box, "offsety") or 0
    return x + ox, y + oy
end

return utils
