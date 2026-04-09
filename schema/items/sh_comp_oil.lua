ITEM.name = "Oil"
ITEM.description = "itemOilDesc"
ITEM.price = 3
ITEM.model = "models/mosi/fallout4/props/junk/components/oil.mdl"
ITEM.isjunk = true
ITEM.isStackable = true

ITEM.functions.Fuel = {
	name = "Fill Fuel",
	icon = "icon16/fire.png",
	OnCanRun = function(item)
		local client = item.player
		local ent = client:GetEyeTrace().Entity
		local allowed = {ix_bucket = true, ix_bonfire = true, ix_stove = true}
		return !IsValid(item.entity) and IsValid(ent) and allowed[ent:GetClass()] and client:GetPos():DistToSqr(ent:GetPos()) < 10000 and ix.plugin.list["hunger"] != nil and ent:GetNetVar("fuelCount", 0) < ent:GetNetVar("fuelMax", 5)
	end,
	OnRun = function(item)
		local client = item.player
		local ent = client:GetEyeTrace().Entity
		local allowed = {ix_bucket = true, ix_bonfire = true, ix_stove = true}
		if (IsValid(ent) and allowed[ent:GetClass()]) then
			if (ent:AddFuel(600)) then
				client:NotifyLocalized("fuelAdded", item.name, 10)
				return true
			else
				client:NotifyLocalized("fuelFull", ent:GetNetVar("fuelMax", 5))
			end
		end
		return false
	end
}