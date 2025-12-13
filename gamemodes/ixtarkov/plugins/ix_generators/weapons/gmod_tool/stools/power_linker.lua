TOOL.Category = "Generators"
TOOL.Name     = "Power Linker"
TOOL.Command  = nil
TOOL.ConfigName = ""

if CLIENT then
    language.Add("tool.power_linker.name", "Power Linker")
    language.Add("tool.power_linker.desc", "Conecta generadores con consumidores")
    language.Add("tool.power_linker.0", "LClick: seleccionar generador | RClick: enlazar consumidor | Reload: desenlazar")
end

local SELECTED_GEN = {}

function TOOL:LeftClick(trace)
    if not IsValid(trace.Entity) or trace.Entity:GetClass() ~= "ix_power_device" then return false end
    local id = trace.Entity:GetDeviceID() or "unknown"
    local def = ix and ix.power and ix.power.GetDevice(id) or nil
    if not def or def.type ~= "generator" then return false end
    SELECTED_GEN[self:GetOwner()] = trace.Entity:EntIndex()
    return true
end

function TOOL:RightClick(trace)
    local ply = self:GetOwner()
    local genIndex = SELECTED_GEN[ply]
    if not genIndex then return false end
    if not IsValid(trace.Entity) or trace.Entity:GetClass() ~= "ix_power_device" then return false end
    local id = trace.Entity:GetDeviceID() or "unknown"
    local def = ix and ix.power and ix.power.GetDevice(id) or nil
    if not def or def.type == "generator" then return false end
    if SERVER then
        util.AddNetworkString("ix_power_link_add")
        net.Start("ix_power_link_add")
            net.WriteUInt(genIndex, 16)
            net.WriteUInt(trace.Entity:EntIndex(), 16)
        net.Send(ply)
    end
    return true
end

function TOOL:Reload(trace)
    local ply = self:GetOwner()
    local genIndex = SELECTED_GEN[ply]
    if not genIndex then return false end
    if not IsValid(trace.Entity) or trace.Entity:GetClass() ~= "ix_power_device" then return false end
    if SERVER then
        util.AddNetworkString("ix_power_link_remove")
        net.Start("ix_power_link_remove")
            net.WriteUInt(genIndex, 16)
            net.WriteUInt(trace.Entity:EntIndex(), 16)
        net.Send(ply)
    end
    return true
end

function TOOL.BuildCPanel(panel)
    panel:Help("Selecciona un generador con clic izquierdo y enlaza un consumidor con clic derecho.")
end
