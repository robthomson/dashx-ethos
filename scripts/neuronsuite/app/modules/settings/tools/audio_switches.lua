local i18n = neuronsuite.i18n.get

-- Local config table for in-memory edits
local config = {}

local function sensorNameMap(sensorList)
    local nameMap = {}
    for _, sensor in ipairs(sensorList) do
        nameMap[sensor.key] = sensor.name
    end
    return nameMap
end

local function openPage(pageIdx, title, script)
    enableWakeup = true
    if not neuronsuite.app.navButtons then neuronsuite.app.navButtons = {} end
    neuronsuite.app.triggers.closeProgressLoader = true
    form.clear()

    neuronsuite.app.lastIdx    = pageIdx
    neuronsuite.app.lastTitle  = title
    neuronsuite.app.lastScript = script

    neuronsuite.app.ui.fieldHeader(
        i18n("app.modules.settings.name") .. " / " .. i18n("app.modules.settings.audio") .. " / " .. i18n("app.modules.settings.txt_audio_switches")
    )
    neuronsuite.app.formLineCnt = 0

    local formFieldCount = 0

    local function sortSensorListByName(sensorList)
        table.sort(sensorList, function(a, b)
            return a.name:lower() < b.name:lower()
        end)
        return sensorList
    end

    local sensorList = sortSensorListByName(neuronsuite.tasks.telemetry.listSwitchSensors())

    -- Prepare working config as a shallow copy of switches preferences
    local saved = neuronsuite.preferences.switches or {}
    for k, v in pairs(saved) do
        config[k] = v
    end

    for i, v in ipairs(sensorList) do
        formFieldCount = formFieldCount + 1
        neuronsuite.app.formLineCnt = neuronsuite.app.formLineCnt + 1
        neuronsuite.app.formLines[neuronsuite.app.formLineCnt] = form.addLine(v.name or "unknown")

        neuronsuite.app.formFields[formFieldCount] = form.addSwitchField(
            neuronsuite.app.formLines[neuronsuite.app.formLineCnt],
            nil,
            function()
                local value = config[v.key]
                if value then
                    local scategory, smember = value:match("([^,]+),([^,]+)")
                    if scategory and smember then
                        local source = system.getSource({ category = tonumber(scategory), member = tonumber(smember) })
                        return source
                    end
                end
                return nil
            end,
            function(newValue)
                if newValue then
                    local cat_member = newValue:category() .. "," .. newValue:member()
                    config[v.key] = cat_member
                else
                    config[v.key] = nil
                end
            end
        )
    end

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
        "settings/tools/audio.lua"
    )
end

local function onSaveMenu()
    local buttons = {
        {
            label  = i18n("app.btn_ok_long"),
            action = function()
                local msg = i18n("app.modules.profile_select.save_prompt_local")
                neuronsuite.app.ui.progressDisplaySave(msg:gsub("%?$", "."))
                for key, value in pairs(config) do
                    neuronsuite.preferences.switches[key] = value
                end
                neuronsuite.ini.save_ini_file(
                    "SCRIPTS:/" .. neuronsuite.config.preferences .. "/preferences.ini",
                    neuronsuite.preferences
                )
                neuronsuite.tasks.events.switches.resetSwitchStates()
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
            "settings/tools/audio.lua"
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
