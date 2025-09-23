local settings = {}

local function openPage(pageIdx, title, script)
    enableWakeup = true
    neurondash.app.triggers.closeProgressLoader = true
    form.clear()

    neurondash.app.lastIdx    = pageIdx
    neurondash.app.lastTitle  = title
    neurondash.app.lastScript = script

    neurondash.app.ui.fieldHeader(
        "@i18n(app.modules.settings.name)@" .. " / " .. "@i18n(app.modules.settings.txt_development)@"
    )
    neurondash.session.formLineCnt = 0

    local formFieldCount = 0

    settings = neurondash.preferences.developer

formFieldCount = formFieldCount + 1
    neurondash.session.formLineCnt = neurondash.session.formLineCnt + 1
    neurondash.app.formLines[neurondash.session.formLineCnt] = form.addLine("@i18n(app.modules.settings.txt_devtools)@")
    neurondash.app.formFields[formFieldCount] = form.addBooleanField(neurondash.app.formLines[neurondash.session.formLineCnt], 
                                                        nil, 
                                                        function() 
                                                            if neurondash.preferences and neurondash.preferences.developer then
                                                                return settings['devtools'] 
                                                            end
                                                        end, 
                                                        function(newValue) 
                                                            if neurondash.preferences and neurondash.preferences.developer then
                                                                settings.devtools = newValue
                                                            end    
                                                        end)    


    formFieldCount = formFieldCount + 1
    neurondash.session.formLineCnt = neurondash.session.formLineCnt + 1
    neurondash.app.formLines[neurondash.session.formLineCnt] = form.addLine("@i18n(app.modules.settings.txt_compilation)@")
    neurondash.app.formFields[formFieldCount] = form.addBooleanField(neurondash.app.formLines[neurondash.session.formLineCnt], 
                                                        nil, 
                                                        function() 
                                                            if neurondash.preferences and neurondash.preferences.developer then
                                                                return settings['compile'] 
                                                            end
                                                        end, 
                                                        function(newValue) 
                                                            if neurondash.preferences and neurondash.preferences.developer then
                                                                settings.compile = newValue
                                                            end    
                                                        end)                                                        



    local logpanel = form.addExpansionPanel("@i18n(app.modules.settings.txt_logging)@")
    logpanel:open(false) 

    formFieldCount = formFieldCount + 1
    neurondash.session.formLineCnt = neurondash.session.formLineCnt + 1
    neurondash.app.formLines[neurondash.session.formLineCnt] = logpanel:addLine("@i18n(app.modules.settings.txt_loglocation)@")
    neurondash.app.formFields[formFieldCount] = form.addChoiceField(neurondash.app.formLines[neurondash.session.formLineCnt], nil, 
                                                        {{"@i18n(app.modules.settings.txt_console)@", 0}, {"@i18n(app.modules.settings.txt_consolefile)@", 1}}, 
                                                        function() 
                                                            if neurondash.preferences and neurondash.preferences.developer then
                                                                if neurondash.preferences.developer.logtofile  == false then
                                                                    return 0
                                                                else
                                                                    return 1
                                                                end   
                                                            end
                                                        end, 
                                                        function(newValue) 
                                                            if neurondash.preferences and neurondash.preferences.developer then
                                                                local value
                                                                if newValue == 0 then
                                                                    value = false
                                                                else    
                                                                    value = true
                                                                end    
                                                                settings.logtofile = value
                                                            end    
                                                        end) 

    formFieldCount = formFieldCount + 1
    neurondash.session.formLineCnt = neurondash.session.formLineCnt + 1
    neurondash.app.formLines[neurondash.session.formLineCnt] = logpanel:addLine("@i18n(app.modules.settings.txt_loglevel)@")
    neurondash.app.formFields[formFieldCount] = form.addChoiceField(neurondash.app.formLines[neurondash.session.formLineCnt], nil, 
                                                        {{"@i18n(app.modules.settings.txt_off)@", 0}, {"@i18n(app.modules.settings.txt_info)@", 1}, {"@i18n(app.modules.settings.txt_debug)@", 2}}, 
                                                        function() 
                                                            if neurondash.preferences and neurondash.preferences.developer then
                                                                if settings['loglevel']  == "off" then
                                                                    return 0
                                                                elseif settings['loglevel']  == "info" then
                                                                    return 1
                                                                else
                                                                    return 2
                                                                end   
                                                            end
                                                        end, 
                                                        function(newValue) 
                                                            if neurondash.preferences and neurondash.preferences.developer then
                                                                local value
                                                                if newValue == 0 then
                                                                    value = "off"
                                                                elseif newValue == 1 then
                                                                    value = "info"
                                                                else
                                                                    value = "debug"
                                                                end    
                                                                settings['loglevel'] = value 
                                                            end    
                                                        end) 
 

    formFieldCount = formFieldCount + 1
    neurondash.session.formLineCnt = neurondash.session.formLineCnt + 1
    neurondash.app.formLines[neurondash.session.formLineCnt] = logpanel:addLine("@i18n(app.modules.settings.txt_memusage)@")
    neurondash.app.formFields[formFieldCount] = form.addBooleanField(neurondash.app.formLines[neurondash.session.formLineCnt], 
                                                        nil, 
                                                        function() 
                                                            if neurondash.preferences and neurondash.preferences.developer then
                                                                return settings['memstats'] 
                                                            end
                                                        end, 
                                                        function(newValue) 
                                                            if neurondash.preferences and neurondash.preferences.developer then
                                                                settings.memstats = newValue
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
end

local function onSaveMenu()
    local buttons = {
        {
            label  = "@i18n(app.btn_ok_long)@",
            action = function()
                local msg = "@i18n(app.modules.profile_select.save_prompt_local)@"
                neurondash.app.ui.progressDisplaySave(msg:gsub("%?$", "."))
                for key, value in pairs(settings) do
                    neurondash.preferences.developer[key] = value
                end
                neurondash.ini.save_ini_file(
                    "SCRIPTS:/" .. neurondash.config.preferences .. "/preferences.ini",
                    neurondash.preferences
                )
                
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
