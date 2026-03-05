ITEM.name = "Sniper Rifle Ammo"
ITEM.model = "models/items/sniper_round_box.mdl"
ITEM.ammo = "SniperRound" -- type of the ammo
ITEM.ammoAmount = 30 -- amount of the ammo
ITEM.ammoClip = 10
ITEM.description = "sniperammoDesc"
ITEM.classes = {CLASS_EOW, CLASS_OWS, CLASS_EMP}
ITEM.price = 100

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(team.GetColor(FACTION_MPF))
		data:SetText(L("securitizedItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end