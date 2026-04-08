ITEM.name = "9V Battery"
ITEM.model = Model("models/hls/alyxports/battery.mdl")
ITEM.description = "item9vBatteryDesc"
ITEM.price = 10
ITEM.isjunk = true
ITEM.isStackable = true
ITEM.classes = {CLASS_CWU}

ITEM.functions.Install = {
	name = "Install Igniter",
	icon = "icon16/lightning.png",
	OnCanRun = function(item)
		local client = item.player
		local ent = client:GetEyeTrace().Entity
		return IsValid(ent) and ent:GetClass() == "ix_stove" and !ent:GetNetVar("broken", false) and ent:GetNetVar("igniter", 0) <= 0 and client:GetPos():DistToSqr(ent:GetPos()) < 10000 and ix.plugin.list["hunger"] != nil
	end,
	OnRun = function(item)
		local client = item.player
		local ent = client:GetEyeTrace().Entity
		if (IsValid(ent) and ent:GetClass() == "ix_stove") then
			ent:SetNetVar("igniter", 100)
			client:NotifyLocalized("igniterInstalled")
			return true
		end
		return false
	end
}