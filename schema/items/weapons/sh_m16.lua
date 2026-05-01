ITEM.name = "M16A2"
ITEM.description = "m16a2Desc"
ITEM.class = "ix_m16a2"
ITEM.weaponCategory = "primary"
ITEM.classes = {CLASS_EOW, CLASS_OWS, CLASS_EMP}
ITEM.price = 500
ITEM.model = "models/weapons/w_m16a2.mdl"
ITEM.width = 4
ITEM.height = 2
ITEM.iconCam = {
	pos = Vector(8, 200, 1),
	ang = Angle(0, 270, 0),
	fov = 14,
}
ITEM.exRender = true
ITEM.factions = {FACTION_CONSCRIPT}

ITEM.clip = "ar2ammo"

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(team.GetColor(FACTION_MPF))
		data:SetText(L("securitizedItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end