
if SERVER then
    util.AddNetworkString("ix_power_devices")
    util.AddNetworkString("ix_power_toggle")
    util.AddNetworkString("ix_power_subscribe")
    util.AddNetworkString("ix_power_unsubscribe")

    util.AddNetworkString("ix_power_device_open")
    util.AddNetworkString("ix_power_device_subscribe")
    util.AddNetworkString("ix_power_device_unsubscribe")
    util.AddNetworkString("ix_power_device_data")
    util.AddNetworkString("ix_power_refuel")

    util.AddNetworkString("ix_power_link_pick")

    local subscribers = subscribers or {}
    local deviceSubs  = deviceSubs  or {}
    local linkSessions = linkSessions or {} -- [ply] = {first=entIndex}

    local function snapshot()
        local list = {}
        for _, ent in ipairs(ents.FindByClass("ix_power_device")) do
            if IsValid(ent) then
                local id  = ent:GetDeviceID() or "unknown"
                local def = ix.power.GetDevice(id) or {}
                local cooldownRemaining = 0
                if ent.nextToggle then cooldownRemaining = math.max(0, ent.nextToggle - CurTime()) end
                local links = 0
                local tbl = ix.power.links[ent:EntIndex()] or {}
                for _ in pairs(tbl) do links = links + 1 end
                table.insert(list, {
                    entIndex = ent:EntIndex(),
                    id       = id,
                    name     = def.printName or id,
                    type     = def.type or "generator",
                    output   = def.output or 0,
                    capacity = def.capacity or 0,
                    pos      = ent:GetPos(),
                    active   = ent:GetActive(),
                    stored   = ent:GetStored(),
                    cooldown = cooldownRemaining,
                    toggleCd = def.toggleCooldown or 3,
                    links    = links
                })
            end
        end
        return list
    end

    local function broadcast(devlist, target)
        local function send(toClient)
            net.Start("ix_power_devices")
                net.WriteUInt(#devlist, 16)
                for _, row in ipairs(devlist) do
                    net.WriteUInt(row.entIndex, 16)
                    net.WriteString(row.id)
                    net.WriteString(row.name)
                    net.WriteString(row.type)
                    net.WriteFloat(row.output)
                    net.WriteFloat(row.capacity)
                    net.WriteVector(row.pos)
                    net.WriteBool(row.active)
                    net.WriteFloat(row.stored)
                    net.WriteFloat(row.cooldown)
                    net.WriteFloat(row.toggleCd)
                end
            net.Send(toClient)
        end
        if target then send(target) else for ply,_ in pairs(subscribers) do if IsValid(ply) then send(ply) end end end
    end

    local function sendDeviceData(ent, target)
        if not IsValid(ent) or ent:GetClass() ~= "ix_power_device" then return end
        local id  = ent:GetDeviceID() or "unknown"
        local def = ix.power.GetDevice(id) or {}
        local payload = {
            entIndex   = ent:EntIndex(),
            id         = id,
            name       = def.printName or id,
            type       = def.type or "generator",
            output     = def.output or 0,
            capacity   = def.capacity or 0,
            active     = ent:GetActive(),
            stored     = ent:GetStored(),
            fuel       = ent.GetFuel and ent:GetFuel() or 0,
            fuelCap    = ent.GetFuelCapacity and ent:GetFuelCapacity() or 0,
            voltage    = ent.GetVoltage and ent:GetVoltage() or 0,
            toggleCd   = def.toggleCooldown or 3,
            cooldown   = math.max(0, (ent.nextToggle or 0) - CurTime())
        }
        local function writePayload(ply)
            net.Start("ix_power_device_data")
                net.WriteUInt(payload.entIndex, 16)
                net.WriteString(payload.id)
                net.WriteString(payload.name)
                net.WriteString(payload.type)
                net.WriteFloat(payload.output)
                net.WriteFloat(payload.capacity)
                net.WriteBool(payload.active)
                net.WriteFloat(payload.stored)
                net.WriteFloat(payload.fuel)
                net.WriteFloat(payload.fuelCap)
                net.WriteFloat(payload.voltage)
                net.WriteFloat(payload.toggleCd)
                net.WriteFloat(payload.cooldown)
            net.Send(ply)
        end
        if target then writePayload(target) else
            local subs = deviceSubs[payload.entIndex]
            if subs then for ply,_ in pairs(subs) do if IsValid(ply) then writePayload(ply) end end end
        end
    end

    -- Helpers de cable
    local function makeRope(ent1, ent2)
        if not IsValid(ent1) or not IsValid(ent2) then return end
        local lpos1 = ent1:OBBCenter()
        local lpos2 = ent2:OBBCenter()
        local length = ent1:GetPos():Distance(ent2:GetPos())
        local _, rope = constraint.Rope(ent1, ent2, 0, 0, lpos1, lpos2, length, 0, 0, 2, "cable/rope", false)
        return rope
    end

    local function removeRopesFor(genIdx)
        local m = ix.power.ropes[genIdx]
        if m then
            for _, rope in pairs(m) do if IsValid(rope) then rope:Remove() end end
            ix.power.ropes[genIdx] = nil
        end
    end

    -- Suscripción panel global
    net.Receive("ix_power_subscribe", function(_, ply)
        subscribers[ply] = true
        broadcast(snapshot(), ply)
    end)
    net.Receive("ix_power_unsubscribe", function(_, ply)
        subscribers[ply] = nil
    end)

    -- Suscripción panel por entidad
    net.Receive("ix_power_device_subscribe", function(_, ply)
        local entIndex = net.ReadUInt(16)
        deviceSubs[entIndex] = deviceSubs[entIndex] or {}
        deviceSubs[entIndex][ply] = true
        local ent = Entity(entIndex)
        if IsValid(ent) then sendDeviceData(ent, ply) end
    end)
    net.Receive("ix_power_device_unsubscribe", function(_, ply)
        local entIndex = net.ReadUInt(16)
        local subs = deviceSubs[entIndex]
        if subs then subs[ply] = nil end
    end)

    -- Toggle
    net.Receive("ix_power_toggle", function(_, ply)
        local entIndex = net.ReadUInt(16)
        local ent = Entity(entIndex)
        if not IsValid(ent) or ent:GetClass() ~= "ix_power_device" then return end
        if ent.AttemptToggle then ent:AttemptToggle(ply) end
        broadcast(snapshot())
        sendDeviceData(ent)
    end)

    -- Pick: crear/guardar enlace y cable
    net.Receive("ix_power_link_pick", function(_, ply)
        if not ply:GetNWBool("ix_power_tool_equipped", false) then
            ply:ChatPrint("Equipa las herramientas de conexión para enlazar.")
            return
        end
        local vStart   = ply:GetShootPos()
        local vForward = ply:GetAimVector()
        local tr = util.TraceLine({start = vStart, endpos = vStart + vForward * 2048, filter = ply})
        local ent = tr.Entity
        if not IsValid(ent) or ent:GetClass() ~= "ix_power_device" then ply:ChatPrint("Mira a un equipo válido."); return end
        local sess = linkSessions[ply] or {}
        if not sess.first then
            sess.first = ent:EntIndex(); linkSessions[ply] = sess
            ply:ChatPrint("Origen seleccionado. Ahora selecciona el consumidor.")
        else
            local a = sess.first; local b = ent:EntIndex(); linkSessions[ply] = nil
            if a == b then ply:ChatPrint("El destino no puede ser el mismo."); return end
            ix.power.links[a] = ix.power.links[a] or {}; ix.power.links[a][b] = true
            -- Cable físico
            local entA, entB = Entity(a), Entity(b)
            local rope = makeRope(entA, entB)
            ix.power.ropes[a] = ix.power.ropes[a] or {}; ix.power.ropes[a][b] = rope
            -- Persistencia por mapa (ID + posición)
            local idA = IsValid(entA) and entA:GetDeviceID() or ""
            local idB = IsValid(entB) and entB:GetDeviceID() or ""
            table.insert(ix.power.persist, {a={id=idA,pos=entA:GetPos()}, b={id=idB,pos=entB:GetPos()}})
            ix.power.SaveLinks()
            ply:ChatPrint("Enlace creado.")
            broadcast(snapshot())
        end
    end)

    -- Limpieza de enlaces del generador al que miras (y cables)
    concommand.Add("ix_power_link_clear", function(ply)
        local vStart   = ply:GetShootPos(); local vForward = ply:GetAimVector()
        local tr = util.TraceLine({start = vStart, endpos = vStart + vForward * 2048, filter = ply})
        local ent = tr.Entity
        if not IsValid(ent) or ent:GetClass() ~= "ix_power_device" then ply:ChatPrint("Mira a un generador válido."); return end
        local genIdx = ent:EntIndex()
        ix.power.links[genIdx] = nil
        removeRopesFor(genIdx)
        -- borrar persistentes que tengan este origen
        local keep = {}
        for _, rec in ipairs(ix.power.persist or {}) do
            if rec.a and rec.a.id ~= (ent:GetDeviceID() or "") then table.insert(keep, rec) end
        end
        ix.power.persist = keep; ix.power.SaveLinks()
        ply:ChatPrint("Enlaces borrados.")
        broadcast(snapshot())
    end)

    -- Restaurar enlaces persistentes tras cargar el mapa
    local function tryRestore()
        for _, rec in ipairs(ix.power.persist or {}) do
            if not rec.bound then
                -- Buscar entidades por id y proximidad
                local closestA, dA
                local closestB, dB
                for _, e in ipairs(ents.FindByClass("ix_power_device")) do
                    local id = e:GetDeviceID() or ""
                    if id == (rec.a and rec.a.id or "") then
                        local d = e:GetPos():Distance(rec.a.pos or e:GetPos())
                        if not dA or d < dA then closestA, dA = e, d end
                    end
                    if id == (rec.b and rec.b.id or "") then
                        local d = e:GetPos():Distance(rec.b.pos or e:GetPos())
                        if not dB or d < dB then closestB, dB = e, d end
                    end
                end
                if IsValid(closestA) and IsValid(closestB) and dA < 128 and dB < 128 then
                    local a = closestA:EntIndex(); local b = closestB:EntIndex()
                    ix.power.links[a] = ix.power.links[a] or {}; ix.power.links[a][b] = true
                    local rope = makeRope(closestA, closestB)
                    ix.power.ropes[a] = ix.power.ropes[a] or {}; ix.power.ropes[a][b] = rope
                    rec.bound = true
                end
            end
        end
    end

    hook.Add("InitPostEntity", "ix_power_restore_links", function()
        ix.power.LoadLinks()
        timer.Create("ix_power_restore_tick", 1.0, 15, tryRestore)
    end)

    -- Broadcast periódico
    timer.Create("ix_power_broadcast", 1.0, 0, function()
        local list = snapshot(); broadcast(list)
        for _, ent in ipairs(ents.FindByClass("ix_power_device")) do
            if deviceSubs[ent:EntIndex()] then sendDeviceData(ent) end
        end
    end)

    -- Comandos de spawn (fix de spawn)
    local function spawnDevice(client, deviceID)
        local def = ix.power.GetDevice(deviceID)
        if not def then return false, "Dispositivo no encontrado: " .. tostring(deviceID) end
        local vStart   = client:GetShootPos(); local vForward = client:GetAimVector()
        local tr = util.TraceLine({start = vStart, endpos = vStart + vForward * 2048, filter = client})
        local pos = tr.HitPos + tr.HitNormal * 8
        local ent = ents.Create("ix_power_device")
        if not IsValid(ent) then return false, "No se pudo crear la entidad." end
        ent:SetDeviceID(deviceID); ent:SetPos(pos); ent:SetAngles(Angle(0, client:EyeAngles().y, 0)); ent:Spawn()
        return true, "Spawn: " .. deviceID
    end

    ix.command.Add("PowerSpawn", {description = "Spawnea un dispositivo eléctrico donde estás mirando.", adminOnly   = true, arguments   = {ix.type.string}, OnRun = function(self, client, deviceID) local ok, msg = spawnDevice(client, deviceID); return msg end})
    ix.command.Add("power_spawn", {description = "Alias de PowerSpawn.", adminOnly   = true, arguments   = {ix.type.string}, OnRun = function(self, client, deviceID) local ok, msg = spawnDevice(client, deviceID); return msg end})
    ix.command.Add("PowerUI", {description = "Abre el panel global de energía.", adminOnly   = true, OnRun = function(self, client) subscribers[client] = true; broadcast(snapshot(), client); return "Panel solicitado." end})
    concommand.Add("ix_power_spawn", function(client, cmd, args) if not IsValid(client) or not client:IsAdmin() then return end; local deviceID = args and (args[1] or args[0]) or nil; if not deviceID then client:ChatPrint("Uso: ix_power_spawn <deviceID>"); return end; local ok, msg = spawnDevice(client, deviceID); client:ChatPrint(msg or "") end)
end
