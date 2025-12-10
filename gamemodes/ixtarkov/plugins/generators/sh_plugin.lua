
local PLUGIN = PLUGIN
PLUGIN.name = "Generators & Camp Power"
PLUGIN.author = "IosifStalin6773"
PLUGIN.description = "Generadores y dispositivos eléctricos para campamentos."

-- Configuraciones editables
ix.config.Add("generatorFuelBurnRate", 0.05, "Litros por segundo a potencia nominal.", nil, {
    category = "Camp Power", min = 0, max = 1, decimals = 3
})

ix.config.Add("maxCableLength", 900, "Longitud máxima de cable (unidades).", nil, {
    category = "Camp Power", min = 100, max = 3000, decimals = 0
})

ix.config.Add("defaultGeneratorOutput", 1500, "Potencia nominal del generador (W).", nil, {
    category = "Camp Power", min = 100, max = 10000, decimals = 0
})

ix.util.Include("sv_plugin.lua")
ix.util.Include("cl_plugin.lua")
