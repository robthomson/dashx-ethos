local settings = {}

local function openPage(pageIdx, title, script)
    enableWakeup = true
    neurondash.app.triggers.closeProgressLoader = true
    form.clear()

    neurondash.app.lastIdx    = pageIdx
    neurondash.app.lastTitle  = title
    neurondash.app.lastScript = script

    neurondash.app.ui.fieldHeader(
        "@i18n(app.modules.model.name)@" .. " / " .. "@i18n(app.modules.model.triggers)@"
    )

    local formFieldCount = 0
    local formLineCnt = 0
    neurondash.app.formLines = {}
    neurondash.app.formFields = {}

    settings = neurondash.preferences.model

    -- Arm Switch
    formFieldCount = formFieldCount + 1
    formLineCnt = formLineCnt + 1
    neurondash.app.formLines[formLineCnt] = form.addLine("@i18n(app.modules.model.model_armswitch)@")
    neurondash.app.formFields[formFieldCount] = form.addSwitchField(
        neurondash.app.formLines[formLineCnt],
        nil,
        function()
            if neurondash.session.modelPreferences then
                local category, member = settings.armswitch:match("([^:]+):([^:]+)")
                if category and member then
                    return system.getSource({category = category, member = member})
                end
            end
            return nil
        end,
        function(newValue)
            if neurondash.session.modelPreferences then
                local member = newValue:member()
                local category = newValue:category()
                settings.armswitch = category .. ":" .. member
            end
        end
    )

    -- Idle Switch
    formFieldCount = formFieldCount + 1
    formLineCnt = formLineCnt + 1
    neurondash.app.formLines[formLineCnt] = form.addLine("@i18n(app.modules.model.model_idleswitch)@")
    neurondash.app.formFields[formFieldCount] = form.addSwitchField(
        neurondash.app.formLines[formLineCnt],
        nil,
        function()
            if neurondash.session.modelPreferences then
                local category, member = settings.idleswitch:match("([^:]+):([^:]+)")
                if category and member then
                    return system.getSource({category = category, member = member})
                end
            end
            return nil
        end,
        function(newValue)
            if neurondash.session.modelPreferences then
                local member = newValue:member()
                local category = newValue:category()
                settings.idleswitch = category .. ":" .. member
            end
        end
    )

    --[[
    -- Rate Switch
    formFieldCount = formFieldCount + 1
    formLineCnt = formLineCnt + 1
    neurondash.app.formLines[formLineCnt] = form.addLine("@i18n(app.modules.model.model_rateswitch)@")
    neurondash.app.formFields[formFieldCount] = form.addSwitchField(
        neurondash.app.formLines[formLineCnt],
        nil,
        function()
            if neurondash.session.modelPreferences then
                local category, member = settings.rateswitch:match("([^:]+):([^:]+)")
                if category and member then
                    return system.getSource({category = category, member = member})
                end
            end
            return nil
        end,
        function(newValue)
            if neurondash.session.modelPreferences then
                local member = newValue:member()
                local category = newValue:category()
                settings.rateswitch = category .. ":" .. member
            end
        end
    )
        ]]--
end

local function onNavMenu()
    neurondash.app.ui.progressDisplay()
    neurondash.app.ui.openPage(
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
                neurondash.app.ui.progressDisplaySave(msg:gsub("%?$", "."))

                -- save model dashboard settings
                if neurondash.session.isConnected and neurondash.session.mcu_id and neurondash.session.modelPreferencesFile then
                    for key, value in pairs(settings) do
                        neurondash.session.modelPreferences.model[key] = value
                    end


                    neurondash.ini.save_ini_file(
                        neurondash.session.modelPreferencesFile,
                        neurondash.session.modelPreferences
                    )
                end

                neurondash.app.triggers.closeSave = true

                if neurondash.tasks and neurondash.tasks.sensors  then
                    neurondash.tasks.sensors.reset()
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
    if (category == EVT_CLOSE and value == 0) or value == 35 then
        neurondash.app.ui.openPage(
            pageIdx,
            "@i18n(app.modules.model.name)@",
            "models/models.lua"
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
