if SERVER then AddCSLuaFile() end

ix.power.RegisterDevice("rack_server", {
    printName = "Rack de Servidores",
    type = "consumer",
    model = "models/props_lab/servers.mdl",
    voltageRating = 220,
    output = 1200,
    toggleCooldown = 1
})
