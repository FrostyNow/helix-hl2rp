ITEM.name = "Coke"
ITEM.model = "models/bloocobalt/l4d/items/w_cola_bottle.mdl"
ITEM.description = "itemCokeDesc"
ITEM.thirst = 25
ITEM.hunger = -10
ITEM.price = 15
ITEM.heal = 10
ITEM.usenum = 2
ITEM.sound = "interface/inv_beer.ogg"
ITEM.empty = "coke_bottle_empty"
ITEM.exRender = true

ITEM.bodyGroups = {
	["Bottlecap"] = 0
}

function ITEM:OnInstantiated()
	self.bodyGroups = self:GetData("bodygroups", self.bodyGroups)
end

function ITEM:OnDataChanged(key, oldValue, newValue)
	if (key == "bodygroups") then
		self.bodyGroups = newValue

		if (CLIENT) then
			ix.gui.RefreshItemIcon(self.id)
		end
	end
end

ITEM.hooks = ITEM.hooks or {}
ITEM.hooks.Eat = function(item)
	local bodygroups = table.Copy(item:GetData("bodygroups", item.bodyGroups))
	bodygroups["Bottlecap"] = 1
	item:SetData("bodygroups", bodygroups)
end