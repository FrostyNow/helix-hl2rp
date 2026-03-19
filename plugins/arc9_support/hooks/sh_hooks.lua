local PLUGIN = PLUGIN
local retryTimer = "ixARC9SupportRetry"
local minimumRaiseDuration = 0.1

local function patchARC9Items()
	if (ix.arc9 and ix.arc9.PatchWeaponItems) then
		ix.arc9.PatchWeaponItems()
	end
end

local function shouldWeaponStayRaised(client, weapon)
	if (not IsValid(client) or not IsValid(weapon)) then
		return false
	end

	if (weapon.IsAlwaysRaised or (ALWAYS_RAISED and ALWAYS_RAISED[weapon:GetClass()])) then
		return true
	end

	if (weapon.IsAlwaysLowered or weapon.NeverRaised or client:IsRestricted()) then
		return false
	end

	return ix.config.Get("weaponAlwaysRaised", false) == true
end

local function getAnimationEndTime(weapon, minimumDuration)
	local endTime = CurTime() + (minimumDuration or minimumRaiseDuration)

	if (isfunction(weapon.GetNextPrimaryFire)) then
		endTime = math.max(endTime, weapon:GetNextPrimaryFire())
	end

	if (isfunction(weapon.GetNextSecondaryFire)) then
		endTime = math.max(endTime, weapon:GetNextSecondaryFire())
	end

	return endTime
end

local function getARC9DeployEndTime(weapon)
	local endTime = CurTime() + minimumRaiseDuration

	if (isfunction(weapon.GetAnimLockTime)) then
		endTime = math.max(endTime, weapon:GetAnimLockTime())
	end

	if (isfunction(weapon.GetReadyTime)) then
		endTime = math.max(endTime, weapon:GetReadyTime())
	end

	return math.max(endTime, getAnimationEndTime(weapon))
end

local function getARC9HolsterEndTime(weapon)
	if (isfunction(weapon.GetHolsterTime)) then
		local holsterTime = weapon:GetHolsterTime()

		if (isnumber(holsterTime) and holsterTime > CurTime()) then
			return holsterTime
		end
	end

	return getAnimationEndTime(weapon)
end

local function holdRaisedUntil(client, weapon, endTime)
	if (not IsValid(client) or not IsValid(weapon)) then
		return
	end

	endTime = math.max(endTime or 0, CurTime() + minimumRaiseDuration)
	weapon.ixARC9RaisedUntil = math.max(weapon.ixARC9RaisedUntil or 0, endTime)
	client.ixARC9RaisedUntil = math.max(client.ixARC9RaisedUntil or 0, endTime)
	client:SetNetVar("raised", true)

	if (isfunction(weapon.SetSafe)) then
		weapon:SetSafe(false)
	end
end

local function clearAnimationRaise(client)
	if (not IsValid(client)) then
		return
	end

	client.ixARC9RaisedUntil = nil

	local weapon = client:GetActiveWeapon()

	if (not IsValid(weapon)) then
		client:SetNetVar("raised", false)
		client:SetNetVar("canShoot", false)
		return
	end

	local bRaised = shouldWeaponStayRaised(client, weapon)
	client:SetWepRaised(bRaised, weapon)

	if (isfunction(weapon.SetSafe)) then
		weapon:SetSafe(not bRaised)
	end
end

