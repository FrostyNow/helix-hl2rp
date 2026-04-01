AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local MODEL_PATH = "models/breen.mdl"
local SET_SCENES = {
	welcome = "scenes/breencast/welcome.vcd",
	instinct = "scenes/breencast/instinct.vcd",
	collaboration = "scenes/breencast/collaboration_plaza.vcd"
}
local IDLE_SEQUENCE_NAMES = {
	"idle_all_01",
	"idle_all_02",
	"idle_subtle",
	"idle_unarmed",
	"br_thinking"
}
local FALLBACK_BROADCAST_SEQUENCES = {
	"br_preach",
	"br_preach_short",
	"br_reproach",
	"br_reproach_short",
	"br_look_out",
	"br_condescending",
	"br_welcomeshort",
	"br_welcome"
}
local FLEX_CANDIDATES = {
	jaw = {
		"jaw_drop",
		"phoneme_ou",
		"phoneme_big_a"
	},
	smileLeft = {
		"left_lip_corner_puller",
		"left_corner_puller",
		"left_smile"
	},
	smileRight = {
		"right_lip_corner_puller",
		"right_corner_puller",
		"right_smile"
	},
	browLeft = {
		"left_inner_raiser",
		"left_outer_raiser"
	},
	browRight = {
		"right_inner_raiser",
		"right_outer_raiser"
	}
}

local function GetTimerID(entity, suffix)
	return "ixBreencast.Entity." .. suffix .. "." .. entity:EntIndex()
end

local function IsValidSequence(sequence)
	return isnumber(sequence) and sequence >= 0
end

local function LookupFirstSequence(entity, names)
	for _, name in ipairs(names) do
		local sequence = entity:LookupSequence(name)

		if (IsValidSequence(sequence)) then
			return sequence
		end
	end
end

function ENT:GetAxisAlignedBoundingBox()
	local mins, maxs = self:GetModelBounds()
	mins = Vector(mins.x, mins.y, 0)
	mins, maxs = self:GetRotatedAABB(mins, maxs)

	return mins, maxs
end

function ENT:InitPhysObj()
	local mins, maxs = self:GetAxisAlignedBoundingBox()
	local created = self:PhysicsInitBox(mins, maxs)

	if (created) then
		local physicsObject = self:GetPhysicsObject()

		if (IsValid(physicsObject)) then
			physicsObject:EnableMotion(false)
			physicsObject:Sleep()
		end
	end
end

function ENT:AlignToGround()
	local position = self:GetPos()
	local angles = self:GetAngles()
	local mins, maxs = self:GetAxisAlignedBoundingBox()
	local trace = util.TraceHull({
		start = position + Vector(0, 0, 16),
		endpos = position - Vector(0, 0, 512),
		mins = mins,
		maxs = maxs,
		filter = self,
		mask = MASK_SOLID_BRUSHONLY
	})

	if (trace.Hit) then
		self:SetPos(trace.HitPos)
	else
		self:DropToFloor()
	end

	self:SetAngles(angles)
end

function ENT:ApplyIdleAnimation(force)
	local sequence = self.ixBreencastIdleSequence

	if (!force and self.ixBreencastLastSequence == sequence) then
		return
	end

	if (!IsValidSequence(sequence)) then
		return
	end

	self:ResetSequence(sequence)
	self:ResetSequenceInfo()
	self:SetCycle(0)
	self:SetPlaybackRate(1)
	self.ixBreencastLastSequence = sequence
end

