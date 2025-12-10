
AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Caja de Fusibles"
ENT.Author = "TuNombre"
ENT.Category = "Camp Power"
ENT.Spawnable = true

function ENT:SetupDataTables()
    -- La caja conoce su generador
    self:NetworkVar("Entity", 0, "Generator")
end
