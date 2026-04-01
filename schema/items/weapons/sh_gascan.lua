ITEM.name = "Gas Canister"
ITEM.description = "itemGasCanisterDesc"
ITEM.class = "weapon_vfire_gascan"
ITEM.category = "Utility"
ITEM.weaponCategory = "special"
ITEM.price = 200
ITEM.model = "models/props_junk/gascan001a.mdl"
ITEM.width = 2
ITEM.height = 2

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(Color(218, 24, 24))
		data:SetText(L("sociocidalItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end