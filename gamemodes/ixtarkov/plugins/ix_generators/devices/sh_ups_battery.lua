if SERVER then AddCSLuaFile() end

ix.power.RegisterDevice("ups_battery", {
    printName = "UPS/Batería",
    type = "battery",
    model = "models/props_c17/substation_transformer01b.mdl",
    voltageRating = 220,
    capacity = 10000,
    output = 600,
    toggleCooldown = 1
})
