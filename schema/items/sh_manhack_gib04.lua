ITEM.name = "Manhack Parts"
ITEM.model = "models/gibs/manhack_gib04.mdl"
ITEM.description = "itemManhackPartsDesc"
ITEM.isjunk = true
ITEM.price = 5
ITEM.isStackable = true

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(team.GetColor(FACTION_MPF))
		data:SetText(L("securitizedItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end