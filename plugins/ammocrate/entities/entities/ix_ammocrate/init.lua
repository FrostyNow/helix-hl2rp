include("shared.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

function ENT:Initialize()
	self:SetModel("models/items/ammocrate_smg1.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	local phys = self:GetPhysicsObject()
	if (IsValid(phys)) then
		phys:EnableMotion(false)
		phys:Wake()
	end

	self.cooldowns = {}
	self.bOpening = false

	self:SetNextThink(CurTime())
end

function ENT:Think()
	self:FrameAdvance(FrameTime())
	self:SetNextThink(CurTime())
	return true
end

function ENT:Use(activator)
	if (!activator:IsPlayer()) then return end

	local char = activator:GetCharacter()
	if (!char) then return end

	if (self.bOpening) then return end

	local charID = char:GetID()
	local curTime = CurTime()

	if (self.cooldowns[charID] and self.cooldowns[charID] > curTime) then
		local timeRemaining = math.ceil(self.cooldowns[charID] - curTime)
		activator:NotifyLocalized("ammoCrateUseWait", timeRemaining)
		return
	end

	local weapon = activator:GetActiveWeapon()

	if (!IsValid(weapon) or weapon:GetClass() == "ix_hands" or weapon:GetClass() == "ix_keys") then
		return
	end

	local holdType = weapon:GetHoldType()
	if (holdType == "grenade" or holdType == "slam" or holdType == "melee") then
		return
	end

	local ammoType = weapon:GetPrimaryAmmoType()
	if (ammoType == -1 or ammoType == 0) then
		return
	end

	local maxAmmo = game.GetAmmoMax(ammoType)

	if (maxAmmo <= 0 or maxAmmo >= 9999) then
		local clipSize = weapon:GetMaxClip1()
		if (clipSize and clipSize > 0) then
			maxAmmo = clipSize * 5
		else
			maxAmmo = 150
		end
	end

	local currentAmmo = activator:GetAmmoCount(ammoType)

	if (currentAmmo >= maxAmmo) then
		return
	end

	local openSeq = self:LookupSequence("open")
	local closeSeq = self:LookupSequence("close")

	-- Fallback: try capitalized names if lowercase not found
	if (openSeq < 0) then openSeq = self:LookupSequence("Open") end
	if (closeSeq < 0) then closeSeq = self:LookupSequence("Close") end

	-- If sequences still not found, use fallback durations
	local openDuration = (openSeq >= 0) and self:SequenceDuration(openSeq) or 1.0
	local closeDuration = (closeSeq >= 0) and self:SequenceDuration(closeSeq) or 1.0

	-- Sanity clamp: avoid instant/zero-duration timers
	openDuration = math.max(openDuration, 0.5)
	closeDuration = math.max(closeDuration, 0.5)

	self.bOpening = true
	self:EmitSound("items/ammo_pickup.wav")
	activator:SetAmmo(maxAmmo, ammoType)
	self.cooldowns[charID] = curTime + 300

	if (openSeq >= 0) then
		self:ResetSequence(openSeq)
		self:ResetSequenceInfo()
		self:SetPlaybackRate(1)
	end

	timer.Simple(openDuration, function()
		if (!IsValid(self)) then return end

		self:SetCycle(1)
		self:SetPlaybackRate(0)

		timer.Simple(0.5, function()
			if (!IsValid(self)) then return end

			if (closeSeq >= 0) then
				self:ResetSequence(closeSeq)
				self:ResetSequenceInfo()
				self:SetPlaybackRate(1)
			end

			timer.Simple(closeDuration, function()
				if (!IsValid(self)) then return end
				self:SetCycle(1)
				self:SetPlaybackRate(0)
				self.bOpening = false
			end)
		end)
	end)
end
