AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local MODEL_PATH = "models/breen.mdl"
local SET_SCENES = {
	welcome = "scenes/breencast/welcome.vcd",
	instinct = "scenes/breencast/instinct.vcd",
	collaboration = "scenes/breencast/collaboration.vcd"
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

	if (!scenePath) then
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
	self.lastFrameAdvance = CurTime()
	self.ixBreencastIdleSequence = LookupFirstSequence(self, IDLE_SEQUENCE_NAMES)
	self.ixBreencastFallbackIndex = 0
	self.ixBreencastLastSequence = nil
	self.ixBreencastSceneEntity = nil
	self.ixBreencastSceneID = nil

	timer.Simple(0, function()
		if (IsValid(self)) then
			self:AlignToGround()
			self:ApplyIdleAnimation(true)
		end
	end)

	timer.Simple(1, function()
		if (IsValid(self)) then
			self:AlignToGround()
			self:ApplyIdleAnimation(true)
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
end

function ENT:Think()
	local currentTime = CurTime()
	local delta = math.max(currentTime - (self.lastFrameAdvance or currentTime), 0)

	if (!self:IsRelayActive() and !IsValid(self.ixBreencastSceneEntity)) then
		self:ApplyIdleAnimation(false)
	end

	self:FrameAdvance(delta)
	self.lastFrameAdvance = currentTime
	self:NextThink(currentTime)

	return true
end
