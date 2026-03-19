
local CHAR = ix.meta.character

function CHAR:IsCombine()
	local faction = self:GetFaction()
	local inventory = self:GetInventory()
	local mimic = false
	
	if (istable(inventory) and inventory.GetItems) then
		for k, v in pairs(inventory:GetItems()) do
			if (v.uniqueID == "metropolice" and v:GetData("equip")) then
				mimic = true
				break
			end
		end
	end
	
	return faction == FACTION_MPF or faction == FACTION_OTA or mimic
end
