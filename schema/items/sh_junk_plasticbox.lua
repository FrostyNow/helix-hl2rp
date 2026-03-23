ITEM.name = "Box"
ITEM.description = "itemPlasticBoxJunkDesc"
ITEM.model = "models/props_junk/garbage_plasticbox001a.mdl"
ITEM.isjunk = true
ITEM.isStackable = true
ITEM.price = 2

function ITEM:GetModel()
	local models = {
		"models/props_junk/garbage_plasticbox001a.mdl",
		"models/props_junk/garbage_plasticbox001b.mdl",
		"models/props_junk/garbage_plasticbox002a.mdl",
		"models/props_junk/garbage_plasticbox002b.mdl"
	}

	return models[self:GetData("model", 1)]
end

function ITEM:OnInstanced(invID, x, y, item)
	item:SetData("model", math.random(1, 4))
end
