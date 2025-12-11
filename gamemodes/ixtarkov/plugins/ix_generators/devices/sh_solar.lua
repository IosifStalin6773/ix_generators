
ix.power.RegisterDevice("solar_panel", {
    type           = "generator",
    printName      = "Panel Solar",
    model          = "models/props/de_train/Utility02.mdl",
    output         = 50,
    interval       = 2.0,
    spawnable      = true,
    voltageRating  = 220,
    toggleCooldown = 3,
    fuelCapacity   = 0,
})
