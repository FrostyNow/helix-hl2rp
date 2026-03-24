include("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

function ENT:Initialize()
    self:SetModel("models/noble/limelight/farmbox.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

    local phys = self:GetPhysicsObject()
    if (IsValid(phys)) then
        phys:Wake()
        phys:EnableMotion(true)
    end

    self:SetCropType("")
    self:SetProgress(0)
    self:SetWaterAmount(0)
    self:SetHasFertilizer(false)
    self:SetWaterQuality(0)
end

function ENT:Think()
    local cropType = self:GetCropType()
    
    if (cropType != "") then
        local baseTime = 3 * 24 * 60 * ix.config.Get("secondsPerMinute", 60)
        local growthTime = ix.config.Get("cropGrowthTime", baseTime)
        
        if (self:GetHasFertilizer()) then
            growthTime = growthTime / 2
        end
        
        -- 물이 있어야만 작물이 자랍니다. (1 이상의 물 수치가 있을 때)
        if (self:GetWaterAmount() > 0) then
            self:SetProgress(math.min(self:GetProgress() + 1, growthTime))
            
            -- 한 시간에 1 정도의 물이 마른다고 가정 (3600초)
            if (math.random(1, 3600) == 1) then
                self:SetWaterAmount(self:GetWaterAmount() - 1)
            end
        end
    end

    self:NextThink(CurTime() + 1)
    return true
end

function ENT:Use(activator)
    if (self:GetCropType() != "") then
        local baseTime = 3 * 24 * 60 * ix.config.Get("secondsPerMinute", 60)
        local growthTime = ix.config.Get("cropGrowthTime", baseTime)
        if (self:GetHasFertilizer()) then growthTime = growthTime / 2 end
        
        if (self:GetProgress() >= growthTime) then
            -- 수확!
            local amount = 1
            if (self:GetWaterQuality() > 0) then
                local chance = math.Clamp(self:GetWaterQuality() * 20, 0, 80)
                if (math.random(1, 100) <= chance) then
                    amount = math.random(2, 3)
                end
            end
            
            for i = 1, amount do
                ix.item.Spawn(self:GetCropType(), self:GetPos() + Vector(0, 0, 20 + i * 5))
            end
            
            local cropName = "(?)"
            if (self:GetCropType() == "carrot") then cropName = L("cropCarrot", activator)
            elseif (self:GetCropType() == "corn") then cropName = L("cropCorn", activator)
            elseif (self:GetCropType() == "potato") then cropName = L("cropPotato", activator)
            elseif (self:GetCropType() == "wheat") then cropName = L("cropWheat", activator) end

            self:SetCropType("")
            self:SetProgress(0)
            self:SetHasFertilizer(false)
            self:SetWaterQuality(0)
            -- 물은 조금 남겨두어도 됨

            activator:NotifyLocalized("farmHarvestSuccess", cropName, amount)
        else
            if (self:GetWaterAmount() <= 0) then
                activator:NotifyLocalized("farmNeedsWater")
            else
                activator:NotifyLocalized("farmNotReady", math.Round((self:GetProgress() / growthTime) * 100))
            end
        end
    else
        activator:NotifyLocalized("farmNeedCrop")
    end
end
