local PLUGIN = PLUGIN

function PLUGIN:InitPostEntity()
	local map = game.GetMap()
	local mapTriggers = self.buttonTriggers[map]

	if (!mapTriggers) then 
		return 
	end

	self.registeredButtons = {}

	for id, trigger in pairs(mapTriggers) do
		local entity = ents.GetMapCreatedEntity(id)

		if (IsValid(entity)) then
			self.registeredButtons[entity:EntIndex()] = id
		else
			print("[MapButtons] WARNING: Could not find entity for ID " .. id)
		end
	end
end

function PLUGIN:PlayerUse(client, entity)
	if (!IsValid(entity)) then return end
	
	local entIndex = entity:EntIndex()
	local buttonID = self.registeredButtons and self.registeredButtons[entIndex]

	if (buttonID) then
		-- Add a cooldown to prevent multiple triggers (the x11 issue)
		self.buttonCooldowns = self.buttonCooldowns or {}
		if ((self.buttonCooldowns[entIndex] or 0) > CurTime()) then
			return
		end
		self.buttonCooldowns[entIndex] = CurTime() + 2 -- 2 seconds cooldown
		
		local map = game.GetMap()
		local trigger = self.buttonTriggers[map][buttonID]

		if (trigger and isfunction(trigger)) then
			trigger(client, entity)
		end
	end
end

-- If the plugin is reloaded, InitPostEntity won't fire again.
-- We check if entities already exist and call it manually.
if (SERVER) then
	PLUGIN:InitPostEntity()
end
