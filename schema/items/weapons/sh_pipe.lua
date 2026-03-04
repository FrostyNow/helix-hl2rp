ITEM.name = "Pipe"
ITEM.description = "pipeDesc"
ITEM.class = "weapon_hl2pipe"
ITEM.category = "misc"
ITEM.weaponCategory = "melee"
ITEM.price = 5
ITEM.model = "models/props_canal/mattpipe.mdl"
ITEM.width = 1
ITEM.height = 2
ITEM.iconCam = {
	pos = Vector(509.64, 427.61, 310.24),
	ang = Angle(25.22, 220.08, 0),
	fov = 1.34
}
ITEM.exRender = true
ITEM.isjunk = true

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(Color(218, 24, 24))
		data:SetText(L("sociocidalItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end