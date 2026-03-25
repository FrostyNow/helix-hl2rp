ITEM.name = "Wheat Seed"
ITEM.description = "itemWheatSeedDesc"
ITEM.model = "models/mosi/fnv/props/junk/seedbag.mdl"

ITEM.functions.Plant = {
	icon = "icon16/arrow_down.png",
	OnRun = function(item)
		local client = item.player
		local trace = client:GetEyeTraceNoCursor()
		local entity = trace.Entity

		if (IsValid(entity) and entity:GetClass() == "ix_farmbox" and entity:GetPos():DistToSqr(client:GetPos()) <= 10000) then
			if (entity:GetCropType() == "") then
				entity:SetCropType("wheat")
				entity:SetProgress(0)
				client:NotifyLocalized("farmPlanted", L("itemWheat", client))
				return true
			else
				client:NotifyLocalized("farmAlreadyPlanted")
			end
		else
			client:NotifyLocalized("farmLookAtBox")
		end
		return false
	end
}
