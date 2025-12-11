
-- sv_use_fix.lua - Fuerza la apertura del panel al pulsar E y permite el uso
-- Inclúyelo desde sh_plugin.lua con: ix.util.Include("sv_use_fix.lua")

if SERVER then
    util.AddNetworkString("ix_power_device_open")

    -- Permite PlayerUse sobre nuestra entidad y abre panel al instante
    hook.Add("PlayerUse", "ix_power_open_panel_on_use", function(ply, ent)
        if not IsValid(ply) or not IsValid(ent) then return end
        if ent:GetClass() ~= "ix_power_device" then return end
        -- Abre el panel para el jugador que usó la entidad
        net.Start("ix_power_device_open")
            net.WriteUInt(ent:EntIndex(), 16)
        net.Send(ply)
        -- Devuelve true para asegurar que el uso está permitido
        return true
    end)

    -- Mensaje de diagnóstico en consola cuando se crea la entidad
    hook.Add("OnEntityCreated", "ix_power_debug_created", function(ent)
        if ent:GetClass() == "ix_power_device" then
            print("[ix_generators] Creada entidad ix_power_device id="..ent:EntIndex())
        end
    end)
end
