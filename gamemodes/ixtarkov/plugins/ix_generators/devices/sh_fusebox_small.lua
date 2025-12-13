if SERVER then AddCSLuaFile() end

ix.power.RegisterDevice("fusebox_small", {
    printName = "Caja de Fusibles (Pequeña)",
    type = "fusebox",
    model = "models/z-o-m-b-i-e/metro_2033/electro/m33_electro_box_08.mdl",
    voltageRating = 220,
    output = 2500,
    loss = 0.02,
    perLinkLimit = 800,
    autoReset = false,
    toggleCooldown = 1
})
