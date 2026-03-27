ITEM.name = "Wheat Seed"
ITEM.description = "itemWheatSeedDesc"
ITEM.model = "models/mosi/fnv/props/junk/seedbag.mdl"

ITEM.functions.Plant = {
	icon = "icon16/arrow_down.png",
	OnCanRun = function(item)
		if (!ix.plugin.Get("ixfarming")) then
			return false
		end

		local client = item.player
		local trace = client:GetEyeTraceNoCursor()
		local entity = trace.Entity

		return !IsValid(item.entity)
	end,
	OnRun = function(item)
		local client = item.player
		local trace = client:GetEyeTraceNoCursor()
		local entity = trace.Entity

		if (IsValid(entity) and entity:GetClass() == "ix_farmbox" and entity:GetPos():DistToSqr(client:GetPos()) <= 20000) then
			if (entity:GetCropType() == "") then
				entity:SetCropType("wheat")
				entity:SetProgress(0)
				client:NotifyLocalized("farmPlanted", L("cropWheat", client))
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
