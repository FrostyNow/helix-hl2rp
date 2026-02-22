ITEM.name = "Metropolice Uniform"
ITEM.description = "itemMetropoliceDesc"
-- ITEM.category = "Outfit"
ITEM.model = "models/props_c17/SuitCase_Passenger_Physics.mdl"
ITEM.price = 750
ITEM.width = 1
ITEM.height = 1
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
ITEM.maxDurability = 150
ITEM.outfitCategory = "suit"
ITEM.pacData = {}
ITEM.replacements = "models/dpfilms/metropolice/hdpolice.mdl"

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(Color(85, 127, 242))
		data:SetText(L("securitizedItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end

/*
-- This will change a player's skin after changing the model. Keep in mind it starts at 0.
ITEM.newSkin = 1
-- This will change a certain part of the model.
ITEM.replacements = {"group01", "group02"}
-- This will change the player's model completely.
ITEM.replacements = "models/manhack.mdl"
-- This will have multiple replacements.
ITEM.replacements = {
	{"male", "female"},
	{"group01", "group02"}
}

-- This will apply body groups.
ITEM.bodyGroups = {
	["blade"] = 1,
	["bladeblur"] = 1
}
*/