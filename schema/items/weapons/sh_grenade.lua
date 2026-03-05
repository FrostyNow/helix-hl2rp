ITEM.name = "HE Grenade"
ITEM.description = "grenadeDesc"
ITEM.model = "models/weapons/w_grenade.mdl"
ITEM.class = "weapon_frag"
ITEM.weaponCategory = "grenade"
ITEM.classes = {CLASS_SGS, CLASS_OWS, CLASS_EMP, CLASS_REBEL}
ITEM.width = 1
ITEM.height = 1
ITEM.price = 150
ITEM.factions = {FACTION_CONSCRIPT}

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(team.GetColor(FACTION_MPF))
		data:SetText(L("securitizedItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end