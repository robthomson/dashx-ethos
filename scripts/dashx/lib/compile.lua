--[[
 * dashx - Deferred/Throttled Lua Script Compilation and Caching
 * ENV-aware, keyed by config.baseDir to allow coexistence with other suites.
 * License GPLv3: https://www.gnu.org/licenses/gpl-3.0.en.html
]]

local compile = {}
local arg = {...}
local config = arg[1] or {}
-- Use the suite key passed from main.lua (dashx.config.baseDir = "dashx")
local SUITE = (config and config.baseDir) or "dashx"

-- Environment captured from loader (includes `dashx` from main.lua)
local ENV = _ENV or _G

-- Always run loaded chunks under ENV (Lua 5.1 fallback uses setfenv)
local function loadfile_in_env(path)
  if setfenv and _VERSION == "Lua 5.1" then
    local chunk, err = loadfile(path)
    if not chunk then return nil, err end
    setfenv(chunk, ENV)
    return chunk
  else
    -- nil mode = accept text/bytecode; third arg = env (ETHOS-friendly)
    return loadfile(path, nil, ENV)
  end
end

compile._startTime = os.clock()
compile._startupDelay = 15 -- seconds before starting any compiles

-- Optional timing flag (if present in preferences)
local logTimings = true
if dashx and dashx.config then
  if type(dashx.preferences.developer.compilerTiming) == "boolean" then
    logTimings = dashx.preferences.developer.compilerTiming or false
  end
end

-- Suite-specific compiled directory to avoid cross-suite clashes
local compiledDir = "cache/" .. SUITE .. "/"
local SCRIPT_PREFIX = "SCRIPTS:"

-- Ensure cache directories exist
os.mkdir("cache")
os.mkdir(compiledDir)

-- Index compiled files
local disk_cache = {}
do
  local list = system.listFiles and system.listFiles(compiledDir) or {}
  for _, fname in ipairs(list) do
    disk_cache[fname] = true
  end
end

-- Unique, cache-safe compiled filename (prefix with suite)
local function cachename(name)
  if name:sub(1, #SCRIPT_PREFIX) == SCRIPT_PREFIX then
    name = name:sub(#SCRIPT_PREFIX + 1)
  end
  name = name:gsub("/", "_")
  name = name:gsub("^_", "", 1)
  return SUITE .. "__" .. name
end

--------------------------------------------------
-- Adaptive LRU Cache (in-memory loaders, interval-based eviction)
--------------------------------------------------
local LUA_RAM_THRESHOLD = 32 * 1024 -- 32 KB free (bytes)
local LRU_HARD_LIMIT    = 50        -- absolute maximum (safety)
local EVICT_INTERVAL    = 5         -- seconds between eviction checks

local function LRUCache()
  local self = { cache = {}, order = {}, _last_evict = 0 }

  function self:get(key)
    local value = self.cache[key]
    if value then
      for i, k in ipairs(self.order) do
        if k == key then
          table.remove(self.order, i)
          break
        end
      end
      table.insert(self.order, key)
    end
    return value
  end

  function self:evict_if_low_memory()
    self._last_evict = os.clock()
    local usage = system.getMemoryUsage and system.getMemoryUsage()
    while #self.order > 0 do
      if usage and usage.luaRamAvailable and usage.luaRamAvailable < LUA_RAM_THRESHOLD then
        local oldest = table.remove(self.order, 1)
        self.cache[oldest] = nil
        usage = system.getMemoryUsage()
      elseif #self.order > LRU_HARD_LIMIT then
        local oldest = table.remove(self.order, 1)
        self.cache[oldest] = nil
      else
        break
      end
    end
  end

  function self:set(key, value)
    if not self.cache[key] then
      table.insert(self.order, key)
    else
      for i, k in ipairs(self.order) do
        if k == key then
          table.remove(self.order, i)
          break
        end
      end
      table.insert(self.order, key)
    end
    self.cache[key] = value

    local now = os.clock()
    if now - self._last_evict > EVICT_INTERVAL then
      self:evict_if_low_memory()
    end
  end

  return self
end

local lru_cache = LRUCache()

--------------------------------------------------
-- Throttled Compile Queue System
--------------------------------------------------
compile._queue = {}
compile._queued_map = {}

function compile._enqueue(script, cache_path, cache_fname)
  if not compile._queued_map[cache_fname] then
    table.insert(compile._queue, { script = script, cache_path = cache_path, cache_fname = cache_fname })
    compile._queued_map[cache_fname] = true
  end
end

function compile.wakeup()
  local now = os.clock()
  if (now - compile._startTime) < compile._startupDelay then return end
  if #compile._queue == 0 then return end

  local entry = table.remove(compile._queue, 1)
  compile._queued_map[entry.cache_fname] = nil

  local ok, err = pcall(function()
    system.compile(entry.script)
    os.rename(entry.script .. "c", entry.cache_path)
    disk_cache[entry.cache_fname] = true
  end)

  if dashx and dashx.utils then
    if ok then
      dashx.utils.log("Deferred-compiled (throttled): " .. entry.script, "info")
    else
      dashx.utils.log("Deferred-compile error: " .. tostring(err), "debug")
    end
  end
end

-- ENV-aware loadfile with compiled fallback
function compile.loadfile(script)
  local startTime
  if logTimings then startTime = os.clock() end

  local cache_fname = cachename(script) .. "c"
  local cache_key   = cache_fname

  local loader = lru_cache:get(cache_key)
  local which

  if not loader then
    if not dashx.preferences.developer.compile then
      loader, which = loadfile_in_env(script), "raw"
    else
      local cache_path = compiledDir .. cache_fname
      if disk_cache[cache_fname] then
        loader, which = loadfile_in_env(cache_path), "compiled"
      else
        compile._enqueue(script, cache_path, cache_fname)
        loader, which = loadfile_in_env(script), "raw (queued for deferred compile)"
      end
    end

    if loader then
      lru_cache:set(cache_key, loader)
    end
  else
    which = "in-memory"
  end

  if not loader then
    return nil, ("Failed to load script '%s' (%s)"):format(script, which or "unknown")
  end

  return loader
end

function compile.dofile(script, ...)
  local chunk = compile.loadfile(script)
  return chunk(...)
end

function compile.require(modname)
  -- Suite-scoped module cache to avoid clashes across suites
  local key = SUITE .. ":" .. modname
  if package.loaded[key] then
    return package.loaded[key]
  end

  local raw_path = modname:gsub("%%.", "/") .. ".lua"
  local chunk

  if not dashx.preferences.developer.compile then
    chunk = assert(loadfile_in_env(raw_path))
  else
    chunk = compile.loadfile(raw_path)
  end

  local result = chunk()
  package.loaded[key] = (result == nil) and true or result
  return package.loaded[key]
end

return compile
