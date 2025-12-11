
-- Cliente: panel global auto-actualizable
local devicesCache = {}
local frame

local function Populate(list)
    list:Clear()
    for _, row in ipairs(devicesCache) do
        local st = row.active and "ON" or "OFF"
        local line = list:AddLine(row.name, row.type, tostring(row.output), st)
        line.DeviceData = row
    end
end

local function OpenPowerDashboard()
    if IsValid(frame) then frame:Close() end
    frame = vgui.Create("DFrame")
    frame:SetTitle("Panel de Energía (Helix)")
    frame:SetSize(780, 520)
    frame:Center()
    frame:MakePopup()

    net.Start("ix_power_subscribe")
    net.SendToServer()
    frame.OnClose = function()
        net.Start("ix_power_unsubscribe")
        net.SendToServer()
    end

    local list = vgui.Create("DListView", frame)
    list:Dock(LEFT)
    list:SetWide(440)
    list:AddColumn("Nombre")
    list:AddColumn("Tipo")
    list:AddColumn("Output")
    list:AddColumn("Estado")

    local right = vgui.Create("DPanel", frame)
    right:Dock(FILL)

    local toggleBtn = vgui.Create("DButton", right)
    toggleBtn:Dock(TOP)
    toggleBtn:SetTall(30)
    toggleBtn:SetText("Encender/Apagar seleccionado")
    toggleBtn:SetEnabled(false)
    toggleBtn.DoClick = function()
        local sel = list:GetSelectedLine()
        if not sel then return end
        local data = list:GetLine(sel).DeviceData
        net.Start("ix_power_toggle")
            net.WriteUInt(data.entIndex, 16)
        net.SendToServer()
    end

    list.OnRowSelected = function()
        local sel = list:GetSelectedLine()
        if not sel then toggleBtn:SetEnabled(false); return end
        local data = list:GetLine(sel).DeviceData
        local cd = math.max(0, tonumber(data.cooldown or 0))
        if cd > 0 then
            toggleBtn:SetEnabled(false)
            toggleBtn:SetText(string.format("En cooldown (%.1fs)…", cd))
        else
            toggleBtn:SetEnabled(true)
            toggleBtn:SetText("Encender/Apagar seleccionado")
        end
    end

    list.Populate = function() Populate(list) end
    list.Populate()
end

net.Receive("ix_power_devices", function()
    local n = net.ReadUInt(16)
    devicesCache = {}
    for i=1, n do
        local entIndex = net.ReadUInt(16)
        local id = net.ReadString()
        local name = net.ReadString()
        local type_ = net.ReadString()
        local output = net.ReadFloat()
        local capacity = net.ReadFloat()
        local pos = net.ReadVector()
        local active = net.ReadBool()
        local stored = net.ReadFloat()
        local cooldown = net.ReadFloat()
        local toggleCd = net.ReadFloat()
        table.insert(devicesCache, {
            entIndex=entIndex, id=id, name=name, type=type_, output=output,
            capacity=capacity, pos=pos, active=active, stored=stored,
            cooldown=cooldown, toggleCd=toggleCd
        })
    end
    if not IsValid(frame) then OpenPowerDashboard() else
        for _, child in ipairs(frame:GetChildren()) do
            if child:GetClassName() == "DListView" and child.Populate then child:Populate() end
        end
    end
end)
