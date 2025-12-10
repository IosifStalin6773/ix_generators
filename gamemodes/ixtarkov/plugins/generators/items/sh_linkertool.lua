
ITEM.name = "Linker Eléctrico (Herramienta)"
ITEM.description = "Herramienta tipo palanca para enlazar generadores con dispositivos."
ITEM.category = "Herramientas"
ITEM.model = "models/weapons/w_crowbar.mdl"
ITEM.width = 1
ITEM.height = 2

ITEM.class = "weapon_ix_linkertool"   -- DEBE coincidir con el nombre del archivo del SWEP
ITEM.weaponCategory = "tool"

function ITEM:IsEquipped()
    return self:GetData("equipped", false)
end

ITEM.functions.Equip = {
    name = "Equipar",
    tip = "equip",
    icon = "icon16/wrench.png",
    OnCanRun = function(item)
        return not item:IsEquipped() and not IsValid(item.entity)
    end,
    OnRun = function(item)
        local client = item.player
        if not IsValid(client) then return false end

        if not client:HasWeapon(item.class) then
            client:Give(item.class)
        end
        timer.Simple(0, function()
            if IsValid(client) and client:HasWeapon(item.class) then
                client:SelectWeapon(item.class)
            end
        end)

        item:SetData("equipped", true)
        client:Notify("Has equipado la herramienta.")
        return false
    end
}

ITEM.functions.Guardar = {
    name = "Guardar",
    tip = "unequip",
    icon = "icon16/box.png",
    OnCanRun = function(item)
        return item:IsEquipped() and not IsValid(item.entity)
    end,
    OnRun = function(item)
        local client = item.player
        if not IsValid(client) then return false end

        if client:HasWeapon(item.class) then
            client:StripWeapon(item.class)
        end

        item:SetData("equipped", false)
        client:Notify("Has guardado la herramienta.")
        return false
    end
}

function ITEM:CanTransfer(inventory, newInventory)
    if self:IsEquipped() then
        local client = self.player
        if IsValid(client) then
            client:Notify("Primero guarda la herramienta antes de moverla.")
        end
        return false
    end
    return true
end

function ITEM:OnRemoved()
    local client = self.player
    if self:IsEquipped() and IsValid(client) and client:HasWeapon(self.class) then
        client:StripWeapon(self.class)
    end
end