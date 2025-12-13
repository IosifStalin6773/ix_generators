if SERVER then
    util.AddNetworkString("ix_power_device_open")

    
    hook.Add("PlayerUse", "ix_power_open_panel_on_use", function(ply, ent)
        if not IsValid(ply) or not IsValid(ent) then return end
        if ent:GetClass() ~= "ix_power_device" then return end
        
        net.Start("ix_power_device_open")
            net.WriteUInt(ent:EntIndex(), 16)
        net.Send(ply)
        
        return true
    end)

    
    hook.Add("OnEntityCreated", "ix_power_debug_created", function(ent)
        if ent:GetClass() == "ix_power_device" then
            print("[ix_generators] Creada entidad ix_power_device id="..ent:EntIndex())
        end
    end)
end
