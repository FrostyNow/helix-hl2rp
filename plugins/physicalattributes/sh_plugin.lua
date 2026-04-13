
PLUGIN.name = "Attribute System"
PLUGIN.author = "Hoooldini | Modified by Frosty"
PLUGIN.description = "Implementation of an attribute system for roleplay."

ix.lang.AddTable("english", {
	attrViewInfo = "Attribute information for %s:",
	cmdCharGetAttr = "View a character's attributes.",
	cmdRollStat = "Rolls and adds a bonus for the stat provided."
})

ix.lang.AddTable("korean", {
	attrViewInfo = "%s 캐릭터의 능력치 정보:",
	cmdCharGetAttr = "대상 캐릭터의 능력치를 확인합니다.",
	cmdRollStat = "제공된 능력치의 보너스를 더해 주사위를 굴립니다."
})

-- [[ CONFIGURATION OPTIONS ]] --

ix.config.Add("enableStamina", true, "Whether or not stamina drain is enabled.", nil, {
	category = "Stamina"
})

ix.config.Add("strengthMeleeMultiplier", 0.3, "The strength multiplier for melee damage.", nil, {
	data = {min = 0, max = 1.0, decimals = 1},
	category = "Attributes"
})

ix.config.Add("strengthMultiplier", 1, "The strength multiplier for carrying objects.", nil, {
	data = {min = 0, max = 10.0, decimals = 1},
	category = "Attributes"
})

ix.config.Add("enduranceMultiplier", 0.2, "Mutiplies the health that endurance adds to characters.", nil, {
	data = {min = 0, max = 10.0, decimals = 1},
	category = "Attributes"
})

ix.config.Add("agilityMultiplier", 0.5, "Mutiplies the speed that agility adds to sprinting.", nil, {
	data = {min = 0, max = 10.0, decimals = 1},
	category = "Attributes"
})

ix.config.Add("luckMultiplier", 1, "The luck multiplier.", nil, {
	data = {min = 0, max = 10.0, decimals = 1},
	category = "Attributes"
})

ix.config.Add("intelligenceMultiplier", 0.5, "The intelligence multiplier.", nil, {
	data = {min = 0, max = 10.0, decimals = 1},
	category = "Attributes"
})

ix.config.Add("staminaMax", 0, "Max amount of stamina players will have.", nil, {
	data = {min = -30, max = 30, decimals = 2},
	category = "Stamina"
})

ix.config.Add("staminaDrain", 1, "How much stamina to drain per tick (every quarter second). This is calculated before attribute reduction.", nil, {
	data = {min = 0, max = 10, decimals = 2},
	category = "Stamina"
})

ix.config.Add("staminaRegeneration", 1.75, "How much stamina to regain per tick (every quarter second).", nil, {
	data = {min = 0, max = 10, decimals = 2},
	category = "Stamina"
})

ix.config.Add("staminaCrouchRegeneration", 2, "How much stamina to regain per tick (every quarter second) while crouching.", nil, {
	data = {min = 0, max = 10, decimals = 2},
	category = "Stamina"
})

ix.config.Add("jumpPower", 200, "How high a player normally jumps.", function(oldValue, newValue)
	for _, v in ipairs(player.GetAll())	do
		v:SetJumpPower(newValue)
	end
end, {
	data = {min = 75, max = 500},
	category = "characters"
})

ix.config.Add("gunAimPunch", 1, "The multiplier for aim punch when hit by a gun.", nil, {
	data = {min = 0, max = 5, decimals = 1},
	category = "Attributes"
})

ix.config.Add("meleeAimPunch", 1, "The multiplier for aim punch when hit by a melee weapon.", nil, {
	data = {min = 0, max = 5, decimals = 1},
	category = "Attributes"
})

ix.config.Add("maxAimPunch", 30, "The maximum degrees a player's aim can be punched upwards.", nil, {
	data = {min = 10, max = 90},
	category = "Attributes"
})

ix.config.Add("aimSwayIntensity", 1, "The intensity of the noise-based aim sway.", nil, {
	data = {min = 0, max = 5, decimals = 1},
	category = "Attributes"
})

-- [[ COMMANDS ]] --

--[[
	COMMAND: /RollStat
	DESCRIPTION: RollStat is designed to allow for a client to roll one of their attributes in a 1-100 roll. Attributes must be
	their three letter abbreviation as designated in their file name.
]]--

