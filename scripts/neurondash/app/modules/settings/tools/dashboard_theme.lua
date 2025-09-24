local settings = {}
local settings_model = {}

local themeList = neurondash.widgets.dashboard.listThemes() 
local formattedThemes = {}
local formattedThemesModel = {}

local enableWakeup = false
local prevConnectedState = nil

--- Generates formatted lists of available themes and their models.
-- Iterates over the global `themeList` and populates two tables:
-- `formattedThemes` with theme names and indices, and
-- `formattedThemesModel` with a disabled option followed by theme names and indices.
-- Assumes `themeList`, `formattedThemes`, `formattedThemesModel`, and `neurondash.i18n` are defined in the surrounding scope.
local function generateThemeList()

    -- setup environment
    settings = neurondash.preferences.dashboard

    if neurondash.session.modelPreferences then
        settings_model = neurondash.session.modelPreferences.dashboard
    else
        settings_model = {}
    end

    -- build global table
    for i, theme in ipairs(themeList) do
        table.insert(formattedThemes, { theme.name, theme.idx })
    end

    -- build model table
    table.insert(formattedThemesModel, { "@i18n(app.modules.settings.dashboard_theme_panel_model_disabled)@", 0 })
    for i, theme in ipairs(themeList) do
        table.insert(formattedThemesModel, { theme.name, theme.idx })
    end   
end

