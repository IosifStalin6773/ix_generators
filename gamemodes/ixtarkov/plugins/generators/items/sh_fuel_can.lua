
ITEM.name = "Garrafa de combustible"
ITEM.description = "Recipiente con combustible para generadores."
ITEM.category = "Suministros"
ITEM.model = "models/props_junk/gascan001a.mdl"
ITEM.width = 1
ITEM.height = 2

ITEM.fuelAmount = 5000 -- mL

ITEM.functions.Rellenar = {
    name = "Rellenar generador",
    tip = "use",
    icon = "icon16/add.png",
    OnRun = function(item)
        local client = item.player
        local tr = client:GetEyeTrace()
        local ent = tr.Entity

        if not IsValid(ent) or ent:GetClass() ~= "ix_generator" then
            client:Notify("Mira a un generador para rellenar.")
            return false
        end

        local current = ent:GetFuel() or 0
        local capacity_mL = (ent.FuelCapacity or 100) * 1000
        local newFuel = math.min(capacity_mL, current + item.fuelAmount)
        ent:SetFuel(newFuel)
        client:Notify("Has rellenado el generador (+".. item.fuelAmount .." mL).")

        return true -- consume el ítem
    end
}
