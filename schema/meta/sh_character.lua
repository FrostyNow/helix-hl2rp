
local CHAR = ix.meta.character

function CHAR:IsCombine()
	local faction = self:GetFaction()
	local items = self:GetInventory():GetItems()
	local mimic = false
	
	for k, v in pairs(items) do
		if ((v.id == "combine_soldier" or v.id == "metropolice" or v.id == "hazmat_suit_citizen") and v:GetData("equip")) then
			mimic = true
			break
		end
	end
	
	return faction == FACTION_MPF or faction == FACTION_OTA or mimic
end
