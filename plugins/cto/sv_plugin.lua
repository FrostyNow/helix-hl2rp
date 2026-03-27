
local PLUGIN = PLUGIN

PLUGIN.cameraData = PLUGIN.cameraData or {}
PLUGIN.fixedCameras = PLUGIN.fixedCameras or false
PLUGIN.outputEntity = PLUGIN.outputEntity or nil
PLUGIN.socioStatus = PLUGIN.socioStatus or "GREEN"

util.AddNetworkString("UpdateBiosignalCameraData")
util.AddNetworkString("RecalculateHUDObjectives")
util.AddNetworkString("CombineRequestSignal")
util.AddNetworkString("ixCTOPlayLocalSoundQueue")

function PLUGIN:PlayRestrictedSoundQueue(client, soundQueue)
	if (!IsValid(client)) then
		return
	end

	if (client:Team() == FACTION_OTA) then
		net.Start("ixCTOPlayLocalSoundQueue")
			net.WriteTable(soundQueue)
		net.Send(client)
	else
		ix.util.EmitQueuedSounds(client, soundQueue)
	end
end

function PLUGIN:SafelyPrepareCamera(combineCamera)
	if (!IsValid(self.outputEntity)) then
		self.outputEntity = ents.Create("base_entity")
		self.outputEntity:SetName("__ixCTOhook")

		function self.outputEntity:AcceptInput(inputName, activator, called, data)
			if (data == "OnFoundPlayer") then
				PLUGIN:CombineCameraFoundPlayer(called, activator)
			end
		end

		self.outputEntity:Spawn()
		self.outputEntity:Activate()
	end

	combineCamera:Fire("addoutput", "OnFoundPlayer __ixCTOhook:PLUGIN:OnFoundPlayer:0:-1")
	self.cameraData[combineCamera] = {}
end

function PLUGIN:CombineCameraFoundPlayer(combineCamera, client)
	if (self.cameraData[combineCamera] and client:GetMoveType() != MOVETYPE_NOCLIP) then
		if (!self.cameraData[combineCamera][client]) then
			self.cameraData[combineCamera][client] = {}
		end
	end
end

