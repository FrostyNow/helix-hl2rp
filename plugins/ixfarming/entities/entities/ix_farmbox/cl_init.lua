include("shared.lua")

ENT.PopulateEntityInfo = true

function ENT:OnPopulateEntityInfo(tooltip)
	local title = tooltip:AddRow("name")
	title:SetText(L("farmBox"))
	title:SetImportant()
	title:SizeToContents()

	local desc = tooltip:AddRow("desc")
	desc:SetText(L("farmBoxDesc"))
	desc:SizeToContents()

	local cropType = self:GetCropType()
	if (cropType != "") then
		local cropName = "Crop"
		if (cropType == "carrot") then cropName = L("cropCarrot")
		elseif (cropType == "corn") then cropName = L("cropCorn")
		elseif (cropType == "potato") then cropName = L("cropPotato")
		elseif (cropType == "wheat") then cropName = L("cropWheat") end
		
		local cropRow = tooltip:AddRow("cropName")
		cropRow:SetText(L("farmBoxCrop", cropName))
		cropRow:SetBackgroundColor(ix.config.Get("color"))
		cropRow:SizeToContents()

		local growthDays = ix.config.Get("cropGrowthDays", 3)
		local growthTime = growthDays * 24 * 60 * ix.config.Get("secondsPerMinute", 60)
		if (self:GetHasFertilizer()) then growthTime = growthTime / 2 end

		local progress = self:GetProgress() / growthTime
		local status = tooltip:AddRow("status")

		if (progress >= 1) then
			status:SetText(L("farmHarvest"))
			status:SetBackgroundColor(Color(50, 200, 50))
		elseif (self:GetWaterAmount() <= 0) then
			status:SetText(L("farmWithered"))
			status:SetBackgroundColor(Color(200, 50, 50))
		elseif (self:GetHasPesticide()) then
			status:SetText(L("farmPoisoned"))
			status:SetBackgroundColor(Color(150, 50, 200))
		else
			local percent = math.Round(progress * 100)
			status:SetText(L("farmGrowing", percent))
			status:SetBackgroundColor(Color(50, 150, 200))
		end
		status:SizeToContents()
	else
		local condition = tooltip:AddRow("condition")
		if (self:GetHasPesticide()) then
			condition:SetText(L("farmBoxPoisoned"))
			condition:SetBackgroundColor(Color(150, 50, 200))
		else
			condition:SetText(L("farmBoxEmpty"))
		end
		condition:SizeToContents()
	end

	-- Additional environment info
	if (self:GetWaterAmount() > 0) then
		local water = tooltip:AddRow("water")
		water:SetText(L("farmWaterAmount", self:GetWaterAmount()))
		water:SizeToContents()
	end

	if (self:GetHasFertilizer()) then
		local fertilizer = tooltip:AddRow("fertilizer")
		fertilizer:SetText(L("farmFertilized"))
		fertilizer:SetBackgroundColor(Color(100, 150, 50))
		fertilizer:SizeToContents()
	end
end

function ENT:Draw()
	self:DrawModel()
end
