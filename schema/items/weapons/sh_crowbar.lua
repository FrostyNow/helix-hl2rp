ITEM.name = "Crowbar"
ITEM.description = "crowbarDesc"
ITEM.model = "models/weapons/w_crowbar.mdl"
ITEM.class = "weapon_crowbar"
ITEM.weaponCategory = "melee"
ITEM.width = 2
ITEM.height = 1
ITEM.price = 25
ITEM.iconCam = {
	ang	= Angle(-0.23955784738064, 270.44906616211, 0),
	fov	= 10.780103254469,
	pos	= Vector(0, 200, 0)
}

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(Color(218, 24, 24))
		data:SetText(L("sociocidalItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end