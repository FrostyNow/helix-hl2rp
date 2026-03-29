AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local broadcasts = {
	{sound = "npc/breen/breencast_01.wav", sequence = "br_preach"},
	{sound = "npc/breen/breencast_02.wav", sequence = "br_preach_short"},
	{sound = "npc/breen/breencast_03.wav", sequence = "br_thinking"},
	{sound = "npc/breen/breencast_04.wav", sequence = "br_reproach"},
	{sound = "npc/breen/breencast_05.wav", sequence = "br_reproach_short"},
	{sound = "npc/breen/breencast_06.wav", sequence = "br_look_out"},
	{sound = "npc/breen/breencast_07.wav", sequence = "br_condescending"},
	{sound = "npc/breen/breencast_08.wav", sequence = "br_dismissive"},
	{sound = "npc/breen/breencast_09.wav", sequence = "br_welcomeshort"},
	{sound = "npc/breen/breencast_10.wav", sequence = "br_welcome"},
	{sound = "npc/breen/breencast_11.wav", sequence = "br_preach"},
	{sound = "npc/breen/breencast_12.wav", sequence = "br_preach_short"}
}

function ENT:Initialize()
	self:SetModel("models/breen.mdl")
	self:SetUseType(SIMPLE_USE)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetSolid(SOLID_BBOX)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	
	self:SetInterval(10)
	self:SetLooping(true)
	self:SetPlaying(false)
	
	self.currentIndex = 1

    local phys = self:GetPhysicsObject()
	if (IsValid(phys)) then
		phys:Wake()
		phys:EnableMotion(false)
	end

    self:SetAutomaticFrameAdvance(true)
end

function ENT:Think()
    self:NextThink(CurTime())
    return true
end

function ENT:PlayNextBroadcast()
	if (!self:GetPlaying()) then return end
	
	local broadcast = broadcasts[self.currentIndex]
	if (broadcast) then
		self:EmitSound(broadcast.sound, 75, 100, 1, CHAN_VOICE)
		self:ResetSequence(broadcast.sequence)
		self:SetCycle(0)
		self:SetPlaybackRate(1)
		
		self.currentIndex = self.currentIndex + 1
		if (self.currentIndex > #broadcasts) then
			if (self:GetLooping()) then
				self.currentIndex = 1
			else
				self:SetPlaying(false)
				return
			end
		end
		
		timer.Create("ixBreenCast_"..self:EntIndex(), self:GetInterval(), 1, function()
			if (IsValid(self)) then
				self:PlayNextBroadcast()
			end
		end)
	end
end

function ENT:Use(activator, caller)
	if (activator:IsAdmin()) then
		if (self:GetPlaying()) then
			self:SetPlaying(false)
			activator:NotifyLocalized("breenCastStop")
            timer.Remove("ixBreenCast_"..self:EntIndex())
		else
			self:SetPlaying(true)
			self:PlayNextBroadcast()
			activator:NotifyLocalized("breenCastPlay")
		end
	end
end

function ENT:OnRemove()
    timer.Remove("ixBreenCast_"..self:EntIndex())
end
