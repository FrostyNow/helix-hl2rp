ITEM.name = "Pulse-Rifle Energy"
ITEM.model = "models/items/combine_rifle_cartridge01.mdl"
ITEM.ammo = "ar2" -- type of the ammo
ITEM.ammoAmount = 90 -- amount of the ammo
ITEM.description = "ar2ammoDesc"
ITEM.classes = {CLASS_EOW, CLASS_OWS, CLASS_EMP}
ITEM.price = 30

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(team.GetColor(FACTION_MPF))
		data:SetText(L("securitizedItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end