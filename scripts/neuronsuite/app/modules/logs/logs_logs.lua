local utils = assert(neuronsuite.compiler.loadfile("SCRIPTS:/" .. neuronsuite.config.baseDir .. "/app/modules/logs/lib/utils.lua"))()
local i18n = neuronsuite.i18n.get
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
    if not neuronsuite.utils.ethosVersionAtLeast() then
        return
    end

    if not neuronsuite.tasks.active() then

        local buttons = {{
            label = i18n("app.btn_ok"),
            action = function()

                neuronsuite.app.triggers.exitAPP = true
                neuronsuite.app.dialogs.nolinkDisplayErrorDialog = false
                return true
            end
        }}

        form.openDialog({
            width = nil,
            title = i18n("error"):gsub("^%l", string.upper),
            message = i18n("app.check_bg_task") ,
            buttons = buttons,
            wakeup = function()
            end,
            paint = function()
            end,
            options = TEXT_LEFT
        })

    end


    currentDisplayMode = displaymode

    if neuronsuite.tasks.msp then
        neuronsuite.tasks.msp.protocol.mspIntervalOveride = nil
    end

    neuronsuite.app.triggers.isReady = false
    neuronsuite.app.uiState = neuronsuite.app.uiStatus.pages

    form.clear()

    neuronsuite.app.lastIdx = idx
    neuronsuite.app.lastTitle = title
    neuronsuite.app.lastScript = script

    local w, h = lcd.getWindowSize()
    local windowWidth = w
    local windowHeight = h
    local padding = neuronsuite.app.radio.buttonPadding

    local sc
    local panel

     local logDir = utils.getLogPath()

    local logs = utils.getLogs(logDir)   


    local name = utils.resolveModelName(neuronsuite.session.mcu_id or neuronsuite.app.activeLogDir)
    neuronsuite.app.ui.fieldHeader("Logs / " .. name)

    local buttonW
    local buttonH
    local padding
    local numPerRow

   if neuronsuite.preferences.general.iconsize == 0 then
        padding = neuronsuite.app.radio.buttonPaddingSmall
        buttonW = (neuronsuite.app.lcdWidth - padding) / neuronsuite.app.radio.buttonsPerRow - padding
        buttonH = neuronsuite.app.radio.navbuttonHeight
        numPerRow = neuronsuite.app.radio.buttonsPerRow
    end
    -- SMALL ICONS
    if neuronsuite.preferences.general.iconsize == 1 then

        padding = neuronsuite.app.radio.buttonPaddingSmall
        buttonW = neuronsuite.app.radio.buttonWidthSmall
        buttonH = neuronsuite.app.radio.buttonHeightSmall
        numPerRow = neuronsuite.app.radio.buttonsPerRowSmall
    end
    -- LARGE ICONS
    if neuronsuite.preferences.general.iconsize == 2 then

        padding = neuronsuite.app.radio.buttonPadding
        buttonW = neuronsuite.app.radio.buttonWidth
        buttonH = neuronsuite.app.radio.buttonHeight
        numPerRow = neuronsuite.app.radio.buttonsPerRow
    end


    local x = windowWidth - buttonW + 10

    local lc = 0
    local bx = 0

    if neuronsuite.app.gfx_buttons["logs_logs"] == nil then neuronsuite.app.gfx_buttons["logs_logs"] = {} end
    if neuronsuite.preferences.menulastselected["logs"] == nil then neuronsuite.preferences.menulastselected["logs_logs"] = 1 end

    if neuronsuite.app.gfx_buttons["logs"] == nil then neuronsuite.app.gfx_buttons["logs"] = {} end
    if neuronsuite.preferences.menulastselected["logs_logs"] == nil then neuronsuite.preferences.menulastselected["logs_logs"] = 1 end

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

        LCD_W, LCD_H = lcd.getWindowSize()
        local str = i18n("app.modules.logs.msg_no_logs_found")
        local ew = LCD_W
        local eh = LCD_H
        local etsizeW, etsizeH = lcd.getTextSize(str)
        local eposX = ew / 2 - etsizeW / 2
        local eposY = eh / 2 - etsizeH / 2

        local posErr = {w = etsizeW, h = neuronsuite.app.radio.navbuttonHeight, x = eposX, y = ePosY}

        line = form.addLine("", nil, false)
        form.addStaticText(line, posErr, str)

    else
        neuronsuite.app.gfx_buttons["logs_logs"] = neuronsuite.app.gfx_buttons["logs_logs"] or {}
        neuronsuite.preferences.menulastselected["logs_logs"] = neuronsuite.preferences.menulastselected["logs_logs"] or 1

        for idx, section in ipairs(dates) do

                form.addLine(format_date(section))
                local lc, y = 0, 0

                for pidx, page in ipairs(groupedLogs[section]) do

                            if lc == 0 then
                                y = form.height() + (neuronsuite.preferences.general.iconsize == 2 and neuronsuite.app.radio.buttonPadding or neuronsuite.app.radio.buttonPaddingSmall)
                            end

                            local x = (buttonW + padding) * lc
                            if neuronsuite.preferences.general.iconsize ~= 0 then
                                if neuronsuite.app.gfx_buttons["logs_logs"][pidx] == nil then neuronsuite.app.gfx_buttons["logs_logs"][pidx] = lcd.loadMask("app/modules/logs/gfx/logs.png") end
                            else
                                neuronsuite.app.gfx_buttons["logs_logs"][pidx] = nil
                            end

                            neuronsuite.app.formFields[pidx] = form.addButton(line, {x = x, y = y, w = buttonW, h = buttonH}, {
                                text = extractHourMinute(page),
                                icon = neuronsuite.app.gfx_buttons["logs_logs"][pidx],
                                options = FONT_S,
                                paint = function() end,
                                press = function()
                                    neuronsuite.preferences.menulastselected["logs_logs"] = tostring(idx) .. "_" .. tostring(pidx)
                                    neuronsuite.app.ui.progressDisplay()
                                    neuronsuite.app.ui.openPage(pidx, "Logs", "logs/logs_view.lua", page)                       
                                end
                            })

                            if neuronsuite.preferences.menulastselected["logs_logs"] == tostring(idx) .. "_" .. tostring(pidx) then
                                neuronsuite.app.formFields[pidx]:focus()
                            end

                            lc = (lc + 1) % numPerRow

                end

        end   

            
    end

    if neuronsuite.tasks.msp then
        neuronsuite.app.triggers.closeProgressLoader = true
    end
    enableWakeup = true

    return
end

local function event(widget, category, value, x, y)
    if  value == 35 then
        neuronsuite.app.ui.openPage(neuronsuite.app.lastIdx, neuronsuite.app.lastTitle, "logs/logs_dir.lua")
        return true
    end
    return false
end

local function wakeup()

    if enableWakeup == true then

    end

end

local function onNavMenu()

      neuronsuite.app.ui.openPage(neuronsuite.app.lastIdx, neuronsuite.app.lastTitle, "logs/logs_dir.lua")


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
