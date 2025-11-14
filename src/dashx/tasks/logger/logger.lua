--[[
  Copyright (C) 2025 Rob Thomson
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local dashx = require("dashx")

local arg = {...}
local config = arg[1]

local logger = {}

os.mkdir("LOGS:")
os.mkdir("LOGS:/dashx")
os.mkdir("LOGS:/dashx/logs")
logger.queue = assert(loadfile("tasks/logger/lib/log.lua"))(config)
logger.queue.config.log_file = "LOGS:/dashx/logs/dashx_" .. os.date("%Y-%m-%d_%H-%M-%S") .. ".log"
logger.queue.config.min_print_level = dashx.preferences.developer.loglevel
logger.queue.config.log_to_file = tostring(dashx.preferences.developer.logtofile)

function logger.wakeup() logger.queue.process() end

function logger.reset() end

function logger.add(message, level)
    logger.queue.config.min_print_level = dashx.preferences.developer.loglevel
    logger.queue.config.log_to_file = tostring(dashx.preferences.developer.logtofile)
    logger.queue.add(message, level)
end

return logger
