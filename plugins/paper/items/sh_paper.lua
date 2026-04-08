ITEM.name = "Paper"
ITEM.model = "models/props_c17/paper01.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.description = "paperDesc"
ITEM.price = 10

ITEM.functions.use = {
	name = "Lire",
	icon = "icon16/pencil.png",
	OnRun = function(item)
		local client = item.player
		local id = item:GetID()
		if (id) then
			netstream.Start(client, "receivePaper", id, item:GetData("PaperData") or "")
		end
		return false
	end
}

ITEM.functions.Fuel = {
	name = "Fill Fuel",
	icon = "icon16/fire.png",
	OnCanRun = function(item)
		local client = item.player
		local ent = client:GetEyeTrace().Entity
		local allowed = {ix_bucket = true, ix_bonfire = true}
		return IsValid(ent) and allowed[ent:GetClass()] and client:GetPos():DistToSqr(ent:GetPos()) < 10000 and ix.plugin.list["hunger"] != nil and ent:GetNetVar("fuelCount", 0) < ent:GetNetVar("fuelMax", 5)
	end,
	OnRun = function(item)
		local client = item.player
		local ent = client:GetEyeTrace().Entity
		local allowed = {ix_bucket = true, ix_bonfire = true}
		if (IsValid(ent) and allowed[ent:GetClass()]) then
			if (ent:AddFuel(60)) then
				client:NotifyLocalized("fuelAdded", item.name, 1)
				return true
			else
				client:NotifyLocalized("fuelFull", ent:GetNetVar("fuelMax", 5))
			end
		end
		return false
	end
}

