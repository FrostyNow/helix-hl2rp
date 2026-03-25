ITEM.name = "Corn"
ITEM.model = "models/bioshockinfinite/porn_on_cob.mdl"
ITEM.description = "itemCornDesc"
ITEM.price = 10
ITEM.hunger = 7
ITEM.heal = 5
ITEM.cookable = true

ITEM.functions = ITEM.functions or {}
ITEM.functions.Plant = {
	icon = "icon16/arrow_down.png",
	OnCanRun = function(item)
		if (!ix.plugin.Get("ixfarming")) then
			return false
		end

		local client = item.player
		local trace = client:GetEyeTraceNoCursor()
		local entity = trace.Entity

		return !IsValid(item.entity) and (IsValid(entity) and entity:GetClass() == "ix_farmbox" and entity:GetPos():DistToSqr(client:GetPos()) <= 10000)
	end,
	OnRun = function(item)
		local client = item.player
		local trace = client:GetEyeTraceNoCursor()
		local entity = trace.Entity

		if (IsValid(entity) and entity:GetClass() == "ix_farmbox" and entity:GetPos():DistToSqr(client:GetPos()) <= 10000) then
			if (entity:GetCropType() == "") then
				entity:SetCropType("corn")
				entity:SetProgress(0)
				client:NotifyLocalized("farmPlanted", L("cropCorn", client))
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