
ITEM.name = "Herramientas de conexión"
ITEM.description = "Pinzas y cableado para enlazar equipos eléctricos."
ITEM.model = "models/Items/BoxFlares.mdl"
ITEM.category = "Energía"
ITEM.width = 2
ITEM.height = 1
ITEM.swepClass = "weapon_ix_linktool"

local function setEquipped(ply, equipped, swepClass)
    if not IsValid(ply) then return end
    ply:SetNWBool("ix_power_tool_equipped", equipped)
    if equipped then
        if not ply:HasWeapon(swepClass) then ply:Give(swepClass) end
        timer.Simple(0, function()
            if IsValid(ply) and ply:HasWeapon(swepClass) then ply:SelectWeapon(swepClass) end
        end)
        ply:ChatPrint("Herramientas equipadas: Primario pick origen/destino, Secundario limpiar.")
    else
        if ply:HasWeapon(swepClass) then ply:StripWeapon(swepClass) end
        ply:ChatPrint("Herramientas de conexión guardadas.")
    end
end

ITEM.functions.Equipar = {
    name = "Equipar",
    icon = "icon16/wrench.png",
    OnRun = function(item)
        setEquipped(item.player, true, item.swepClass)
        return false
    end
}

ITEM.functions.Guardar = {
    name = "Guardar",
    icon = "icon16/box.png",
    OnRun = function(item)
        setEquipped(item.player, false, item.swepClass)
        return false
    end
}

function ITEM:OnRemoved()
    local ply = self.player
    if IsValid(ply) and ply:GetNWBool("ix_power_tool_equipped", false) then
        setEquipped(ply, false, self.swepClass)
    end
end
