local PLUGIN = PLUGIN
PLUGIN.name = "Fishing"
PLUGIN.author = "Frosty"
PLUGIN.description = "Adds a /fish command to catch leeches in infested areas using empty cans."

ix.lang.AddTable("english", {
	fishingSuccess = "You successfully caught a fish and canned it!",
	fishingFailed = "You failed to catch anything this time.",
	fishingNoCan = "You need an empty can to fish.",
	fishingNoWater = "You must be looking at a water source to fish.",
	fishingSink = "You cannot fish in a sink!",
	fishingNoLeech = "There are no fishable leeches in this area.",
	fishingAction = "Fishing for leeches...",
	fishingNoLeechPlugin = "The leech plugin is required for fishing.",
	fishingNoSpace = "You do not have enough space in your inventory.",
	fishingCancelled = "You moved too far and stopped fishing.",
	cmdFish = "Fish for leeches in infested water.",
	fishingPushed = "You leaned too far and fell into the water!",
	fishingLostCan = "You failed and dropped your can into the depths."
})

ix.lang.AddTable("korean", {
	fishingSuccess = "물고기를 낚아 캔에 담았습니다!",
	fishingFailed = "이번에는 아무것도 낚지 못했습니다.",
	fishingNoCan = "낚시를 하려면 빈 캔이 필요합니다.",
	fishingNoWater = "낚시를 할 수원을 바라보고 있어야 합니다.",
	fishingSink = "싱크대에서는 낚시를 할 수 없습니다!",
	fishingNoLeech = "이곳은 낚시를 할 수 있는 구역이 아닙니다.",
	fishingAction = "물고기 낚는 중...",
	fishingNoLeechPlugin = "거머리 플러그인이 활성화되어 있어야 합니다.",
	fishingNoSpace = "인벤토리에 공간이 부족합니다.",
	fishingCancelled = "수원으로부터 너무 멀어지면서 낚시가 중단되었습니다.",
	cmdFish = "감염된 물에서 거머리를 낚습니다.",
	fishingPushed = "낚시 도중 균형을 잃고 물 속으로 빠졌습니다!",
	fishingLostCan = "아무것도 낚지 못했고 빈 캔마저 물에 빠뜨렸습니다."
})

local SINK_MODELS = {
	["models/props_interiors/sinkkitchen01a.mdl"] = true,
	["models/props_c17/furnituresink001a.mdl"] = true
}

local function GetFishingTarget(client)
	local shootPos = client:GetShootPos()
	local aimVec = client:GetAimVector()
	local endPos = shootPos + aimVec * 80 -- Max distance for fishing
	
	-- 1. Try to find water surface
	local waterTrace = util.TraceLine({
		start = shootPos,
		endpos = endPos,
		filter = client,
		mask = CONTENTS_WATER
	})

	-- 2. Try to find solids (like sinks)
	local solidTrace = util.TraceLine({
		start = shootPos,
		endpos = endPos,
		filter = client,
		mask = MASK_SOLID
	})
	
	local isWater = waterTrace.Hit
	local isSink = false

	-- If we hit water, check if there's a sink blocking it or being looked at
	if (solidTrace.Hit) then
		local entity = solidTrace.Entity
		if (IsValid(entity)) then
			local model = entity:GetModel()
			if (model) then
				local cleanModel = model:lower():gsub("\\", "/")
				if (SINK_MODELS[cleanModel]) then
					isSink = true
				end
			end
		end
		
		-- Even if no entity, check if the distance to solid is closer than water
		if (isWater and solidTrace.Fraction < waterTrace.Fraction) then
			-- If we hit something (not a sink) before water, maybe it's the ground
			-- But if we hit water first, it's fine.
		end
	end

	return isWater, isSink, waterTrace
end

