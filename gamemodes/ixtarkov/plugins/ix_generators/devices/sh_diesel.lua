
ix.power.RegisterDevice("diesel_generator", {
    type           = "generator",
    printName      = "Generador Diésel",
    model          = "models/props_c17/TrapPropeller_Engine.mdl",
    output         = 120,
    interval       = 1.0,
    spawnable      = true,
    voltageRating  = 220,
    toggleCooldown = 5,
    fuelCapacity   = 100,
    startFuel      = 100,
    fuelPerTick    = 1,
})
