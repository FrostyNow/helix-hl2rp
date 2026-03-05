ITEM.name = "Panzerfaust 3"
ITEM.description = "panzerfaustDesc"
ITEM.model = "models/weapons/w_panzerfaust3_sandstorm.mdl"
ITEM.class = "tfa_ins2_panzerfaust3"
ITEM.weaponCategory = "grenade"
ITEM.width = 5
ITEM.height = 2
ITEM.price = 5000

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(team.GetColor(FACTION_MPF))
		data:SetText(L("securitizedItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end