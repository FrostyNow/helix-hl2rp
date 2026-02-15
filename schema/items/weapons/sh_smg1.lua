ITEM.name = "MP7"
ITEM.description = "smg1Desc"
ITEM.model = "models/weapons/w_smg1.mdl"
ITEM.class = "arc9_hl2_smg1"
ITEM.weaponCategory = "primary"
ITEM.classes = {CLASS_EMP, CLASS_MPU, CLASS_OWS, CLASS_REBEL}
ITEM.width = 3
ITEM.height = 2
ITEM.price = 475
ITEM.iconCam = {
	ang	= Angle(-0.020070368424058, 270.40155029297, 0),
	fov	= 7.2253324508038,
	pos	= Vector(0, 200, -1)
}
ITEM.factions = {FACTION_CONSCRIPT}

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(Color(85, 127, 242))
		data:SetText(L("securitizedItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end