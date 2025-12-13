
-- sh_ix_power_devices_loader.lua (en raíz del plugin)
if SERVER then AddCSLuaFile() end

-- Evitar re-entrada del loader
if ix and ix.power and ix.power.__devicesLoaded then
  return
end

-- Si ix.power no existe aún, créalo (o usa tu módulo actual)
ix.power = ix.power or {}
ix.power.__devicesLoaded = true

local devicesDir = PLUGIN and (PLUGIN.folder .. "/devices") or "plugins/ix_generators/devices"

local function log(msg)
  print("[ix.power] " .. msg)
end

local function TryInclude(path)
  if SERVER then AddCSLuaFile(path) end
  include(path)
  log("Device cargado: " .. path)
end

-- Preferir IncludeDir sin recursividad (no hace falta bajar subcarpetas)
if ix and ix.util and ix.util.IncludeDir then
  -- recursive = false para evitar sorpresas
  ix.util.IncludeDir(devicesDir, true, false)
  log("IncludeDir OK -> " .. devicesDir)
else
  -- Fallback: cargar todos los sh_*.lua del directorio devices
  local glob = devicesDir .. "/sh_*.lua"
  local files = file.Find(glob, "LUA")

  if not files or #files == 0 then
    log("No se encontraron archivos 'sh_*.lua' en: " .. devicesDir)
  else
    for _, fname in ipairs(files) do
      local path = devicesDir .. "/" .. fname
      -- Por si en un futuro vuelves a poner el loader en devices,
      -- ignoramos cualquier archivo con "loader" en el nombre
      if not string.find(string.lower(fname), "loader") then
        local ok, err = pcall(TryInclude, path)
        if not ok then
          log("No se pudo cargar " .. path .. ": " .. tostring(err))
        end
      end
    end
  end
end
