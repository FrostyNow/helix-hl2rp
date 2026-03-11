ITEM.name = "Molotov Cocktail"
ITEM.description = "molotovDesc"
ITEM.model = "models/weapons/anya/w_molly.mdl"
ITEM.class = "weapon_molotov"
ITEM.isGrenade = true
ITEM.weaponCategory = "grenade"
ITEM.classes = {CLASS_REBEL}
ITEM.width = 1
ITEM.height = 1
ITEM.price = 60

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(Color(218, 24, 24))
		data:SetText(L("sociocidalItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end