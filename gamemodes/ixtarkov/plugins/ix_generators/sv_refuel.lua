
if SERVER then
    util.AddNetworkString("ix_power_refuel")

    local function refuelDevice(ply, ent, amount)
        if not IsValid(ent) or ent:GetClass() ~= "ix_power_device" then return false, "No es un ix_power_device" end
        local cap = ent.GetFuelCapacity and ent:GetFuelCapacity() or 0
        if cap <= 0 then return false, "Este dispositivo no usa combustible" end
        local cur = ent:GetFuel() or 0
        if cur >= cap then return false, "Depósito ya lleno" end
        local add = math.max(0, tonumber(amount) or 0)
        if add <= 0 then return false, "Cantidad inválida" end
        local new = math.min(cur + add, cap)
        ent:SetFuel(new)
        return true, string.format("Repostado +%d (%.0f/%.0f)", math.floor(new - cur), new, cap)
    end

    net.Receive("ix_power_refuel", function(_, ply)
        local entIndex = net.ReadUInt(16)
        local amount   = net.ReadFloat()
        local ent = Entity(entIndex)
        local ok, msg = refuelDevice(ply, ent, amount)
        ply:ChatPrint(msg or "")
    end)

    ix.command.Add("PowerRefuel", {description = "Reposta combustible al dispositivo que estás mirando.", adminOnly   = true, arguments   = {ix.type.number}, OnRun = function(self, client, amount) local vStart = client:GetShootPos(); local vForward = client:GetAimVector(); local tr = util.TraceLine({start = vStart, endpos = vStart + vForward * 2048, filter = client}); local ent = tr.Entity; local ok, msg = refuelDevice(client, ent, amount or 10); return msg end})
end