ix.command.Add("RollStat", {
	syntax = "<stat>",
	description = "@cmdRollStat",
	arguments = {
		ix.type.text
	},
	OnRun = function(self, client, stat)
		local character = client:GetCharacter()

		if (character and character:GetAttribute(stat, 0)) then
			local bonus = character:GetAttribute(stat, 0)
			local roll = tostring(math.random(0, 100))

			ix.chat.Send(client, "roll", (roll + bonus).." ( "..roll.." + "..stat..bonus.." )", nil, nil, {
				max = maximum
			})
		end
	end
})

ix.command.Add("CharGetAttr", {
	syntax = "<string target>",
	description = "@cmdCharGetAttr",
	adminOnly = true,
	arguments = {
		ix.type.character
	},
	OnRun = function(self, client, target)
		local text = "\n" .. L("attrViewInfo", client, target:GetName())
		
		for k, v in pairs(ix.attributes.list) do
			local value = target:GetAttribute(k, 0)
			local name = L(v.name or k, client)
			text = text .. string.format("\n- %s (%s): %s", name, k, value)
		end

		return text
	end
})

-- [[ FUNCTIONS ]] --

if (SERVER) then

	--[[
		FUNCTION: PLUGIN:PostPlayerLoadout(client)
		DESCRIPTION: Code taken from the stamina plugin that was taken for use here.
		Sets up the stamina and run speed of the character and contains hooks for stamina.
	]]--

	function PLUGIN:PostPlayerLoadout(client)
		local uniqueID = "ixStam"..client:SteamID()
		local offset = 0
		local runSpeed = client:GetRunSpeed() - 5

		timer.Create(uniqueID, 0.25, 0, function()
			if (!IsValid(client)) then
				timer.Remove(uniqueID)
				return
			end

			local character = client:GetCharacter()

			if (!character or client:GetMoveType() == MOVETYPE_NOCLIP) then
				return
			end

			runSpeed = ix.config.Get("runSpeed") + (character:GetAttribute("stm", 0) * ix.config.Get("agilityMultiplier"))

			if (client:WaterLevel() > 1) then
				runSpeed = runSpeed * 0.775
			end

			local walkSpeed = ix.config.Get("walkSpeed")
			local maxAttributes = ix.config.Get("maxAttributes", 30)

			local bSprinting = client:KeyDown(IN_SPEED) and client:GetVelocity():LengthSqr() >= (walkSpeed * walkSpeed)
			local bSwimming = client:WaterLevel() > 1 and !client:IsOnGround()

			if (ix.config.Get("enableStamina", false) and (bSprinting or bSwimming)) then
				local multiplier = (bSprinting and bSwimming) and 2 or 1

				-- characters could have attribute values greater than max if the config was changed
				offset = -ix.config.Get("staminaDrain", 1) * multiplier + math.min(ix.config.Get("staminaMax", 0), maxAttributes) / maxAttributes
			else
				offset = client:Crouching() and ix.config.Get("staminaCrouchRegeneration", 2) or ix.config.Get("staminaRegeneration", 1.75)
			end

			offset = hook.Run("AdjustStaminaOffset", client, offset) or offset

			local current = client:GetLocalVar("stm", 0)
			local value = math.Clamp(current + offset, 0, 100)

			if (current != value) then
				client:SetLocalVar("stm", value)

				if (value == 0 and !client:GetNetVar("brth", false)) then
					client:SetRunSpeed(walkSpeed)
					client:SetNetVar("brth", true)

					character:UpdateAttrib("end", 0.01)
					character:UpdateAttrib("stm", 0.01)

					hook.Run("PlayerStaminaLost", client)
				elseif (value >= 50 and client:GetNetVar("brth", false)) then
					client:SetRunSpeed(runSpeed)
					client:SetNetVar("brth", nil)

					hook.Run("PlayerStaminaGained", client)
				end
			end
		end)
	end

	--[[
		FUNCTION: PLUGIN:CharacterPreSave(character)
		DESCRIPTION: Code taken from the stamina plugin that was taken for use here.
		Saves stamina of the character, or the agility depending on how you look at it.
	]]--

	function PLUGIN:CharacterPreSave(character)
		local client = character:GetPlayer()

		if (IsValid(client)) then
			character:SetData("stamina", client:GetLocalVar("stm", 0))
		end
	end

	--[[
		FUNCTION: PLUGIN:PlayerLoadedCharacter(client, character)
		DESCRIPTION: Code taken from the stamina plugin that was taken for use here.
		Sets stamina of the character, or the agility depending on how you look at it.
	]]--

	function PLUGIN:PlayerLoadedCharacter(client, character)
		timer.Simple(0.25, function()
			client:SetLocalVar("stm", character:GetData("stamina", 100))
		end)
	end

	local playerMeta = FindMetaTable("Player")

	--[[
		FUNCTION: PLUGIN:RestoreStamina(amount)
		DESCRIPTION: Code taken from the stamina plugin that was taken for use here.
		Restores the stamina of the character, probably.
	]]--

	function playerMeta:RestoreStamina(amount)
		local current = self:GetLocalVar("stm", 0)
		local value = math.Clamp(current + amount, 0, 100)

		self:SetLocalVar("stm", value)
	end

	--[[
		FUNCTION: PLUGIN:GetPlayerPunchDamage(client, damage, context)
		DESCRIPTION: Code taken from the strength plugin. Changes the damage value of the fists.
	]]--

	function PLUGIN:GetPlayerPunchDamage(client, damage, context)
		if (client:GetCharacter()) then
			local strength = client:GetCharacter():GetAttribute("str", 0)
			local scaledDamage = 1 + (strength * ix.config.Get("strengthMeleeMultiplier", 0.3))

			-- Fists start at 1 damage and are hard-capped to 10.
			-- context.damage = math.Clamp(scaledDamage, 1, 10)
			context.damage = damage + (strength * ix.config.Get("strengthMeleeMultiplier", 0.3))
		end
	end

	function PLUGIN:EntityTakeDamage(entity, dmgInfo)
		if (!IsValid(entity) or !entity:IsPlayer() or dmgInfo:GetDamage() <= 0) then
			return
		end

		local bIsBullet = dmgInfo:IsBulletDamage()
		local bIsMelee = dmgInfo:IsDamageType(DMG_CLUB) or dmgInfo:IsDamageType(DMG_SLASH) or dmgInfo:IsDamageType(DMG_GENERIC) or dmgInfo:IsDamageType(DMG_SHOCK)
		local bIsBlast = dmgInfo:IsDamageType(DMG_BLAST)
		local bIsFall = dmgInfo:IsDamageType(DMG_FALL)

		local armorMultiplier = (entity:Armor() > 0) and 0.5 or 1
		local endurance = 0
		local maxAttr = ix.config.Get("maxAttributes", 30)
		local character = entity:GetCharacter()

		if (character) then
			endurance = character:GetAttribute("end", 0)
		end

		-- Reduce punch intensity based on endurance (up to 85% reduction at max endurance)
		local attribMultiplier = 1 - (math.min(endurance, maxAttr) / maxAttr * 0.85)
		local finalMultiplier = armorMultiplier * attribMultiplier

		-- Accumulate and limit aim punch to prevent "lifting to the sky"
		local curTime = CurTime()
		entity.ixAimPunchAccum = entity.ixAimPunchAccum or 0
		entity.ixLastAimPunch = entity.ixLastAimPunch or 0

		-- Decay accumulated punch (roughly 20 degrees per second)
		entity.ixAimPunchAccum = math.max(0, entity.ixAimPunchAccum - (curTime - entity.ixLastAimPunch) * 20)
		entity.ixLastAimPunch = curTime

		local maxPunch = ix.config.Get("maxAimPunch", 30)
		local punchUp = 0
		local punchSide = math.Rand(-0.8, 0.8)

		-- Apply aim punch effect
		if (bIsBullet) then
			local multiplier = ix.config.Get("gunAimPunch", 1) * finalMultiplier

			if (multiplier > 0) then
				punchUp = math.Rand(1.5, 3.5) * multiplier
				punchSide = punchSide * multiplier
			end
		elseif (bIsMelee) then
			local multiplier = ix.config.Get("meleeAimPunch", 1) * finalMultiplier

			if (multiplier > 0) then
				punchUp = math.Rand(1.0, 2.5) * multiplier
				punchSide = punchSide * multiplier
			end
		elseif (bIsBlast) then
			local multiplier = ix.config.Get("gunAimPunch", 1) * finalMultiplier

			if (multiplier > 0) then
				punchUp = math.Rand(6.0, 10.0) * multiplier
				punchSide = math.Rand(-4.0, 4.0) * multiplier
			end
		elseif (bIsFall) then
			-- Armor doesn't usually protect against fall impact, so we only use endurance
			local multiplier = ix.config.Get("meleeAimPunch", 1) * attribMultiplier

			if (multiplier > 0) then
				punchUp = math.Rand(3.0, 6.0) * multiplier
				punchSide = math.Rand(-1.5, 1.5) * multiplier
			end
		end

		-- Cap the punch if it exceeds the max
		if (entity.ixAimPunchAccum + punchUp > maxPunch) then
			punchUp = math.max(0, maxPunch - entity.ixAimPunchAccum)
		end

		if (punchUp > 0) then
			entity:ViewPunch(Angle(-punchUp, punchSide, 0))
			entity.ixAimPunchAccum = entity.ixAimPunchAccum + punchUp
		end

		-- Stunstick melee scaling is handled in plugins/wepadjust.lua so the
		-- attacker's strength is applied once, consistently with other melee weapons.
	end

	--[[
		FUNCTION: PLUGIN:CanPlayerHoldObject(client, entity)
		DESCRIPTION: Code taken from the strength plugin. Changes how much a player can
		hold in their hand.
	]]--

	function PLUGIN:CanPlayerHoldObject(client, entity)
		if (client:GetCharacter()) then
			local physics = entity:GetPhysicsObject()

			return IsValid(physics) and 
			 	(physics:GetMass() <= (ix.config.Get("maxHoldWeight", 100) + client:GetCharacter():GetAttribute("str", 0) * ix.config.Get("strengthMultiplier", 1)))
		end
	end

	--[[
		FUNCTION: PLUGIN:PlayerThrowPunch(client, trace)
		DESCRIPTION: Code taken from the strength plugin. Currently defunct as I try to find a non
		abusable way of gaining stats.
	]]--

	function PLUGIN:PlayerThrowPunch(client, trace)
		if (client:GetCharacter() and IsValid(trace.Entity) and trace.Entity:IsPlayer()) then
			client:GetCharacter():UpdateAttrib("str", 0.001)
		end
	end
