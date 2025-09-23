local settings = {}


local function sensorNameMap(sensorList)
    local nameMap = {}
    for _, sensor in ipairs(sensorList) do
        nameMap[sensor.key] = sensor.name
    end
    return nameMap
end

local function openPage(pageIdx, title, script)
    enableWakeup = true
    neurondash.app.triggers.closeProgressLoader = true
    form.clear()

    neurondash.app.lastIdx    = pageIdx
    neurondash.app.lastTitle  = title
    neurondash.app.lastScript = script

    neurondash.app.ui.fieldHeader(
        "@i18n(app.modules.settings.name)@" .. " / " .. "@i18n(app.modules.settings.audio)@" .. " / " .. "@i18n(app.modules.settings.txt_audio_events)@"
    )
    neurondash.session.formLineCnt = 0

    local formFieldCount = 0

    local eventList = neurondash.tasks.events.telemetry.eventTable
    local eventNames = sensorNameMap(neurondash.tasks.telemetry.listSensors())

    settings = neurondash.preferences.events

    for i, v in ipairs(eventList) do
    formFieldCount = formFieldCount + 1
    neurondash.session.formLineCnt = neurondash.session.formLineCnt + 1
    neurondash.app.formLines[neurondash.session.formLineCnt] = form.addLine(eventNames[v.sensor] or "unknown")
    neurondash.app.formFields[formFieldCount] = form.addBooleanField(neurondash.app.formLines[neurondash.session.formLineCnt], 
                                                        nil, 
                                                        function() 
                                                            if neurondash.preferences and neurondash.preferences.events then
                                                                return settings[v.sensor] 
                                                            end
                                                        end, 
                                                        function(newValue) 
                                                            if neurondash.preferences and neurondash.preferences.events then
                                                                settings[v.sensor] = newValue 
                                                            end    
                                                        end)
    end
  
end

local function onNavMenu()
    neurondash.app.ui.progressDisplay()
    neurondash.app.ui.openPage(
        pageIdx,
        "@i18n(app.modules.settings.name)@",
        "settings/tools/audio.lua"
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
                    neurondash.preferences.events[key] = value
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
        "settings/tools/audio.lua"
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
