
local PLUGIN = PLUGIN

-- Yuck. No wonder Clockwork had low FPS, with plugins like these.
function PLUGIN:Tick()
	local curTime = CurTime()
	
	local allPlayers = player.GetAll()
	local receivers = {}
	for i = 1, #allPlayers do
		local ply = allPlayers[i]
		if (ply:IsCombine() and !ply:GetNetVar("IsBiosignalGone")) then
			receivers[#receivers + 1] = ply
		end
	end

	if (!self.nextCameraTick or curTime >= self.nextCameraTick) then
		self.nextCameraTick = curTime + 1
		local networkedCameraData = {}
		local bChanged = false
		local walkSpeed = ix.config.Get("walkSpeed")

		for combineCamera, data in pairs(self.cameraData) do
			if (!IsValid(combineCamera)) then
				self.cameraData[combineCamera] = nil
				bChanged = true
			elseif (self:isCameraEnabled(combineCamera)) then
				local camPos = combineCamera:GetPos()

				for client, _ in pairs(data) do
					if (!IsValid(client)) then
						data[client] = nil
						bChanged = true
					else
						-- Throttle traces: only check every second for each client
						if ((client.ixNextCamTrace or 0) < curTime) then
							client.ixNextCamTrace = curTime + 1

							if (camPos:Distance(client:GetPos()) > 450 or !combineCamera:IsLineOfSightClear(client)) then
								data[client] = nil
								bChanged = true
							elseif (!self:CanCameraTrackTarget(client)) then
								data[client] = nil
								bChanged = true
							elseif (#data[client] < 1 and self:CanFlagTargetForViolation(client)) then
								local violations = {}
								if (client:KeyDown(IN_SPEED) and client:GetVelocity():LengthSqr() >= (walkSpeed * walkSpeed)) then
									violations[#violations + 1] = self.VIOLATION_RUNNING
								end
								
								if (!client:OnGround() and client:WaterLevel() <= 0) then
									violations[#violations + 1] = self.VIOLATION_JUMPING
								end

								if (client:Crouching()) then
									violations[#violations + 1] = self.VIOLATION_CROUCHING
								end

								if (client:GetLocalVar("ragdoll")) then
									violations[#violations + 1] = self.VIOLATION_FALLEN_OVER
								end

								if (self:IsSuspectedViolentAct(client)) then
									violations[#violations + 1] = self.VIOLATION_SUSPECTED_VIOLENCE
								end

								if (self:IsVisibleWeaponViolation(client)) then
									violations[#violations + 1] = self.VIOLATION_RAISED_WEAPON
								end

								if (client:GetNetVar("isSearchingLoot")) then
									violations[#violations + 1] = self.VIOLATION_SEARCHING_TRASH
								end

								if (self:HasMultipleCIDs(client)) then
									violations[#violations + 1] = self.VIOLATION_MULTIPLE_CIDS
								end

								if (#violations > 0) then
									data[client] = violations
									bChanged = true

									combineCamera:Fire("SetIdle")
									combineCamera:Fire("SetAngry")

									Schema:AddCombineDisplayMessage("@MovementViolation", Color(255, 128, 0, 255), L(combineCamera:EntIndex(), client))

									if (ix.plugin.Get("scanner")) then
										self:RequestSurveillancePhoto(combineCamera)
									end
								end
							end
						end
					end
				end

				networkedCameraData[combineCamera:EntIndex()] = data
			else
				networkedCameraData[combineCamera:EntIndex()] = 0
			end
		end

		if (#receivers > 0) then
			net.Start("UpdateBiosignalCameraData")
				net.WriteUInt(table.Count(networkedCameraData), 8)
				for entIndex, data in pairs(networkedCameraData) do
					net.WriteUInt(entIndex, 16)
					if (data == 0) then
						net.WriteBool(false)
					else
						net.WriteBool(true)
						net.WriteUInt(table.Count(data), 8)
						for client, violations in pairs(data) do
							net.WriteUInt(IsValid(client) and client:EntIndex() or 0, 8)
							net.WriteUInt(#violations, 4)
							for _, violation in ipairs(violations) do
								net.WriteUInt(violation, 4)
							end
						end
					end
				end
			net.Send(receivers)
		end
	end

	if (!self.nextBiosignalUpdate or curTime >= self.nextBiosignalUpdate) then
		self.nextBiosignalUpdate = curTime + math.random(5, 10) -- Increased interval for objectives

		if (#receivers > 0) then
			net.Start("RecalculateHUDObjectives")
				net.WriteString(self.socioStatus)
				net.WriteTable(Schema.CombineObjectives)
			net.Send(receivers)
		end
	end
end

function PLUGIN:PlayerSpawn(client)
	if (client:IsCombine()) then
		net.Start("RecalculateHUDObjectives")
			net.WriteString(self.socioStatus)
			net.WriteTable(Schema.CombineObjectives)
		net.Send(client)

		if (client:GetNetVar("IsBiosignalGone")) then
			if (ix.config.Get("useBiosignalSystem")) then
				self:SetPlayerBiosignal(client, true)
			else
				client:SetNetVar("IsBiosignalGone", false)
			end
		end
	end

	if (!self.fixedCameras) then
		for combineCamera, data in pairs(self.cameraData) do
			if (!combineCamera:HasSpawnFlags(SF_NPC_WAIT_FOR_SCRIPT)) then -- This is documented as the "Start Inactive" flag by Valve for combine cameras.
				combineCamera:Fire("Enable")
			end
		end

		self.fixedCameras = true
	end
end

function PLUGIN:OnCharacterFallover(client, entity, bFallenOver)
	if (client:IsCombine() and !client:GetNetVar("IsBiosignalGone")) then
		if (bFallenOver) then
			local location = (client.GetAreaName and client:GetAreaName() != "") and client:GetAreaName() or L("unknown location", client)
			local unitID = Schema:GetCombineUnitID(client)

			Schema:AddCombineDisplayMessage("@DownloadingTrauma", Color(255, 255, 255, 255))
			Schema:AddCombineDisplayMessage("@UnitLostConsciousness", Color(255, 0, 0, 255), unitID, location)
		end
	end
end

function PLUGIN:PlayerDeath(client, inflictor, attacker)
	if (client:IsCombine()) then
		if (!client:GetNetVar("IsBiosignalGone")) then
			PLUGIN:DoPostBiosignalLoss(client)
		end

		if (IsValid(client.ixScanner) and client.ixScanner:Health() > 0) then
			client.ixScanner:TakeDamage(999)
		end
	end
end

function PLUGIN:OnEntityCreated(entity)
	if (entity:GetClass() == "npc_combine_camera") then
		if (self.cameraData[entity] == nil) then
			self:SafelyPrepareCamera(entity)
		end
	end
end

function PLUGIN:SetupPlayerVisibility(client)
	for _, terminal in pairs(ents.FindByClass("ix_ctocameraterminal")) do
		local camera = terminal:GetNWEntity("camera")

		if (IsValid(camera) and client:IsLineOfSightClear(terminal)) then
			AddOriginToPVS(camera:GetPos() + Vector("0 0 -10"))
		end
	end
end

function PLUGIN:PlayerTick(ply)
	if ((ply.ixNextCIDCheck or 0) < CurTime()) then
		ply:SetNetVar("hasMultipleCIDs", self:HasMultipleCIDs(ply))
		ply.ixNextCIDCheck = CurTime() + 5
	end
end
