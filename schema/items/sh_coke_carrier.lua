ITEM.name = "Coke"
ITEM.model = "models/bloocobalt/l4d/items/w_cola.mdl"
ITEM.category = "Food"
ITEM.description = "itemCokeDesc"
ITEM.price = 120
ITEM.usenum = 6

ITEM.bodyGroups = {
	["Bottle 1"] = 0, ["bottle 1"] = 0, ["bottle_1"] = 0, ["bottle1"] = 0,
	["Bottle 2"] = 0, ["bottle 2"] = 0, ["bottle_2"] = 0, ["bottle2"] = 0,
	["Bottle 3"] = 0, ["bottle 3"] = 0, ["bottle_3"] = 0, ["bottle3"] = 0,
	["Bottle 4"] = 0, ["bottle 4"] = 0, ["bottle_4"] = 0, ["bottle4"] = 0,
	["Bottle 5"] = 0, ["bottle 5"] = 0, ["bottle_5"] = 0, ["bottle5"] = 0,
	["Bottle 6"] = 0, ["bottle 6"] = 0, ["bottle_6"] = 0, ["bottle6"] = 0,
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

ITEM.functions.Use = {
	name = "Take",
	OnRun = function(item)
		local client = item.player
		local character = client:GetCharacter()
		local usenum = item:GetData("usenum", item.usenum)

		if (!character:GetInventory():Add("coke_bottle")) then
			ix.item.Spawn("coke_bottle", client)
		end

		usenum = usenum - 1
		item:SetData("usenum", usenum)

		local bodygroups = table.Copy(item:GetData("bodygroups", item.bodyGroups))
		local index = item.usenum - usenum
		
		bodygroups["Bottle " .. index] = 1
		bodygroups["bottle " .. index] = 1
		bodygroups["Bottle_" .. index] = 1
		bodygroups["bottle_" .. index] = 1
		bodygroups["Bottle" .. index] = 1
		bodygroups["bottle" .. index] = 1

		item:SetData("bodygroups", bodygroups)

		client:EmitSound("physics/glass/glass_bottle_impact_hard1.wav", 80)

		if (usenum <= 0) then
			return true
		end

		return false
	end,
	OnCanRun = function(item)
		return !IsValid(item.entity)
	end
}