local function openPage(pageIdx, title, script)
    enableWakeup = true
    neurondash.app.triggers.closeProgressLoader = true
    form.clear()

    neurondash.app.lastIdx    = pageIdx
    neurondash.app.lastTitle  = title
    neurondash.app.lastScript = script

    neurondash.app.ui.fieldHeader(
        "@i18n(app.modules.settings.name)@" .. " / " .. "@i18n(app.modules.settings.dashboard)@" .. " / " .. "@i18n(app.modules.settings.dashboard_theme)@"
    )
    neurondash.app.formLineCnt = 0

    local formFieldCount = 0

    -- generate the initial list
    generateThemeList()

    -- ===========================================================================
    -- create global theme selection panel
    -- ===========================================================================
    local global_panel = form.addExpansionPanel("@i18n(app.modules.settings.dashboard_theme_panel_global)@")
    global_panel:open(true) 

    -- preflight theme selection
    formFieldCount = formFieldCount + 1
    neurondash.app.formLineCnt = neurondash.app.formLineCnt + 1
    neurondash.app.formLines[neurondash.app.formLineCnt] = global_panel:addLine("@i18n(app.modules.settings.dashboard_theme_preflight)@")
            
    neurondash.app.formFields[formFieldCount] = form.addChoiceField(neurondash.app.formLines[neurondash.app.formLineCnt], nil, 
                                                        formattedThemes, 
                                                        function()
                                                            if neurondash.preferences and neurondash.preferences.dashboard then
                                                                local folderName = settings.theme_preflight
                                                                for _, theme in ipairs(themeList) do
                                                                    if (theme.source .. "/" .. theme.folder) == folderName then
                                                                        return theme.idx
                                                                    end
                                                                end
                                                            end
                                                            return nil
                                                        end, 
                                                        function(newValue) 
                                                            if neurondash.preferences and neurondash.preferences.dashboard then
                                                                local theme = themeList[newValue]
                                                                if theme then
                                                                    settings.theme_preflight = theme.source .. "/" .. theme.folder
                                                                end
                                                            end
                                                        end)     

    -- inflight theme selection                                                          
    formFieldCount = formFieldCount + 1
    neurondash.app.formLineCnt = neurondash.app.formLineCnt + 1
    neurondash.app.formLines[neurondash.app.formLineCnt] = global_panel:addLine("@i18n(app.modules.settings.dashboard_theme_inflight)@")
                              
    neurondash.app.formFields[formFieldCount] = form.addChoiceField(neurondash.app.formLines[neurondash.app.formLineCnt], nil, 
                                                        formattedThemes, 
                                                        function()
                                                            if neurondash.preferences and neurondash.preferences.dashboard then
                                                                local folderName = settings.theme_inflight
                                                                for _, theme in ipairs(themeList) do
                                                                    if (theme.source .. "/" .. theme.folder) == folderName then
                                                                        return theme.idx
                                                                    end
                                                                end
                                                            end
                                                            return nil
                                                        end, 
                                                        function(newValue) 
                                                            if neurondash.preferences and neurondash.preferences.dashboard then
                                                                local theme = themeList[newValue]
                                                                if theme then
                                                                    settings.theme_inflight = theme.source .. "/" .. theme.folder
                                                                end
                                                            end
                                                        end)                                                             

                                                        
     -- postflight theme selection                                                            
    formFieldCount = formFieldCount + 1
    neurondash.app.formLineCnt = neurondash.app.formLineCnt + 1
    neurondash.app.formLines[neurondash.app.formLineCnt] = global_panel:addLine("@i18n(app.modules.settings.dashboard_theme_postflight)@")
                                    
    neurondash.app.formFields[formFieldCount] = form.addChoiceField(neurondash.app.formLines[neurondash.app.formLineCnt], nil, 
                                                        formattedThemes, 
                                                        function()
                                                            if neurondash.preferences and neurondash.preferences.dashboard then
                                                                local folderName = settings.theme_postflight
                                                                for _, theme in ipairs(themeList) do
                                                                    if (theme.source .. "/" .. theme.folder) == folderName then
                                                                        return theme.idx
                                                                    end
                                                                end
                                                            end
                                                            return nil
                                                        end, 
                                                        function(newValue) 
                                                            if neurondash.preferences and neurondash.preferences.dashboard then
                                                                local theme = themeList[newValue]
                                                                if theme then
                                                                    settings.theme_postflight = theme.source .. "/" .. theme.folder
                                                                end
                                                            end
                                                        end)      

   -- ===========================================================================
    -- create model theme selection panel
    -- ===========================================================================
    local model_panel = form.addExpansionPanel("@i18n(app.modules.settings.dashboard_theme_panel_model)@")
    model_panel:open(false) 


    -- preflight theme selection
    formFieldCount = formFieldCount + 1
    neurondash.app.formLineCnt = neurondash.app.formLineCnt + 1
    neurondash.app.formLines[neurondash.app.formLineCnt] = model_panel:addLine("@i18n(app.modules.settings.dashboard_theme_preflight)@")
            
    neurondash.app.formFields[formFieldCount] = form.addChoiceField(neurondash.app.formLines[neurondash.app.formLineCnt], nil, 
                                                        formattedThemesModel, 
                                                        function()
                                                            if neurondash.session.modelPreferences and neurondash.session.modelPreferences then
                                                                local folderName = settings_model.theme_preflight
                                                                for _, theme in ipairs(themeList) do
                                                                    if (theme.source .. "/" .. theme.folder) == folderName then
                                                                        return theme.idx
                                                                    end
                                                                end
                                                            end
                                                            return nil
                                                        end, 
                                                        function(newValue) 
                                                            if neurondash.session.modelPreferences and neurondash.session.modelPreferences then
                                                                local theme = themeList[newValue]
                                                                if theme then
                                                                    settings_model.theme_preflight = theme.source .. "/" .. theme.folder
                                                                else
                                                                    settings_model.theme_preflight = "nil"    
                                                                end
                                                            end
                                                        end) 
    neurondash.app.formFields[formFieldCount]:enable(false)                                                        

    -- inflight theme selection                                                          
    formFieldCount = formFieldCount + 1
    neurondash.app.formLineCnt = neurondash.app.formLineCnt + 1
    neurondash.app.formLines[neurondash.app.formLineCnt] = model_panel:addLine("@i18n(app.modules.settings.dashboard_theme_inflight)@")
                              
    neurondash.app.formFields[formFieldCount] = form.addChoiceField(neurondash.app.formLines[neurondash.app.formLineCnt], nil, 
                                                        formattedThemesModel, 
                                                        function()
                                                            if neurondash.session.modelPreferences and neurondash.session.modelPreferences then
                                                                local folderName = settings_model.theme_inflight
                                                                for _, theme in ipairs(themeList) do
                                                                    if (theme.source .. "/" .. theme.folder) == folderName then
                                                                        return theme.idx
                                                                    end
                                                                end
                                                            end
                                                            return nil
                                                        end, 
                                                        function(newValue) 
                                                            if neurondash.session.modelPreferences and neurondash.session.modelPreferences then
                                                                local theme = themeList[newValue]
                                                                if theme then
                                                                    settings_model.theme_inflight = theme.source .. "/" .. theme.folder
                                                                else
                                                                    settings_model.theme_inflight = "nil"    
                                                                end
                                                            end
                                                        end)                                                             
    neurondash.app.formFields[formFieldCount]:enable(false)  
                                                        
     -- postflight theme selection                                                            
    formFieldCount = formFieldCount + 1
    neurondash.app.formLineCnt = neurondash.app.formLineCnt + 1
    neurondash.app.formLines[neurondash.app.formLineCnt] = model_panel:addLine("@i18n(app.modules.settings.dashboard_theme_postflight)@")
                                    
    neurondash.app.formFields[formFieldCount] = form.addChoiceField(neurondash.app.formLines[neurondash.app.formLineCnt], nil, 
                                                        formattedThemesModel, 
                                                        function()
                                                            if neurondash.session.modelPreferences and neurondash.session.modelPreferences then
                                                                local folderName = settings_model.theme_postflight
                                                                for _, theme in ipairs(themeList) do
                                                                    if (theme.source .. "/" .. theme.folder) == folderName then
                                                                        return theme.idx
                                                                    end
                                                                end
                                                            end
                                                            return nil
                                                        end, 
                                                        function(newValue) 
                                                            if neurondash.preferences and neurondash.preferences.dashboard then
                                                                local theme = themeList[newValue]
                                                                if theme then
                                                                    settings_model.theme_postflight = theme.source .. "/" .. theme.folder
                                                                else
                                                                    settings_model.theme_postflight = "nil"    
                                                                end
                                                            end
                                                        end)      
    neurondash.app.formFields[formFieldCount]:enable(false)  
                                                  
