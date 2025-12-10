
AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

-- Config de luz
ENT.LightOffset = Vector(0, 0, 50)  -- Posición relativa del haz
ENT.LightAngles = Angle(120, 0, 0)    -- Orientación del haz (ajústalo al modelo)
ENT.LightColor  = "255 255 235"     -- Color (RGB) para entity KeyValues
ENT.LightFOV    = 50                -- Apertura del haz (proyector)
ENT.LightFarZ   = 600               -- Alcance (proyector)
ENT.LightNearZ  = 8                 -- Near clip
ENT.LightBrightness = 2             -- Para light_dynamic (no aplica al proyector)
ENT.LightDistance   = 400           -- Distancia de light_dynamic

function ENT:Initialize()
    self:SetModel("models/z-o-m-b-i-e/metro_ll/lamps/m_ll_lamp_nastolny_01.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_VPHYSICS)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:Wake() end

    self:SetPowered(false)

    -- Handlers
    self._Projected = nil  -- env_projectedtexture
    self._DynLight  = nil  -- light_dynamic (fallback)
end


-- ===== Luz: creación y destrucción =====

local function createProjected(ent)
    local pt = ents.Create("env_projectedtexture")
    if not IsValid(pt) then return nil end

    pt:SetParent(ent)
    pt:SetLocalPos(ent.LightOffset or Vector(0,0,50))
    pt:SetLocalAngles(ent.LightAngles or Angle(0,0,0))

    pt:SetKeyValue("enableshadows", 1)
    pt:SetKeyValue("lightcolor", ent.LightColor or "255 255 235")
    pt:SetKeyValue("nearz", tostring(ent.LightNearZ or 8))
    pt:SetKeyValue("farz", tostring(ent.LightFarZ or 600))
    pt:SetKeyValue("fov", tostring(ent.LightFOV or 50))

    pt:Spawn()
    pt:Activate()
    pt:Fire("TurnOn")

    return pt
end

local function createDynamic(ent)
    local dl = ents.Create("light_dynamic")
    if not IsValid(dl) then return nil end

    dl:SetParent(ent)
    dl:SetLocalPos(ent.LightOffset or Vector(0,0,50))
    dl:SetLocalAngles(ent.LightAngles or Angle(0,0,0))

    dl:SetKeyValue("distance", tostring(ent.LightDistance or 400))
    dl:SetKeyValue("brightness", tostring(ent.LightBrightness or 2))
    dl:SetKeyValue("style", "0")
    dl:SetKeyValue("color", ent.LightColor or "255 255 235")

    dl:Spawn()
    dl:Activate()
    dl:Fire("TurnOn")

    return dl
end

function ENT:TurnLightOn()
    if IsValid(self._Projected) or IsValid(self._DynLight) then return end
    local pt = createProjected(self)
    if IsValid(pt) then
        self._Projected = pt
        return
    end
    local dl = createDynamic(self)
    if IsValid(dl) then
        self._DynLight = dl
    end
end

function ENT:TurnLightOff()
    if IsValid(self._Projected) then
        self._Projected:Fire("TurnOff")
        self._Projected:Remove()
        self._Projected = nil
    end
    if IsValid(self._DynLight) then
        self._DynLight:Fire("TurnOff")
        self._DynLight:Remove()
        self._DynLight = nil
    end
end

-- ===== Lógica de encendido según Powered+Enabled =====
local function shouldBeOn(ent)
    return ent:GetPowered() and ent:GetEnabled()
end

local function applyState(ent)
    if shouldBeOn(ent) then
        ent:TurnLightOn()
    else
        ent:TurnLightOff()
    end
end

-- API usada por la red eléctrica (caja/generador)
function ENT:ApplyPower(state)
    local changed = (self:GetPowered() ~= state)
    self:SetPowered(state)
    if changed then
        applyState(self)
        self:EmitSound(state and "buttons/button17.wav" or "buttons/button18.wav")
    end
end

-- Uso con E: alterna el interruptor local (Enabled)
function ENT:Use(activator)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    if CurTime() < (self._nextUse or 0) then return end
    self._nextUse = CurTime() + 0.3

    self:SetEnabled(not self:GetEnabled())
    -- Feedback
    activator:ChatPrint(self:GetEnabled() and "Lámpara: interruptor ON" or "Lámpara: interruptor OFF")

    -- Reaplicar según Powered + Enabled
    applyState(self)
    self:EmitSound(self:GetEnabled() and "buttons/button9.wav" or "buttons/button10.wav")
end

function ENT:OnRemove()
    self:TurnLightOff()
end
