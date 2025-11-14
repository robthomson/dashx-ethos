--[[
  Copyright (C) 2025 Rob Thomson
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local dashx = require("dashx")
local LCD_W, LCD_H = dashx.utils.getWindowSize()
local resolution = LCD_W .. "x" .. LCD_H

local supportedRadios = {

    ["784x406"] = {
        inlinesize_mult = 1,
        menuButtonWidth = 100,
        navbuttonHeight = 40,
        buttonsPerRow = 6,
        buttonsPerRowSmall = 7,
        buttonWidth = 120,
        buttonHeight = 120,
        buttonPadding = 10,
        buttonWidthSmall = 105,
        buttonHeightSmall = 110,
        buttonPaddingSmall = 6,
        linePaddingTop = 8,
        logGraphMenuOffset = 70,
        logGraphWidthPercentage = 0.79,
        logGraphButtonsPerRow = 5,
        logGraphKeyHeight = 65,
        logGraphHeightOffset = -15,
        logKeyFont = FONT_S,
        logKeyFontSmall = FONT_XS,
        logSliderPaddingLeft = 42,
        logShowAvg = true
    },

    ["472x288"] = {
        inlinesize_mult = 1.28,
        menuButtonWidth = 60,
        navbuttonHeight = 30,
        navButtonOffset = 47,
        buttonsPerRow = 4,
        buttonsPerRowSmall = 5,
        buttonWidth = 110,
        buttonHeight = 110,
        buttonPadding = 8,
        buttonWidthSmall = 89,
        buttonHeightSmall = 95,
        buttonPaddingSmall = 5,
        linePaddingTop = 6,
        logGraphMenuOffset = 55,
        logGraphWidthPercentage = 0.72,
        logGraphButtonsPerRow = 4,
        logGraphKeyHeight = 45,
        logGraphHeightOffset = 10,
        logKeyFont = FONT_XS,
        logKeyFontSmall = FONT_XXS,
        logSliderPaddingLeft = 30,
        logShowAvg = false
    },

    ["472x240"] = {
        inlinesize_mult = 1.0715,
        menuButtonWidth = 60,
        navbuttonHeight = 30,
        buttonsPerRow = 4,
        buttonsPerRowSmall = 5,
        buttonWidth = 110,
        buttonHeight = 110,
        buttonPadding = 8,
        buttonWidthSmall = 87,
        buttonHeightSmall = 97,
        buttonPaddingSmall = 7,
        linePaddingTop = 6,
        logGraphMenuOffset = 50,
        logGraphWidthPercentage = 0.65,
        logGraphButtonsPerRow = 4,
        logGraphKeyHeight = 38,
        logGraphHeightOffset = 0,
        logKeyFont = FONT_XS,
        logKeyFontSmall = FONT_XXS,
        logSliderPaddingLeft = 30,
        logShowAvg = false
    },

    ["632x314"] = {
        menuButtonWidth = 80,
        inlinesize_mult = 1.11,
        navbuttonHeight = 35,
        navButtonOffset = 47,
        buttonsPerRow = 5,
        buttonsPerRowSmall = 6,
        buttonWidth = 118,
        buttonHeight = 120,
        buttonPadding = 7,
        buttonWidthSmall = 97,
        buttonHeightSmall = 115,
        buttonPaddingSmall = 8,
        linePaddingTop = 6,
        logGraphMenuOffset = 60,
        logGraphWidthPercentage = 0.76,
        logGraphButtonsPerRow = 4,
        logGraphKeyHeight = 50,
        logGraphHeightOffset = 0,
        logKeyFont = FONT_XXS,
        logKeyFontSmall = FONT_XXS,
        logSliderPaddingLeft = 30,
        logShowAvg = false
    }
}

local radio = assert(supportedRadios[resolution], resolution .. " not supported")

return radio
