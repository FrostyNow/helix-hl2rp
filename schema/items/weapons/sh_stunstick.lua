ITEM.name = "Stunstick"
ITEM.description = "stunstickDesc"
ITEM.class = "ix_stunstick"
ITEM.weaponCategory = "melee"
ITEM.model = "models/weapons/w_stunbaton.mdl"
ITEM.width = 1
ITEM.height = 2
ITEM.iconCam = {
	pos = Vector(-1, 0.5, 200),
	ang = Angle(90, 177, 0),
	fov = 4
}
ITEM.price = 175
ITEM.exRender = true

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(Color(85, 127, 242))
		data:SetText(L("securitizedItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end