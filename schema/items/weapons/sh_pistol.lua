ITEM.name = "9mm Pistol"
ITEM.description = "pistolDesc"
ITEM.class = "arc9_hl2_pistol"
ITEM.weaponCategory = "sidearm"
ITEM.classes = {CLASS_REBEL}
ITEM.flag = "V"
ITEM.width = 2
ITEM.height = 1
ITEM.price = 300
ITEM.model = "models/weapons/juniez/pistol.mdl"
ITEM.width = 2
ITEM.height = 1
ITEM.gearSlot = {"weapon1", "weapon2", "weapon3", "weapon4"}
ITEM.iconCam = {
	pos = Vector(0, 200, 0),
	ang = Angle(-0.49, 270.64, 0),
	fov = 4.68
}
ITEM.exRender = true

ITEM.factions = {FACTION_MPF, FACTION_CONSCRIPT}

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(team.GetColor(FACTION_MPF))
		data:SetText(L("securitizedItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end