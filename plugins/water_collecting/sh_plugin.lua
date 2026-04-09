local PLUGIN = PLUGIN
PLUGIN.name = "Water Collecting"
PLUGIN.author = "Frosty"
PLUGIN.description = "Allows players to collect dirty water from water sources and sinks."

PLUGIN.license = [[
Copyright © 2026 Frosty

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/
]]

ix.lang.AddTable("english", {
	cmdCollectWater = "Collect dirty water from a source in front of you.",
	collectingWater = "Collecting water...",
	waterTooFar = "You are too far away from the water source.",
	waterNoSource = "You are not looking at a water source.",
	waterSuccess = "You have collected some dirty water.",
	waterCancelled = "Water collection cancelled."
})

ix.lang.AddTable("korean", {
	cmdCollectWater = "바로 앞에 있는 수원에서 더러운 물을 뜹니다. 대체로 싱크대나 물가에서만 가능합니다.",
	collectingWater = "물을 뜨는 중...",
	waterTooFar = "물에서 너무 멉니다.",
	waterNoSource = "물을 뜰 수 있는 수원을 바라보고 있지 않습니다.",
	waterSuccess = "더러운 물을 떴습니다.",
	waterCancelled = "물 뜨기가 취소되었습니다."
})

-- Distance constant (1 meter is roughly 52.5 units, using 60 for usability)
local COLLECT_DISTANCE = 60
local SINK_MODELS = {
	["models/props_interiors/sinkkitchen01a.mdl"] = Vector(1, 0, 20), -- Raised Z to 20 for visibility
	["models/props_c17/furnituresink001a.mdl"] = Vector(2, 0, 30)  -- Raised Z to 30 for visibility
}

local function GetWaterSource(client)
	local shootPos = client:GetShootPos()
	local aimVec = client:GetAimVector()
	local endPos = shootPos + aimVec * COLLECT_DISTANCE
	
	-- 1. Try to find water surface first (more precise for effects)
	local waterTrace = util.TraceLine({
		start = shootPos,
		endpos = endPos,
		filter = client,
		mask = CONTENTS_WATER
	})

	-- 2. Try to find solids/sinks
	local solidTrace = util.TraceLine({
		start = shootPos,
		endpos = endPos,
		filter = client,
		mask = bit.bor(MASK_SOLID, CONTENTS_TRANSLUCENT)
	})
	
	local isWater = waterTrace.Hit
	local isSink = false
	local sinkOffset = Vector(0, 0, 0)
	local targetEntity = nil
	local targetTrace = solidTrace

	-- Determine what we are actually focusing on
	if (waterTrace.Hit and (!solidTrace.Hit or waterTrace.Fraction < solidTrace.Fraction)) then
		targetTrace = waterTrace
	end

	local entity = solidTrace.Entity
	if (IsValid(entity)) then
		local model = entity:GetModel()
		if (model) then
			local cleanModel = model:lower():gsub("\\", "/")
			if (SINK_MODELS[cleanModel]) then
				isSink = true
				sinkOffset = SINK_MODELS[cleanModel]
				targetEntity = entity
			end
		end
	end

	if (!isSink) then
		for _, v in ipairs(ents.FindInSphere(solidTrace.HitPos, 16)) do
			if (IsValid(v)) then
				local model = v:GetModel()
				if (model) then
					local cleanModel = model:lower():gsub("\\", "/")
					if (SINK_MODELS[cleanModel]) then
						isSink = true
						sinkOffset = SINK_MODELS[cleanModel]
						targetEntity = v
						break
					end
				end
			end
		end
	end

	local distance = shootPos:Distance(targetTrace.HitPos)
	return (isWater or isSink), distance, targetTrace, isSink, targetEntity, sinkOffset
end

ix.command.Add("CollectWater", {
	description = "@cmdCollectWater",
	alias = {"GetWater", "Water"},
	OnRun = function(self, client)
		local character = client:GetCharacter()
		if (!character) then return end

		local inventory = character:GetInventory()
		if (!inventory) then return end

		-- Check for inventory space BEFORE starting the action
		if (!inventory:FindEmptySlot(1, 1)) then
			return "@itemNoSpace"
		end

		local isSource, distance, _, isSink, sinkEnt, sinkOffset = GetWaterSource(client)

		if (!isSource) then
			return "@waterNoSource"
		end

		if (distance > COLLECT_DISTANCE) then
			return "@waterTooFar"
		end

		local uniqueID = "ixWaterCollect" .. client:SteamID64()

		-- If it's a sink, play the leaking sound during the process
		if (isSink) then
			client:EmitSound("ambient/water/leak_1.wav", 65, 100, 1, CHAN_AUTO)
		end
		
		-- Start collecting
		client:SetAction("@collectingWater", 3, function()
			local isStillSource, finalDist, trace, isStillSink, finalSinkEnt, finalSinkOffset = GetWaterSource(client)

			if (isStillSource and finalDist <= COLLECT_DISTANCE) then
				if (inventory:Add("water_dirty")) then
					-- Success Sound & Effect
					if (!isStillSink) then
						-- Natural water: Big splash with sound
						client:EmitSound("ambient/water/water_splash" .. math.random(1, 3) .. ".wav", 75, 100)
						
						local effectData = EffectData()
						effectData:SetOrigin(trace.HitPos)
						effectData:SetScale(0.8)
						util.Effect("WaterSplash", effectData)
					end

					client:NotifyLocalized("waterSuccess")
				else
					client:NotifyLocalized("itemNoSpace")
				end
			else
				client:NotifyLocalized("waterCancelled")
			end
			
			client:StopSound("ambient/water/leak_1.wav")
			timer.Remove(uniqueID)
		end)

		-- Cancel logic (removed continuous effects for sinks)
		timer.Create(uniqueID, 0.1, 3 / 0.1, function()
			if (!IsValid(client)) then
				timer.Remove(uniqueID)
				return
			end
			
			local isStillSource, curDist, tr, isStillSink, curSinkEnt, curSinkOffset = GetWaterSource(client)

			if (!isStillSource or curDist > COLLECT_DISTANCE) then
				client:SetAction(false)
				client:StopSound("ambient/water/leak_1.wav")
				client:NotifyLocalized("waterCancelled")
				timer.Remove(uniqueID)
				return
			end
		end)
	end
})