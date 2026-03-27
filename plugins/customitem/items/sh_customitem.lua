ITEM.name = "Generic Item"
ITEM.description = "Generic Description"
ITEM.model = Model("models/maxofs2d/hover_rings.mdl")

function ITEM:GetName()
	return self:GetData("customName", "Custom Item")
end

function ITEM:GetDescription()
	return self:GetData("customDescription", "Custom item description.")
end

function ITEM:GetModel()
	return self:GetData("customModel", "models/Gibs/HGIBS.mdl")
end
