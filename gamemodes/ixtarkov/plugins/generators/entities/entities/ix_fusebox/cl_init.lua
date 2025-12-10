
include("shared.lua")

-- Evita doble registro en hot-reloads
if CLIENT and _G.IXCampPower_FuseUI_Registered then return end
_G.IXCampPower_FuseUI_Registered = true

local function buildFuseUI(fuseEnt, genEnt, linkArray)
    if not IsValid(fuseEnt) or not IsValid(genEnt) then return end

    if IsValid(_G.ix_camp_fuseFrame) then
        _G.ix_camp_fuseFrame:Close()
        _G.ix_camp_fuseFrame = nil
    end

    local frm = vgui.Create("DFrame")
    _G.ix_camp_fuseFrame = frm
    frm:SetTitle("Caja de Fusibles")
    frm:SetSize(440, 400)
    frm:Center()
    frm:MakePopup()

    local lbl = vgui.Create("DLabel", frm)
    lbl:SetPos(16, 36)
    lbl:SetText("Generador vinculado: " .. (IsValid(genEnt) and genEnt:GetClass() or "N/A"))
    lbl:SizeToContents()

    local scroll = vgui.Create("DScrollPanel", frm)
    scroll:SetPos(16, 64)
    scroll:SetSize(408, 316)

    for _, ent in ipairs(linkArray) do
        if not IsValid(ent) then continue end

        local row = vgui.Create("DPanel", scroll)
        row:SetTall(44)
        row:Dock(TOP)
        row:DockMargin(0, 0, 0, 8)
        function row:Paint(w, h)
            surface.SetDrawColor(35, 35, 35, 200)
            surface.DrawRect(0, 0, w, h)
        end

        local name = (ent.PrintName or ent:GetClass())
        local dist = IsValid(genEnt) and math.floor(ent:GetPos():Distance(genEnt:GetPos())) or 0

        local lblName = vgui.Create("DLabel", row)
        lblName:SetPos(10, 12)
        lblName:SetText(name .. "  (" .. dist .. "u)")
        lblName:SizeToContents()

        local btn = vgui.Create("DButton", row)
        btn:SetSize(120, 28)
        btn:SetPos(270, 8)
        btn:SetText("Desconectar")
        function btn:DoClick()
            if not IsValid(fuseEnt) or not IsValid(genEnt) then frm:Close() return end
            net.Start("ix_camp_disconnectLink")
                net.WriteEntity(fuseEnt)
                net.WriteEntity(genEnt)
                net.WriteEntity(ent)
            net.SendToServer()
        end
    end
end

net.Receive("ix_camp_openFuseBox", function()
    local fuse = net.ReadEntity()
    local gen  = net.ReadEntity()
    local count = net.ReadUInt(8)
    local links = {}
    for i = 1, count do
        local e = net.ReadEntity()
        if IsValid(e) then table.insert(links, e) end
    end
    buildFuseUI(fuse, gen, links)
end)

net.Receive("ix_camp_fusebox_refresh", function()
    local fuse = net.ReadEntity()
    local gen  = net.ReadEntity()
    local count = net.ReadUInt(8)
    local links = {}
    for i = 1, count do
        local e = net.ReadEntity()
        if IsValid(e) then table.insert(links, e) end
    end
    buildFuseUI(fuse, gen, links)
end)

function ENT:Draw()
    self:DrawModel()
end