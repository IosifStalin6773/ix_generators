
ITEM.name = "Garrafa de diésel"
ITEM.description = "Contiene combustible para generadores (25 L)."
ITEM.model = "models/props_junk/gascan001a.mdl"
ITEM.category = "Energía"
ITEM.width = 1
ITEM.height = 2
ITEM.fuelAmount = 25

ITEM.functions.Use = {
    name = "Usar",
    tip = "Repostar",
    icon = "icon16/add.png",
    OnRun = function(item)
        local ply = item.player
        if not IsValid(ply) then return false end
        local vStart   = ply:GetShootPos()
        local vForward = ply:GetAimVector()
        local tr = util.TraceLine({start = vStart, endpos = vStart + vForward * 2048, filter = ply})
        local ent = tr.Entity
        if not IsValid(ent) or ent:GetClass() ~= "ix_power_device" then
            ply:ChatPrint("Mira a un equipo válido.")
            return false
        end
        net.Start("ix_power_refuel")
            net.WriteUInt(ent:EntIndex(), 16)
            net.WriteFloat(item.fuelAmount)
        net.SendToServer()
        return true -- Consumible
    end
}
