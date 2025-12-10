
-- Evita registrar dos veces el net.Receive si hay hot-reload
if CLIENT and _G.IXCampPower_GeneratorUI_Registered then return end
_G.IXCampPower_GeneratorUI_Registered = true

local function openGeneratorUI(ent)
    if not IsValid(ent) then return end

    -- Cierra la ventana previa si ya existe (singleton)
    if IsValid(_G.ix_camp_genFrame) then
        _G.ix_camp_genFrame:Close()
        _G.ix_camp_genFrame = nil
    end

    local frm = vgui.Create("DFrame")
    _G.ix_camp_genFrame = frm
    frm:SetTitle("Generador")
    frm:SetSize(300, 180)
    frm:Center()
    frm:MakePopup()

    local fuel = isfunction(ent.GetFuel) and (ent:GetFuel() or 0) or 0
    local output = isfunction(ent.GetOutput) and (ent:GetOutput() or 0) or 0
    local active = isfunction(ent.GetActive) and ent:GetActive() or false

    local lbl = vgui.Create("DLabel", frm)
    lbl:SetPos(16, 40)
    lbl:SetText("Combustible: " .. fuel .. " mL")
    lbl:SizeToContents()

    local lbl2 = vgui.Create("DLabel", frm)
    lbl2:SetPos(16, 60)
    lbl2:SetText("Salida: " .. output .. " W")
    lbl2:SizeToContents()

    local btn = vgui.Create("DButton", frm)
    btn:SetPos(16, 90)
    btn:SetSize(120, 28)
    btn:SetText(active and "Apagar" or "Encender")
    function btn:DoClick()
        if not IsValid(ent) then frm:Close() return end
        net.Start("ix_camp_toggleGenerator")
            net.WriteEntity(ent)
        net.SendToServer()
        frm:Close()
        _G.ix_camp_genFrame = nil
    end

    -- Si el generador actualiza los NetworkVars, refrescamos los labels cada 0.5s
    local tick = 0
    function frm:Think()
        tick = tick + FrameTime()
        if tick > 0.5 then
            tick = 0
            if not IsValid(ent) then self:Close() _G.ix_camp_genFrame = nil return end
            local nf = isfunction(ent.GetFuel) and (ent:GetFuel() or 0) or fuel
            local no = isfunction(ent.GetOutput) and (ent:GetOutput() or 0) or output
            lbl:SetText("Combustible: " .. nf .. " mL")
            lbl:SizeToContents()
            lbl2:SetText("Salida: " .. no .. " W")
            lbl2:SizeToContents()
        end
    end
end

-- Registrar el receptor una sola vez (gracias al guardia de arriba)
net.Receive("ix_camp_openGeneratorUI", function()
    local ent = net.ReadEntity()
    openGeneratorUI(ent)
end)
