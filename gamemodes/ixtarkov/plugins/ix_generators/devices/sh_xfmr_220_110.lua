if SERVER then AddCSLuaFile() end

ix.power.RegisterDevice("xfmr_220_110", {
    printName = "Transformador 220->110",
    type = "transformer",
    model = "models/props_c17/substation_transformer01a.mdl",
    voltageIn = 220,
    voltageOut = 110,
    efficiency = 0.9,
    maxThroughput = 2000,
    toggleCooldown = 1
})