function ENT:PlayFallbackBroadcastAnimation()
	self.ixBreencastFallbackIndex = (self.ixBreencastFallbackIndex or 0) + 1

	if (self.ixBreencastFallbackIndex > #FALLBACK_BROADCAST_SEQUENCES) then
		self.ixBreencastFallbackIndex = 1
	end

	local sequence = self:LookupSequence(FALLBACK_BROADCAST_SEQUENCES[self.ixBreencastFallbackIndex])

	if (!IsValidSequence(sequence)) then
		return
	end

	self:ResetSequence(sequence)
	self:ResetSequenceInfo()
	self:SetCycle(0)
	self:SetPlaybackRate(1)
	self.ixBreencastLastSequence = sequence
end

local function LookupFlexID(entity, candidates)
	if (!entity.GetFlexIDByName) then
		return
	end

	for _, name in ipairs(candidates) do
		local flexID = entity:GetFlexIDByName(name)

		if (isnumber(flexID) and flexID >= 0) then
			return flexID
		end
	end
end

function ENT:ResolveFlexControllers()
	if (self.ixBreencastFlexIDs) then
		return self.ixBreencastFlexIDs
	end

	self.ixBreencastFlexIDs = {}

	for key, names in pairs(FLEX_CANDIDATES) do
		self.ixBreencastFlexIDs[key] = LookupFlexID(self, names)
	end

	return self.ixBreencastFlexIDs
end

function ENT:SetFlexWeightSafe(key, weight)
	if (!self.SetFlexWeight) then
		return
	end

	local flexID = self:ResolveFlexControllers()[key]

	if (isnumber(flexID) and flexID >= 0) then
		self:SetFlexWeight(flexID, math.Clamp(weight or 0, 0, 1))
	end
end

function ENT:ClearBroadcastExpression()
	self:SetFlexWeightSafe("jaw", 0)
	self:SetFlexWeightSafe("smileLeft", 0)
	self:SetFlexWeightSafe("smileRight", 0)
	self:SetFlexWeightSafe("browLeft", 0)
	self:SetFlexWeightSafe("browRight", 0)
	self:SetPoseParameter("head_pitch", 0)
	self:SetPoseParameter("head_yaw", 0)
	self:SetPoseParameter("eyes_updown", 0)
	self:SetPoseParameter("eyes_rightleft", 0)
end

function ENT:UpdateBroadcastExpression(currentTime)
	local pulse = math.abs(math.sin(currentTime * 7.5))
	local sway = math.sin(currentTime * 1.35)
	local glance = math.sin(currentTime * 0.85)

	self:SetFlexWeightSafe("jaw", 0.12 + pulse * 0.58)
	self:SetFlexWeightSafe("smileLeft", 0.04 + pulse * 0.12)
	self:SetFlexWeightSafe("smileRight", 0.05 + pulse * 0.1)
	self:SetFlexWeightSafe("browLeft", 0.08 + math.max(sway, 0) * 0.14)
	self:SetFlexWeightSafe("browRight", 0.08 + math.max(-sway, 0) * 0.14)
	self:SetPoseParameter("head_pitch", 1.5 + sway * 4)
	self:SetPoseParameter("head_yaw", glance * 8)
	self:SetPoseParameter("eyes_updown", sway * 1.5)
	self:SetPoseParameter("eyes_rightleft", glance * 2)
end

function ENT:StopSetScene()
	local sceneEntity = self.ixBreencastSceneEntity

	if (IsValid(sceneEntity)) then
		sceneEntity:Remove()
	end

	self.ixBreencastSceneEntity = nil
	self.ixBreencastSceneID = nil
end

function ENT:StartSetScene(setID)
	local scenePath = SET_SCENES[setID]

	self:StopSetScene()

	if (!scenePath or !file.Exists(scenePath, "GAME")) then
		return false
	end

	if (!self.PlayScene) then
		return false
	end

	local sceneEntity = self:PlayScene(scenePath)

	if (IsValid(sceneEntity)) then
		self.ixBreencastSceneEntity = sceneEntity
		self.ixBreencastSceneID = setID
		return true
	end

	return false
end

function ENT:Initialize()
	local plugin = ix.plugin.Get("breencast")

	self:SetModel(MODEL_PATH)
	self:SetUseType(SIMPLE_USE)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_BBOX)
	self:DrawShadow(true)
	self:InitPhysObj()
	self:SetCollisionBounds(self:GetAxisAlignedBoundingBox())
	self:AddCallback("OnAngleChange", function(entity)
		local mins, maxs = entity:GetAxisAlignedBoundingBox()

		entity:SetCollisionBounds(mins, maxs)
		entity:AlignToGround()
	end)

	self:SetPlaying(false)
	self:SetLooping(true)
	self:SetBroadcasting(false)
	self:SetLiveRelay(false)
	self:SetVolume(plugin and plugin.defaultVolume or 80)
	self:SetInterval(plugin and plugin.repeatDelay or 300)
	self:SetActiveUntil(0)
	self:SetBroadcastDuration(0)
	self:SetCurrentText("")
	self:SetCurrentSource("")

	self.ixBreencastIdleSequence = LookupFirstSequence(self, IDLE_SEQUENCE_NAMES)
	self.ixBreencastFallbackIndex = 0
	self.ixBreencastLastSequence = nil
	self.ixBreencastSceneEntity = nil
	self.ixBreencastSceneID = nil
	self.ixBreencastFlexIDs = nil

	-- NPC-specific initialization for VCDs
	if (self.SetCapability) then
		self:SetCapability(CAP_ANIMATEDFACE)
		self:SetCapability(CAP_TURN_HEAD)
	end

	timer.Simple(0, function()
		if (IsValid(self)) then
			self:AlignToGround()
			self:ApplyIdleAnimation(true)
			self:ClearBroadcastExpression()
		end
	end)
