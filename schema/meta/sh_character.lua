
local CHAR = ix.meta.character

function CHAR:IsCombine()
	local faction = self:GetFaction()
	local items = self:GetInventory():GetItems()
	local mimic = false
	
	for k, v in pairs(items) do
		if ((v.uniqueID == "combine_soldier" or v.uniqueID == "metropolice" or v.uniqueID == "hazmat_suit_citizen") and v:GetData("equip")) then
			mimic = true
			break
		end
	end
	
	return faction == FACTION_MPF or faction == FACTION_OTA or mimic
end
