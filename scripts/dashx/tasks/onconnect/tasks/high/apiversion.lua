--[[
  Copyright (C) 2025 Rob Thomson
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local dashx = require("dashx")

local apiversion = {}

function apiversion.wakeup() dashx.session.apiVersion = 12.07 end

function apiversion.reset() dashx.session.apiVersion = nil end

function apiversion.isComplete() if dashx.session.apiVersion ~= nil then return true end end

return apiversion
