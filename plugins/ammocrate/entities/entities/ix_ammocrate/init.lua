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
end

function ENT:Use(activator)
	if (!activator:IsPlayer()) then return end
	
	local char = activator:GetCharacter()
	if (!char) then return end
	
	if (self.bOpening) then return end
	
	-- Cooldown logic
	local charID = char:GetID()
	local curTime = CurTime()
	
	if (self.cooldowns[charID] and self.cooldowns[charID] > curTime) then
		local timeRemaining = math.ceil(self.cooldowns[charID] - curTime)
		activator:NotifyLocalized("ammoCrateUseWait", timeRemaining)
		return
	end
	
	-- Weapon checks
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
	
	-- Max ammo calculation fallback
	local maxAmmo = game.GetAmmoMax(ammoType)
	
	-- If the game's max ammo is not set properly, calculate a reasonable capacity amount based on max clip size
	if (maxAmmo <= 0 or maxAmmo >= 9999) then
		local clipSize = weapon:GetMaxClip1()
		if (clipSize and clipSize > 0) then
			maxAmmo = clipSize * 5
		else
			maxAmmo = 150 -- Arbitrary reasonable amount for weapons with no clip
		end
	end
	
	local currentAmmo = activator:GetAmmoCount(ammoType)
	
	if (currentAmmo >= maxAmmo) then
		return
	end
	
	-- Success: Play animations and replenish ammo
	local openSeq = self:LookupSequence("Open")
	local closeSeq = self:LookupSequence("Close")
	local openDuration = self:SequenceDuration(openSeq)
	local closeDuration = self:SequenceDuration(closeSeq)

	self:ResetSequence(openSeq)
	self:SetPlaybackRate(1)
	self:EmitSound("items/ammo_pickup.wav")
	self.bOpening = true

	activator:SetAmmo(maxAmmo, ammoType)

	-- Set 5 minutes cooldown (300 seconds)
	self.cooldowns[charID] = curTime + 300

	-- Hold at last frame of Open, then play Close
	timer.Simple(openDuration, function()
		if (!IsValid(self)) then return end
		self:SetCycle(1)
		self:SetPlaybackRate(0)

		timer.Simple(0.5, function()
			if (!IsValid(self)) then return end
			self:ResetSequence(closeSeq)
			self:SetPlaybackRate(1)

			timer.Simple(closeDuration, function()
				if (!IsValid(self)) then return end
				self:SetCycle(1)
				self:SetPlaybackRate(0)
				self.bOpening = false
			end)
		end)
	end)
end