end

function ENT:SpawnFunction(client, trace)
	if (!trace.Hit) then
		return
	end

	local angles = client:EyeAngles()
	angles.p = 0
	angles.r = 0
	angles.y = angles.y + 180

	local entity = ents.Create("ix_breencast")
	entity:SetPos(trace.HitPos)
	entity:SetAngles(angles)
	entity:Spawn()
	entity:Activate()

	local plugin = ix.plugin.Get("breencast")

	if (plugin) then
		plugin:SaveData()
	end

	return entity
end

function ENT:FinishBroadcast(stopScene)
	self:SetBroadcasting(false)
	self:SetLiveRelay(false)
	self:SetActiveUntil(0)
	self:SetBroadcastDuration(0)
	self:SetCurrentText("")
	self:SetCurrentSource("")

	if (stopScene == true) then
		self:StopSetScene()
	end

	self:ClearBroadcastExpression()
	self:ApplyIdleAnimation(true)
	timer.Remove(GetTimerID(self, "clear"))
end

function ENT:StartRelay(text, duration, source, isLive)
	duration = math.max(duration or 0, 0.1)

	timer.Remove(GetTimerID(self, "clear"))

	self:SetBroadcasting(true)
	self:SetLiveRelay(isLive == true)
	self:SetCurrentText(tostring(text or ""))
	self:SetCurrentSource(tostring(source or ""))
	self:SetActiveUntil(CurTime() + duration)
	self:SetBroadcastDuration(duration)

	if (!IsValid(self.ixBreencastSceneEntity)) then
		self:PlayFallbackBroadcastAnimation()
	end

	timer.Create(GetTimerID(self, "clear"), duration, 1, function()
		if (IsValid(self)) then
			self:FinishBroadcast(false)
		end
	end)
end

function ENT:Use(activator)
	if (IsValid(activator) and activator:IsPlayer() and activator:IsAdmin()) then
		activator:NotifyLocalized("breenCastUseHint")
	end
end

function ENT:OnRemove()
	timer.Remove(GetTimerID(self, "clear"))
	self:StopSetScene()
	self:ClearBroadcastExpression()
end

function ENT:Think()
	local currentTime = CurTime()

	if (self:IsRelayActive()) then
		if (!IsValid(self.ixBreencastSceneEntity)) then
			-- Only apply manual expressions if no VCD is playing
			self:UpdateBroadcastExpression(currentTime)

			if (self:GetCycle() >= 0.98) then
				self:PlayFallbackBroadcastAnimation()
			end
		end
	else
		if (!IsValid(self.ixBreencastSceneEntity)) then
			self:ClearBroadcastExpression()
		end
	end

	if (!self:IsRelayActive() and !IsValid(self.ixBreencastSceneEntity)) then
		self:ApplyIdleAnimation(false)
	end

	self:NextThink(currentTime)
	return true
end
