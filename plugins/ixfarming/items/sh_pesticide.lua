ITEM.name = "Pesticide"
ITEM.description = "itemPesticideDesc"
ITEM.model = "models/noble/limelight/pesticide.mdl"

ITEM.functions.Apply = {
	icon = "icon16/bug.png",
	OnRun = function(item)
		local client = item.player
		local trace = client:GetEyeTraceNoCursor()
		local entity = trace.Entity

		if (IsValid(entity) and entity:GetClass() == "ix_farmcrop") then
			entity = entity:GetFarmBox()
		end

		if (IsValid(entity) and entity:GetClass() == "ix_farmbox" and entity:GetPos():DistToSqr(client:GetPos()) <= 20000) then
			if (entity:GetCropType() != "") then
				entity:SetCropType("")
				entity:SetProgress(0)
				entity:SetHasFertilizer(false)
				entity:SetWaterQuality(0)
				entity:SetHasPesticide(false)
				client:NotifyLocalized("farmCropRemoved")
				return true
			else
				if (!entity:GetHasPesticide()) then
					entity:SetHasPesticide(true)
					client:NotifyLocalized("farmPesticideApplied")
					return true
				else
					client:NotifyLocalized("farmPesticideAlreadyApplied")
					return false
				end
			end
		else
			client:NotifyLocalized("farmLookAtBox")
		end
		return false
	end,
	OnCanRun = function(item)
		return !IsValid(item.entity)
	end
}
