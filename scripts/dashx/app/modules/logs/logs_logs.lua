local utils = assert(dashx.compiler.loadfile("SCRIPTS:/" .. dashx.config.baseDir .. "/app/modules/logs/lib/utils.lua"))()

local triggerOverRide = false
local triggerOverRideAll = false
local lastServoCountTime = os.clock()
local enableWakeup = false
local wakeupScheduler = os.clock()
local currentDisplayMode

local function getCleanModelName()
    local logdir
    logdir = string.gsub(model.name(), "%s+", "_")
    logdir = string.gsub(logdir, "%W", "_")
    return logdir
end


local function extractHourMinute(filename)
    -- Capture hour and minute from the time-portion (HH-MM-SS) after the underscore
    local hour, minute = filename:match(".-%d%d%d%d%-%d%d%-%d%d_(%d%d)%-(%d%d)%-%d%d")
    if hour and minute then
        return hour .. ":" .. minute
    end
    return nil
end

local function format_date(iso_date)
  local y, m, d = iso_date:match("^(%d+)%-(%d+)%-(%d+)$")
  return os.date("%d %B %Y", os.time{
    year  = tonumber(y),
    month = tonumber(m),
    day   = tonumber(d),
  })
end

local function openPage(pidx, title, script, displaymode)

    -- hard exit on error
    if not dashx.utils.ethosVersionAtLeast() then
        return
    end


    currentDisplayMode = displaymode


    dashx.app.triggers.isReady = false
    dashx.app.uiState = dashx.app.uiStatus.pages

    form.clear()

    dashx.app.lastIdx = idx
    dashx.app.lastTitle = title
    dashx.app.lastScript = script

    local w, h = dashx.utils.getWindowSize()
    local windowWidth = w
    local windowHeight = h
    local padding = dashx.app.radio.buttonPadding

    local sc
    local panel

     local logDir = utils.getLogPath()

    local logs = utils.getLogs(logDir)   

    print(logDir)


    local name = utils.resolveModelName(dashx.session.mcu_id or dashx.session.activeLogDir)
    dashx.app.ui.fieldHeader("Logs" )

    local buttonW
    local buttonH
    local padding
    local numPerRow

   if dashx.preferences.general.iconsize == 0 then
        padding = dashx.app.radio.buttonPaddingSmall
        buttonW = (dashx.session.lcdWidth - padding) / dashx.app.radio.buttonsPerRow - padding
        buttonH = dashx.app.radio.navbuttonHeight
        numPerRow = dashx.app.radio.buttonsPerRow
    end
    -- SMALL ICONS
    if dashx.preferences.general.iconsize == 1 then

        padding = dashx.app.radio.buttonPaddingSmall
        buttonW = dashx.app.radio.buttonWidthSmall
        buttonH = dashx.app.radio.buttonHeightSmall
        numPerRow = dashx.app.radio.buttonsPerRowSmall
    end
    -- LARGE ICONS
    if dashx.preferences.general.iconsize == 2 then

        padding = dashx.app.radio.buttonPadding
        buttonW = dashx.app.radio.buttonWidth
        buttonH = dashx.app.radio.buttonHeight
        numPerRow = dashx.app.radio.buttonsPerRow
    end


    local x = windowWidth - buttonW + 10

    local lc = 0
    local bx = 0

    if dashx.app.gfx_buttons["logs_logs"] == nil then dashx.app.gfx_buttons["logs_logs"] = {} end
    if dashx.preferences.menulastselected["logs"] == nil then dashx.preferences.menulastselected["logs_logs"] = 1 end

    if dashx.app.gfx_buttons["logs"] == nil then dashx.app.gfx_buttons["logs"] = {} end
    if dashx.preferences.menulastselected["logs_logs"] == nil then dashx.preferences.menulastselected["logs_logs"] = 1 end

    -- Group logs by date
    local groupedLogs = {}
    for _, filename in ipairs(logs) do
        local datePart = filename:match("(%d%d%d%d%-%d%d%-%d%d)_")
        if datePart then
            groupedLogs[datePart] = groupedLogs[datePart] or {}
            table.insert(groupedLogs[datePart], filename)
        end
    end

    -- Sort dates descending
    local dates = {}
    for date,_ in pairs(groupedLogs) do table.insert(dates, date) end
    table.sort(dates, function(a,b) return a > b end)


    if #dates == 0 then

        LCD_W, LCD_H = dashx.utils.getWindowSize()
        local str = "@i18n(app.modules.logs.msg_no_logs_found)@"
        local ew = LCD_W
        local eh = LCD_H
        local etsizeW, etsizeH = lcd.getTextSize(str)
        local eposX = ew / 2 - etsizeW / 2
        local eposY = eh / 2 - etsizeH / 2

        local posErr = {w = etsizeW, h = dashx.app.radio.navbuttonHeight, x = eposX, y = ePosY}

        line = form.addLine("", nil, false)
        form.addStaticText(line, posErr, str)

    else
        dashx.app.gfx_buttons["logs_logs"] = dashx.app.gfx_buttons["logs_logs"] or {}
        dashx.preferences.menulastselected["logs_logs"] = dashx.preferences.menulastselected["logs_logs"] or 1

        for idx, section in ipairs(dates) do

                form.addLine(format_date(section))
                local lc, y = 0, 0

                for pidx, page in ipairs(groupedLogs[section]) do

                            if lc == 0 then
                                y = form.height() + (dashx.preferences.general.iconsize == 2 and dashx.app.radio.buttonPadding or dashx.app.radio.buttonPaddingSmall)
                            end

                            local x = (buttonW + padding) * lc
                            if dashx.preferences.general.iconsize ~= 0 then
                                if dashx.app.gfx_buttons["logs_logs"][pidx] == nil then dashx.app.gfx_buttons["logs_logs"][pidx] = lcd.loadMask("app/modules/logs/gfx/logs.png") end
                            else
                                dashx.app.gfx_buttons["logs_logs"][pidx] = nil
                            end

                            dashx.app.formFields[pidx] = form.addButton(line, {x = x, y = y, w = buttonW, h = buttonH}, {
                                text = extractHourMinute(page),
                                icon = dashx.app.gfx_buttons["logs_logs"][pidx],
                                options = FONT_S,
                                paint = function() end,
                                press = function()
                                    dashx.preferences.menulastselected["logs_logs"] = tostring(idx) .. "_" .. tostring(pidx)
                                    dashx.app.ui.progressDisplay()
                                    dashx.app.ui.openPage(pidx, "Logs", "logs/logs_view.lua", page)                       
                                end
                            })

                            if dashx.preferences.menulastselected["logs_logs"] == tostring(idx) .. "_" .. tostring(pidx) then
                                dashx.app.formFields[pidx]:focus()
                            end

                            if not dashx.tasks or not dashx.tasks.active() then
                                dashx.app.formFields[pidx]:enable(false)
                            end

                            lc = (lc + 1) % numPerRow

                end

        end   

            
    end


    dashx.app.triggers.closeProgressLoader = true

    enableWakeup = true

    return
end

local function event(widget, category, value, x, y)
    if  value == 35 then
        dashx.app.ui.openMainMenu()
        return true
    end
    return false
end

local function wakeup()

    if enableWakeup == true then

    end

end

local function onNavMenu()

      --dashx.app.ui.openPage(dashx.app.lastIdx, dashx.app.lastTitle, "logs/logs_dir.lua")
    dashx.app.ui.openMainMenu()

end

return {
    event = event,
    openPage = openPage,
    wakeup = wakeup,
    onNavMenu = onNavMenu,
    navButtons = {
        menu = true,
        save = false,
        reload = false,
        tool = false,
        help = true
    },
    API = {},
}