end

local function onNavMenu()
    neurondash.app.ui.progressDisplay(nil,nil,true)
        neurondash.app.ui.openPage(
            pageIdx,
            "@i18n(app.modules.settings.dashboard)@",
            "settings/tools/dashboard.lua"
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

                -- save global dashboard settings
                for key, value in pairs(settings) do
                    neurondash.preferences.dashboard[key] = value
                end
                neurondash.ini.save_ini_file(
                    "SCRIPTS:/" .. neurondash.config.preferences .. "/preferences.ini",
                    neurondash.preferences
                )

                -- save model dashboard settings
                if neurondash.session.isConnected and neurondash.session.mcu_id and neurondash.session.modelPreferencesFile then
                    for key, value in pairs(settings_model) do
                        neurondash.session.modelPreferences.dashboard[key] = value
                    end
                    neurondash.ini.save_ini_file(
                        neurondash.session.modelPreferencesFile,
                        neurondash.session.modelPreferences
                    )
                end    
               

                -- update dashboard theme
                neurondash.widgets.dashboard.reload_themes(true) -- send true to force full reload
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
            "@i18n(app.modules.settings.dashboard)@",
            "settings/tools/dashboard.lua"
        )
        return true
    end
end

local function wakeup()
    if not enableWakeup then
        return
    end

    -- current combined state: true only if both are truthy
    local currState = (neurondash.session.isConnected and neurondash.session.mcu_id) and true or false

    -- only update if state has changed
    if currState ~= prevConnectedState then

        -- if we're now connected, you can do any repopulation here
        if currState then
                generateThemeList()
                for i = 4, 6 do
                    neurondash.app.formFields[i]:values(formattedThemesModel)
                end               
        end

        -- toggle all three fields together
        for i = 4, 6 do
            neurondash.app.formFields[i]:enable(currState)
        end

        -- remember for next time
        prevConnectedState = currState
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
