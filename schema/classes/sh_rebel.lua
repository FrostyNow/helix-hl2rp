CLASS.name = "Resistance"
CLASS.faction = FACTION_CITIZEN
-- CLASS.color = Color(243, 123, 33, 255)

function CLASS:CanSwitchTo(client)
	return false
end

function CLASS:OnSet(client)
	local character = client:GetCharacter()
	local inventory = character:GetInventory()

	inventory:Add("smg1", 1)
	inventory:Add("smg1ammo", 3)
	inventory:Add("pistol", 1)
	inventory:Add("pistolammo", 2)
	inventory:Add("grenade", 1)
	inventory:Add("walkietalkie", 1)
	inventory:Add("bandage", 3)
	inventory:Add("flashlight", 1)
end

CLASS_REBEL = CLASS.index