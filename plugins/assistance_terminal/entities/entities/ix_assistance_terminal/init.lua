AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
	self:SetModel("models/props_combine/combine_smallmonitor001.mdl")
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)
	self:SetSolid(SOLID_VPHYSICS)

	self:SetNetVar("alarm", false)
end

function ENT:Use(ply)
	local bIsCombine = ply:IsCombine()

	if (bIsCombine) then
		if ( self:GetNetVar("alarm", false) ) then
			self:EmitSound("buttons/combine_button5.wav")
			self:SetNetVar("alarm", false)
			self:SetNetVar("requester", nil)

			local waypointPlugin = ix.plugin.Get("waypoints")
			if (waypointPlugin) then
				local waypointIndex = self:GetNetVar("waypoint")

				if ( waypointIndex ) then
					waypointPlugin:UpdateWaypoint(waypointIndex, nil)
					self:SetNetVar("waypoint", nil)
				end
			end
		end
		return
	end

	-- Citizen logic
	if ( self:GetNetVar("alarm", false) ) then
		if ((self.nextLockSoundTime or 0) < CurTime()) then
			self:EmitSound("buttons/combine_button_locked.wav")
			self.nextLockSoundTime = CurTime() + 1
		end
		return
	end

	if ( (self.nextUseTime or 0) > CurTime() ) then
		if ((self.nextLockSoundTime or 0) < CurTime()) then
			self:EmitSound("buttons/combine_button_locked.wav")
			self.nextLockSoundTime = CurTime() + 1
		end

		local timeLeft = math.ceil(self.nextUseTime - CurTime())
		ply:NotifyLocalized("terminalCooldown", timeLeft)
		return
	end

	if ( !ply:GetCharacter():GetInventory():HasItem("cid") ) then
		if ((self.nextLockSoundTime or 0) < CurTime()) then
			self:EmitSound("buttons/combine_button_locked.wav")
			self.nextLockSoundTime = CurTime() + 1
		end

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
		local cidName = "Anonymous"
		local cidID = "000000"
		for _, v in pairs(ply:GetCharacter():GetInventory():GetItems()) do
			if (v.uniqueID == "cid") then
				cidName = v:GetData("name")
				cidID = v:GetData("id")
				break
			end
		end

		if (!area or area == "") then
			area = "@terminalUnknownLocation"
		end

		self:EmitSound("buttons/combine_button1.wav")
		self:SetNetVar("alarm", true)
		self:SetNetVar("requester", cidName)

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
