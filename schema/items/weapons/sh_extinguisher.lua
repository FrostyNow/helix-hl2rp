ITEM.name = "Extinguisher"
ITEM.description = "extinguisherDesc"
ITEM.class = "weapon_extinguisher"
ITEM.weaponCategory = "grenade"
ITEM.price = 200
ITEM.model = "models/weapons/w_fire_extinguisher.mdl"
ITEM.width = 1
ITEM.height = 2
ITEM.iconCam = {
	pos = Vector(2.5, 200, 20),
	ang = Angle(0, 270, 0),
	fov = 5,
}
ITEM.exRender = true

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(team.GetColor(FACTION_MPF))
		data:SetText(L("securitizedItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end