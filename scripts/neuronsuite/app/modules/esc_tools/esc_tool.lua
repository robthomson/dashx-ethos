local pages = {}

local mspSignature
local mspHeaderBytes
local mspBytes
local simulatorResponse
local escDetails = {}
local foundESC = false
local foundESCupdateTag = false
local showPowerCycleLoader = false
local showPowerCycleLoaderInProgress = false
local ESC
local powercycleLoader
local powercycleLoaderCounter = 0
local powercycleLoaderRateLimit = 2
local showPowerCycleLoaderFinished = false

local i18n = neuronsuite.i18n.get

local modelField
local versionField
local firmwareField

local findTimeoutClock = os.clock()
local findTimeout = math.floor(neuronsuite.tasks.msp.protocol.pageReqTimeout * 0.5)

local modelLine
local modelText
local modelTextPos = {x = 0, y = neuronsuite.app.radio.linePaddingTop, w = neuronsuite.app.lcdWidth, h = neuronsuite.app.radio.navbuttonHeight}

local function getESCDetails()

    if neuronsuite.session.escDetails ~= nil then
        escDetails = neuronsuite.session.escDetails
        foundESC = true 
        return
    end

    if foundESC == true then 
        return
    end

    local message = {
        command = 217, -- MSP_STATUS
        processReply = function(self, buf)

            local mspBytesCheck = 2 -- we query 2 only unless the flack to cache the init buffer is set
            if ESC and ESC.mspBufferCache == true then
                mspBytesCheck = mspBytes
            end
 
            --if #buf >= mspBytesCheck and buf[1] == mspSignature then
            if buf[1] == mspSignature then
                escDetails.model = ESC.getEscModel(buf)
                escDetails.version = ESC.getEscVersion(buf)
                escDetails.firmware = ESC.getEscFirmware(buf)

                neuronsuite.session.escDetails = escDetails

                if ESC.mspBufferCache == true then
                    neuronsuite.session.escBuffer = buf 
                end    

                if escDetails.model ~= nil  then
                    foundESC = true
                end

            end

        end,
        uuid = "123e4567-e89b-12d3-b456-426614174201",
        simulatorResponse = simulatorResponse
    }

    neuronsuite.tasks.msp.mspQueue:add(message)
end

