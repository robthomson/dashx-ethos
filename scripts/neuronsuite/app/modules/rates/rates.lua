local labels = {}
local tables = {}

local activateWakeup = false
local i18n = neuronsuite.i18n.get

tables[0] = "app/modules/rates/ratetables/none.lua"
tables[1] = "app/modules/rates/ratetables/betaflight.lua"
tables[2] = "app/modules/rates/ratetables/raceflight.lua"
tables[3] = "app/modules/rates/ratetables/kiss.lua"
tables[4] = "app/modules/rates/ratetables/actual.lua"
tables[5] = "app/modules/rates/ratetables/quick.lua"

if neuronsuite.session.activeRateTable == nil then 
    neuronsuite.session.activeRateTable = neuronsuite.config.defaultRateProfile 
end


neuronsuite.utils.log("Loading Rate Table: " .. tables[neuronsuite.session.activeRateTable],"debug")
local apidata = assert(neuronsuite.compiler.loadfile(tables[neuronsuite.session.activeRateTable]))()
local mytable = apidata.formdata



local function postLoad(self)

    local v = apidata.values[apidata.api[1]].rates_type
    
    neuronsuite.utils.log("Active Rate Table: " .. neuronsuite.session.activeRateTable,"debug")

    if v ~= neuronsuite.session.activeRateTable then
        neuronsuite.utils.log("Switching Rate Table: " .. v,"info")
        neuronsuite.app.triggers.reloadFull = true
        neuronsuite.session.activeRateTable = v           
        return
    end 

    neuronsuite.app.triggers.closeProgressLoader = true
    activateWakeup = true

end

function rightAlignText(width, text)
    local textWidth, _ = lcd.getTextSize(text)  -- Get the text width
    local padding = width - textWidth  -- Calculate how much padding is needed
    
    if padding > 0 then
        return string.rep(" ", math.floor(padding / lcd.getTextSize(" "))) .. text
    else
        return text  -- No padding needed if text is already wider than width
    end
end

