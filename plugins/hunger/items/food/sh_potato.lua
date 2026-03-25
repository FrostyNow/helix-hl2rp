ITEM.name = "Potato"
ITEM.model = "models/griim/foodpack/potato.mdl"
ITEM.description = "itemPotatoDesc"
ITEM.price = 10
ITEM.hunger = 15
ITEM.thirst = 1
ITEM.heal = 2

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
				entity:SetCropType("potato")
				entity:SetProgress(0)
				client:NotifyLocalized("farmPlanted", L("cropPotato", client))
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
