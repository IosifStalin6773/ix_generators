
AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

-- Nets para abrir UI y refrescar
util.AddNetworkString("ix_camp_openFuseBox")
util.AddNetworkString("ix_camp_disconnectLink")
util.AddNetworkString("ix_camp_fusebox_refresh")

function ENT:Initialize()
    self:SetModel("models/z-o-m-b-i-e/metro_ll/electro/m_ll_electro_box_10.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_VPHYSICS)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:Wake() end

    self._nextUse = 0

    -- Enlaces de dispositivos que cuelgan de esta caja
    self.DeviceLinks = {}   -- [ent] = true
    self.DeviceRopes = {}   -- [ent] = rope
end

-- Validación y gestión de dispositivos (para el esquema Generador -> Caja -> Dispositivos)

function ENT:CanLinkDevice(dev)
    if not IsValid(dev) then return false, "Dispositivo inválido." end

    -- Acepta dispositivos estándar (PowerRequired) y hubs (ConsumePower)
    local isDeviceOrHub = (dev.PowerRequired ~= nil) or isfunction(dev.ConsumePower)
    if not isDeviceOrHub then
        return false, "No es un dispositivo eléctrico compatible."
    end

    if self.DeviceLinks[dev] then return false, "Este dispositivo ya está enlazado a esta caja." end

    local maxLen = ix.config.Get("maxCableLength", 900)
    if self:GetPos():Distance(dev:GetPos()) > maxLen then
        return false, "Fuera de alcance del cable."
    end
    return true
end

function ENT:AddDeviceLink(dev)
    local ok, err = self:CanLinkDevice(dev)
    if not ok then return false, err end

    self.DeviceLinks[dev] = true

    local dist = self:GetPos():Distance(dev:GetPos())
    local rope = constraint.Rope(self, dev, 0, 0,
        Vector(0,0,0), Vector(0,0,0),
        dist, 0, 0, 1.5, "cable/cable2", false)
    if IsValid(rope) then
        self.DeviceRopes[dev] = rope
    end

    return true
end

function ENT:RemoveDeviceLink(dev)
    if not IsValid(dev) then return end

    if dev.ApplyPower then dev:ApplyPower(false) end

    local rope = self.DeviceRopes[dev]
    if IsValid(rope) then rope:Remove() end

    self.DeviceLinks[dev] = nil
    self.DeviceRopes[dev] = nil
end

function ENT:RemoveAllDevices()
    for dev, _ in pairs(self.DeviceLinks) do
        if IsValid(dev) and dev.ApplyPower then dev:ApplyPower(false) end
        local rope = self.DeviceRopes[dev]
        if IsValid(rope) then rope:Remove() end
        self.DeviceRopes[dev] = nil
    end
    self.DeviceLinks = {}
end

-- Reparto de potencia desde el generador hacia los dispositivos
-- available: W disponibles. Devuelve W consumidos.

function ENT:DistributePower(available)
    local used = 0
    if available <= 0 then
        for dev,_ in pairs(self.DeviceLinks) do
            if IsValid(dev) and dev.ApplyPower then dev:ApplyPower(false) end
        end
        return 0
    end

    for dev,_ in pairs(self.DeviceLinks) do
        if not IsValid(dev) then
            self.DeviceLinks[dev] = nil
        else
            -- Si el dispositivo es un hub (caja de empalmes), delega reparto
            if isfunction(dev.ConsumePower) then
                local usedByHub = dev:ConsumePower(available)
                available = math.max(0, available - usedByHub)
                used = used + usedByHub
            else
                local need = dev.PowerRequired or 0
                if available >= need then
                    if dev.ApplyPower then dev:ApplyPower(true) end
                    available = available - need
                    used = used + need
                else
                    if dev.ApplyPower then dev:ApplyPower(false) end
                end
            end
        end

        if available <= 0 then break end
    end

    return used
end


-- Abrir UI con E
function ENT:Use(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if CurTime() < (self._nextUse or 0) then return end
    self._nextUse = CurTime() + 0.3

    local gen = self:GetGenerator()
    if not IsValid(gen) or gen:GetClass() ~= "ix_generator" then
        ply:ChatPrint("Esta caja de fusibles no está vinculada a un generador.")
        return
    end

    -- Construir lista de dispositivos conectados a esta caja
    local links = {}
    for dev, _ in pairs(self.DeviceLinks) do
        if IsValid(dev) then table.insert(links, dev) end
    end

    net.Start("ix_camp_openFuseBox")
        net.WriteEntity(self)      -- la caja
        net.WriteEntity(gen)       -- el generador vinculado
        net.WriteUInt(#links, 8)   -- cantidad
        for _, e in ipairs(links) do
            net.WriteEntity(e)     -- cada dispositivo enlazado
        end
    net.Send(ply)
end

-- Solicitud desde UI para desconectar uno
net.Receive("ix_camp_disconnectLink", function(_, ply)
    local fuse = net.ReadEntity()
    local gen  = net.ReadEntity()
    local target = net.ReadEntity()

    if not IsValid(ply) or not IsValid(fuse) or fuse:GetClass() ~= "ix_fusebox" then return end
    if not IsValid(gen) or gen:GetClass() ~= "ix_generator" then return end
    if fuse:GetGenerator() ~= gen then return end
    if not IsValid(target) then return end

    if not fuse.DeviceLinks or not fuse.DeviceLinks[target] then
        ply:ChatPrint("Ese dispositivo no está enlazado a esta caja.")
        return
    end

    fuse:RemoveDeviceLink(target)
    ply:ChatPrint("Dispositivo desconectado.")

    -- reenviar lista para refrescar UI
    local links = {}
    for dev, _ in pairs(fuse.DeviceLinks or {}) do
        if IsValid(dev) then table.insert(links, dev) end
    end

    net.Start("ix_camp_fusebox_refresh")
        net.WriteEntity(fuse)
        net.WriteEntity(gen)
        net.WriteUInt(#links, 8)
        for _, e in ipairs(links) do
            net.WriteEntity(e)
        end
    net.Send(ply)
end)

function ENT:OnRemove()
    if self.DeviceRopes then
        for _, rope in pairs(self.DeviceRopes) do
            if IsValid(rope) then rope:Remove() end
        end
    end
end