local function patchARC9BaseSWEP()
	local swep = weapons.GetStored("arc9_base")

	if (not swep) then
		return false
	end

	if (swep.ixARC9SupportPatched) then
		return true
	end

	swep.ixARC9SupportPatched = true

	if (CLIENT) then
		function swep:UpdateItemPreset()
			local client = LocalPlayer()
			local character = IsValid(client) and client:GetCharacter()

			if (not character) then
				return
			end

			net.Start("ixARC9UpdatePreset")
				net.WriteUInt(character:GetID(), 32)
				net.WriteUInt(self:EntIndex(), 32)
				net.WriteString(self:GeneratePresetExportCode())
			net.SendToServer()
		end

		local originalPostModify = swep.PostModify

		if (isfunction(originalPostModify)) then
			function swep:PostModify(...)
				local results = {originalPostModify(self, ...)}
				local owner = self.GetOwner and self:GetOwner()

				if (not self.ixARC9BlockPresetUpdate and IsValid(owner) and owner == LocalPlayer() and isfunction(self.UpdateItemPreset)) then
					self:UpdateItemPreset()
				end

				return unpack(results)
			end
		end

		local originalLoadPreset = swep.LoadPreset

		if (isfunction(originalLoadPreset)) then
			function swep:LoadPreset(...)
				local results = {originalLoadPreset(self, ...)}
				local owner = self.GetOwner and self:GetOwner()

				if (not self.ixARC9BlockPresetUpdate and IsValid(owner) and owner == LocalPlayer() and isfunction(self.UpdateItemPreset)) then
					self:UpdateItemPreset()
				end

				return unpack(results)
			end
		end
	end

	if (SERVER) then
		local originalDeploy = swep.Deploy
		function swep:Deploy(...)
			local results = {}
			if (isfunction(originalDeploy)) then
				results = {originalDeploy(self, ...)}
			end

			local owner = self:GetOwner()

			if (IsValid(owner)) then
				timer.Simple(0, function()
					if (IsValid(owner) and IsValid(self) and owner:GetActiveWeapon() == self) then
						holdRaisedUntil(owner, self, getARC9DeployEndTime(self))
					end
				end)
			end

			return unpack(results)
		end

		function swep:OnRaised()
			if (isfunction(self.SetSafe)) then self:SetSafe(false) end
		end

		function swep:OnLowered()
			if (isfunction(self.SetSafe)) then self:SetSafe(true) end
		end

		local originalThink = swep.Think
		function swep:Think(...)
			if (isfunction(originalThink)) then
				return originalThink(self, ...)
			end
		end

		local originalHolster = swep.Holster
		function swep:Holster(...)
			local owner = self:GetOwner()
			if (isfunction(originalHolster)) then
				local bCanHolster = originalHolster(self, ...)

				if ((bCanHolster == false or bCanHolster == nil) and IsValid(owner)) then
					holdRaisedUntil(owner, self, getARC9HolsterEndTime(self))
				elseif (bCanHolster == true and IsValid(owner)) then
					-- Immediate holsters should not leak a fake raised state into the next weapon.
					if ((owner.ixARC9RaisedUntil or 0) > CurTime()) then
						clearAnimationRaise(owner)
					end
				else
					self.ixARC9RaisedUntil = nil
				end

				return bCanHolster
			end

			return true
		end
	end

	return true
end

local function initializeARC9Support()
	local attachmentItemsReady = true

	if (ix.arc9 and ix.arc9.CacheAttachmentTemplates) then
		ix.arc9.CacheAttachmentTemplates(true)
	end

	if (ix.arc9 and ix.arc9.RegisterAttachmentItems) then
		attachmentItemsReady = ix.arc9.RegisterAttachmentItems(true) ~= false
	end

	patchARC9Items()
	return patchARC9BaseSWEP() and attachmentItemsReady
end

function PLUGIN:InitializedPlugins()
	timer.Simple(0, initializeARC9Support)

	if (timer.Exists(retryTimer)) then
		timer.Remove(retryTimer)
	end

	timer.Create(retryTimer, 1, 30, function()
		if (initializeARC9Support()) then
			timer.Remove(retryTimer)
		end
	end)
end

function PLUGIN:InitializedConfig()
	initializeARC9Support()
end

function PLUGIN:Think()
	if (CLIENT) then
		return
	end

	for _, client in player.Iterator() do
		local raisedUntil = client.ixARC9RaisedUntil

		if (not raisedUntil) then
			continue
		end

		if (raisedUntil > CurTime()) then
			client:SetNetVar("raised", true)
		else
			clearAnimationRaise(client)
		end
	end
end

function PLUGIN:PlayerWeaponChanged(client, weapon)
	if (CLIENT or not IsValid(client)) then
		return
	end

	if ((client.ixARC9RaisedUntil or 0) <= CurTime()) then
		return
	end

	timer.Simple(0, function()
		if (IsValid(client) and (client.ixARC9RaisedUntil or 0) > CurTime()) then
			client:SetNetVar("raised", true)
		end
	end)
end

function PLUGIN:PlayerDisconnected(client)
	client.ixARC9RaisedUntil = nil
end

function PLUGIN:ARC9_PlayerGetAtts(client, att)
	if (not ix.arc9 or not ix.arc9.CountAttachmentItems) then
		return
	end

	return ix.arc9.CountAttachmentItems(client, att)
end

function PLUGIN:ARC9_PlayerTakeAtt(client, att, amount)
	if (CLIENT or not ix.arc9 or not ix.arc9.TakeAttachmentItems) then
		return
	end

	if ((client.ixARC9SuppressAttInventorySync or 0) > 0) then
		return true
	end

	return ix.arc9.TakeAttachmentItems(client, att, amount)
end

function PLUGIN:ARC9_PlayerGiveAtt(client, att, amount)
	if (CLIENT or not ix.arc9 or not ix.arc9.GiveAttachmentItems) then
		return
	end

	if ((client.ixARC9SuppressAttInventorySync or 0) > 0) then
		return true
	end

	return ix.arc9.GiveAttachmentItems(client, att, amount)
end