local function openPage(idx, title, script)

    neuronsuite.app.Page = assert(neuronsuite.compiler.loadfile("app/modules/" .. script))()

    neuronsuite.app.lastIdx = idx
    neuronsuite.app.lastTitle = title
    neuronsuite.app.lastScript = script
    neuronsuite.session.lastPage = script

    neuronsuite.app.uiState = neuronsuite.app.uiStatus.pages

    longPage = false

    form.clear()

    neuronsuite.app.ui.fieldHeader(title)

    neuronsuite.utils.log("Merging form data from apidata","debug")
    neuronsuite.app.Page.fields = neuronsuite.app.Page.apidata.formdata.fields
    neuronsuite.app.Page.labels = neuronsuite.app.Page.apidata.formdata.labels
    neuronsuite.app.Page.rows = neuronsuite.app.Page.apidata.formdata.rows
    neuronsuite.app.Page.cols = neuronsuite.app.Page.apidata.formdata.cols

    local numCols
    if neuronsuite.app.Page.cols ~= nil then
        numCols = #neuronsuite.app.Page.cols
    else
        numCols = 3
    end

    -- we dont use the global due to scrollers
    local screenWidth, screenHeight = lcd.getWindowSize()

    local padding = 10
    local paddingTop = neuronsuite.app.radio.linePaddingTop
    local h = neuronsuite.app.radio.navbuttonHeight
    local w = ((screenWidth * 70 / 100) / numCols)
    local paddingRight = 10
    local positions = {}
    local positions_r = {}
    local pos

    --line = form.addLine(apidata.formdata.name)
    line = form.addLine("")
    pos = {x = 0, y = paddingTop, w = 200, h = h}
    neuronsuite.app.formFields['col_0'] = form.addStaticText(line, pos, apidata.formdata.name)

    local loc = numCols
    local posX = screenWidth - paddingRight
    local posY = paddingTop

    neuronsuite.session.colWidth = w - paddingRight

    local c = 1
    while loc > 0 do
        local colLabel = neuronsuite.app.Page.cols[loc]

        positions[loc] = posX - w
        positions_r[c] = posX - w

        lcd.font(FONT_M)
        --local tsizeW, tsizeH = lcd.getTextSize(colLabel)
        colLabel = rightAlignText(neuronsuite.session.colWidth, colLabel)

        local posTxt = positions_r[c] + paddingRight 

        pos = {x = posTxt, y = posY, w = w, h = h}
        neuronsuite.app.formFields['col_'..tostring(c)] = form.addStaticText(line, pos, colLabel)

        posX = math.floor(posX - w)

        loc = loc - 1
        c = c + 1
    end

    -- display each row
    local rateRows = {}
    for ri, rv in ipairs(neuronsuite.app.Page.rows) do rateRows[ri] = form.addLine(rv) end

    for i = 1, #neuronsuite.app.Page.fields do
        local f = neuronsuite.app.Page.fields[i]
        local l = neuronsuite.app.Page.labels
        local pageIdx = i
        local currentField = i

        if f.hidden == nil or f.hidden == false then
            posX = positions[f.col]

            pos = {x = posX + padding, y = posY, w = w - padding, h = h}

            minValue = f.min * neuronsuite.app.utils.decimalInc(f.decimals)
            maxValue = f.max * neuronsuite.app.utils.decimalInc(f.decimals)
            if f.mult ~= nil then
                minValue = minValue * f.mult
                maxValue = maxValue * f.mult
            end
            if f.scale ~= nil then
                minValue = minValue / f.scale
                maxValue = maxValue / f.scale
            end            

            neuronsuite.app.formFields[i] = form.addNumberField(rateRows[f.row], pos, minValue, maxValue, function()
                local value
                if neuronsuite.session.activeRateProfile == 0 then
                    value = 0
                else
                    value = neuronsuite.app.utils.getFieldValue(neuronsuite.app.Page.fields[i])
                end
                return value
            end, function(value)
                f.value = neuronsuite.app.utils.saveFieldValue(neuronsuite.app.Page.fields[i], value)
            end)
            if f.default ~= nil then
                local default = f.default * neuronsuite.app.utils.decimalInc(f.decimals)
                if f.mult ~= nil then default = math.floor(default * f.mult) end
                if f.scale ~= nil then default = math.floor(default / f.scale) end
                neuronsuite.app.formFields[i]:default(default)
            else
                neuronsuite.app.formFields[i]:default(0)
            end           
            if f.decimals ~= nil then neuronsuite.app.formFields[i]:decimals(f.decimals) end
            if f.unit ~= nil then neuronsuite.app.formFields[i]:suffix(f.unit) end
            if f.step ~= nil then neuronsuite.app.formFields[i]:step(f.step) end
            if f.help ~= nil then
                if neuronsuite.app.fieldHelpTxt[f.help]['t'] ~= nil then
                    local helpTxt = neuronsuite.app.fieldHelpTxt[f.help]['t']
                    neuronsuite.app.formFields[i]:help(helpTxt)
                end
            end   
            if f.disable == true then 
                neuronsuite.app.formFields[i]:enable(false) 
            end  
        end
    end

end

local function wakeup()

    if activateWakeup == true and neuronsuite.tasks.msp.mspQueue:isProcessed() then       
        if neuronsuite.session.activeRateProfile ~= nil then
            if neuronsuite.app.formFields['title'] then
                neuronsuite.app.formFields['title']:value(neuronsuite.app.Page.title .. " #" .. neuronsuite.session.activeRateProfile)
            end
        end 
    end
end

local function onHelpMenu()

    local helpPath = "app/modules/rates/help.lua"
    local help = assert(neuronsuite.compiler.loadfile(helpPath))()

    neuronsuite.app.ui.openPageHelp(help.help["table"][neuronsuite.session.activeRateTable], "rates")


end    

return {
    apidata = apidata,
    title = i18n("app.modules.rates.name"),
    reboot = false,
    eepromWrite = true,
    refreshOnRateChange = true,
    rows = mytable.rows,
    cols = mytable.cols,
    flagRateChange = flagRateChange,
    postLoad = postLoad,
    openPage = openPage,
    wakeup = wakeup,
    onHelpMenu = onHelpMenu,
    API = {},
}
