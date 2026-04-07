local PLUGIN = PLUGIN

if (SERVER) then
	-- Interaction tracking function
	function PLUGIN:TouchItem(entity)
		if (IsValid(entity) and entity:GetClass() == "ix_item") then
			entity.ixLastInteraction = os.time()
		end
	end

	-- Check if item is in an area marked with noItemCleanup
	function PLUGIN:IsItemInNoCleanupArea(entity)
		if (!ix.plugin.list["area"]) then return false end

		local pos = entity:GetPos() + entity:OBBCenter()
		for _, info in pairs(ix.area.stored) do
			if (pos:WithinAABox(info.startPosition, info.endPosition)) then
				if (info.properties and info.properties.noItemCleanup) then
					return true
				end
			end
		end

		return false
	end

	-- Interaction Hooks
	function PLUGIN:OnItemSpawned(entity)
		self:TouchItem(entity)
	end

	function PLUGIN:PhysgunDrop(client, entity)
		self:TouchItem(entity)
	end

	function PLUGIN:OnGravGunDrop(client, entity)
		self:TouchItem(entity)
	end

	function PLUGIN:PlayerUse(client, entity)
		self:TouchItem(entity)
	end

	function PLUGIN:OnEntityCreated(entity)
		if (entity:GetClass() == "ix_item") then
			timer.Simple(0.1, function()
				if (IsValid(entity)) then
					self:TouchItem(entity)
				end
			end)
		end
	end

	-- Visibility Check
	function PLUGIN:IsItemVisibleToPlayers(entity)
		local pos = entity:LocalToWorld(entity:OBBCenter())
		-- Convert meters to Source units: 1 meter approx 39.37 units.
		local proximityInMeters = ix.config.Get("itemCleanerProximity", 15)
		local proximityInUnits = proximityInMeters * 39.37
		local sqDistance = proximityInUnits * proximityInUnits

		for _, ply in ipairs(player.GetAll()) do
			if (!ply:Alive() or ply:GetMoveType() == MOVETYPE_NOCLIP) then continue end

			local eyePos = ply:EyePos()
			local distSqr = eyePos:DistToSqr(pos)
			
			-- 1. Tight proximity check (always ignore if very close)
			if (distSqr < sqDistance) then 
				return true 
			end

			-- 2. Trace and FOV check for slightly further items
			local tr = util.TraceLine({
				start = eyePos,
				endpos = pos,
				filter = {ply, entity},
				mask = MASK_VISIBLE
			})

			if (!tr.Hit) then
				local aimVec = ply:GetAimVector()
				local dirToPos = (pos - eyePos):GetNormalized()
				local dot = aimVec:Dot(dirToPos)

				if (dot > 0.4) then -- Approx. 130 degrees FOV
					return true
				end
			end
		end

		return false
	end

	-- Cleanup Logic
	function PLUGIN:ScheduleCleanup()
		local interval = ix.config.Get("itemCleanerInterval", 30) * 60

		timer.Create("ixItemCleaner", interval, 0, function()
			if (ix.config.Get("itemCleanerEnabled", true)) then
				self:PerformCleanup()
			end
		end)
	end

	function PLUGIN:PerformCleanup()
		local minItems = ix.config.Get("itemCleanerMinItems", 30)
		local maxAge = ix.config.Get("itemCleanerMaxAge", 10) * 60
		local currentTime = os.time()
		local allItems = ents.FindByClass("ix_item")

		if (#allItems <= minItems) then return end

		local eligibleItems = {}

		for _, entity in ipairs(allItems) do
			if (!IsValid(entity) or entity.ixIsSafe) then continue end
			
			local itemTable = entity:GetItemTable()
			if (!itemTable) then continue end

			-- 1. Check if it's "un-takable" (cannotTake data)
			if (itemTable:GetData("cannotTake")) then
				continue
			end

			-- 2. Check if it's in a no-cleanup area
			if (self:IsItemInNoCleanupArea(entity)) then
				continue
			end

			-- 3. Check age/last interaction
			local lastTouch = entity.ixLastInteraction or 0
			if (currentTime - lastTouch < maxAge) then
				continue
			end

			-- 4. Check visibility (Includes proximity check)
			if (self:IsItemVisibleToPlayers(entity)) then
				continue
			end

			table.insert(eligibleItems, entity)
		end

		-- 5. Sort from oldest to newest interaction (oldest first)
		table.sort(eligibleItems, function(a, b)
			local lastA = a.ixLastInteraction or 0
			local lastB = b.ixLastInteraction or 0
			return lastA < lastB
		end)

		-- 6. Cleanup
		local cleanedCount = 0
		for _, entity in ipairs(eligibleItems) do
			if (IsValid(entity)) then
				entity:Remove()
				cleanedCount = cleanedCount + 1
			end
		end

		if (cleanedCount > 0) then
			-- Log cleanup to server and tell admins
			ix.util.NotifyLocalized("itemCleanerRemoved", nil, cleanedCount)
		end
	end

	function PLUGIN:InitializedPlugins()
		self:ScheduleCleanup()
	end
end
