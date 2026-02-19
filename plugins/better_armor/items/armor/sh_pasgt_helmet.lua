
ITEM.name = "PASGT Helmet"
ITEM.description = "pasgtHelmetDesc"
ITEM.model = "models/props_junk/cardboard_box004a.mdl"
ITEM.height = 1
ITEM.width = 1
ITEM.armorAmount = 30
ITEM.price = 250
ITEM.gasmask = false -- It will protect you from bad air
ITEM.resistance = true -- This will activate the protection bellow
ITEM.damage = { -- It is scaled; so 100 damage * 0.8 will makes the damage be 80.
			.8, -- Bullets
			.9, -- Slash
			.9, -- Shock
			1, -- Burn
			1, -- Radiation
			1, -- Acid
			.8, -- Explosion
}
ITEM.bodyGroups = {
	["helmet"] = 1
}
ITEM.outfitCategory = "head"
ITEM.noResetBodyGroups = true
ITEM.hitGroups = {HITGROUP_HEAD}
ITEM.maxDurability = 100
ITEM.allowedModels = {
	"models/wichacks/erdimnovest.mdl",
	"models/wichacks/ericnovest.mdl",
	"models/wichacks/joenovest.mdl",
	"models/wichacks/mikenovest.mdl",
	"models/wichacks/sandronovest.mdl",
	"models/wichacks/tednovest.mdl",
	"models/wichacks/vannovest.mdl",
	"models/wichacks/vancenovest.mdl",
}

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(Color(85, 127, 242))
		data:SetText(L("securitizedItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end