ix.command.Add("Fish", {
	description = "@cmdFish",
	OnRun = function(self, client)
		local character = client:GetCharacter()
		if (!character) then return end

		-- 1. Check if leech plugin exists
		if (!ix.plugin.Get("leech")) then
			return "@fishingNoLeechPlugin"
		end

		-- 2. Check if in leech area
		local areaID = client:GetArea()
		local area = ix.area.stored[areaID]
		if (!area or !area.properties or !area.properties.leeches) then
			return "@fishingNoLeech"
		end

		-- 3. Check for water and exclude sinks
		local isWater, isSink = GetFishingTarget(client)
		if (isSink) then
			return "@fishingSink"
		end
		if (!isWater) then
			return "@fishingNoWater"
		end

		-- 4. Check for empty can
		local inventory = character:GetInventory()
		local canItem = inventory:HasItem("empty_can")
		if (!canItem) then
			return "@fishingNoCan"
		end

		-- 5. Start timed action
		local startPos = client:GetPos()
		local uniqueID = "ixFishing" .. client:SteamID64()

		client:SetAction("@fishingAction", 5, function()
			timer.Remove(uniqueID)

			-- Check requirements again upon completion
			local stillWater, stillSink = GetFishingTarget(client)
			if (stillSink) then
				client:NotifyLocalized("fishingSink")
				return
			end
			if (!stillWater) then
				client:NotifyLocalized("fishingNoWater")
				return
			end

			-- Re-check for can item
			canItem = inventory:HasItem("empty_can")
			if (!canItem) then
				client:NotifyLocalized("fishingNoCan")
				return
			end

			-- Success calculation
			-- Success depends on Agility (stm), Luck (lck), and Luck modifier (luckMultiplier config)
			local agi = character:GetAttribute("stm", 0)
			local agiMod = ix.config.Get("agilityMultiplier", 0.5)
			local luck = character:GetAttribute("lck", 0)
			local luckMod = ix.config.Get("luckMultiplier", 1)
			local maxAtt = ix.config.Get("maxAttributes", 30)

			-- Success formula: 10% base + scaled contribution from attributes (Max 80%)
			-- (Current Score / Max Possible Score) * 80
			local maxScore = (maxAtt * agiMod) + (maxAtt * luckMod)
			local currentScore = (agi * agiMod) + (luck * luckMod)
			local attributeBonus = (currentScore / math.max(maxScore, 1)) * 80

			local chance = math.Clamp(10 + attributeBonus, 5, 95)
			local roll = math.random(1, 100)

			if (roll <= chance) then
				if (inventory:Add("fish")) then
					canItem:Remove()
					client:NotifyLocalized("fishingSuccess")
				else
					client:NotifyLocalized("fishingNoSpace")
				end
			else
				-- Very rare case: Pushed into water if chance is very low
				if (chance < 20 and math.random(1, 100) <= 5) then
					client:SetVelocity(client:GetAimVector() * 600 + Vector(0, 0, 150))
					client:NotifyLocalized("fishingPushed")
					canItem:Remove() -- Obviously lose the can too
					return
				end

				-- Moderately low chance: Lose the can
				if (chance < 30 and math.random(1, 100) <= 15) then
					canItem:Remove()
					client:NotifyLocalized("fishingLostCan")
				else
					client:NotifyLocalized("fishingFailed")
				end
			end
		end)

		local finishTime = CurTime() + 5.5 -- Extra buffer
		timer.Create(uniqueID, 0.5, 0, function()
			if (!IsValid(client) or CurTime() > finishTime) then
				timer.Remove(uniqueID)
				return
			end

			if (client:GetPos():DistToSqr(startPos) > 4096) then -- 64 units
				client:SetAction()
				client:NotifyLocalized("fishingCancelled")
				timer.Remove(uniqueID)
				return
			end
			
			-- Splash Effect (Every 0.5s during fishing)
			local isWater, isSink, trace = GetFishingTarget(client)
			if (isWater and !isSink) then
				client:EmitSound("ambient/water/water_splash" .. math.random(1, 3) .. ".wav", 60, math.random(90, 110))
				
				local effectData = EffectData()
				effectData:SetOrigin(trace.HitPos)
				effectData:SetScale(0.3)
				util.Effect("WaterSplash", effectData)
			end
		end)
	end
})

