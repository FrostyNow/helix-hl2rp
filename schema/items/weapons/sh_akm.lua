ITEM.name = "AKM"
ITEM.description = "akmDesc"
ITEM.class = "arc9_rtb_akm"
ITEM.weaponCategory = "primary"
ITEM.classes = {CLASS_REBEL}
ITEM.price = 430
ITEM.model = "models/rtbr/weapons/akm/w_akm.mdl"
ITEM.width = 4
ITEM.height = 2
ITEM.iconCam = {
	pos = Vector(13, 199.8, -6.97),
	ang = Angle(-2.1, 267.87, 0),
	fov = 11.97
}
ITEM.exRender = true

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(Color(218, 24, 24))
		data:SetText(L("sociocidalItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end