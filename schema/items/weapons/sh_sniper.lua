ITEM.name = "Overwatch Sniper Rifle"
ITEM.description = "sniperDesc"
ITEM.class = "arc9_hl2_sniper"
ITEM.weaponCategory = "primary"
ITEM.classes = {CLASS_EOW, CLASS_OWS, CLASS_EMP}
ITEM.model = "models/weapons/w_combine_sniper.mdl"
ITEM.width = 5
ITEM.height = 2
ITEM.iconCam = {
	pos = Vector(-5, 200, 3),
	ang = Angle(0, 270, 0),
	fov = 17.5
}
ITEM.price = 2000
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