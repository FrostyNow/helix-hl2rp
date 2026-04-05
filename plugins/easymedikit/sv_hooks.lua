
local PLUGIN = PLUGIN

PLUGIN.BulletDamages = {
	[DMG_BULLET]    = true,
	[DMG_SLASH]     = true,
	[DMG_BLAST]     = true,
	[DMG_AIRBOAT]   = true,
	[DMG_BUCKSHOT]  = true,
	[DMG_SNIPER]    = true,
	[DMG_MISSILEDEFENSE] = true
}

function PLUGIN:EntityTakeDamage(target, info)
	if ( target:IsValid() and target:IsPlayer() ) then
		local char = target:GetCharacter()
		if (!char) then return end

		local luck = char:GetAttribute("lck", 0)
		local luckMlt = ix.config.Get("luckMultiplier", 1)
		local endurance = char:GetAttribute("end", 0)
		local endMlt = ix.config.Get("enduranceMultiplier", 0.5)
		local maxAttr = ix.config.Get("maxAttributes", 100)
		local normFactor = 100 / maxAttr

		if ( self.BulletDamages[info:GetDamageType()] and target:Armor() <= 0 and target:Team() != FACTION_OTA ) then
			local threshold = 30 - (luck * normFactor * luckMlt * 0.1) - (endurance * normFactor * endMlt * 0.1)

			if ( math.random(1, 100) <= threshold ) then
				self:SetBleeding(target, true)
			end
		elseif ( info:GetDamageType() == DMG_FALL and target:Team() != FACTION_OTA ) then
			local threshold = 30 - (luck * normFactor * luckMlt * 0.2) - (endurance * normFactor * endMlt * 0.2)

			if ( math.random(1, 100) <= threshold ) then
				self:SetFracture(target, true)
			end
		end
	end
end

function PLUGIN:PlayerLoadedCharacter(client, character)
	if (!character:GetFracture()) then
		self:SetFracture(client, false)
	end

	if (!character:GetBleeding()) then
		self:SetBleeding(client, false)
	end

	if (character:GetFracture()) then
		self:SetFracture(client, true)
	end

	if (character:GetBleeding()) then
		self:SetBleeding(client, true)
	end
end

function PLUGIN:SetBleeding(client, status)
	local character = client:GetCharacter()
	if (!character) then return end
	
	local bStatus = hook.Run("CanCharacterGetBleeding", client, character)
	if (bStatus) then return end

	local oldStatus = character:GetBleeding()
	character:SetBleeding(status)

	if (status and !oldStatus) then
		ix.chat.Send(client, "it", L("startBleeding" .. math.random(1, 3), client), false, {client})
	end

	if (status) then
		timer.Create("bleeding."..client:AccountID(), 7, 0, function()
			if IsValid(client) and character then
				client:SetHealth( client:Health() - math.random(3) )
				client:ScreenFade( SCREENFADE.IN, Color(255, 0, 0, 128), 0.3, 0 )

				if (client:Health() <= 0) then
					client:Kill()
					self:ClearWounds(client)
				elseif (client:Health() >= client:GetMaxHealth()) then
					self:ClearWounds(client)
				end
			end
		end)
	else
		if timer.Exists("bleeding."..client:AccountID()) then
			timer.Remove("bleeding."..client:AccountID())
		end
	end
end

function PLUGIN:SetFracture(client, status)
	local character = client:GetCharacter()
	local bStatus = hook.Run("CanCharacterGetFracture", client, character)
	if not (character) then return end
	if (bStatus) then return end

	local oldStatus = character:GetFracture()
	character:SetFracture(status)

	if (status and !oldStatus) then
		ix.chat.Send(client, "it", L("startFracture" .. math.random(1, 3), client), false, {client})
	end

	if (status) then
		client:SetWalkSpeed(ix.config.Get("walkSpeed", 100) / 1.4)
		client:SetRunSpeed(ix.config.Get("walkSpeed", 100) / 1.4)
	else
		client:SetWalkSpeed(ix.config.Get("walkSpeed"))
		client:SetRunSpeed(ix.config.Get("runSpeed"))
	end
end

function PLUGIN:ClearWounds(client)
	self:SetFracture(client, false)
	self:SetBleeding(client, false)
end

function PLUGIN:DoPlayerDeath(client)
	self:ClearWounds(client)
end

function PLUGIN:PlayerDeath(client)
	self:ClearWounds(client)
end