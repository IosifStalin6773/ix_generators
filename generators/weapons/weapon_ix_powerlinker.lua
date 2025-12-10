
-- addons/tu_addon/lua/weapons/weapon_ix_linkertool.lua
if SERVER then AddCSLuaFile() end

SWEP.PrintName = "Linker Eléctrico (Palanca)"
SWEP.Author = "TuNombre"
SWEP.Instructions = [[
Izq: Golpe tipo palanca
Der: Selecciona generador / Enlaza dispositivo
Reload: Desenlaza dispositivo (mirando al dispositivo)
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

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
    self.SelectedGenerator = nil
end

local function traceFront(ply, dist)
    dist = dist or 90
    local tr = util.TraceLine({
        start = ply:EyePos(),
        endpos = ply:EyePos() + ply:GetAimVector() * dist,
        filter = ply
    })
    return tr
end

function SWEP:PrimaryAttack()
    if not IsValid(self.Owner) then return end
    self.Owner:SetAnimation(PLAYER_ATTACK1)
    self:SendWeaponAnim(ACT_VM_HITCENTER)

    if SERVER then
        local tr = traceFront(self.Owner, 75)
        self.Owner:EmitSound("weapons/iceaxe/iceaxe_swing1.wav")
        if tr.Hit and IsValid(tr.Entity) and self.PrimaryDamage > 0 then
            local dmg = DamageInfo()
            dmg:SetAttacker(self.Owner)
            dmg:SetInflictor(self)
            dmg:SetDamage(self.PrimaryDamage)
            dmg:SetDamageType(DMG_CLUB)
            dmg:SetDamageForce(self.Owner:GetAimVector() * 120)
            tr.Entity:TakeDamageInfo(dmg)
        end
    end

    self:SetNextPrimaryFire(CurTime() + self.PrimaryDelay)
end

function SWEP:SecondaryAttack()
    if not IsValid(self.Owner) then return end
    if CLIENT then return end

    local tr = self.Owner:GetEyeTrace()
    local ent = tr.Entity
    if not IsValid(ent) then return end

    if ent:GetClass() == "ix_generator" then
        self.SelectedGenerator = ent
        self.Owner:ChatPrint("Generador seleccionado.")
    else
        if not IsValid(self.SelectedGenerator) then
            self.Owner:ChatPrint("Mira a un generador primero (click derecho).")
            return
        end
        local ok, err = self.SelectedGenerator:CanLink(ent)
        if not ok then
            self.Owner:ChatPrint(err or "No se pudo enlazar.")
            return
        end
        if self.SelectedGenerator:AddLink(ent) then
            self.Owner:ChatPrint("Enlazado.")
            constraint.Rope(self.SelectedGenerator, ent, 0, 0,
                Vector(0,0,0), Vector(0,0,0),
                self.SelectedGenerator:GetPos():Distance(ent:GetPos()),
                0, 0, 1.5, "cable/cable2", false)
        end
    end

    self:SetNextSecondaryFire(CurTime() + self.SecondaryDelay)
end

function SWEP:Reload()
    if CLIENT or not IsValid(self.Owner) then return end
    if not IsValid(self.SelectedGenerator) then
        self.Owner:ChatPrint("No hay generador seleccionado para desenlazar.")
        return
    end
    local tr = self.Owner:GetEyeTrace()
    local ent = tr.Entity
    if IsValid(ent) then
        self.SelectedGenerator:RemoveLink(ent)
        self.Owner:ChatPrint("Desenlace realizado.")
    end
end
