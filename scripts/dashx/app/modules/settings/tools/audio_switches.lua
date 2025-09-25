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
    dashx.app.triggers.closeProgressLoader = true
    form.clear()

    dashx.app.lastIdx    = pageIdx
    dashx.app.lastTitle  = title
    dashx.app.lastScript = script

    dashx.app.ui.fieldHeader(
        "@i18n(app.modules.settings.name)@" .. " / " .. "@i18n(app.modules.settings.audio)@" .. " / " .. "@i18n(app.modules.settings.txt_audio_switches)@"
    )
    dashx.session.formLineCnt = 0

    local formFieldCount = 0

    local function sortSensorListByName(sensorList)
        table.sort(sensorList, function(a, b)
            return a.name:lower() < b.name:lower()
        end)
        return sensorList
    end

    local sensorList = sortSensorListByName(dashx.tasks.telemetry.listSwitchSensors())

    settings = dashx.preferences.switches

    for i, v in ipairs(sensorList) do
    formFieldCount = formFieldCount + 1
    dashx.session.formLineCnt = dashx.session.formLineCnt + 1
    dashx.app.formLines[dashx.session.formLineCnt] = form.addLine(v.name or "unknown")


    dashx.app.formFields[formFieldCount] = form.addSwitchField(dashx.app.formLines[dashx.session.formLineCnt], 
                                                        nil, 
                                                        function() 
                                                            if dashx.preferences and dashx.preferences.switches then
                                                                local value = settings[v.key]
                                                                if value then
                                                                    local scategory, smember = value:match("([^,]+),([^,]+)")
                                                                    if scategory and smember then
                                                                        local source = system.getSource({ category = tonumber(scategory), member = tonumber(smember) }) 
                                                                        return source
                                                                    end    
                                                                end
                                                                return nil
                                                            end
                                                        end, 
                                                        function(newValue) 
                                                            if dashx.preferences and dashx.preferences.switches then
                                                                local cat_member = newValue:category() .. "," .. newValue:member()
                                                                settings[v.key] = cat_member or nil
                                                            end    
                                                        end)

    end
  
end

local function onNavMenu()
    dashx.app.ui.progressDisplay()
    dashx.app.ui.openPage(
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
                dashx.app.ui.progressDisplaySave(msg:gsub("%?$", "."))
                for key, value in pairs(settings) do
                    dashx.preferences.switches[key] = value
                end
                dashx.ini.save_ini_file(
                    "SCRIPTS:/" .. dashx.config.preferences .. "/preferences.ini",
                    dashx.preferences
                )
                dashx.tasks.events.switches.resetSwitchStates()
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
