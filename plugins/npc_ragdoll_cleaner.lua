local PLUGIN = PLUGIN
PLUGIN.name = "NPC Ragdoll Cleaner"
PLUGIN.author = "Frosty"
PLUGIN.description = "Automatically removes the oldest NPC ragdolls when the limit is exceeded."

-- Licensed under CC BY-NC-SA 4.0 (https://creativecommons.org/licenses/by-nc-sa/4.0/)

ix.config.Add("maxNPCRagdolls", 40, "The maximum number of NPC ragdolls to keep. Player ragdolls are excluded.", nil, {
	data = {min = 1, max = 100},
	category = "NPC Ragdoll Cleaner"
})

ix.lang.AddTable("english", {
	cmdNPCRagdollClear = "Cleans NPC ragdolls that haven't been interacted with for a certain amount of time.",
	npcRagdollsCleared = "Removed %d NPC ragdolls.",
	noNPCRagdollsCleared = "No NPC ragdolls were found that could be removed."
})

ix.lang.AddTable("korean", {
	cmdNPCRagdollClear = "일정 시간 동안 상호작용이 없었던 NPC 래그돌을 제거합니다.",
	npcRagdollsCleared = "%d개의 NPC 래그돌을 제거했습니다.",
	noNPCRagdollsCleared = "제거할 수 있는 NPC 래그돌이 없습니다."
})

if (SERVER) then
	PLUGIN.ragdolls = PLUGIN.ragdolls or {}

	function PLUGIN:TouchRagdoll(entity)
		entity.ixLastTouch = CurTime()

		for k, v in ipairs(self.ragdolls) do
			if (v == entity) then
				table.remove(self.ragdolls, k)
				table.insert(self.ragdolls, entity)
				return true
			end
		end
		return false
	end

	function PLUGIN:IsRagdollInUse(entity)
		if (entity:IsPlayerHolding()) then
			return true
		end

		for i = 0, entity:GetPhysicsObjectCount() - 1 do
			local phys = entity:GetPhysicsObjectNum(i)
			if (IsValid(phys) and !phys:IsMotionEnabled()) then
				return true
			end
		end

		return false
	end

	function PLUGIN:OnEntityCreated(entity)
		if (entity:GetClass() == "prop_ragdoll") then
			local uniqueID = "ixNPCCleaner" .. entity:EntIndex()
			
			timer.Create(uniqueID, 0.1, 1, function()
				if (!IsValid(entity)) then return end
				
				for _, v in ipairs(self.ragdolls) do
					if (v == entity) then return end
				end

				if (entity:GetNetVar("player") or 
					IsValid(entity.ixPlayer) or 
					entity.ixCharacterID or 
					(IsValid(entity:GetNWEntity("player")) and entity:GetNWEntity("player"):IsPlayer())) then
					return
				end

				local persistentCorpses = ix.plugin.list["persistent_corpses"]
				if (persistentCorpses and persistentCorpses.corpses) then
					for _, v in ipairs(persistentCorpses.corpses) do
						if (v == entity) then return end
					end
				end

				table.insert(self.ragdolls, entity)
				entity.ixLastTouch = CurTime()
				self:CleanupRagdolls()
			end)
		end
	end

	function PLUGIN:CleanupRagdolls()
		local maxRagdolls = ix.config.Get("maxNPCRagdolls", 40)
		
		for i = #self.ragdolls, 1, -1 do
			if (!IsValid(self.ragdolls[i])) then
				table.remove(self.ragdolls, i)
			end
		end

		local i = 1
		while (#self.ragdolls > maxRagdolls and i <= #self.ragdolls) do
			local ragdoll = self.ragdolls[i]
			
			if (IsValid(ragdoll) and !self:IsRagdollInUse(ragdoll)) then
				table.remove(self.ragdolls, i)
				ragdoll:Remove()
			else
				i = i + 1
			end
		end
	end

	function PLUGIN:EntityRemoved(entity)
		if (entity:GetClass() == "prop_ragdoll") then
			for k, v in ipairs(self.ragdolls) do
				if (v == entity) then
					table.remove(self.ragdolls, k)
					break
				end
			end
		end
	end

	function PLUGIN:PhysgunPickup(client, entity)
		if (entity:GetClass() == "prop_ragdoll") then
			self:TouchRagdoll(entity)
		end
	end

	function PLUGIN:OnGravGunPickup(client, entity)
		if (entity:GetClass() == "prop_ragdoll") then
			self:TouchRagdoll(entity)
		end
	end

	function PLUGIN:PlayerUse(client, entity)
		if (entity:GetClass() == "prop_ragdoll") then
			self:TouchRagdoll(entity)
		end
	end
end

ix.command.Add("NPCRagdollClear", {
	description = "@cmdNPCRagdollClear",
	adminOnly = true,
	arguments = {
		bit.bor(ix.type.number, ix.type.optional)
	},
	argumentNames = {"minutes"},
	OnRun = function(self, client, minutes)
		minutes = minutes or 5
		local count = 0
		local currentTime = CurTime()
		local threshold = minutes * 60

		local toRemove = {}
		for _, ragdoll in ipairs(PLUGIN.ragdolls) do
			if (IsValid(ragdoll)) then
				local lastTouch = ragdoll.ixLastTouch or 0

				if (minutes == 0 or (currentTime - lastTouch) >= threshold) then
					if (!PLUGIN:IsRagdollInUse(ragdoll)) then
						table.insert(toRemove, ragdoll)
					end
				end
			end
		end

		for _, ragdoll in ipairs(toRemove) do
			ragdoll:Remove()
			count = count + 1
		end

		if (count > 0) then
			return "@npcRagdollsCleared", count
		else
			return "@noNPCRagdollsCleared"
		end
	end
})
