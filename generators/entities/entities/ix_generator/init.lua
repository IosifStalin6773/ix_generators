
-- Enviar al cliente y cargar shared
AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

util.AddNetworkString("ix_camp_toggleGenerator")
util.AddNetworkString("ix_camp_openGeneratorUI")

function ENT:Initialize()
    self:SetModel("models/metro/generator_1.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_VPHYSICS)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:Wake() end

    -- NetworkVars por defecto
    self:SetFuel(0) -- mL
    self:SetActive(false)
    self:SetOutput(ix.config.Get("defaultGeneratorOutput", 1500)) -- W

    -- Estado interno
    self.FuseBoxes = {}     -- [fuseEnt] = true
    self.FuseRopes = {}     -- [fuseEnt] = rope constraint
    self.SoundLoop = nil
    self.NextTick = CurTime()
    self._nextUse = 0
end

-- UI del generador (cooldown)
function ENT:Use(activator)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    if CurTime() < (self._nextUse or 0) then return end
    self._nextUse = CurTime() + 0.3

    net.Start("ix_camp_openGeneratorUI")
        net.WriteEntity(self)
    net.Send(activator)
end

-- Encendido/apagado
net.Receive("ix_camp_toggleGenerator", function(_, ply)
    local ent = net.ReadEntity()
    if not IsValid(ent) or ent:GetClass() ~= "ix_generator" then return end

    if ent:GetActive() then ent:StopGenerator() else ent:StartGenerator() end
end)

function ENT:StartGenerator()
    if (self:GetFuel() or 0) <= 0 then return end
    self:SetActive(true)
    if not self.SoundLoop then
        self.SoundLoop = CreateSound(self, "ambient/machines/diesel_engine_idle1.wav")
        if self.SoundLoop then self.SoundLoop:PlayEx(0.6, 100) end
    end
end

function ENT:StopGenerator()
    self:SetActive(false)
    if self.SoundLoop then self.SoundLoop:Stop() self.SoundLoop = nil end

    -- Apaga todos los dispositivos a través de cada caja
    for fuse, _ in pairs(self.FuseBoxes) do
        if IsValid(fuse) and fuse.DistributePower then
            fuse:DistributePower(0) -- corta suministro
        end
    end
end

-- === VINCULACIÓN DE CAJAS DE FUSIBLES ===

function ENT:CanLinkFuseBox(fuse)
    if not IsValid(fuse) or fuse:GetClass() ~= "ix_fusebox" then
        return false, "No es una caja de fusibles válida."
    end
    if self.FuseBoxes[fuse] then
        return false, "Esta caja ya está vinculada."
    end
    local maxLen = ix.config.Get("maxCableLength", 900)
    if self:GetPos():Distance(fuse:GetPos()) > maxLen then
        return false, "Fuera de alcance del cable."
    end
    return true
end

function ENT:AddFuseBox(fuse)
    local ok, err = self:CanLinkFuseBox(fuse)
    if not ok then return false, err end

    self.FuseBoxes[fuse] = true
    fuse:SetGenerator(self) -- guarda referencia en la caja

    -- Cable visual opcional entre generador y caja
    local dist = self:GetPos():Distance(fuse:GetPos())
    local rope = constraint.Rope(self, fuse, 0, 0,
        Vector(0,0,0), Vector(0,0,0),
        dist, 0, 0, 1.5, "cable/cable2", false)
    if IsValid(rope) then
        self.FuseRopes[fuse] = rope
    end

    return true
end

function ENT:RemoveFuseBox(fuse)
    if not IsValid(fuse) then return end
    -- corta suministro a esa caja
    if fuse.DistributePower then fuse:DistributePower(0) end

    local rope = self.FuseRopes[fuse]
    if IsValid(rope) then rope:Remove() end
    self.FuseRopes[fuse] = nil

    self.FuseBoxes[fuse] = nil
    if fuse.SetGenerator then fuse:SetGenerator(NULL) end
end

function ENT:RemoveAllFuseBoxes()
    for fuse, _ in pairs(self.FuseBoxes) do
        self:RemoveFuseBox(fuse)
    end
    self.FuseBoxes = {}
end

-- === CICLO DE POTENCIA ===
-- Reparte potencia a las cajas, y cada caja se encarga de sus dispositivos.
function ENT:Think()
    if CurTime() < (self.NextTick or 0) then return end
    self.NextTick = CurTime() + 1

    if not self:GetActive() then return end
    if (self:GetFuel() or 0) <= 0 then self:StopGenerator() return end

    -- Potencia disponible del generador
    local available = self:GetOutput()
    local totalOutput = math.max(1, available)

    -- Recorre cajas y les da potencia hasta que se agote
    for fuse, _ in pairs(self.FuseBoxes) do
        if not IsValid(fuse) or not fuse.DistributePower then
            self.FuseBoxes[fuse] = nil
        else
            local usedByFuse = fuse:DistributePower(available) -- la caja consume y enciende lo que pueda
            available = math.max(0, available - usedByFuse)
            if available <= 0 then break end
        end
    end

    -- Consumo de combustible proporcional a carga (idle mínimo del 20%)
    local burnRate = ix.config.Get("generatorFuelBurnRate", 0.05) -- L/s nominal
    local loadFactor = 0.2 + 0.8 * (1 - (available / totalOutput))
    local consume_mL = math.max(1, math.floor(burnRate * 1000 * loadFactor))
    self:SetFuel(math.max(0, (self:GetFuel() or 0) - consume_mL))
end

-- Limpieza
function ENT:OnRemove()
    if self.SoundLoop then self.SoundLoop:Stop() self.SoundLoop = nil end
    if self.FuseRopes then
        for _, rope in pairs(self.FuseRopes) do
            if IsValid(rope) then rope:Remove() end
        end
    end
end