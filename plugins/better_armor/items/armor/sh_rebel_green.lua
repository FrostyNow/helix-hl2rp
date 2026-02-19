ITEM.name = "Rebel Clothing (Green)"
ITEM.description = "itemRebelDesc"
-- ITEM.category = "Outfit"
ITEM.model = "models/tnb/items/aphelion/shirt_rebel1.mdl"
ITEM.skin = 0
ITEM.width = 1
ITEM.height = 1
ITEM.price = 100
ITEM.armorAmount = 70
ITEM.gasmask = false -- It will protect you from bad air
ITEM.resistance = false -- This will activate the protection bellow
ITEM.damage = { -- It is scaled; so 100 damage * 0.8 will makes the damage be 80.
			1, -- Bullets
			1, -- Slash
			1, -- Shock
			1, -- Burn
			1, -- Radiation
			1, -- Acid
			1, -- Explosion
}
ITEM.hitGroups = {HITGROUP_CHEST, HITGROUP_STOMACH, HITGROUP_LEFTARM, HITGROUP_LEFTLEG, HITGROUP_RIGHTLEG}
ITEM.outfitCategory = "outfit"
ITEM.pacData = {}
ITEM.bodyGroups = {
	["torso"] = 9,
	["legs"] = 5,
	["hands"] = 1,
	["headgear"] = 4
}

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(Color(218, 24, 24))
		data:SetText(L("sociocidalItemTooltip"))
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