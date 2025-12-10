
include("shared.lua")

local function hasNVMethods(ent)
    -- Verifica que los métodos de NetworkVar existan en el cliente
    return isfunction(ent.GetFuel) and isfunction(ent.GetActive) and isfunction(ent.GetOutput)
end

function ENT:Draw()
    self:DrawModel()

    -- Evita spam de errores si aún no están los getters generados
    if not hasNVMethods(self) then return end

    local pos = self:GetPos() + Vector(0,0,50)
    local ang = LocalPlayer():EyeAngles()
    ang:RotateAroundAxis(ang:Right(), 90)
    ang:RotateAroundAxis(ang:Up(), 90)

    local fuel = self:GetFuel() or 0

    cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.1)
        draw.RoundedBox(6, -120, -40, 240, 80, Color(20,20,20,180))
        draw.SimpleText("Generador", "DermaDefaultBold", 0, -20, Color(255,255,255), TEXT_ALIGN_CENTER)
        draw.SimpleText("Combustible: ".. fuel .." mL", "DermaDefault", 0, 10, Color(200,220,255), TEXT_ALIGN_CENTER)
    cam.End3D2D()
end
