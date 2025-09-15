local i18n = neuronsuite.i18n.get
local enableWakeup = false

-- Local config table for in-memory edits
local config = {}

local function openPage(pageIdx, title, script)
    enableWakeup = true
    if not neuronsuite.app.navButtons then neuronsuite.app.navButtons = {} end
    neuronsuite.app.triggers.closeProgressLoader = true
    form.clear()

    neuronsuite.app.lastIdx    = pageIdx
    neuronsuite.app.lastTitle  = title
    neuronsuite.app.lastScript = script

    neuronsuite.app.ui.fieldHeader(
        i18n("app.modules.settings.name") .. " / " .. i18n("app.modules.settings.dashboard") .. " / " .. i18n("app.modules.settings.localizations")
    )
    neuronsuite.app.formLineCnt = 0
    local formFieldCount = 0

    -- Prepare working config as a shallow copy of localizations preferences
    local saved = neuronsuite.preferences.localizations or {}
    for k, v in pairs(saved) do
        config[k] = v
    end

    formFieldCount = formFieldCount + 1
    neuronsuite.app.formLineCnt = neuronsuite.app.formLineCnt + 1
    neuronsuite.app.formLines[neuronsuite.app.formLineCnt] = form.addLine(i18n("app.modules.settings.temperature_unit"))
    neuronsuite.app.formFields[formFieldCount] = form.addChoiceField(
        neuronsuite.app.formLines[neuronsuite.app.formLineCnt],
        nil,
        {
            {i18n("app.modules.settings.celcius"), 0},
            {i18n("app.modules.settings.fahrenheit"), 1}
        },
        function()
            return config.temperature_unit or 0
        end,
        function(newValue)
            config.temperature_unit = newValue
        end
    )

    formFieldCount = formFieldCount + 1
    neuronsuite.app.formLineCnt = neuronsuite.app.formLineCnt + 1
    neuronsuite.app.formLines[neuronsuite.app.formLineCnt] = form.addLine(i18n("app.modules.settings.altitude_unit"))
    neuronsuite.app.formFields[formFieldCount] = form.addChoiceField(
        neuronsuite.app.formLines[neuronsuite.app.formLineCnt],
        nil,
        {
            {i18n("app.modules.settings.meters"), 0},
            {i18n("app.modules.settings.feet"), 1}
        },
        function()
            return config.altitude_unit or 0
        end,
        function(newValue)
            config.altitude_unit = newValue
        end
    )

    -- Always enable all fields and Save
    for i, field in ipairs(neuronsuite.app.formFields) do
        if field and field.enable then field:enable(true) end
    end
    neuronsuite.app.navButtons.save = true
end

local function onNavMenu()
    neuronsuite.app.ui.progressDisplay(nil,nil,true)
    neuronsuite.app.ui.openPage(
        pageIdx,
        i18n("app.modules.settings.name"),
        "settings/settings.lua"
    )
    return true
end

local function onSaveMenu()
    local buttons = {
        {
            label  = i18n("app.btn_ok_long"),
            action = function()
                local msg = i18n("app.modules.profile_select.save_prompt_local")
                neuronsuite.app.ui.progressDisplaySave(msg:gsub("%?$", "."))
                for key, value in pairs(config) do
                    neuronsuite.preferences.localizations[key] = value
                end
                neuronsuite.ini.save_ini_file(
                    "SCRIPTS:/" .. neuronsuite.config.preferences .. "/preferences.ini",
                    neuronsuite.preferences
                )
                -- update dashboard theme
                neuronsuite.widgets.dashboard.reload_themes()
                -- close save progress
                neuronsuite.app.triggers.closeSave = true
                return true
            end,
        },
        {
            label  = i18n("app.modules.profile_select.cancel"),
            action = function()
                return true
            end,
        },
    }

    form.openDialog({
        width   = nil,
        title   = i18n("app.modules.profile_select.save_settings"),
        message = i18n("app.modules.profile_select.save_prompt_local"),
        buttons = buttons,
        wakeup  = function() end,
        paint   = function() end,
        options = TEXT_LEFT,
    })
end

local function event(widget, category, value, x, y)
    -- if close event detected go to section home page
    if category == EVT_CLOSE and value == 0 or value == 35 then
        neuronsuite.app.ui.openPage(
            pageIdx,
            i18n("app.modules.settings.name"),
            "settings/settings.lua"
        )
        return true
    end
end

return {
    event      = event,
    openPage   = openPage,
    onNavMenu  = onNavMenu,
    onSaveMenu = onSaveMenu,
    navButtons = {
        menu   = true,
        save   = true,
        reload = false,
        tool   = false,
        help   = false,
    },
    API = {},
}
