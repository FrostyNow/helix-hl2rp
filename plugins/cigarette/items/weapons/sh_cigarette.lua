ITEM.name = "Cigarette"
ITEM.description = "cigaretteDesc"
ITEM.model = "models/oldcigshib.mdl"
ITEM.class = "ix_cigarette"
ITEM.isGrenade = true
ITEM.weaponCategory = "special"
ITEM.classes = {CLASS_CWU}
ITEM.width = 1
ITEM.height = 1
ITEM.price = 2
ITEM.isjunk = true

ITEM.isStackable = true
ITEM.maxStack = 14

local function findFireSource(client)
	local inv = client:GetCharacter():GetInventory()
	if (!inv) then return nil end

	for _, v in pairs(inv:GetItems()) do
		if ((v.uniqueID == "lighter" or v.uniqueID == "match") and v:GetData("uses", v.usenum) > 0) then
			return v
		end
	end

	return nil
end

ITEM.functions.Equip.OnCanRun = function(item)
	if (item.baseTable.functions.Equip.OnCanRun(item) == false) then
		return false
	end

	return findFireSource(item.player) != nil
end

ITEM.functions.Equip.OnRun = function(item)
	local client = item.player
	local result = item.baseTable.functions.Equip.OnRun(item)

	if (SERVER) then
		local src = findFireSource(client)
		if (IsValid(src)) then
			src:SetData("uses", src:GetData("uses", src.usenum) - 1)
		end

		client:EmitSound("ambient/fire/mtov_flame2.wav", 60, 100, 0.8)
	end

	return result
end