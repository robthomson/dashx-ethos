local i18n = neuronsuite.i18n.get

local function findMFG()
    local mfgsList = {}

    local mfgdir = "app/modules/esc_tools/mfg/"
    local mfgs_path = mfgdir 

    for _, v in pairs(system.listFiles(mfgs_path)) do

        local init_path = mfgs_path .. v .. '/init.lua'

        local f = os.stat(init_path)
        if f then

            local func, err = neuronsuite.compiler.loadfile(init_path)

            if func then
                local mconfig = func()
                if type(mconfig) ~= "table" or not mconfig.toolName then
                    neuronsuite.utils.log("Invalid configuration in " .. init_path)
                else
                    mconfig['folder'] = v
                    table.insert(mfgsList, mconfig)
                end
            end
        end
    end

    return mfgsList
end

local function openPage(pidx, title, script)


    neuronsuite.tasks.msp.protocol.mspIntervalOveride = nil
    neuronsuite.session.escDetails = nil

    neuronsuite.app.triggers.isReady = false
    neuronsuite.app.uiState = neuronsuite.app.uiStatus.mainMenu

    form.clear()

    neuronsuite.app.lastIdx = idx
    neuronsuite.app.lastTitle = title
    neuronsuite.app.lastScript = script

    ESC = {}

    -- size of buttons
    if neuronsuite.preferences.general.iconsize == nil or neuronsuite.preferences.general.iconsize == "" then
        neuronsuite.preferences.general.iconsize = 1
    else
        neuronsuite.preferences.general.iconsize = tonumber(neuronsuite.preferences.general.iconsize)
    end

    local w, h = lcd.getWindowSize()
    local windowWidth = w
    local windowHeight = h
    local padding = neuronsuite.app.radio.buttonPadding

    local sc
    local panel

    form.addLine(title)

    buttonW = 100
    local x = windowWidth - buttonW - 10

    neuronsuite.app.formNavigationFields['menu'] = form.addButton(line, {x = x, y = neuronsuite.app.radio.linePaddingTop, w = buttonW, h = neuronsuite.app.radio.navbuttonHeight}, {
        text = i18n("app.navigation_menu"),
        icon = nil,
        options = FONT_S,
        paint = function()
        end,
        press = function()
            neuronsuite.app.lastIdx = nil
            neuronsuite.session.lastPage = nil

            if neuronsuite.app.Page and neuronsuite.app.Page.onNavMenu then neuronsuite.app.Page.onNavMenu(neuronsuite.app.Page) end

            if  neuronsuite.app.lastMenu == nil then
                neuronsuite.app.ui.openMainMenu()
            else
                neuronsuite.app.ui.openMainMenuSub(neuronsuite.app.lastMenu)
            end
        end
    })
    neuronsuite.app.formNavigationFields['menu']:focus()

    local buttonW
    local buttonH
    local padding
    local numPerRow

    -- TEXT ICONS
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


    if neuronsuite.app.gfx_buttons["escmain"] == nil then neuronsuite.app.gfx_buttons["escmain"] = {} end
    if neuronsuite.preferences.menulastselected["escmain"] == nil then neuronsuite.preferences.menulastselected["escmain"] = 1 end


    local ESCMenu = assert(neuronsuite.compiler.loadfile("app/modules/" .. script))()
    local pages = findMFG()
    local lc = 0
    local bx = 0



    for pidx, pvalue in ipairs(pages) do

        if lc == 0 then
            if neuronsuite.preferences.general.iconsize == 0 then y = form.height() + neuronsuite.app.radio.buttonPaddingSmall end
            if neuronsuite.preferences.general.iconsize == 1 then y = form.height() + neuronsuite.app.radio.buttonPaddingSmall end
            if neuronsuite.preferences.general.iconsize == 2 then y = form.height() + neuronsuite.app.radio.buttonPadding end
        end

        if lc >= 0 then bx = (buttonW + padding) * lc end

        if neuronsuite.preferences.general.iconsize ~= 0 then
            if neuronsuite.app.gfx_buttons["escmain"][pidx] == nil then neuronsuite.app.gfx_buttons["escmain"][pidx] = lcd.loadMask("app/modules/esc_tools/mfg/" .. pvalue.folder .. "/" .. pvalue.image) end
        else
            neuronsuite.app.gfx_buttons["escmain"][pidx] = nil
        end

        neuronsuite.app.formFields[pidx] = form.addButton(line, {x = bx, y = y, w = buttonW, h = buttonH}, {
            text = pvalue.toolName,
            icon = neuronsuite.app.gfx_buttons["escmain"][pidx],
            options = FONT_S,
            paint = function()
            end,
            press = function()
                neuronsuite.preferences.menulastselected["escmain"] = pidx
                neuronsuite.app.ui.progressDisplay()
                neuronsuite.app.ui.openPage(pidx, pvalue.folder, "esc_tools/esc_tool.lua")
            end
        })

        if pvalue.disabled == true then neuronsuite.app.formFields[pidx]:enable(false) end

        if neuronsuite.preferences.menulastselected["escmain"] == pidx then neuronsuite.app.formFields[pidx]:focus() end

        lc = lc + 1

        if lc == numPerRow then lc = 0 end

    end

    neuronsuite.app.triggers.closeProgressLoader = true
    collectgarbage()
    return
end

neuronsuite.app.uiState = neuronsuite.app.uiStatus.pages

return {
    pages = pages, 
    openPage = openPage,
    API = {},
}