local function openPage(pidx, title, script)

    neuronsuite.app.lastIdx = pidx
    neuronsuite.app.lastTitle = title
    neuronsuite.app.lastScript = script

    

    local folder = title

    ESC = assert(neuronsuite.compiler.loadfile("app/modules/esc_tools/mfg/" .. folder .. "/init.lua"))()

    if ESC.mspapi ~= nil then
        -- we are using the api so get values from that!
        local API = neuronsuite.tasks.msp.api.load(ESC.mspapi)
        mspSignature = API.mspSignature
        mspHeaderBytes = API.mspHeaderBytes
        simulatorResponse = API.simulatorResponse or {0}
        mspBytes = #simulatorResponse
    else
        --legacy method
        mspSignature = ESC.mspSignature
        mspHeaderBytes = ESC.mspHeaderBytes
        simulatorResponse = ESC.simulatorResponse
        mspBytes = ESC.mspBytes
    end    

    neuronsuite.app.formFields = {}
    neuronsuite.app.formLines = {}


    local windowWidth = neuronsuite.app.lcdWidth
    local windowHeight = neuronsuite.app.lcdHeight

    local y = neuronsuite.app.radio.linePaddingTop

    form.clear()

    line = form.addLine(i18n("app.modules.esc_tools.name") .. ' / ' .. ESC.toolName)

    buttonW = 100
    local x = windowWidth - buttonW

    neuronsuite.app.formNavigationFields['menu'] = form.addButton(line, {x = x - buttonW - 5, y = neuronsuite.app.radio.linePaddingTop, w = buttonW, h = neuronsuite.app.radio.navbuttonHeight}, {
        text = i18n("app.navigation_menu"),
        icon = nil,
        options = FONT_S,
        paint = function()
        end,
        press = function()
            neuronsuite.app.ui.openPage(pidx, i18n("app.modules.esc_tools.name"), "esc_tools/esc.lua")

        end
    })
    neuronsuite.app.formNavigationFields['menu']:focus()

    neuronsuite.app.formNavigationFields['refresh'] = form.addButton(line, {x = x, y = neuronsuite.app.radio.linePaddingTop, w = buttonW, h = neuronsuite.app.radio.navbuttonHeight}, {
        text = i18n("app.navigation_reload"),
        icon = nil,
        options = FONT_S,
        paint = function()
        end,
        press = function()
            neuronsuite.app.Page = nil
            local foundESC = false
            local foundESCupdateTag = false
            local showPowerCycleLoader = false
            local showPowerCycleLoaderInProgress = false
            neuronsuite.app.triggers.triggerReloadFull = true
        end
    })
    neuronsuite.app.formNavigationFields['menu']:focus()

    ESC.pages = assert(neuronsuite.compiler.loadfile("app/modules/esc_tools/mfg/" .. folder .. "/pages.lua"))()

    modelLine = form.addLine("")
    modelText = form.addStaticText(modelLine, modelTextPos, "")

    local buttonW
    local buttonH
    local padding
    local numPerRow

    if neuronsuite.preferences.general.iconsize == nil or neuronsuite.preferences.general.iconsize == "" then
        neuronsuite.preferences.general.iconsize = 1
    else
        neuronsuite.preferences.general.iconsize = tonumber(neuronsuite.preferences.general.iconsize)
    end

    -- TEXT ICONS
    if neuronsuite.preferences.general.iconsize == 0 then
        padding = neuronsuite.app.radio.buttonPaddingSmall
        buttonW = (neuronsuite.app.lcdWidth - padding) / neuronsuite.app.radio.buttonsPerRow - padding
        buttonH = neuronsuite.app.radio.navbuttonHeight
        numPerRow = neuronsuite.app.radio.buttonsPerRow
    end
    -- SMALL ICONS
    if neuronsuite.preferences.general.iconsize == 1 then

        padding = neuronsuite.app.radio.buttonPaddingSmall
        buttonW = neuronsuite.app.radio.buttonWidthSmall
        buttonH = neuronsuite.app.radio.buttonHeightSmall
        numPerRow = neuronsuite.app.radio.buttonsPerRowSmall
    end
    -- LARGE ICONS
    if neuronsuite.preferences.general.iconsize == 2 then

        padding = neuronsuite.app.radio.buttonPadding
        buttonW = neuronsuite.app.radio.buttonWidth
        buttonH = neuronsuite.app.radio.buttonHeight
        numPerRow = neuronsuite.app.radio.buttonsPerRow
    end

    local lc = 0
    local bx = 0

    if neuronsuite.app.gfx_buttons["esctool"] == nil then neuronsuite.app.gfx_buttons["esctool"] = {} end
    if neuronsuite.preferences.menulastselected["esctool"] == nil then neuronsuite.preferences.menulastselected["esctool"] = 1 end

    for pidx, pvalue in ipairs(ESC.pages) do 


        local section = pvalue
        local hideSection =
            (section.ethosversion and neuronsuite.session.ethosRunningVersion < section.ethosversion) or
            (section.mspversion   and neuronsuite.utils.apiVersionCompare("<", section.mspversion))
                            --or
                            --(section.developer and not neuronsuite.preferences.developer.devtools)

        if not pvalue.disablebutton or (pvalue and pvalue.disablebutton(mspBytes) == false) or not hideSection then

            if lc == 0 then
                if neuronsuite.preferences.general.iconsize == 0 then y = form.height() + neuronsuite.app.radio.buttonPaddingSmall end
                if neuronsuite.preferences.general.iconsize == 1 then y = form.height() + neuronsuite.app.radio.buttonPaddingSmall end
                if neuronsuite.preferences.general.iconsize == 2 then y = form.height() + neuronsuite.app.radio.buttonPadding end
            end

            if lc >= 0 then bx = (buttonW + padding) * lc end

            if neuronsuite.preferences.general.iconsize ~= 0 then
                if neuronsuite.app.gfx_buttons["esctool"][pvalue.image] == nil then neuronsuite.app.gfx_buttons["esctool"][pvalue.image] = lcd.loadMask("app/modules/esc_tools/mfg/" .. folder .. "/gfx/" .. pvalue.image) end
            else
                neuronsuite.app.gfx_buttons["esctool"][pvalue.image] = nil
            end

            neuronsuite.app.formFields[pidx] = form.addButton(nil, {x = bx, y = y, w = buttonW, h = buttonH}, {
                text = pvalue.title,
                icon = neuronsuite.app.gfx_buttons["esctool"][pvalue.image],
                options = FONT_S,
                paint = function()
                end,
                press = function()
                    neuronsuite.preferences.menulastselected["esctool"] = pidx
                    neuronsuite.app.ui.progressDisplay()

                    neuronsuite.app.ui.openPage(pidx, title, "esc_tools/mfg/" .. folder .. "/pages/" .. pvalue.script)

                end
            })

            if neuronsuite.preferences.menulastselected["esctool"] == pidx then neuronsuite.app.formFields[pidx]:focus() end

            if neuronsuite.app.triggers.escToolEnableButtons == true then
                neuronsuite.app.formFields[pidx]:enable(true)
            else
                neuronsuite.app.formFields[pidx]:enable(false)
            end

            lc = lc + 1

            if lc == numPerRow then lc = 0 end
        end

    end

    neuronsuite.app.triggers.escToolEnableButtons = false
    --getESCDetails()
    collectgarbage()
