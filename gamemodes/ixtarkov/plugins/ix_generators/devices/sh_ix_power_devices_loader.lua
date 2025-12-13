if SERVER then AddCSLuaFile() end

if ix and ix.util and ix.util.IncludeDir then
    ix.util.IncludeDir("devices", true, true)
    print("[ix.power] IncludeDir devices OK")
else
    local function TryInclude(name)
        if SERVER then AddCSLuaFile(name) end
        include(name)
        print("[ix.power] Device cargado: " .. name)
    end

    local files = {
        "devices/dev_gen_diesel_small.lua",
        "devices/dev_xfmr_220_110.lua",
        "devices/dev_fusebox_small.lua",
        "devices/dev_lamp.lua",
        "devices/dev_rack_server.lua",
        "devices/dev_ups_battery.lua",
    }
    for _, f in ipairs(files) do
        local ok, err = pcall(TryInclude, f)
        if not ok then
            print("[ix.power] No se pudo cargar " .. f .. ": " .. tostring(err))
        end
    end
end
