ITEM.name = "Panzerfaust 3 Rocket"
ITEM.model = "models/weapons/w_panzerfaust3_sandstorm_projectile.mdl"
ITEM.ammo = "PanzerFaust3 Rocket" -- type of the ammo
ITEM.ammoAmount = 1 -- amount of the ammo
ITEM.width = 2
ITEM.description = "panzerfaustammoDesc"
-- ITEM.iconCam = {
-- 	ang	= Angle(-0.70499622821808, 268.25439453125, 0),
-- 	fov	= 12.085652091515,
-- 	pos	= Vector(7, 200, -2)
-- }
ITEM.price = 150

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(team.GetColor(FACTION_MPF))
		data:SetText(L("securitizedItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end