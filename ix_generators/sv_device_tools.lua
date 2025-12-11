
if SERVER then
    local function listDevicesFor(ply)
        if not ix or not ix.power or not ix.power.devices then
            ply:ChatPrint('ix.power.devices no existe — ¿se ha cargado sh_power.lua?')
            return
        end
        local count = 0
        for id, def in pairs(ix.power.devices) do
            count = count + 1
            ply:ChatPrint(string.format(' - %s (type=%s, model=%s, output=%s)', id, tostring(def.type), tostring(def.model), tostring(def.output)))
        end
        if count == 0 then
            ply:ChatPrint('No hay dispositivos registrados. Asegúrate de incluir devices/*.lua en sh_plugin.lua')
        else
            ply:ChatPrint(string.format('Total dispositivos: %d', count))
        end
    end

    ix.command.Add('PowerList', {description = 'Lista los dispositivos eléctricos registrados (debug).', adminOnly   = true, OnRun = function(self, client) listDevicesFor(client) end})
    concommand.Add('ix_power_list', function(client) if not IsValid(client) then return end; if not client:IsAdmin() then return end; listDevicesFor(client) end)
end
