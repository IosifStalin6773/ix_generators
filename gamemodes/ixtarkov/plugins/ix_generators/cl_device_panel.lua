local openPanels = openPanels or {}

local function spacer(parent, h)
    local s = vgui.Create("DPanel", parent)
    s:SetTall(h)
    s:Dock(TOP)
    s.Paint = function() end
    return s
end

local function openDeviceFrame(entIndex)
    local frame = vgui.Create("DFrame")
    frame:SetTitle("Equipo eléctrico")
    frame:SetSize(560, 520)
    frame:Center(); frame:MakePopup()
    openPanels[entIndex] = frame

    net.Start("ix_power_device_subscribe")
        net.WriteUInt(entIndex, 16)
    net.SendToServer()
    frame.OnClose = function()
        net.Start("ix_power_device_unsubscribe")
            net.WriteUInt(entIndex, 16)
        net.SendToServer()
        openPanels[entIndex] = nil
    end

    local root = vgui.Create("DPanel", frame)
    root:Dock(FILL)
    root:DockPadding(10,10,10,10)
    root.Paint = function(self,w,h)
        surface.SetDrawColor(15,15,15,230)
        surface.DrawRect(0,0,w,h)
    end

    local voltLabel = vgui.Create("DLabel", root)
    voltLabel:Dock(TOP)
    voltLabel:SetTall(22)
    voltLabel:SetText("Voltaje")
    voltLabel:SetFont("ixGaugeTitle")
    voltLabel:SetContentAlignment(4)

    local voltGauge = vgui.Create("ixAnalogGauge", root)
    voltGauge:Dock(TOP)
    voltGauge:SetTall(200)
    voltGauge:SetTitle("")
    voltGauge:SetUnit("V")
    voltGauge:SetMin(0)
    voltGauge:SetMax(450)
    voltGauge:SetMajorStep(50)
    voltGauge:SetMinorStep(10)
    voltGauge:SetPadding(20)

    spacer(root, 12)

    local fuelLabel = vgui.Create("DLabel", root)
    fuelLabel:Dock(TOP)
    fuelLabel:SetTall(22)
    fuelLabel:SetText("Combustible")
    fuelLabel:SetFont("ixGaugeTitle")
    fuelLabel:SetContentAlignment(4)

    local fuelGauge = vgui.Create("ixAnalogGauge", root)
    fuelGauge:Dock(TOP)
    fuelGauge:SetTall(200)
    fuelGauge:SetTitle("")
    fuelGauge:SetUnit("L")
    fuelGauge:SetMin(0)
    fuelGauge:SetMax(100)
    fuelGauge:SetMajorStep(20)
    fuelGauge:SetMinorStep(5)
    fuelGauge:SetPadding(20)

    spacer(root, 8)

    local rowBtns = vgui.Create("DPanel", root)
    rowBtns:Dock(BOTTOM)
    rowBtns:SetTall(56)
    rowBtns:DockPadding(8,8,8,8)
    rowBtns.Paint = function(self,w,h)
        surface.SetDrawColor(25,25,25,240)
        surface.DrawRect(0,0,w,h)
    end

    local toggleBtn = vgui.Create("DButton", rowBtns)
    toggleBtn:Dock(LEFT)
    toggleBtn:SetWide(260)
    toggleBtn:SetText("Encender/Apagar")
    toggleBtn:SetEnabled(false)
    toggleBtn.DoClick = function()
        net.Start("ix_power_toggle")
            net.WriteUInt(entIndex, 16)
        net.SendToServer()
    end

    local refuelBtn = vgui.Create("DButton", rowBtns)
    refuelBtn:Dock(RIGHT)
    refuelBtn:SetWide(260)
    refuelBtn:SetText("Repostar +10")
    refuelBtn:SetEnabled(false)
    refuelBtn.DoClick = function()
        net.Start("ix_power_refuel")
            net.WriteUInt(entIndex, 16)
            net.WriteFloat(10)
        net.SendToServer()
    end

    function frame:ApplyData(payload)
        self:SetTitle(string.format("%s (%s)", payload.name or payload.id, payload.type))
        local volt = tonumber(payload.voltage or 0) or 0
        voltGauge:SetValue(volt)
        local cap = tonumber(payload.fuelCap or 0) or 0
        local fuel = tonumber(payload.fuel or 0) or 0
        if cap > 0 then
            fuelGauge:SetMax(cap)
            fuelGauge:SetValue(fuel)
            refuelBtn:SetEnabled(true)
        else
            fuelGauge:SetMax(100)
            fuelGauge:SetValue(0)
            refuelBtn:SetEnabled(false)
        end
        local cd = math.max(0, payload.cooldown or 0)
        if cd > 0 then
            toggleBtn:SetEnabled(false)
            toggleBtn:SetText(string.format("Cooldown (%.1fs)…", cd))
        else
            toggleBtn:SetEnabled(true)
            toggleBtn:SetText(payload.active and "Apagar" or "Encender")
        end
    end
end

net.Receive("ix_power_device_open", function()
    local entIndex = net.ReadUInt(16)
    if openPanels[entIndex] and IsValid(openPanels[entIndex]) then
        openPanels[entIndex]:MakePopup(); return
    end
    openDeviceFrame(entIndex)
end)

net.Receive("ix_power_device_data", function()
    local entIndex = net.ReadUInt(16)
    local payload = {
        id       = net.ReadString(),
        name     = net.ReadString(),
        type     = net.ReadString(),
        output   = net.ReadFloat(),
        capacity = net.ReadFloat(),
        active   = net.ReadBool(),
        stored   = net.ReadFloat(),
        fuel     = net.ReadFloat(),
        fuelCap  = net.ReadFloat(),
        voltage  = net.ReadFloat(),
        toggleCd = net.ReadFloat(),
        cooldown = net.ReadFloat()
    }
    local frame = openPanels[entIndex]
    if IsValid(frame) and frame.ApplyData then frame:ApplyData(payload) end
end)