function PLUGIN:DoPostBiosignalLoss(client)
	client:SetNetVar("IsBiosignalGone", true)

	local location = (client.GetAreaName and client:GetAreaName() != "") and client:GetAreaName() or L("unknown location", client)
	local unitID = Schema:GetCombineUnitID(client)

	-- Alert all other units.
	Schema:AddCombineDisplayMessage("@DownloadingLostBiosignal", Color(0, 180, 255, 45))
	Schema:AddCombineDisplayMessage("@BiosignalLostForUnit", Color(255, 0, 0, 45), unitID, location)

	local soundQueue = {
		"npc/metropolice/vo/on" .. math.random(1, 2) .. ".wav",
		"npc/overwatch/radiovoice/lostbiosignalforunit.wav"
	}

	soundQueue[#soundQueue + 1] = "npc/overwatch/radiovoice/remainingunitscontain.wav"
	soundQueue[#soundQueue + 1] = "npc/metropolice/vo/off" .. math.random(1, 4) .. ".wav"

	for _, player in ipairs(player.GetAll()) do
		if (player:IsCombine() and player != client and !player:GetNetVar("IsBiosignalGone")) then
			self:PlayRestrictedSoundQueue(player, soundQueue)
		end
	end
end

-- scanner plugin support
function PLUGIN:DoPostScannerLoss(scanner)
	local pilot = scanner:GetPilot()
	local location = (IsValid(pilot) and pilot.GetAreaName and pilot:GetAreaName() != "") and pilot:GetAreaName() or "unknown location"
	local scannerID = scanner:GetNetVar("ixScannerName", "SCN")

	-- Alert all other units.
	Schema:AddCombineDisplayMessage("@DownloadingLostBiosignal", Color(0, 180, 255, 45))
	Schema:AddCombineDisplayMessage("@BiosignalLostForUnit", Color(255, 0, 0, 45), scannerID, location)
end

function PLUGIN:SetPlayerBiosignal(client, bEnable)
	if (client:IsCombine()) then
		local isDisabledAlready = client:GetNetVar("IsBiosignalGone")

		if (bEnable and !isDisabledAlready) then
			return self.ERROR_ALREADY_ENABLED
		elseif (!bEnable and isDisabledAlready) then
			return self.ERROR_ALREADY_DISABLED
		else
			if (bEnable) then
				client:SetNetVar("IsBiosignalGone", false)

				local location = (client.GetAreaName and client:GetAreaName() != "") and client:GetAreaName() or L("unknown location", client)

				client:AddCombineDisplayMessage("@ConnectionRestored", Color(0, 255, 0, 45)) -- Alert this unit.

				local unitID = Schema:GetCombineUnitID(client)

				-- Alert all units.
				Schema:AddCombineDisplayMessage("@DownloadingFoundBiosignal", Color(0, 180, 255, 45))
				Schema:AddCombineDisplayMessage("@NoncohesiveBiosignalFound", Color(0, 255, 0, 45), unitID, location)

				local soundQueue = {
					"npc/metropolice/vo/on" .. math.random(1, 2) .. ".wav",
					"npc/overwatch/radiovoice/engagingteamisnoncohesive.wav",
					"npc/metropolice/vo/off" .. math.random(1, 4) .. ".wav"
				}

				for _, player in ipairs(player.GetAll()) do
					if (player:IsCombine() and !player:GetNetVar("IsBiosignalGone")) then
						self:PlayRestrictedSoundQueue(player, soundQueue)
					end
				end
			else
				client:AddCombineDisplayMessage("@ErrorShuttingDown", Color(255, 0, 0, 45)) -- Alert this unit.

				self:DoPostBiosignalLoss(client)
			end

			return self.ERROR_NONE
		end
	else
		return self.ERROR_NOT_COMBINE
	end
end

function PLUGIN:DispatchRequestSignal(client, text)
	local players = {}
	local soundQueue = {
		"npc/metropolice/vo/on" .. math.random(1, 2) .. ".wav",
		"npc/overwatch/radiovoice/allteamsrespondcode3.wav",
		"npc/metropolice/vo/off" .. math.random(1, 4) .. ".wav"
	}

	for _, player in ipairs(player.GetAll()) do
		if (player:IsCombine() and !player:GetNetVar("IsBiosignalGone")) then
			players[#players + 1] = player

			ix.util.EmitQueuedSounds(player, soundQueue)
		end
	end

	net.Start("CombineRequestSignal")
		net.WriteEntity(client)
		net.WriteString(text)
	net.Send(players)

	Schema:AddCombineDisplayMessage("@AssistanceRequestRecv", Color(175, 125, 100, 45))
end

function PLUGIN:RequestSurveillancePhoto(camera)
	if ((camera.ixNextPhotoRequest or 0) > CurTime()) then
		return
	end

	camera.ixNextPhotoRequest = CurTime() + 15

	local receiver
	local bestReceiver

	-- Find nearest camera terminal first for sake of resource friendship
	for _, v in ipairs(ents.FindByClass("ix_ctocameraterminal")) do
		if (v:GetNWEntity("camera") == camera) then
			for _, client in ipairs(player.GetAll()) do
				if (client:IsCombine() and !client:GetNetVar("IsBiosignalGone", false) and client:GetPos():DistToSqr(v:GetPos()) <= 250 * 250) then
					bestReceiver = client
					break
				end
			end
		end

		if (bestReceiver) then break end
	end

	if (bestReceiver) then
		receiver = bestReceiver
	else
		for _, v in ipairs(player.GetAll()) do
			if (v:IsCombine() and !v:GetNetVar("IsBiosignalGone", false)) then
				if (!v.ixScn and !v:GetNetVar("ixScanning")) then
					receiver = v
					break
				end
			end
		end
	end

	if (receiver) then
		net.Start("ixSurveillancePhotoRequest")
			net.WriteEntity(camera)
		net.Send(receiver)
	end
end