end

local function wakeup()

    if foundESC == false and neuronsuite.tasks.msp.mspQueue:isProcessed() then getESCDetails() end

    -- enable the form
    if foundESC == true and foundESCupdateTag == false then
        foundESCupdateTag = true

        if escDetails.model ~= nil and escDetails.model ~= nil and escDetails.firmware ~= nil then
            local text = escDetails.model .. " " .. escDetails.version .. " " .. escDetails.firmware
            neuronsuite.escHeaderLineText = text
            modelText = form.addStaticText(modelLine, modelTextPos, text)
        end

        for i, v in ipairs(neuronsuite.app.formFields) do neuronsuite.app.formFields[i]:enable(true) end

        if ESC and ESC.powerCycle == true and showPowerCycleLoader == true then
            powercycleLoader:close()
            powercycleLoaderCounter = 0
            showPowerCycleLoaderInProgress = false
            showPowerCycleLoader = false
            showPowerCycleLoaderFinished = true
            neuronsuite.app.triggers.isReady = true
        end

        neuronsuite.app.triggers.closeProgressLoader = true

    end

    if showPowerCycleLoaderFinished == false and foundESCupdateTag == false and showPowerCycleLoader == false and ((findTimeoutClock <= os.clock() - findTimeout) or neuronsuite.app.dialogs.progressCounter >= 101) then
        neuronsuite.app.dialogs.progress:close()
        neuronsuite.app.dialogs.progressDisplay = false
        neuronsuite.app.triggers.isReady = true

        if ESC and ESC.powerCycle ~= true then modelText = form.addStaticText(modelLine, modelTextPos, i18n("app.modules.esc_tools.unknown")) end

        if ESC and ESC.powerCycle == true then showPowerCycleLoader = true end

    end

    if showPowerCycleLoaderInProgress == true then

        local now = os.clock()
        if (now - powercycleLoaderRateLimit) >= 2 then

            getESCDetails()

            powercycleLoaderRateLimit = now
            powercycleLoaderCounter = powercycleLoaderCounter + 5
            powercycleLoader:value(powercycleLoaderCounter)

            if powercycleLoaderCounter >= 100 then
                powercycleLoader:close()
                modelText = form.addStaticText(modelLine, modelTextPos, i18n("app.modules.esc_tools.unknown"))
                showPowerCycleLoaderInProgress = false
                neuronsuite.app.triggers.disableRssiTimeout = false
                showPowerCycleLoader = false
                neuronsuite.app.audio.playTimeout = true
                showPowerCycleLoaderFinished = true
                neuronsuite.app.triggers.isReady = false
            end

        end

    end

    if showPowerCycleLoader == true then
        if showPowerCycleLoaderInProgress == false then
            showPowerCycleLoaderInProgress = true
            neuronsuite.app.audio.playEscPowerCycle = true
            neuronsuite.app.triggers.disableRssiTimeout = true
            powercycleLoader = form.openProgressDialog(i18n("app.modules.esc_tools.searching"), i18n("app.modules.esc_tools.please_powercycle"))
            powercycleLoader:value(0)
            powercycleLoader:closeAllowed(false)
        end
    end

end

local function event(widget, category, value, x, y)

    -- if close event detected go to section home page
    if category == EVT_CLOSE and value == 0 or value == 35 then
        if powercycleLoader then powercycleLoader:close() end
        neuronsuite.app.ui.openPage(pidx, i18n("app.modules.esc_tools.name"), "esc_tools/esc.lua")
        return true
    end


end

return {
    openPage = openPage,
    wakeup = wakeup,
    event = event,
    API = {}
}
