AddCSLuaFile()
local ENT = {}
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Power Device"
ENT.Category = "Helix"
ENT.Spawnable = true

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "DeviceID")
    self:NetworkVar("Bool",   0, "Active")
    self:NetworkVar("Float",  0, "Stored")
    self:NetworkVar("Float",  1, "Fuel")
    self:NetworkVar("Float",  2, "FuelCapacity")
    self:NetworkVar("Float",  3, "Voltage")
end

if SERVER then
    util.AddNetworkString("ix_power_device_open")

    local function applyDef(self)
        local id = self:GetDeviceID()
        local def = ix.power and id and ix.power.GetDevice(id) or nil
        if not def then return end
        if def.model and self:GetModel() ~= def.model then
            self:SetModel(def.model)
        end
        local cap = def.fuelCapacity or 0
        self:SetFuelCapacity(cap)
        if (self._appliedOnce or false) == false then
            local startFuel = def.startFuel or cap
            self:SetFuel(math.Clamp(startFuel, 0, cap))
            self._appliedOnce = true
        end
        self._lastDeviceID = id
    end

    function ENT:Initialize()
        applyDef(self)
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        local phys = self:GetPhysicsObject(); if IsValid(phys) then phys:Wake() end
        self:SetUseType(SIMPLE_USE)
        self:SetActive(false)
        self:SetStored(0)
        self.nextTick = CurTime()
        self.nextToggle = 0
        if not self:GetVoltage() then self:SetVoltage(0) end
    end

    function ENT:AttemptToggle(activator)
        local def = ix.power and ix.power.GetDevice(self:GetDeviceID()) or nil
        local cd = (def and def.toggleCooldown) or 3
        local now = CurTime()
        if now < (self.nextToggle or 0) then
            local wait = (self.nextToggle - now)
            if IsValid(activator) then activator:ChatPrint(string.format("Espera %.1fs para volver a alternar.", wait)) end
            return false
        end
        local cap = self:GetFuelCapacity() or 0
        if cap > 0 and self:GetActive() == false then
            if (self:GetFuel() or 0) <= 0 then
                if IsValid(activator) then activator:ChatPrint("Sin combustible.") end
                return false
            end
        end
        self.nextToggle = now + cd
        self:SetActive(not self:GetActive())
        return true
    end

    function ENT:Use(activator)
        if not IsValid(activator) or not activator:IsPlayer() then return end
        net.Start("ix_power_device_open")
        net.WriteUInt(self:EntIndex(), 16)
        net.Send(activator)
    end

    function ENT:Think()
        local currentID = self:GetDeviceID()
        if currentID and currentID ~= self._lastDeviceID then
            applyDef(self)
        end
        local def = ix.power and ix.power.GetDevice(self:GetDeviceID()) or nil
        if not def then return end
        local ct = CurTime()
        if ct >= (self.nextTick or ct) then
            self.nextTick = ct + (def.interval or 1.0)
            local voltage = (def.voltageRating or 220)
            if self:GetActive() then
                if def.type == "generator" then
                    local cap = self:GetFuelCapacity() or 0
                    if cap > 0 then
                        local rate = def.fuelPerTick or 1
                        self:SetFuel(math.max((self:GetFuel() or 0) - rate, 0))
                        if (self:GetFuel() or 0) <= 0 then self:SetActive(false) end
                    end
                    self:SetStored(math.min((self:GetStored() or 0) + (def.output or 0), 100000))
                    self:SetVoltage(voltage)
                elseif def.type == "consumer" then
                    
                    self:SetStored(math.max((self:GetStored() or 0) - math.abs(def.output or 0), 0))
                elseif def.type == "battery" then
                    local capE = def.capacity or 0
                    self:SetStored(math.Clamp((self:GetStored() or 0), 0, capE))
                    local pct = capE > 0 and ((self:GetStored() or 0) / capE) or 0
                    self:SetVoltage(voltage * pct)
                else
                    
                end
            else
                self:SetVoltage(0)
            end
        end
        self:NextThink(ct + 0.05)
        return true
    end
else
    function ENT:Draw()
        self:DrawModel()
        local id = self:GetDeviceID()
        if id == "lamp" and self:GetActive() and (self:GetVoltage() or 0) > 1 then
            local d = DynamicLight(self:EntIndex())
            if d then
                local p = self:GetPos() + self:OBBCenter()
                d.pos = p
                d.r = 255; d.g = 240; d.b = 200
                d.brightness = 2
                d.decay = 600
                d.size = 220
                d.dietime = CurTime() + 0.3
            end
        end
    end
end

scripted_ents.Register(ENT, "ix_power_device")
