
PLUGIN.name        = "ix_generators"
PLUGIN.author      = "M365 Copilot"
PLUGIN.description = "Energía con gauges superiores, repostaje, SWEP de conexión, persistencia y cables físicos (Helix)."

-- Orden de carga
ix.util.Include("sh_power.lua")
ix.util.Include("sh_power_wrap.lua")
ix.util.Include("sv_power.lua")
ix.util.Include("sv_device_tools.lua")
ix.util.Include("sv_refuel.lua")
ix.util.Include("cl_power.lua")
ix.util.Include("cl_analog_gauge.lua")
ix.util.Include("cl_device_panel.lua")

-- SWEP (registro programático)
ix.util.Include("sh_weapon_ix_linktool.lua")

-- Entidad base
ix.util.Include("entities/sh_ix_power_device.lua")

-- Dispositivos
ix.util.Include("devices/sh_solar.lua")
ix.util.Include("devices/sh_diesel.lua")
ix.util.Include("devices/sh_lamp.lua")

-- Items
if (SERVER) then
    ix.item.LoadFromDir(PLUGIN.folder .. "/items")
end
