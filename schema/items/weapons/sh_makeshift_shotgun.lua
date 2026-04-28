ITEM.name = "Makeshift Shotgun"
ITEM.description = "makeshiftShotgunDesc"
ITEM.model = "models/tumbera/tumbera.mdl"
ITEM.class = "arc9_makeshift_tumbera"
ITEM.weaponCategory = "primary"
ITEM.classes = {CLASS_REBEL}
ITEM.width = 2
ITEM.height = 1
ITEM.iconCam = {
	pos = Vector(-26.21, 3.73, -197.13),
	ang = Angle(-81.62, 0.41, 0),
	fov = 6.25
}
ITEM.exRender = true
ITEM.price = 200

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(Color(218, 24, 24))
		data:SetText(L("sociocidalItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end