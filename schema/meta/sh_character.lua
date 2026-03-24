
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

-- Override character permission checks to respect 'true' returns from hooks.
-- This allows bypassing hardcoded Helix whitelist checks if a hook explicitly says it's okay.
local oldCanPlayerUse = CHAR.CanPlayerUse
function CHAR:CanPlayerUse(client)
	local result = hook.Run("CanPlayerUseCharacter", client, self)

	if (result == true) then
		return true
	end

	if (oldCanPlayerUse) then
		return oldCanPlayerUse(self, client)
	end
end

local oldCanPlayerView = CHAR.CanPlayerView
function CHAR:CanPlayerView(client)
	local result = hook.Run("CanPlayerViewCharacter", client, self)

	if (result == true) then
		return true
	end

	if (oldCanPlayerView) then
		return oldCanPlayerView(self, client)
	end
end
