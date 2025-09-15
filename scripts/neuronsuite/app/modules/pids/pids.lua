local activateWakeup = false
local i18n = neuronsuite.i18n.get
local apidata = {
    api = {
        [1] = 'PID_TUNING',
    },
    formdata = {
        labels = {
        },
        rows = {
            i18n("app.modules.pids.roll"),
            i18n("app.modules.pids.pitch"),
            i18n("app.modules.pids.yaw")
        },
        cols = {
            i18n("app.modules.pids.p"),
            i18n("app.modules.pids.i"),
            i18n("app.modules.pids.d"),
            i18n("app.modules.pids.f"),
            i18n("app.modules.pids.o"),
            i18n("app.modules.pids.b")
        },
        fields = {
            -- P
            {row = 1, col = 1, mspapi = 1, apikey = "pid_0_P"},
            {row = 2, col = 1, mspapi = 1, apikey = "pid_1_P"},
            {row = 3, col = 1, mspapi = 1, apikey = "pid_2_P"},
            {row = 1, col = 2, mspapi = 1, apikey = "pid_0_I"},
            {row = 2, col = 2, mspapi = 1, apikey = "pid_1_I"},
            {row = 3, col = 2, mspapi = 1, apikey = "pid_2_I"},
            {row = 1, col = 3, mspapi = 1, apikey = "pid_0_D"},
            {row = 2, col = 3, mspapi = 1, apikey = "pid_1_D"},
            {row = 3, col = 3, mspapi = 1, apikey = "pid_2_D"},
            {row = 1, col = 4, mspapi = 1, apikey = "pid_0_F"},
            {row = 2, col = 4, mspapi = 1, apikey = "pid_1_F"},
            {row = 3, col = 4, mspapi = 1, apikey = "pid_2_F"},
            {row = 1, col = 5, mspapi = 1, apikey = "pid_0_O"},
            {row = 2, col = 5, mspapi = 1, apikey = "pid_1_O"},
            {row = 1, col = 6, mspapi = 1, apikey = "pid_0_B"},
            {row = 2, col = 6, mspapi = 1, apikey = "pid_1_B"},
            {row = 3, col = 6, mspapi = 1, apikey = "pid_2_B"}
        }
    }                 
}


local function postLoad(self)
    neuronsuite.app.triggers.closeProgressLoader = true
    activateWakeup = true
end

local function openPage(idx, title, script)

    neuronsuite.app.uiState = neuronsuite.app.uiStatus.pages
    neuronsuite.app.triggers.isReady = false

    neuronsuite.app.Page = assert(neuronsuite.compiler.loadfile("app/modules/" .. script))()
    -- collectgarbage()

    neuronsuite.app.lastIdx = idx
    neuronsuite.app.lastTitle = title
    neuronsuite.app.lastScript = script
    neuronsuite.session.lastPage = script

    neuronsuite.app.uiState = neuronsuite.app.uiStatus.pages

    longPage = false

    form.clear()

    neuronsuite.app.ui.fieldHeader(title)
    local numCols
    if neuronsuite.app.Page.cols ~= nil then
        numCols = #neuronsuite.app.Page.cols
    else
        numCols = 6
    end
    local screenWidth = neuronsuite.app.lcdWidth - 10
    local padding = 10
    local paddingTop = neuronsuite.app.radio.linePaddingTop
    local h = neuronsuite.app.radio.navbuttonHeight
    local w = ((screenWidth * 70 / 100) / numCols)
    local paddingRight = 20
    local positions = {}
    local positions_r = {}
    local pos

    line = form.addLine("")

    local loc = numCols
    local posX = screenWidth - paddingRight
    local posY = paddingTop


    neuronsuite.utils.log("Merging form data from mspapi","debug")
    neuronsuite.app.Page.fields = neuronsuite.app.Page.apidata.formdata.fields
    neuronsuite.app.Page.labels = neuronsuite.app.Page.apidata.formdata.labels
    neuronsuite.app.Page.rows = neuronsuite.app.Page.apidata.formdata.rows
    neuronsuite.app.Page.cols = neuronsuite.app.Page.apidata.formdata.cols

    local c = 1
    while loc > 0 do
        local colLabel = neuronsuite.app.Page.cols[loc]
        pos = {x = posX, y = posY, w = w, h = h}
        form.addStaticText(line, pos, colLabel)
        positions[loc] = posX - w + paddingRight
        positions_r[c] = posX - w + paddingRight
        posX = math.floor(posX - w)
        loc = loc - 1
        c = c + 1
    end

    -- display each row
    local pidRows = {}
    for ri, rv in ipairs(neuronsuite.app.Page.rows) do pidRows[ri] = form.addLine(rv) end

    for i = 1, #neuronsuite.app.Page.fields do
        local f = neuronsuite.app.Page.fields[i]
        local l = neuronsuite.app.Page.labels
        local pageIdx = i
        local currentField = i

        posX = positions[f.col]

        pos = {x = posX + padding, y = posY, w = w - padding, h = h}

        neuronsuite.app.formFields[i] = form.addNumberField(pidRows[f.row], pos, 0, 0, function()
            if neuronsuite.app.Page.fields == nil or neuronsuite.app.Page.fields[i] == nil then
                ui.disableAllFields()
                ui.disableAllNavigationFields()
                ui.enableNavigationField('menu')
                return nil
            end
            return neuronsuite.app.utils.getFieldValue(neuronsuite.app.Page.fields[i])
        end, function(value)
            if f.postEdit then f.postEdit(neuronsuite.app.Page) end
            if f.onChange then f.onChange(neuronsuite.app.Page) end
    
            f.value = neuronsuite.app.utils.saveFieldValue(neuronsuite.app.Page.fields[i], value)
        end)
    end
    
end

local function wakeup()

    if activateWakeup == true and neuronsuite.tasks.msp.mspQueue:isProcessed() then

        -- update active profile
        -- the check happens in postLoad          
        if neuronsuite.session.activeProfile ~= nil then
            neuronsuite.app.formFields['title']:value(neuronsuite.app.Page.title .. " #" .. neuronsuite.session.activeProfile)
        end

    end

end

return {
    apidata = apidata,
    title = i18n("app.modules.pids.name"),
    reboot = false,
    eepromWrite = true,
    refreshOnProfileChange = true,
    postLoad = postLoad,
    openPage = openPage,
    wakeup = wakeup,
    API = {},
}
