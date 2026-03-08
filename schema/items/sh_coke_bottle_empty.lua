
ITEM.name = "Empty Bottle"
ITEM.description = "itemEmptyBottleDesc"
ITEM.price = 4
ITEM.model = "models/bloocobalt/l4d/items/w_cola_bottle.mdl"
ITEM.bodyGroups = {
	["Bottlecap"] = 1,
	["Liquid"] = 2,
}
ITEM.isjunk = true
ITEM.exRender = true
ITEM.isStackable = true

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