ITEM.name = "Cooking Pan"
ITEM.description = "itemCookingPanDesc"
ITEM.class = "weapon_hl2pot"
ITEM.category = "misc"
ITEM.weaponCategory = "melee"
ITEM.price = 5
ITEM.model = "models/weapons/hl2meleepack/w_pot.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.isjunk = true

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(Color(218, 24, 24))
		data:SetText(L("sociocidalItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end