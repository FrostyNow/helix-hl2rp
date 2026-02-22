ITEM.name = "RPG Launcher"
ITEM.description = "rpgDesc"
ITEM.model = "models/weapons/w_rocket_launcher.mdl"
ITEM.class = "weapon_vj_hlr2_rpg"
ITEM.weaponCategory = "grenade"
ITEM.width = 3
ITEM.height = 1
ITEM.iconCam = {
	pos = Vector(-19.607843399048, 200, 2),
	ang = Angle(0, 270, 0),
	fov = 16
}
ITEM.price = 2000

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(Color(85, 127, 242))
		data:SetText(L("securitizedItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end