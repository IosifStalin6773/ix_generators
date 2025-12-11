
ix.power = ix.power or {}
ix.power.VERSION = 5.3
ix.power.devices = ix.power.devices or {}
ix.power.links   = ix.power.links   or {} -- [genEntIndex] = {consumerEntIndex=true,...}
ix.power.ropes   = ix.power.ropes   or {} -- [genEntIndex] = {[consumerEntIndex]=ropeEnt}
ix.power.persist = ix.power.persist or {} -- array of {a={id,pos}, b={id,pos}}

function ix.power.RegisterDevice(id, def)
    assert(isstring(id), "ix.power.RegisterDevice: id debe ser string")
    assert(istable(def), "ix.power.RegisterDevice: def debe ser tabla")

    def.type           = def.type or "generator"
    def.model          = def.model or "models/props_c17/TrapPropeller_Engine.mdl"
    def.output         = def.output or 0
    def.capacity       = def.capacity or 0
    def.interval       = def.interval or 1.0
    def.spawnable      = def.spawnable ~= false
    def.printName      = def.printName or id
    def.toggleCooldown = def.toggleCooldown or 3
    def.voltageRating  = def.voltageRating or 220
    def.fuelCapacity   = def.fuelCapacity or 0
    def.startFuel      = def.startFuel or def.fuelCapacity
    def.fuelPerTick    = def.fuelPerTick or 0

    ix.power.devices[id] = def
    return def
end

function ix.power.GetDevice(id)
    return ix.power.devices[id]
end

-- Persistencia con ix.data (por mapa)
function ix.power.SaveLinks()
    if ix and ix.data and ix.data.Set then
        ix.data.Set("power_links", ix.power.persist, false, false)
    end
end

function ix.power.LoadLinks()
    if ix and ix.data and ix.data.Get then
        ix.power.persist = ix.data.Get("power_links", {}, false, false, true) or {}
    end
end
