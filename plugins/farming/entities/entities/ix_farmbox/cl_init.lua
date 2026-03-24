include("shared.lua")

ENT.PopulateEntityInfo = true

function ENT:OnPopulateEntityInfo(tooltip)
    local cropType = self:GetCropType()
    
    local title = tooltip:AddRow("name")
    title:SetImportant()
    
    if (cropType != "") then
        local cropName = "Crop"
        if (cropType == "carrot") then cropName = L("cropCarrot")
        elseif (cropType == "corn") then cropName = L("cropCorn")
        elseif (cropType == "potato") then cropName = L("cropPotato")
        elseif (cropType == "wheat") then cropName = L("cropWheat") end
        
        title:SetText(L("farmBoxCrop", cropName))
        title:SizeToContents()

        local baseTime = 3 * 24 * 60 * ix.config.Get("secondsPerMinute", 60)
        local growthTime = ix.config.Get("cropGrowthTime", baseTime)
        if (self:GetHasFertilizer()) then growthTime = growthTime / 2 end

        local status = tooltip:AddRow("status")
        local progress = self:GetProgress() / growthTime

        if (progress >= 1) then
            status:SetText(L("farmHarvest"))
            status:SetBackgroundColor(Color(50, 200, 50))
        elseif (self:GetWaterAmount() <= 0) then
            status:SetText(L("farmWithered"))
            status:SetBackgroundColor(Color(200, 50, 50))
        else
            status:SetText(L("farmWatered"))
            status:SetBackgroundColor(Color(50, 150, 200))
        end
        status:SizeToContents()
    else
        title:SetText(L("farmBoxEmpty"))
        title:SizeToContents()
    end
end

function ENT:Draw()
    self:DrawModel()
end
