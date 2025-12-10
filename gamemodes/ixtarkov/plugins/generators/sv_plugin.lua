
local PLUGIN = PLUGIN

function PLUGIN:SaveData()
    local gens, lamps = {}, {}

    for _, ent in ipairs(ents.FindByClass("ix_generator")) do
        gens[#gens+1] = {
            pos = ent:GetPos(),
            ang = ent:GetAngles(),
            fuel = ent:GetFuel(),
            active = ent:GetActive(),
            output = ent:GetOutput(),
        }
    end

    for _, ent in ipairs(ents.FindByClass("ix_floodlight")) do
        lamps[#lamps+1] = {
            pos = ent:GetPos(),
            ang = ent:GetAngles(),
        }
    end

    local fuseboxes = {}
    for _, ent in ipairs(ents.FindByClass("ix_fusebox")) do
        local gen = ent:GetGenerator()
        fuseboxes[#fuseboxes+1] = {
            pos = ent:GetPos(),
            ang = ent:GetAngles(),
            genPos = IsValid(gen) and gen:GetPos() or nil, -- referencia por posición
        }
    end
    ix.data.Set("camp_fuseboxes", fuseboxes)

    ix.data.Set("camp_generators", gens)
    ix.data.Set("camp_floodlights", lamps)
end

function PLUGIN:LoadData()
    for _, data in ipairs(ix.data.Get("camp_generators", {})) do
        local ent = ents.Create("ix_generator")
        if not IsValid(ent) then continue end
        ent:SetPos(data.pos)
        ent:SetAngles(data.ang)
        ent:Spawn()
        ent:SetFuel(data.fuel or 0)
        ent:SetOutput(data.output or ix.config.Get("defaultGeneratorOutput", 1500))
        ent:SetActive(data.active or false)
    end

    for _, data in ipairs(ix.data.Get("camp_floodlights", {})) do
        local ent = ents.Create("ix_floodlight")
        if not IsValid(ent) then continue end
        ent:SetPos(data.pos)
        ent:SetAngles(data.ang)
        ent:Spawn()
    end
    
    for _, data in ipairs(ix.data.Get("camp_fuseboxes", {})) do
        local ent = ents.Create("ix_fusebox")
        if not IsValid(ent) then continue end
        ent:SetPos(data.pos)
        ent:SetAngles(data.ang)
        ent:Spawn()

        -- Reasociar al generador más cercano a la posición guardada (si existe)
        if data.genPos then
            local nearest = nil
            local best = math.huge
            for _, g in ipairs(ents.FindByClass("ix_generator")) do
                local d = g:GetPos():DistToSqr(data.genPos)
                if d < best then best = d; nearest = g end
            end
            if IsValid(nearest) then
                ent:SetGenerator(nearest)
            end
        end
    end

end