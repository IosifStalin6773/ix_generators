
ix.power = ix.power or {}
local originalRegister = ix.power.RegisterDevice
if originalRegister then
    function ix.power.RegisterDevice(id, def)
        local ret = originalRegister(id, def)
        if SERVER then
            print(string.format('[ix_generators] Registrado dispositivo: %s', tostring(id)))
        end
        return ret
    end
else
    if SERVER then
        print('[ix_generators][ADVERTENCIA] sh_power.lua debe cargarse antes de sh_power_wrap.lua')
    end
end
