local settings = {}

local function openPage(pageIdx, title, script)
    enableWakeup = true
    neurondash.app.triggers.closeProgressLoader = true
    form.clear()

    neurondash.app.lastIdx    = pageIdx
    neurondash.app.lastTitle  = title
    neurondash.app.lastScript = script

    neurondash.app.ui.fieldHeader(
        "@i18n(app.modules.settings.name)@" .. " / " .. "@i18n(app.modules.settings.dashboard)@" .. " / " .. "@i18n(app.modules.settings.localizations)@"
    )
    neurondash.session.formLineCnt = 0

    local formFieldCount = 0

    settings = neurondash.preferences.localizations

    formFieldCount = formFieldCount + 1
    neurondash.session.formLineCnt = neurondash.session.formLineCnt + 1
    neurondash.app.formLines[neurondash.session.formLineCnt] = form.addLine("@i18n(app.modules.settings.temperature_unit)@")
    neurondash.app.formFields[formFieldCount] = form.addChoiceField(neurondash.app.formLines[neurondash.session.formLineCnt], nil, 
                                                        {{"@i18n(app.modules.settings.celcius)@", 0}, {"@i18n(app.modules.settings.fahrenheit)@", 1}}, 
                                                        function() 
                                                            if neurondash.preferences and neurondash.preferences.localizations then
                                                                return settings.temperature_unit or 0
                                                            end
                                                        end, 
                                                        function(newValue) 
                                                            if neurondash.preferences and neurondash.preferences.localizations then
                                                                settings.temperature_unit = newValue
                                                            end    
                                                        end) 
            
    formFieldCount = formFieldCount + 1
    neurondash.session.formLineCnt = neurondash.session.formLineCnt + 1
    neurondash.app.formLines[neurondash.session.formLineCnt] = form.addLine("@i18n(app.modules.settings.altitude_unit)@")
    neurondash.app.formFields[formFieldCount] = form.addChoiceField(neurondash.app.formLines[neurondash.session.formLineCnt], nil, 
                                                        {{"@i18n(app.modules.settings.meters)@", 0}, {"@i18n(app.modules.settings.feet)@", 1}}, 
                                                        function() 
                                                            if neurondash.preferences and neurondash.preferences.localizations then
                                                                return settings.altitude_unit or 0
                                                            end
                                                        end, 
                                                        function(newValue) 
                                                            if neurondash.preferences and neurondash.preferences.localizations then
                                                                settings.altitude_unit = newValue
                                                            end    
                                                        end) 
              
                                                  
end

local function onNavMenu()
    neurondash.app.ui.progressDisplay()
        neurondash.app.ui.openPage(
            pageIdx,
            "@i18n(app.modules.settings.name)@",
            "settings/settings.lua"
        )
        return true
end

local function onSaveMenu()
    local buttons = {
        {
            label  = "@i18n(app.btn_ok_long)@",
            action = function()
                local msg = "@i18n(app.modules.profile_select.save_prompt_local)@"
                neurondash.app.ui.progressDisplaySave(msg:gsub("%?$", "."))
                for key, value in pairs(settings) do
                    neurondash.preferences.dashboard[key] = value
                end
                neurondash.ini.save_ini_file(
                    "SCRIPTS:/" .. neurondash.config.preferences .. "/preferences.ini",
                    neurondash.preferences
                )
                -- update dashboard theme
                neurondash.widgets.dashboard.reload_themes()
                -- close save progress
                neurondash.app.triggers.closeSave = true
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
        neurondash.app.ui.openPage(
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
