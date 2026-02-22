ITEM.name = "XM29 OICW"
ITEM.description = "oicwDesc"
ITEM.class = "ix_oicw"
ITEM.weaponCategory = "primary"
ITEM.classes = {CLASS_EOW, CLASS_OWS, CLASS_EMP}
ITEM.price = 1750
ITEM.model = "models/rtbr/weapons/oicw/w_oicw.mdl"
ITEM.width = 4
ITEM.height = 2
ITEM.iconCam = {
	pos = Vector(0, 200, 0),
	ang = Angle(-0.01, 269.19, 0),
	fov = 11.38
}
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