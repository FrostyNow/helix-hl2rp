
ITEM.name = "Combine Keycard"
ITEM.model = Model("models/synapse/misc_props/synapse_misc_combine_card.mdl")
ITEM.description = "itemCombineKeycardDesc"
ITEM.category = "Utility"
ITEM.price = 2000
ITEM.noDeathDrop = true
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