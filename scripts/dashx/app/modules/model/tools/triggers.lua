local dashx = require("dashx")

local enableWakeup = false

local function openPage(pageIdx, title, script)
    enableWakeup = true
    dashx.app.triggers.closeProgressLoader = true
    form.clear()

    dashx.app.lastIdx    = pageIdx
    dashx.app.lastTitle  = title
    dashx.app.lastScript = script

    dashx.app.ui.fieldHeader(
        "@i18n(app.modules.model.name)@" .. " / " .. "@i18n(app.modules.model.triggers)@"
    )

    local formFieldCount = 0
    local formLineCnt = 0
    dashx.app.formLines = {}
    dashx.app.formFields = {}



    -- Arm Switch
    formFieldCount = formFieldCount + 1
    formLineCnt = formLineCnt + 1
    dashx.app.formLines[formLineCnt] = form.addLine("@i18n(app.modules.model.model_armswitch)@")
    dashx.app.formFields[formFieldCount] = form.addSwitchField(
        dashx.app.formLines[formLineCnt],
        nil,
        function()
                if dashx.session.modelPreferences and dashx.session.modelPreferences.model.armswitch  then
                    local category, member, options = dashx.session.modelPreferences.model.armswitch:match("([^:]+):([^:]+):([^:]+)")
                    if category and member then
                        return system.getSource({category = category, member = member, options = options})
                    end
                end    
            return nil
        end,
        function(newValue)
            if dashx.session.modelPreferences then
                local member = newValue:member()
                local category = newValue:category()
                local options = newValue:options()
                dashx.session.modelPreferences.model.armswitch = category .. ":" .. member .. ":" .. options
            end
        end
    )


    -- Inflight Switch
    formFieldCount = formFieldCount + 1
    formLineCnt = formLineCnt + 1
    dashx.app.formLines[formLineCnt] = form.addLine("@i18n(app.modules.model.model_inflightswitch)@")
    dashx.app.formFields[formFieldCount] = form.addSwitchField(
        dashx.app.formLines[formLineCnt],
        nil,
        function()
            if dashx.session.modelPreferences and dashx.session.modelPreferences.model.inflightswitch  then
                    local category, member, options = dashx.session.modelPreferences.model.inflightswitch:match("([^:]+):([^:]+):([^:]+)")
                    if category and member then
                        return system.getSource({category = category, member = member, options = options})
                    end
                end    
            return nil
        end,
        function(newValue)
            if dashx.session.modelPreferences then
                local member = newValue:member()
                local category = newValue:category()
                local options = newValue:options()
                dashx.session.modelPreferences.model.inflightswitch = category .. ":" .. member .. ":" .. options
            end
        end
    )


    -- Inflight Switch
    formFieldCount = formFieldCount + 1
    formLineCnt = formLineCnt + 1
    dashx.app.formLines[formLineCnt] = form.addLine("@i18n(app.modules.model.model_inflightswitch_delay)@")
    dashx.app.formFields[formFieldCount] = form.addNumberField(
        dashx.app.formLines[formLineCnt],
        nil,
        0,
        120,
        function()
            if dashx.session.modelPreferences and dashx.session.modelPreferences.model.inflightswitch_delay  then
                return dashx.session.modelPreferences.model.inflightswitch_delay
            end
            return nil
        end,
        function(newValue)
            if dashx.session.modelPreferences then
                dashx.session.modelPreferences.model.inflightswitch_delay = newValue
            end
        end
    )
    dashx.app.formFields[formFieldCount]:suffix("s")
    dashx.app.formFields[formFieldCount]:default(20)


end

local function onNavMenu()
    dashx.app.ui.progressDisplay()
    dashx.app.ui.openPage(
        pageIdx,
        "@i18n(app.modules.model.name)@",
        "model/model.lua"
    )
end

local function onSaveMenu()
    local buttons = {
        {
            label  = "@i18n(app.btn_ok_long)@",
            action = function()
                local msg = "@i18n(app.modules.profile_select.save_prompt_local)@"
                dashx.app.ui.progressDisplaySave(msg:gsub("%?$", "."))

                -- save model dashboard dashx.preferences.model
                if dashx.session.mcu_id and dashx.session.modelPreferencesFile then

                    dashx.ini.save_ini_file(
                        dashx.session.modelPreferencesFile,
                        dashx.session.modelPreferences
                    )
                end

                dashx.app.triggers.closeSave = true

                if dashx.tasks and dashx.tasks.sensors  then
                    dashx.tasks.sensors.reset()
                end

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
        title   = "@i18n(app.modules.profile_select.save_dashx.preferences.model)@",
        message = "@i18n(app.modules.profile_select.save_prompt_local)@",
        buttons = buttons,
        wakeup  = function() end,
        paint   = function() end,
        options = TEXT_LEFT,
    })
end

local function event(widget, category, value, x, y)
    -- if close event detected go to section home page
    if (category == EVT_CLOSE and value == 0) or value == 35 then
        dashx.app.ui.openPage(
            pageIdx,
            "@i18n(app.modules.model.name)@",
            "model/model.lua"
        )
        return true
    end
end


local function wakeup()
    if enableWakeup then

            if not dashx.session.isConnected then
                dashx.app.ui.openMainMenu()
            end


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
