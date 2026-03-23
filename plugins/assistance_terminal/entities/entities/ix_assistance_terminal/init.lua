AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

local function PlayLockedSound(entity)
	if ((entity.nextLockSoundTime or 0) < CurTime()) then
		entity:EmitSound("buttons/combine_button_locked.wav")
		entity.nextLockSoundTime = CurTime() + 1
	end
end

local function ClearRequestState(entity, activator)
	entity:EmitSound("buttons/combine_button5.wav")
	entity:SetNetVar("alarm", false)
	entity:SetNetVar("alarmLights", false)
	entity:SetNetVar("requester", nil)
	entity:SetNetVar("requesterCharID", nil)

	local waypointPlugin = ix.plugin.Get("waypoints")
	if (waypointPlugin) then
		local waypointIndex = entity:GetNetVar("waypoint")

		if (waypointIndex) then
			waypointPlugin:UpdateWaypoint(waypointIndex, nil)
			entity:SetNetVar("waypoint", nil)
		end
	end

	if (IsValid(activator)) then
		activator:NotifyLocalized("terminalRequestCancelled")
	end
end

local function CanCancelRequest(entity, ply)
	if (!IsValid(ply) or !entity:GetNetVar("alarm", false)) then
		return false
	end

	if (ply:IsCombine()) then
		return true
	end

	if (ply:IsAdmin() and ply:GetMoveType() == MOVETYPE_NOCLIP) then
		return true
	end

	local character = ply:GetCharacter()
	local requesterCharID = entity:GetNetVar("requesterCharID")

	return character and requesterCharID and character:GetID() == requesterCharID
end

function ENT:Initialize()
	self:SetModel("models/props_combine/combine_smallmonitor001.mdl")
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)
	self:SetSolid(SOLID_VPHYSICS)

	self:SetNetVar("alarm", false)
	self:SetNetVar("requesterCharID", nil)
end

function ENT:Use(ply)
	if ( self:GetNetVar("alarm", false) ) then
		if (CanCancelRequest(self, ply)) then
			ClearRequestState(self, ply)
		else
			PlayLockedSound(self)
			ply:NotifyLocalized("terminalOnlyRequesterCanCancel")
		end

		return
	end

	local character = ply:GetCharacter()

	if (!character) then
		return
	end

	if (ply:IsCombine()) then
		PlayLockedSound(self)
		return
	end

	if ( (self.nextUseTime or 0) > CurTime() ) then
		PlayLockedSound(self)

		local timeLeft = math.ceil(self.nextUseTime - CurTime())
		ply:NotifyLocalized("terminalCooldown", timeLeft)
		return
	end

	if ( !Schema.HasCharacterIdentification or !Schema:HasCharacterIdentification(character) ) then
		PlayLockedSound(self)

		ply:NotifyLocalized("terminalNeedsCID")
		return
	end

	local combineAvailable = false
	for k, v in pairs(player.GetAll()) do
		if ( v:IsCombine() ) then
			combineAvailable = true
			break
		end
	end

	-- Allow use regardless of CP count if it was hardcoded before, 
	-- but let's stick to the config-like behavior or what was there.
	-- The original had combineAvailable = true at the end.
	combineAvailable = true

	if (!combineAvailable) then
		ply:NotifyLocalized("terminalNoOfficers")
		return
	end

	local actionTime = ix.config.Get("assistanceTerminalActionTime", 5)

	ply:SetAction("@terminalRequesting", actionTime)
	ply:DoStaredAction(self, function()
		if (!IsValid(self) or !IsValid(ply)) then return end
		if (ply:GetPos():DistToSqr(self:GetPos()) > 6400) then
			ply:NotifyLocalized("tooFar")
			return
		end

		if (self:GetNetVar("alarm", false)) then return end

		local area = ply:GetAreaName()
		local identification = Schema.GetIdentificationData and Schema:GetIdentificationData(character) or nil
		local cidName = identification and identification.name or "Anonymous"
		local cidID = identification and identification.id or "000000"

		if (!area or area == "") then
			area = "@terminalUnknownLocation"
		end

		self:EmitSound("buttons/combine_button1.wav")
		self:SetNetVar("alarm", true)
		self:SetNetVar("requester", cidName)
		self:SetNetVar("requesterCharID", character:GetID())

		ix.chat.Send(ply, "dispatchradio", L("terminalDispatch", nil, area:sub(1,1) == "@" and L(area:sub(2)) or area, cidName), false, nil)

		local requesterDisplay = string.format("%s #%s", cidName, cidID)

		local waypointPlugin = ix.plugin.Get("waypoints")
		if (waypointPlugin) then
			local waypoint = {
				pos = ply:EyePos(),
				text = "@terminalRequest",
				arguments = {requesterDisplay, area},
				color = team.GetColor(ply:Team()),
				addedBy = ply,
				time = CurTime() + 180
			}

			self:SetNetVar("waypoint", #waypointPlugin.waypoints + 1)
			waypointPlugin:AddWaypoint(waypoint)
		end

		self.nextUseTime = CurTime() + ix.config.Get("assistanceTerminalCooldown", 60)
	end, actionTime, function()
		ply:SetAction(false)
	end)
end

function ENT:Think()
	if ( ( self.NextAlert or 0 ) <= CurTime() and self:GetNetVar("alarm") ) then
		self.NextAlert = CurTime() + 3

		self:EmitSound("ambient/alarms/klaxon1.wav", 80, 70)
		self:EmitSound("ambient/alarms/klaxon1.wav", 80, 80)

		self:SetNetVar("alarmLights", true)
		
		timer.Simple(2, function()
			self:SetNetVar("alarmLights", false)
		end)
	end

	self:NextThink(CurTime() + 2)
end
