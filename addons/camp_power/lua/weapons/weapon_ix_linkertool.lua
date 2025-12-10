
if SERVER then AddCSLuaFile() end

SWEP.PrintName = "Linker Eléctrico (Palanca)"
SWEP.Author = "TuNombre"
SWEP.Instructions = [[
Izq: Golpe tipo palanca
Der: Selecciona generador / Enlaza dispositivo
Reload: Desenlaza dispositivo mirado
]]

SWEP.Spawnable = false
SWEP.AdminOnly = false

SWEP.ViewModel = "models/weapons/c_crowbar.mdl"
SWEP.WorldModel = "models/weapons/w_crowbar.mdl"
SWEP.UseHands = true
SWEP.HoldType = "melee"
SWEP.DrawAmmo = false
SWEP.Primary.Automatic = false
SWEP.Secondary.Automatic = false

SWEP.PrimaryDamage = 10
SWEP.PrimaryDelay  = 0.4
SWEP.SecondaryDelay = 0.3



-- Al crear la herramienta
function SWEP:Initialize()
    self.SelectedOrigin = nil -- puede ser ix_generator o ix_fusebox
end

local function traceEntity(ply)
    local tr = ply:GetEyeTrace()
    return tr.Entity
end

-- Click IZQ: elegir origen (generador o caja)
function SWEP:PrimaryAttack()
    local ply = self:GetOwner()
    local ent = traceEntity(ply)
    if not IsValid(ent) then return end

    local cls = ent:GetClass()
    if cls == "ix_generator" or cls == "ix_fusebox" then
        self.SelectedOrigin = ent
        if SERVER then ply:ChatPrint("Origen seleccionado: " .. cls) end
    else
        if SERVER then ply:ChatPrint("Selecciona un generador o una caja como origen (click izquierdo).") end
    end
    self:SetNextPrimaryFire(CurTime() + 0.3)
end

-- Click DER: crear vínculo
function SWEP:SecondaryAttack()
    local ply = self:GetOwner()
    local origin = self.SelectedOrigin
    local target = traceEntity(ply)
    if not IsValid(origin) or not IsValid(target) then return end

    if SERVER then
        local ocls, tcls = origin:GetClass(), target:GetClass()

        -- Generador -> Caja
        if ocls == "ix_generator" and tcls == "ix_fusebox" then
            local ok, err = origin:AddFuseBox(target)
            ply:ChatPrint(ok and "Caja vinculada al generador." or (err or "No se pudo vincular la caja."))
            return
        end

        -- Caja -> Dispositivo
        if ocls == "ix_fusebox" and tcls ~= "ix_generator" then
            if target.PowerRequired then
                local ok, err = origin:AddDeviceLink(target)
                ply:ChatPrint(ok and "Dispositivo vinculado a la caja." or (err or "No se pudo vincular el dispositivo."))
            else
                ply:ChatPrint("No es un dispositivo eléctrico compatible.")
            end
            return
        end
        
        if ocls == "ix_junctionbox" and tcls ~= "ix_generator" and tcls ~= "ix_fusebox" then
            -- Acepta dispositivos con PowerRequired o hubs con ConsumePower
            if target.PowerRequired ~= nil or isfunction(target.ConsumePower) then
                local ok, err = origin:AddOutputLink(target)
                ply:ChatPrint(ok and "Dispositivo vinculado a la caja de empalmes." or (err or "No se pudo vincular el dispositivo."))
            else
                ply:ChatPrint("No es un dispositivo eléctrico compatible.")
            end
            return
        end


        ply:ChatPrint("Flujo esperado: Generador → Caja → Dispositivo.")
    end

    self:SetNextSecondaryFire(CurTime() + 0.3)
end

-- Reload: desenlazar
function SWEP:Reload()
    local ply = self:GetOwner()
    local origin = self.SelectedOrigin
    local target = traceEntity(ply)
    if not IsValid(origin) then return end

    if SERVER then
        local ocls = origin:GetClass()
        if ocls == "ix_fusebox" then
            if IsValid(target) and origin.DeviceLinks and origin.DeviceLinks[target] then
                origin:RemoveDeviceLink(target)
                ply:ChatPrint("Dispositivo desenlazado de la caja.")
            else
                ply:ChatPrint("Mira a un dispositivo enlazado para desenlazarlo.")
            end
        elseif ocls == "ix_generator" then
            if IsValid(target) and target:GetClass() == "ix_fusebox" and origin.FuseBoxes and origin.FuseBoxes[target] then
                origin:RemoveFuseBox(target)
                ply:ChatPrint("Caja desenlazada del generador.")
            else
                ply:ChatPrint("Mira a una caja vinculada para desenlazarla.")
            end                
        elseif ocls == "ix_junctionbox" then
            if IsValid(target) and origin.OutputLinks and origin.OutputLinks[target] then
                origin:RemoveOutputLink(target)
                ply:ChatPrint("Dispositivo desenlazado de la caja de empalmes.")
            else
                ply:ChatPrint("Mira a un dispositivo enlazado para desenlazarlo.")
            end
            return
        end

    end
end

