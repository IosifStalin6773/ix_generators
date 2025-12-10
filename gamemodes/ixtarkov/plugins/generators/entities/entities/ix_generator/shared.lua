
AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Generador"
ENT.Author = "TuNombre"
ENT.Category = "Camp Power"
ENT.Spawnable = true

function ENT:SetupDataTables()
    -- Genera GetFuel/SetFuel, GetActive/SetActive, GetOutput/SetOutput en servidor y cliente
    self:NetworkVar("Int", 0, "Fuel")    -- mL
    self:NetworkVar("Bool", 0, "Active")
    self:NetworkVar("Int", 1, "Output")  -- W
end

-- Datos no networked
ENT.FuelCapacity = 100 -- L
