local utils = assert(neurondash.compiler.loadfile("SCRIPTS:/" .. neurondash.config.baseDir .. "/app/modules/logs/lib/utils.lua"))()

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
    if not neurondash.utils.ethosVersionAtLeast() then
        return
    end


    currentDisplayMode = displaymode


    neurondash.app.triggers.isReady = false
    neurondash.app.uiState = neurondash.app.uiStatus.pages

    form.clear()

    neurondash.app.lastIdx = idx
    neurondash.app.lastTitle = title
    neurondash.app.lastScript = script

    local w, h = neurondash.utils.getWindowSize()
    local windowWidth = w
    local windowHeight = h
    local padding = neurondash.app.radio.buttonPadding

    local sc
    local panel

     local logDir = utils.getLogPath()

    local logs = utils.getLogs(logDir)   

    print(logDir)


    local name = utils.resolveModelName(neurondash.session.mcu_id or neurondash.session.activeLogDir)
    neurondash.app.ui.fieldHeader("Logs" )

    local buttonW
    local buttonH
    local padding
    local numPerRow

   if neurondash.preferences.general.iconsize == 0 then
        padding = neurondash.app.radio.buttonPaddingSmall
        buttonW = (neurondash.session.lcdWidth - padding) / neurondash.app.radio.buttonsPerRow - padding
        buttonH = neurondash.app.radio.navbuttonHeight
        numPerRow = neurondash.app.radio.buttonsPerRow
    end
    -- SMALL ICONS
    if neurondash.preferences.general.iconsize == 1 then

        padding = neurondash.app.radio.buttonPaddingSmall
        buttonW = neurondash.app.radio.buttonWidthSmall
        buttonH = neurondash.app.radio.buttonHeightSmall
        numPerRow = neurondash.app.radio.buttonsPerRowSmall
    end
    -- LARGE ICONS
    if neurondash.preferences.general.iconsize == 2 then

        padding = neurondash.app.radio.buttonPadding
        buttonW = neurondash.app.radio.buttonWidth
        buttonH = neurondash.app.radio.buttonHeight
        numPerRow = neurondash.app.radio.buttonsPerRow
    end


    local x = windowWidth - buttonW + 10

    local lc = 0
    local bx = 0

    if neurondash.app.gfx_buttons["logs_logs"] == nil then neurondash.app.gfx_buttons["logs_logs"] = {} end
    if neurondash.preferences.menulastselected["logs"] == nil then neurondash.preferences.menulastselected["logs_logs"] = 1 end

    if neurondash.app.gfx_buttons["logs"] == nil then neurondash.app.gfx_buttons["logs"] = {} end
    if neurondash.preferences.menulastselected["logs_logs"] == nil then neurondash.preferences.menulastselected["logs_logs"] = 1 end

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

        LCD_W, LCD_H = neurondash.utils.getWindowSize()
        local str = "@i18n(app.modules.logs.msg_no_logs_found)@"
        local ew = LCD_W
        local eh = LCD_H
        local etsizeW, etsizeH = lcd.getTextSize(str)
        local eposX = ew / 2 - etsizeW / 2
        local eposY = eh / 2 - etsizeH / 2

        local posErr = {w = etsizeW, h = neurondash.app.radio.navbuttonHeight, x = eposX, y = ePosY}

        line = form.addLine("", nil, false)
        form.addStaticText(line, posErr, str)

    else
        neurondash.app.gfx_buttons["logs_logs"] = neurondash.app.gfx_buttons["logs_logs"] or {}
        neurondash.preferences.menulastselected["logs_logs"] = neurondash.preferences.menulastselected["logs_logs"] or 1

        for idx, section in ipairs(dates) do

                form.addLine(format_date(section))
                local lc, y = 0, 0

                for pidx, page in ipairs(groupedLogs[section]) do

                            if lc == 0 then
                                y = form.height() + (neurondash.preferences.general.iconsize == 2 and neurondash.app.radio.buttonPadding or neurondash.app.radio.buttonPaddingSmall)
                            end

                            local x = (buttonW + padding) * lc
                            if neurondash.preferences.general.iconsize ~= 0 then
                                if neurondash.app.gfx_buttons["logs_logs"][pidx] == nil then neurondash.app.gfx_buttons["logs_logs"][pidx] = lcd.loadMask("app/modules/logs/gfx/logs.png") end
                            else
                                neurondash.app.gfx_buttons["logs_logs"][pidx] = nil
                            end

                            neurondash.app.formFields[pidx] = form.addButton(line, {x = x, y = y, w = buttonW, h = buttonH}, {
                                text = extractHourMinute(page),
                                icon = neurondash.app.gfx_buttons["logs_logs"][pidx],
                                options = FONT_S,
                                paint = function() end,
                                press = function()
                                    neurondash.preferences.menulastselected["logs_logs"] = tostring(idx) .. "_" .. tostring(pidx)
                                    neurondash.app.ui.progressDisplay()
                                    neurondash.app.ui.openPage(pidx, "Logs", "logs/logs_view.lua", page)                       
                                end
                            })

                            if neurondash.preferences.menulastselected["logs_logs"] == tostring(idx) .. "_" .. tostring(pidx) then
                                neurondash.app.formFields[pidx]:focus()
                            end

                            lc = (lc + 1) % numPerRow

                end

        end   

            
    end


    neurondash.app.triggers.closeProgressLoader = true

    enableWakeup = true

    return
end

local function event(widget, category, value, x, y)
    if  value == 35 then
        neurondash.app.ui.openMainMenu()
        return true
    end
    return false
end

local function wakeup()

    if enableWakeup == true then

    end

end

local function onNavMenu()

      --neurondash.app.ui.openPage(neurondash.app.lastIdx, neurondash.app.lastTitle, "logs/logs_dir.lua")
    neurondash.app.ui.openMainMenu()

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
