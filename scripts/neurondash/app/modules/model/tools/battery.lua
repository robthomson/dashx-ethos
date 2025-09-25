local settings = {}
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


    -- Fuel sensor
    formFieldCount = formFieldCount + 1
    formLineCnt = formLineCnt + 1
    neurondash.app.formLines[formLineCnt] = form.addLine("@i18n(app.modules.model.calcfuel_using)@")
    neurondash.app.formFields[formFieldCount] = form.addChoiceField(
        neurondash.app.formLines[formLineCnt],
        nil,
        {{"@i18n(app.modules.model.calcfuel_current)@", 0}, {"@i18n(app.modules.model.calcfuel_voltage)@", 1}},
        function()
            if neurondash.session.modelPreferences then
                return neurondash.session.modelPreferences.battery.fuelSensor
            end
            return nil
        end,
        function(newValue)
            if neurondash.session.modelPreferences then
                neurondash.session.modelPreferences.battery.fuelSensor = newValue
            end
        end
    )
    neurondash.app.formFields[formFieldCount]:enable(false)

     -- Battery capacity
    formFieldCount = formFieldCount + 1
    formLineCnt = formLineCnt + 1
    neurondash.app.formLines[formLineCnt] = form.addLine("@i18n(app.modules.model.battery_capacity)@")
    neurondash.app.formFields[formFieldCount] = form.addNumberField(
        neurondash.app.formLines[formLineCnt],
        nil,
        0,
        10000000,
        function()
            if neurondash.session.modelPreferences and settings then
                return neurondash.session.modelPreferences.battery.batteryCapacity
            end
            return nil
        end,
        function(newValue)
            if neurondash.session.modelPreferences then
                neurondash.session.modelPreferences.battery.batteryCapacity = newValue
            end
        end
    )
    neurondash.app.formFields[formFieldCount]:suffix("mAh") 
    neurondash.app.formFields[formFieldCount]:default(2200)  
    neurondash.app.formFields[formFieldCount]:enable(false)

     -- Cell count
    formFieldCount = formFieldCount + 1
    formLineCnt = formLineCnt + 1
    neurondash.app.formLines[formLineCnt] = form.addLine("@i18n(app.modules.model.battery_cells)@")
    neurondash.app.formFields[formFieldCount] = form.addNumberField(
        neurondash.app.formLines[formLineCnt],
        nil,
        1,
        24,
        function()
            if neurondash.session.modelPreferences and neurondash.session.modelPreferences.battery then
                return neurondash.session.modelPreferences.battery.batteryCellCount
            end
            return nil
        end,
        function(newValue)
            if neurondash.session.modelPreferences then
                neurondash.session.modelPreferences.battery.batteryCellCount = newValue
            end
        end
    )
    --neurondash.app.formFields[formFieldCount]:suffix("mAh") 
    neurondash.app.formFields[formFieldCount]:default(3)  
    neurondash.app.formFields[formFieldCount]:enable(false)

     -- Warning cell voltage
    formFieldCount = formFieldCount + 1
    formLineCnt = formLineCnt + 1
    neurondash.app.formLines[formLineCnt] = form.addLine("@i18n(app.modules.model.battery_warning_voltage)@")
    neurondash.app.formFields[formFieldCount] = form.addNumberField(
        neurondash.app.formLines[formLineCnt],
        nil,
        5,
        600,
        function()
            if neurondash.session.modelPreferences and neurondash.session.modelPreferences.battery then
                return neurondash.session.modelPreferences.battery.vbatwarningcellvoltage
            end
            return nil
        end,
        function(newValue)
            if neurondash.session.modelPreferences then
                neurondash.session.modelPreferences.battery.vbatwarningcellvoltage = newValue
            end
        end
    )
    neurondash.app.formFields[formFieldCount]:suffix("v")
    neurondash.app.formFields[formFieldCount]:default(35)
    neurondash.app.formFields[formFieldCount]:decimals(1)
    neurondash.app.formFields[formFieldCount]:enable(false)

     -- Min cell voltage
    formFieldCount = formFieldCount + 1
    formLineCnt = formLineCnt + 1
    neurondash.app.formLines[formLineCnt] = form.addLine("@i18n(app.modules.model.battery_min_voltage)@")
    neurondash.app.formFields[formFieldCount] = form.addNumberField(
        neurondash.app.formLines[formLineCnt],
        nil,
        5,
        600,
        function()
            if neurondash.session.modelPreferences and neurondash.session.modelPreferences.battery then
                return neurondash.session.modelPreferences.battery.vbatmincellvoltage
            end
            return nil
        end,
        function(newValue)
            if neurondash.session.modelPreferences then
                neurondash.session.modelPreferences.battery.vbatmincellvoltage = newValue
            end
        end
    )
    neurondash.app.formFields[formFieldCount]:suffix("v")
    neurondash.app.formFields[formFieldCount]:default(33)
    neurondash.app.formFields[formFieldCount]:decimals(1)
    neurondash.app.formFields[formFieldCount]:enable(false)

     -- Min cell voltage
    formFieldCount = formFieldCount + 1
    formLineCnt = formLineCnt + 1
    neurondash.app.formLines[formLineCnt] = form.addLine("@i18n(app.modules.model.battery_max_voltage)@")
    neurondash.app.formFields[formFieldCount] = form.addNumberField(
        neurondash.app.formLines[formLineCnt],
        nil,
        5,
        600,
        function()
            if neurondash.session.modelPreferences and neurondash.session.modelPreferences.battery then
                return neurondash.session.modelPreferences.battery.vbatmaxcellvoltage
            end
            return nil
        end,
        function(newValue)
            if neurondash.session.modelPreferences then
                neurondash.session.modelPreferences.battery.vbatmaxcellvoltage = newValue
            end
        end
    )
    neurondash.app.formFields[formFieldCount]:suffix("v")
    neurondash.app.formFields[formFieldCount]:default(43)
    neurondash.app.formFields[formFieldCount]:decimals(1)
    neurondash.app.formFields[formFieldCount]:enable(false)

    -- Full cell voltage
    formFieldCount = formFieldCount + 1
    formLineCnt = formLineCnt + 1
    neurondash.app.formLines[formLineCnt] = form.addLine("@i18n(app.modules.model.battery_full_voltage)@")
    neurondash.app.formFields[formFieldCount] = form.addNumberField(
        neurondash.app.formLines[formLineCnt],
        nil,
        5,
        600,
        function()
            if neurondash.session.modelPreferences and neurondash.session.modelPreferences.battery then
                return neurondash.session.modelPreferences.battery.vbatfullcellvoltage
            end
            return nil
        end,
        function(newValue)
            if neurondash.session.modelPreferences then
                neurondash.session.modelPreferences.battery.vbatfullcellvoltage = newValue
            end
        end
    )
    neurondash.app.formFields[formFieldCount]:suffix("v")
    neurondash.app.formFields[formFieldCount]:default(41)
    neurondash.app.formFields[formFieldCount]:decimals(1)
    neurondash.app.formFields[formFieldCount]:enable(false)

    -- consumptionWarningPercentage
    formFieldCount = formFieldCount + 1
    formLineCnt = formLineCnt + 1
    neurondash.app.formLines[formLineCnt] = form.addLine("@i18n(app.modules.model.battery_consumption_warning_percentage)@")
    neurondash.app.formFields[formFieldCount] = form.addNumberField(
        neurondash.app.formLines[formLineCnt],
        nil,
        0,
        100,
        function()
            if neurondash.session.modelPreferences and neurondash.session.modelPreferences.battery then
                return neurondash.session.modelPreferences.battery.consumptionWarningPercentage
            end
            return nil
        end,
        function(newValue)
            if neurondash.session.modelPreferences then
                neurondash.session.modelPreferences.battery.consumptionWarningPercentage = newValue
            end
        end
    )
    neurondash.app.formFields[formFieldCount]:suffix("%")
    neurondash.app.formFields[formFieldCount]:default(30)
    neurondash.app.formFields[formFieldCount]:enable(false)


    enableWakeup = true
 
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
                if neurondash.session.mcu_id and neurondash.session.modelPreferencesFile then
                    for key, value in pairs(settings) do
                        neurondash.session.modelPreferences.battery[key] = value
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
            "model/model.lua"
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

                    if not neurondash.tasks.telemetry.getSensorSource("consumption")  then
                        neurondash.session.modelPreferences.battery.fuelSensor = 1
                        neurondash.app.formFields[1]:enable(false)
                    end


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
