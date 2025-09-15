--[[
 * Copyright (C) Rotorflight Project
 *
 *
 * License GPLv3: https://www.gnu.org/licenses/gpl-3.0.en.html
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 
 * Note.  Some icons have been sourced from https://www.flaticon.com/
 * 

]] --
-- Short aliases
local i18n = neuronsuite.i18n.get

-- State
local enableWakeup = false
local lastWakeup   = 0 -- seconds

-- Layout
local w, h   = lcd.getWindowSize()
local btnW   = 100
local btnWs  = btnW - (btnW * 20) / 100
local xRight = w - 15

local displayPos = {
  x = xRight - btnW - btnWs - 5 - btnWs,
  y = neuronsuite.app.radio.linePaddingTop,
  w = 100,
  h = neuronsuite.app.radio.navbuttonHeight
}

-- Indices into neuronsuite.app.formFields (intentionally 0-based)
local IDX_CPULOAD     = 0
local IDX_FREERAM     = 1
local IDX_BG_TASK     = 2
local IDX_RF_MODULE   = 3
local IDX_MSP         = 4
local IDX_TELEM       = 5
local IDX_FBLCONNECTED= 6
local IDX_APIVERSION  = 7

-- Helpers
local function setStatus(field, ok, dashIfNil)
  if not field then return end
  if dashIfNil and ok == nil then
    field:value("-")
    return
  end
  if ok then
    field:value(i18n("app.modules.rfstatus.ok"))
    field:color(GREEN)
  else
    field:value(i18n("app.modules.rfstatus.error"))
    field:color(RED)
  end
end

local function addStatusLine(captionKey, initialText)
  neuronsuite.app.formLines[neuronsuite.app.formLineCnt] = form.addLine(i18n(captionKey))
  neuronsuite.app.formFields[neuronsuite.app.formFieldCount] = form.addStaticText(
    neuronsuite.app.formLines[neuronsuite.app.formLineCnt],
    displayPos,
    initialText
  )
  neuronsuite.app.formLineCnt     = neuronsuite.app.formLineCnt + 1
  neuronsuite.app.formFieldCount  = neuronsuite.app.formFieldCount + 1
end

local function moduleEnabled()
  local m0 = model.getModule(0)
  local m1 = model.getModule(1)
  return (m0 and m0:enable()) or (m1 and m1:enable()) or false
end

local function haveMspSensor()
  local sportSensor = system.getSource({ appId = 0xF101 })
  local elrsSensor  = system.getSource({ crsfId = 0x14, subIdStart = 0, subIdEnd = 1 })
  return sportSensor or elrsSensor
end

-- Page open
local function openPage(pidx, title, script)
  enableWakeup = false
  neuronsuite.app.triggers.closeProgressLoader = true
  form.clear()

  -- track page
  neuronsuite.app.lastIdx    = pidx
  neuronsuite.app.lastTitle  = title
  neuronsuite.app.lastScript = script

  -- header
  neuronsuite.app.ui.fieldHeader(
    i18n("app.modules.diagnostics.name") .. " / " .. i18n("app.modules.rfstatus.name")
  )

  -- fresh tables so lookups are never stale/nil
  neuronsuite.app.formLineCnt    = 0
  neuronsuite.app.formFields     = {}
  neuronsuite.app.formLines      = {}
  neuronsuite.app.formFieldCount = 0

  -- CPU Load %
  addStatusLine("CPU Load", string.format("%.1f%%", neuronsuite.session.cpuload or 0))

  -- Free RAM
  addStatusLine("Free RAM", string.format("%.1f kB", neuronsuite.session.freeram or 0))


  -- Background Task status
  addStatusLine(
    "app.modules.rfstatus.bgtask",
    neuronsuite.tasks.active() and i18n("app.modules.rfstatus.ok") or i18n("app.modules.rfstatus.error")
  )

  -- RF Module Status
  addStatusLine(
    "app.modules.rfstatus.rfmodule",
    moduleEnabled() and i18n("app.modules.rfstatus.ok") or i18n("app.modules.rfstatus.error")
  )

  -- MSP Sensor Status
  addStatusLine(
    "app.modules.rfstatus.mspsensor",
    haveMspSensor() and i18n("app.modules.rfstatus.ok") or i18n("app.modules.rfstatus.error")
  )

  -- Telemetry Sensor Status
  addStatusLine("app.modules.rfstatus.telemetrysensors", "-")

  -- FBL Connected
  addStatusLine("app.modules.rfstatus.fblconnected", "-")

  -- API Version
  addStatusLine("app.modules.rfstatus.apiversion", "-")

  enableWakeup = true
