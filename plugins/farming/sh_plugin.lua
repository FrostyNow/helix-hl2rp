local PLUGIN = PLUGIN

PLUGIN.name = "Farming"
PLUGIN.author = "Antigravity"
PLUGIN.description = "A plugin that allows players to grow crops in a farm box."

-- 3 in-game days = 3 * 24 * 60 * 60 seconds (unless time passed is different, let's assume default IRL time for growth)
ix.config.Add("cropGrowthTime", 259200, "작물이 다 자라는데 기본적으로 걸리는 시간(초)입니다. 기본값: 3일(259200초)", nil, {
    data = {min = 1, max = 5000000},
    category = "Farming"
})

if (SERVER) then
    function PLUGIN:SaveData()
        local data = {}

        for _, v in ipairs(ents.FindByClass("ix_farmbox")) do
            data[#data + 1] = {
                v:GetPos(),
                v:GetAngles(),
                v:GetCropType(),
                v:GetWaterAmount(),
                v:GetHasFertilizer(),
                v:GetProgress()
            }
        end

        self:SetData(data)
    end

    function PLUGIN:LoadData()
        local data = self:GetData()

        if (data) then
            for _, v in ipairs(data) do
                local entity = ents.Create("ix_farmbox")
                entity:SetPos(v[1])
                entity:SetAngles(v[2])
                entity:Spawn()

                entity:SetCropType(v[3] or "")
                entity:SetWaterAmount(v[4] or 0)
                entity:SetHasFertilizer(v[5] or false)
                entity:SetProgress(v[6] or 0)
                
                local phys = entity:GetPhysicsObject()

                if (IsValid(phys)) then
                    phys:EnableMotion(false)
                end
            end
        end
    end
end
