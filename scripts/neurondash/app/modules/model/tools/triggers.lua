
local enableWakeup = false

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



    -- Arm Switch
    formFieldCount = formFieldCount + 1
    formLineCnt = formLineCnt + 1
    neurondash.app.formLines[formLineCnt] = form.addLine("@i18n(app.modules.model.model_armswitch)@")
    neurondash.app.formFields[formFieldCount] = form.addSwitchField(
        neurondash.app.formLines[formLineCnt],
        nil,
        function()
            if neurondash.session.modelPreferences then
                if neurondash.preferences.model.armswitch  then
                    local category, member, options = neurondash.preferences.model.armswitch:match("([^:]+):([^:]+):([^:]+)")
                    if category and member then
                        return system.getSource({category = category, member = member, options = options})
                    end
                end    
            end
            return nil
        end,
        function(newValue)
            if neurondash.session.modelPreferences then
                local member = newValue:member()
                local category = newValue:category()
                local options = newValue:options()
                neurondash.preferences.model.armswitch = category .. ":" .. member .. ":" .. options
            end
        end
    )
    neurondash.app.formFields[formFieldCount]:enable(false)

    -- Idle Switch
    formFieldCount = formFieldCount + 1
    formLineCnt = formLineCnt + 1
    neurondash.app.formLines[formLineCnt] = form.addLine("@i18n(app.modules.model.model_idleswitch)@")
    neurondash.app.formFields[formFieldCount] = form.addSwitchField(
        neurondash.app.formLines[formLineCnt],
        nil,
        function()
            if neurondash.session.modelPreferences then
                if neurondash.preferences.model.idleswitch  then
                    local category, member, options = neurondash.preferences.model.idleswitch:match("([^:]+):([^:]+):([^:]+)")
                    if category and member then
                        return system.getSource({category = category, member = member, options = options})
                    end
                end    
            end
            return nil
        end,
        function(newValue)
            if neurondash.session.modelPreferences then
                local member = newValue:member()
                local category = newValue:category()
                local options = newValue:options()
                neurondash.preferences.model.idleswitch = category .. ":" .. member .. ":" .. options
            end
        end
    )
    neurondash.app.formFields[formFieldCount]:enable(false)

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
                local category, member = neurondash.preferences.model.rateswitch:match("([^:]+):([^:]+)")
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
                neurondash.preferences.model.rateswitch = category .. ":" .. member
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

                -- save model dashboard neurondash.preferences.model
                if neurondash.session.mcu_id and neurondash.session.modelPreferencesFile then
                    for key, value in pairs(neurondash.preferences.model) do
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
        title   = "@i18n(app.modules.profile_select.save_neurondash.preferences.model)@",
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

local runOnce = false
local function wakeup()
    if enableWakeup then



            if neurondash.session.isConnected then
                  if runOnce == false then
                    for i,v in ipairs(neurondash.app.formFields) do
                        neurondash.app.formFields[i]:enable(true)
                    end
                    neurondash.preferences.model = neurondash.session and neurondash.session.modelPreferences and neurondash.session.modelPreferences.battery
                    runOnce = true
                else
                    runOnce = false        
            end



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
