ITEM.name = "Flare Gun"
ITEM.description = "flaregunDesc"
ITEM.class = "ix_flaregun"
ITEM.weaponCategory = "sidearm"
ITEM.classes = {CLASS_REBEL}
ITEM.width = 2
ITEM.height = 1
ITEM.price = 250
ITEM.model = "models/rtbr/weapons/flaregun/w_flaregun.mdl"
ITEM.width = 2
ITEM.height = 1
ITEM.iconCam = {
	pos = Vector(0, 200, 0),
	ang = Angle(0.54, 270.2, 0),
	fov = 4.83
}
ITEM.exRender = true
ITEM.factions = {FACTION_OTA, FACTION_MPF, FACTION_CONSCRIPT}

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(Color(85, 127, 242))
		data:SetText(L("securitizedItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end