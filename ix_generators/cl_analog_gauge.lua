
local PANEL = {}

surface.CreateFont("ixGaugeTitle", {font="Tahoma", size=18, weight=800, antialias=true})
surface.CreateFont("ixGaugeUnit",  {font="Tahoma", size=24, weight=900, antialias=true})
surface.CreateFont("ixGaugeNum",   {font="Tahoma", size=13, weight=700, antialias=true})

function PANEL:Init()
    self:SetTall(200)
    self.min = 0
    self.max = 100
    self.value = 0
    self.displayValue = 0
    self.title = ""
    self.unit = ""
    self.majorStep = 20
    self.minorStep = 5
    self.angleStart = math.rad(180) -- arco superior limpio (180° a 0°)
    self.angleEnd   = math.rad(0)
    self.tickLenMinor = 8
    self.tickLenMajor = 16
    self.padding = 18
    self.backColor = Color(20,20,20,240)
    self.gridColorMinor = Color(170,170,170,160)
    self.gridColorMajor = Color(220,220,220,220)
    self.needleColor = Color(255,60,60,255)
    self.arcColor = Color(120,120,120,140)
end

function PANEL:SetMin(v) self.min = v end
function PANEL:SetMax(v) self.max = v end
function PANEL:SetValue(v) self.value = tonumber(v) or 0 end
function PANEL:SetTitle(t) self.title = t or "" end
function PANEL:SetUnit(u) self.unit = u or "" end
function PANEL:SetMajorStep(s) self.majorStep = s or self.majorStep end
function PANEL:SetMinorStep(s) self.minorStep = s or self.minorStep end
function PANEL:SetAngleRange(degStart, degEnd)
    self.angleStart = math.rad(degStart)
    self.angleEnd   = math.rad(degEnd)
end
function PANEL:SetPadding(p) self.padding = p or self.padding end

local function lerp(a, b, t) return a + (b - a) * t end
function PANEL:ValueToAngle(val)
    local t = 0
    if self.max > self.min then
        t = math.Clamp((val - self.min) / (self.max - self.min), 0, 1)
    end
    return lerp(self.angleStart, self.angleEnd, t)
end

local function drawArc(cx, cy, r, a1, a2, step, col)
    surface.SetDrawColor(col)
    local prevx, prevy
    if a1 > a2 then step = -math.abs(step) else step = math.abs(step) end
    for a = a1, a2, step do
        local x = cx + math.cos(a) * r
        local y = cy + math.sin(a) * r
        if prevx then surface.DrawLine(prevx, prevy, x, y) end
        prevx, prevy = x, y
    end
end

function PANEL:Paint(w, h)
    surface.SetDrawColor(self.backColor)
    surface.DrawRect(0,0,w,h)

    local pad = self.padding
    local cx = w * 0.5
    local cy = h - pad - 70
    local r  = math.min(w - pad*18, h - pad*18) * 0.55

    draw.SimpleText(self.title or "", "ixGaugeTitle", pad, pad, color_white)
    drawArc(cx, cy, r, self.angleStart, self.angleEnd, 0.03, self.arcColor)
    draw.SimpleText(self.unit or "", "ixGaugeUnit", cx, cy - r*0.20, color_white, TEXT_ALIGN_CENTER)

    local function drawTick(angle, len, col)
        local x1 = cx + math.cos(angle) * (r - len)
        local y1 = cy + math.sin(angle) * (r - len)
        local x2 = cx + math.cos(angle) * (r)
        local y2 = cy + math.sin(angle) * (r)
        surface.SetDrawColor(col)
        surface.DrawLine(x1, y1, x2, y2)
    end

    local stepMinor = self.minorStep
    if stepMinor and stepMinor > 0 then
        for v = self.min, self.max, stepMinor do
            local a = self:ValueToAngle(v)
            drawTick(a, self.tickLenMinor, self.gridColorMinor)
        end
    end

    local stepMajor = self.majorStep
    if stepMajor and stepMajor > 0 then
        for v = self.min, self.max, stepMajor do
            local a = self:ValueToAngle(v)
            drawTick(a, self.tickLenMajor, self.gridColorMajor)
            local tx = cx + math.cos(a) * (r + 18)
            local ty = cy + math.sin(a) * (r + 18)
            draw.SimpleText(tostring(v), "ixGaugeNum", tx, ty, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    self.displayValue = math.Approach(self.displayValue, self.value, (self.max - self.min) * FrameTime() * 0.5)
    local ang = self:ValueToAngle(self.displayValue)
    local nx  = cx + math.cos(ang) * (r - 4)
    local ny  = cy + math.sin(ang) * (r - 4)
    surface.SetDrawColor(self.needleColor)
    surface.DrawLine(cx, cy, nx, ny)
    surface.SetDrawColor(255,255,255,255)
    surface.DrawCircle(cx, cy, 3, 255,255,255,255)
    surface.SetDrawColor(60,60,60,200)
    surface.DrawRect(0, h-3, w, 3)
end

vgui.Register("ixAnalogGauge", PANEL, "DPanel")
