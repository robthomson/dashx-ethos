-- Load utility functions
local utils = assert(neuronsuite.compiler.loadfile("SCRIPTS:/" .. neuronsuite.config.baseDir .. "/app/modules/logs/lib/utils.lua"))()
local i18n = neuronsuite.i18n.get
-- Wakeup control flag
local enableWakeup = false

-- Build and display the Logs directory selection page
local function openPage(idx, title, script)
    neuronsuite.app.activeLogDir = nil
    if not neuronsuite.utils.ethosVersionAtLeast() then return end

    -- Reset any running MSP task overrides
    if neuronsuite.tasks.msp then
        neuronsuite.tasks.msp.protocol.mspIntervalOveride = nil
    end

    -- Initialize page state
    neuronsuite.app.triggers.isReady = false
    neuronsuite.app.uiState = neuronsuite.app.uiStatus.pages
    form.clear()

    neuronsuite.app.lastIdx = idx
    neuronsuite.app.lastTitle = title
    neuronsuite.app.lastScript = script

    -- UI layout settings
    local w, h = lcd.getWindowSize()
    local prefs = neuronsuite.preferences.general
    local radio = neuronsuite.app.radio
    local icons = prefs.iconsize
    local padding, btnW, btnH, perRow

    if icons == 0 then
        padding = radio.buttonPaddingSmall
        btnW = (neuronsuite.app.lcdWidth - padding) / radio.buttonsPerRow - padding
        btnH = radio.navbuttonHeight
        perRow = radio.buttonsPerRow
    elseif icons == 1 then
        padding = radio.buttonPaddingSmall
        btnW, btnH = radio.buttonWidthSmall, radio.buttonHeightSmall
        perRow = radio.buttonsPerRowSmall
    else -- icons == 2
        padding = radio.buttonPadding
        btnW, btnH = radio.buttonWidth, radio.buttonHeight
        perRow = radio.buttonsPerRow
    end

    neuronsuite.app.ui.fieldHeader("Logs")

    local logDir = utils.getLogPath()
    local folders = utils.getLogsDir(logDir)

    -- Show message if no logs exist
    if #folders == 0 then
        local msg = i18n("app.modules.logs.msg_no_logs_found")
        local tw, th = lcd.getTextSize(msg)
        local x = w / 2 - tw / 2
        local y = h / 2 - th / 2
        form.addStaticText(nil, { x = x, y = y, w = tw, h = btnH }, msg)
    else
        -- Display buttons for each log directory
        local x, y, col = 0, form.height() + padding, 0
        neuronsuite.app.gfx_buttons.logs = neuronsuite.app.gfx_buttons.logs or {}

        for i, item in ipairs(folders) do
            if col >= perRow then
                col, y = 0, y + btnH + padding
            end

            local modelName = utils.resolveModelName(item.foldername)

            if icons ~= 0 then
                neuronsuite.app.gfx_buttons.logs[i] = neuronsuite.app.gfx_buttons.logs[i] or lcd.loadMask("app/modules/logs/gfx/folder.png")
            else
                neuronsuite.app.gfx_buttons.logs[i] = nil
            end

            local btn = form.addButton(nil, {
                x = col * (btnW + padding), y = y, w = btnW, h = btnH
            }, {
                text = modelName,
                options = FONT_S,
                icon = neuronsuite.app.gfx_buttons.logs[i],
                press = function()
                    neuronsuite.preferences.menulastselected.logs = i
                    neuronsuite.app.ui.progressDisplay()
                    neuronsuite.app.activeLogDir = item.foldername
                    neuronsuite.utils.log("Opening logs for: " .. item.foldername, "info")
                    neuronsuite.app.ui.openPage(i, "Logs", "logs/logs_logs.lua")
                end
            })

            btn:enable(true)

            if neuronsuite.preferences.menulastselected.logs_folder == i then
                btn:focus()
            end

            col = col + 1
        end
    end

    if neuronsuite.tasks.msp then
        neuronsuite.app.triggers.closeProgressLoader = true
    end

    enableWakeup = true
end

-- Handle form navigation or keypress events
local function event(widget, category, value)
    if value == 35 or category == 3 then
        neuronsuite.app.ui.openMainMenu()
        return true
    end
    return false
end

-- Background wakeup handler (placeholder for future logic)
local function wakeup()
    if enableWakeup then
        -- Future periodic update logic
    end
end

-- Navigation menu handler
local function onNavMenu()
    neuronsuite.app.ui.openMainMenu()
end

-- Module export
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
    API = {}
}
