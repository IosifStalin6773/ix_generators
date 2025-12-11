
-- sh_weapon_ix_linktool.lua
-- SWEP de Herramientas de conexión: pick y limpiar.
AddCSLuaFile()

local SWEP = {}
SWEP.PrintName      = "Herramientas de conexión"
SWEP.Author         = "M365 Copilot"
SWEP.Category       = "Energía"
SWEP.Instructions   = "Primario: seleccionar origen/destino. Secundario: limpiar enlaces del generador que miras."
SWEP.Spawnable      = false
SWEP.AdminOnly      = false

SWEP.Base           = "weapon_base"
SWEP.ViewModel      = "models/weapons/c_toolgun.mdl"
SWEP.WorldModel     = "models/weapons/w_toolgun.mdl"
SWEP.UseHands       = true
SWEP.HoldType       = "pistol"

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
end

function SWEP:Deploy()
    if CLIENT then
        chat.AddText(Color(200,255,200), "[Conexión] Primario: pick origen/destino | Secundario: limpiar")
    end
    return true
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 0.5)
    if CLIENT then
        net.Start("ix_power_link_pick")
        net.SendToServer()
        surface.PlaySound("buttons/button14.wav")
    end
end

function SWEP:SecondaryAttack()
    self:SetNextSecondaryFire(CurTime() + 0.8)
    if CLIENT then
        RunConsoleCommand("ix_power_link_clear")
        surface.PlaySound("buttons/button15.wav")
    end
end

weapons.Register(SWEP, "weapon_ix_linktool")
