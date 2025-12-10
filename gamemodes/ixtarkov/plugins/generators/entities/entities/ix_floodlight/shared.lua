
AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Foco Proyector"
ENT.Author = "TuNombre"
ENT.Category = "Camp Power"
ENT.Spawnable = true

-- Requisito de potencia para el reparto
ENT.PowerRequired = 250 -- W

function ENT:SetupDataTables()
    -- Potencia que llega desde la red (generador/caja)
    self:NetworkVar("Bool", 0, "Powered")
    -- Interruptor del usuario (E). Si está OFF, la lámpara no se enciende aunque haya potencia.
    self:NetworkVar("Bool", 1, "Enabled")
end
