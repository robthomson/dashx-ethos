local settings = {}

local function openPage(pageIdx, title, script)
    enableWakeup = true
    dashx.app.triggers.closeProgressLoader = true
    form.clear()

    dashx.app.lastIdx    = pageIdx
    dashx.app.lastTitle  = title
    dashx.app.lastScript = script

    dashx.app.ui.fieldHeader(
        "@i18n(app.modules.settings.name)@" .. " / " .. "@i18n(app.modules.settings.txt_general)@"
    )
    dashx.session.formLineCnt = 0

    local formFieldCount = 0

    settings = dashx.preferences.general

    -- Icon size choice field
    formFieldCount = formFieldCount + 1
    dashx.session.formLineCnt = dashx.session.formLineCnt + 1
    dashx.app.formLines[dashx.session.formLineCnt] = form.addLine(
        "@i18n(app.modules.settings.txt_iconsize)@"
    )
    dashx.app.formFields[formFieldCount] = form.addChoiceField(
        dashx.app.formLines[dashx.session.formLineCnt],
        nil,
        {
            { "@i18n(app.modules.settings.txt_text)@",  0 },
            { "@i18n(app.modules.settings.txt_small)@", 1 },
            { "@i18n(app.modules.settings.txt_large)@", 2 },
        },
        function()
            if dashx.preferences and dashx.preferences.general and dashx.preferences.general.iconsize then
                return settings.iconsize
            else
                return 1
            end
        end,
        function(newValue)
            if dashx.preferences and dashx.preferences.general then
                settings.iconsize = newValue
            end
        end
    )


end

local function onNavMenu()
    dashx.app.ui.progressDisplay()
    dashx.app.ui.openPage(
        pageIdx,
        "@i18n(app.modules.settings.name)@",
        "settings/settings.lua"
    )
end

local function onSaveMenu()
    local buttons = {
        {
            label  = "@i18n(app.btn_ok_long)@",
            action = function()
                local msg = "@i18n(app.modules.profile_select.save_prompt_local)@"
                dashx.app.ui.progressDisplaySave(msg:gsub("%?$", "."))
                for key, value in pairs(settings) do
                    dashx.preferences.general[key] = value
                end
                dashx.ini.save_ini_file(
                    "SCRIPTS:/" .. dashx.config.preferences .. "/preferences.ini",
                    dashx.preferences
                )
                dashx.app.triggers.closeSave = true
                return true
            end,
        },
        {
            label  = "@i18n(app.modules.profile_select.cancel)@",
            action = function()
                return true
            end,
        },
    }

    form.openDialog({
        width   = nil,
        title   = "@i18n(app.modules.profile_select.save_settings)@",
        message = "@i18n(app.modules.profile_select.save_prompt_local)@",
        buttons = buttons,
        wakeup  = function() end,
        paint   = function() end,
        options = TEXT_LEFT,
    })
end

local function event(widget, category, value, x, y)
    -- if close event detected go to section home page
    if category == EVT_CLOSE and value == 0 or value == 35 then
        dashx.app.ui.openPage(
            pageIdx,
            "@i18n(app.modules.settings.name)@",
            "settings/settings.lua"
        )
        return true
    end
end

return {
    event      = event,
    openPage   = openPage,
    wakeup     = wakeup,
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