end

if (CLIENT) then
	local swayX, swayY = 0, 0
	local weaponWhitelist = {
		-- ["ix_hands"] = true,
		["ix_keys"] = true,
		["ix_suitcase"] = true,
		["swep_vortigaunt_sweep"] = true,
		["gmod_tool"] = true,
		["gmod_physgun"] = true,
		["weapon_physgun"] = true,
		["weapon_physcannon"] = true
	}

	function PLUGIN:CreateMove(cmd)
		local client = LocalPlayer()
		if (!IsValid(client) or !client:Alive() or !client:GetCharacter()) then return end
		
		-- Only apply when weapon is raised and not in noclip
		if (!client:IsWepRaised() or client:GetMoveType() == MOVETYPE_NOCLIP) then return end

		local weapon = client:GetActiveWeapon()
		if (!IsValid(weapon)) then return end

		-- Whitelist check
		local class = weapon:GetClass():lower()
		if (weaponWhitelist[class] or class:find("tool") or class:find("physgun") or class:find("scanner")) then
			return
		end

		local endurance = client:GetCharacter():GetAttribute("end", 0)
		local maxAttr = ix.config.Get("maxAttributes", 30)
		
		-- Higher endurance leads to much lower sway
		local baseIntensity = ix.config.Get("aimSwayIntensity", 1) * math.max(0.02, 1 - (endurance / maxAttr)) * 0.05

		-- Hybrid Approach: Intensity increases based on movement speed
		local velocity = client:GetVelocity():Length2D()
		-- We use a normalized velocity to increase sway up to 3.5x when running
		local moveMultiplier = 1 + (velocity / math.max(ix.config.Get("runSpeed", 225), 1)) * 2.5
		
		-- Vertical movement (Jumping/Falling)
		if (!client:IsOnGround()) then
			-- Significantly increase sway when in the air, scaled by vertical velocity
			local verticalVel = math.abs(client:GetVelocity().z)
			moveMultiplier = moveMultiplier + 3 + (verticalVel / 500) * 5
		end

		local intensity = baseIntensity * moveMultiplier

		if (intensity <= 0) then return end

		local time = CurTime()
		-- Multi-frequency sine waves to simulate semi-random noise
		swayX = (math.sin(time * 0.5) + math.sin(time * 1.2) * 0.5 + math.sin(time * 2.5) * 0.2)
		swayY = (math.cos(time * 0.4) + math.cos(time * 1.4) * 0.5 + math.cos(time * 2.2) * 0.2)
		
		local angles = cmd:GetViewAngles()
		angles.p = angles.p + swayY * intensity
		angles.y = angles.y + swayX * intensity
		
		cmd:SetViewAngles(angles)
	end
end
