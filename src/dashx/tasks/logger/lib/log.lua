--[[
  Copyright (C) 2025 Rob Thomson
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local dashx = require("dashx")

local logs = {}

logs.config = {enabled = true, log_to_file = true, print_interval = 0.5, disk_write_interval = 5.0, max_line_length = 100, min_print_level = "info", log_file = "log.txt", prefix = ""}

if system:getVersion().simulation == true then logs.config.print_interval = 0.025 end

logs.queue = {}
logs.disk_queue = {}
logs.last_print_time = os.clock()
logs.last_disk_write_time = os.clock()

logs.levels = {debug = 0, info = 1, off = 2}

local function split_message(message, max_length, prefix)
    local lines = {}
    while #message > max_length do
        table.insert(lines, message:sub(1, max_length))
        message = prefix .. message:sub(max_length + 1)
    end
    if #message > 0 then table.insert(lines, message) end
    return lines
end

function logs.add(message, level)
    if not logs.config.enabled or logs.config.min_print_level == "off" then return end

    level = level or "info"
    if logs.levels[level] == nil then return end
    if logs.levels[level] < logs.levels[logs.config.min_print_level] then return end

    local max_message_length = logs.config.max_line_length * 10
    if #message > max_message_length then message = message:sub(1, max_message_length) .. " [truncated]" end

    local prefix = logs.config.prefix .. " [" .. level .. "] "
    local log_entry = prefix .. message
    local lines = {}

    if system:getVersion().simulation then
        table.insert(lines, log_entry)
    else
        lines = split_message(log_entry, logs.config.max_line_length, string.rep(" ", #prefix))
    end

    for _, line in ipairs(lines) do table.insert(logs.queue, line) end

    if logs.config.log_to_file then table.insert(logs.disk_queue, log_entry) end
end

local function process_console_queue()
    if not logs.config.enabled or logs.config.min_print_level == "off" then return end

    local now = os.clock()
    if now - logs.last_print_time >= logs.config.print_interval and #logs.queue > 0 then
        logs.last_print_time = now

        local MAX_CONSOLE_MESSAGES = 5
        for i = 1, math.min(MAX_CONSOLE_MESSAGES, #logs.queue) do
            local message = table.remove(logs.queue, 1)
            print(message)
        end
    end
end

local function process_disk_queue()
    if not logs.config.enabled or logs.config.min_print_level == "off" or not logs.config.log_to_file then return end

    local now = os.clock()
    if now - logs.last_disk_write_time >= logs.config.disk_write_interval and #logs.disk_queue > 0 then
        logs.last_disk_write_time = now

        local MAX_DISK_MESSAGES = 20
        local file = io.open(logs.config.log_file, "a")
        if file then
            for i = 1, math.min(MAX_DISK_MESSAGES, #logs.disk_queue) do
                local message = table.remove(logs.disk_queue, 1)
                file:write(message .. "\n")
            end
            file:close()
        end
    end
end

function logs.process()
    process_console_queue()
    process_disk_queue()
end

return logs
