
ITEM.name = "Hazmat Suit"
ITEM.description = "hazmatSuitDesc"
ITEM.model = "models/props_c17/SuitCase_Passenger_Physics.mdl"
ITEM.height = 2
ITEM.width = 2
ITEM.price = 550
ITEM.gasmask = true -- It will protect you from bad air
ITEM.resistance = true -- This will activate the protection bellow
ITEM.damage = { -- It is scaled; so 100 damage * 0.8 will makes the damage be 80.
			.9, -- Bullets
			.9, -- Slash
			.9, -- Shock
			.9, -- Burn
			.7, -- Radiation
			.7, -- Acid
			.9, -- Explosion
}
ITEM.replacements = "models/ddok1994/1980_hazmat.mdl"
ITEM.outfitCategory = "suit"
ITEM.maxDurability = 100

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(Color(85, 127, 242))
		data:SetText(L("securitizedItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end