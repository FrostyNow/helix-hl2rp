ITEM.name = "Crossbow Bolts"
ITEM.model = "models/Items/CrossbowRounds.mdl"
ITEM.ammo = "XBowBolt" -- type of the ammo
ITEM.ammoAmount = 5 -- amount of the ammo
ITEM.description = "crossbowammoDesc"
ITEM.price = 30

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(Color(218, 24, 24))
		data:SetText(L("sociocidalItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end