end

-- Lifecycle hooks
local function postLoad(self) neuronsuite.utils.log("postLoad", "debug") end
local function postRead(self) neuronsuite.utils.log("postRead", "debug") end

-- Periodic refresh
local function wakeup()
  if not enableWakeup then return end

  local now = os.clock()
  if (now - lastWakeup) < 2 then return end
  lastWakeup = now

  -- CPU Load
  do
    local field = neuronsuite.app.formFields and neuronsuite.app.formFields[IDX_CPULOAD]
    if field then
      field:value(string.format("%.1f%%", neuronsuite.session.cpuload or 0))
    end
  end

  -- Free RAM
  do
    local field = neuronsuite.app.formFields and neuronsuite.app.formFields[IDX_FREERAM]
    if field then
      field:value(string.format("%.1f kB", neuronsuite.utils.round(neuronsuite.session.freeram or 0, 1)))
    end
  end

  -- Background Task
  do
    local field = neuronsuite.app.formFields and neuronsuite.app.formFields[IDX_BG_TASK]
    local ok    = neuronsuite.tasks and neuronsuite.tasks.active()
    setStatus(field, ok)
  end

  -- RF Module
  do
    local field = neuronsuite.app.formFields and neuronsuite.app.formFields[IDX_RF_MODULE]
    setStatus(field, moduleEnabled())
  end

  -- MSP Sensor
  do
    local field = neuronsuite.app.formFields and neuronsuite.app.formFields[IDX_MSP]
    setStatus(field, haveMspSensor())
  end

  -- Telemetry Sensors
  do
    local field = neuronsuite.app.formFields and neuronsuite.app.formFields[IDX_TELEM]
    if field then
      local sensors = neuronsuite.tasks
                    and neuronsuite.tasks.telemetry
                    and neuronsuite.tasks.telemetry.validateSensors(false)
                    or false
      if type(sensors) == "table" then
        -- empty list means OK
        setStatus(field, #sensors == 0)
      else
        -- unknown status
        setStatus(field, nil, true) -- dash
      end
    end
  end

  -- FBL Connected
  do
    local field = neuronsuite.app.formFields and neuronsuite.app.formFields[IDX_FBLCONNECTED]
    if field then
      local isConnected = neuronsuite.session and neuronsuite.session.isConnected 
      if isConnected then
        setStatus(field, isConnected)
      else
        setStatus(field, nil, true) -- dash 
      end
    end
  end

  -- API Version
  do
    local field = neuronsuite.app.formFields and neuronsuite.app.formFields[IDX_APIVERSION]
    if field then
      local isInvalid = not neuronsuite.session.apiVersionInvalid 
      setStatus(field, isInvalid)
    end
  end

end

-- Events
local function event(widget, category, value, x, y)
  -- if close event detected go to section home page
  if (category == EVT_CLOSE and value == 0) or value == 35 then
    neuronsuite.app.ui.openPage(
      pageIdx,
      i18n("app.modules.diagnostics.name"),
      "diagnostics/diagnostics.lua"
    )
    return true
  end
end

-- Nav menu
local function onNavMenu()
  neuronsuite.app.ui.progressDisplay(nil, nil, true)
  neuronsuite.app.ui.openPage(
    pageIdx,
    i18n("app.modules.diagnostics.name"),
    "diagnostics/diagnostics.lua"
  )
end

return {
  reboot           = false,
  eepromWrite      = false,
  minBytes         = 0,
  wakeup           = wakeup,
  refreshswitch    = false,
  simulatorResponse= {},
  postLoad         = postLoad,
  postRead         = postRead,
  openPage         = openPage,
  onNavMenu        = onNavMenu,
  event            = event,
  navButtons = {
    menu   = true,
    save   = false,
    reload = false,
    tool   = false,
    help   = false,
  },
  API = {},
}
