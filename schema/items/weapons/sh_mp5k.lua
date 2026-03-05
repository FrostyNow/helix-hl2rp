ITEM.name = "MP5K"
ITEM.description = "mp5kDesc"
ITEM.class = "ix_mp5k"
ITEM.weaponCategory = "primary"
ITEM.classes = {CLASS_EMP, CLASS_MPU, CLASS_OWS, CLASS_REBEL}
ITEM.price = 510
ITEM.factions = {FACTION_CONSCRIPT}
ITEM.model = "models/weapons/tfa_ins2/w_mp5k.mdl"
ITEM.width = 2
ITEM.height = 2
ITEM.iconCam = {
	pos = Vector(3, 200, 0.5),
	ang = Angle(0, 270, 0),
	fov = 4.5,
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