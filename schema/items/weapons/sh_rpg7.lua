ITEM.name = "RPG-7"
ITEM.description = "rpg7Desc"
ITEM.model = "models/weapons/w_rocket_launcher.mdl"
ITEM.class = "tfa_fml_rs2_rpg"
ITEM.weaponCategory = "primary"
ITEM.width = 3
ITEM.height = 1
ITEM.iconCam = {
	pos = Vector(-19.607843399048, 200, 2),
	ang = Angle(0, 270, 0),
	fov = 16
}
ITEM.price = 1500

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(Color(218, 24, 24))
		data:SetText(L("sociocidalItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end