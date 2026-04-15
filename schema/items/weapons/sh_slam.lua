ITEM.name = "S.L.A.M"
ITEM.description = "slamDesc"
ITEM.model = "models/weapons/w_slam.mdl"
ITEM.class = "weapon_slam"
ITEM.isGrenade = true
ITEM.weaponCategory = "grenade"
ITEM.classes = {CLASS_EMP}
ITEM.width = 1
ITEM.height = 1
ITEM.price = 200
ITEM.factions = {FACTION_OTA, FACTION_CONSCRIPT}

ITEM.isStackable = true
ITEM.maxStack = 3

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(team.GetColor(FACTION_MPF))
		data:SetText(L("securitizedItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end