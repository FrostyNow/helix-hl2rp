local PLUGIN = PLUGIN

function PLUGIN:InitPostEntity()
	local map = game.GetMap()
	local mapTriggers = self.buttonTriggers[map]

	-- Stop if no triggers are defined for the current map
	if (!mapTriggers) then return end

	for id, trigger in pairs(mapTriggers) do
		local entity = ents.GetMapCreatedEntity(id)

		if (IsValid(entity)) then
			entity:AddCallback("OnOutput", function(ent, name, activator, caller, data)
				-- Handle both function and table based triggers
				if (isfunction(trigger) and name:lower() == "onpressed") then
					trigger(activator, ent, data)
				elseif (istable(trigger) and trigger[name]) then
					trigger[name](activator, ent, data)
				end
			end)
		end
	end
end

function PLUGIN:Trigger(id, activator, outputName, data)
	local map = game.GetMap()
	local mapTriggers = self.buttonTriggers[map]
	if (!mapTriggers) then return end

	local trigger = mapTriggers[id]
	outputName = outputName or "OnPressed"

	if (trigger) then
		if (isfunction(trigger) and outputName:lower() == "onpressed") then
			trigger(activator, nil, data)
		elseif (istable(trigger) and trigger[outputName]) then
			trigger[outputName](activator, nil, data)
		end
	end
end
