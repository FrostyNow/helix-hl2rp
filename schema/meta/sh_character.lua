
local CHAR = ix.meta.character

function CHAR:IsCombine()
	local faction = self:GetFaction()
	local inventory = self:GetInventory()
	local mimic = false
	
	if (inventory) then
		for k, v in pairs(inventory:GetItems()) do
			if ((v.uniqueID == "combine_soldier" or v.uniqueID == "metropolice" or v.uniqueID == "hazmat_suit_citizen") and v:GetData("equip")) then
				mimic = true
				break
			end
		end
	end
	
	return faction == FACTION_MPF or faction == FACTION_OTA or mimic
end
