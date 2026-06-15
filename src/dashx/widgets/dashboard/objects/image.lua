--[[
  Copyright (C) 2025 Rob Thomson
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local dashx = require("dashx")

local wrapperFactory = assert(loadfile("SCRIPTS:/" .. dashx.config.baseDir .. "/widgets/dashboard/lib/wrapper_factory.lua"))()

return wrapperFactory.createObjectWrapper("image", "model")
