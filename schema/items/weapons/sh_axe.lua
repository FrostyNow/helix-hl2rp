ITEM.name = "Axe"
ITEM.description = "axeDesc"
ITEM.class = "weapon_hl2axe"
ITEM.category = "misc"
ITEM.weaponCategory = "melee"
ITEM.price = 25
ITEM.model = "models/weapons/hl2meleepack/w_axe.mdl"
ITEM.width = 1
ITEM.height = 2
ITEM.iconCam = {
	pos = Vector(0, 0, 200),
	ang = Angle(90, 0, 0),
	fov = 5.05
}
ITEM.exRender = true
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