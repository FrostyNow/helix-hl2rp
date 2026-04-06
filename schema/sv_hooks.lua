
function Schema:LoadData()
	self:LoadRationDispensers()
	self:LoadVendingMachines()
	self:LoadCombineLocks()
	self:LoadForceFields()
	self:LoadMachines()
	self:LoadBusinessAreas()

	Schema.CombineObjectives = ix.data.Get("combineObjectives", {}, false, true)
end

function Schema:SaveData()
	self:SaveRationDispensers()
	self:SaveVendingMachines()
	self:SaveCombineLocks()
	self:SaveForceFields()
	self:SaveMachines()
	self:SaveBusinessAreas()
end

function Schema:PlayerSwitchFlashlight(client, enabled)
	return false
end

function Schema:PlayerUse(client, entity)
	local character = client:GetCharacter()
	local inv = character and character:GetInventory()
	local hasItem = inv:HasItem("comkey") or inv:HasItem("unionkey")

	for _, v in pairs(inv:GetItems()) do
		if (v.uniqueID == "cid") then
			if (v:GetData("class") != "Second Class Citizen") then
				hasItem = true
			end
		end
	end

	if ((client:IsCombine() or (inv and hasItem)) and entity:IsDoor() and IsValid(entity.ixLock) and client:KeyDown(IN_SPEED)) then
		entity.ixLock:Toggle(client)
		return false
	end

	if (!client:IsRestricted() and entity:IsPlayer() and entity:IsRestricted() and !entity:GetNetVar("untying")) then
		entity:SetAction("@beingUntied", 5)
		entity:SetNetVar("untying", true)

		client:SetAction("@unTying", 5)

		client:DoStaredAction(entity, function()
			entity:SetRestricted(false)
			entity:SetNetVar("untying")
		end, 5, function()
			if (IsValid(entity)) then
				entity:SetNetVar("untying")
				entity:SetAction()
			end

			if (IsValid(client)) then
				client:SetAction()
			end
		end)
	end
end

function Schema:PlayerUseDoor(client, door)
	local character = client:GetCharacter()
	local inv = character and character:GetInventory()

	if ((client:IsCombine() or (inv and inv:HasItem("comkey")))) then
		if (!door:HasSpawnFlags(256) and !door:HasSpawnFlags(1024)) then
			door:Fire("open")
		end
	end
end

function Schema:PlayerLoadout(client)
	client:SetNetVar("restricted")
end

function Schema:PostPlayerLoadout(client)
	client:AllowFlashlight(true)

	local char = client:GetCharacter()

	if (client:IsCombine()) then
		local runSpeed = ix.config.Get("runSpeed")

		if (client:Team() == FACTION_OTA) then
			client:SetMaxHealth(50)
			client:SetMaxArmor(255)
			client:SetHealth(50)
			client:SetArmor(255)
			client:GetCharacter():SetAttrib("str", 10)
			client:GetCharacter():SetAttrib("end", 10)
			client:GetCharacter():SetAttrib("stm", 10)
			client:GetCharacter():SetAttrib("int", 5)
		elseif (client:Team() == FACTION_MPF) then
			client:SetMaxHealth(40)
			client:SetHealth(40)
			client:SetMaxArmor(0)
			client:SetArmor(0)
		else
			client:SetMaxArmor(0)
			client:SetArmor(0)
		end

		client:SetRunSpeed(runSpeed * 1.1)

		local factionTable = ix.faction.Get(client:Team())

		if (factionTable.OnNameChanged) then
			factionTable:OnNameChanged(client, "", client:GetCharacter():GetName())
		end
	elseif client:GetCharacter():IsVortigaunt() then
		local str = client:GetCharacter():GetAttribute("str", 0)
		local endurance = client:GetCharacter():GetAttribute("end", 0)
		local stm = client:GetCharacter():GetAttribute("stm", 0)
		local int = client:GetCharacter():GetAttribute("int", 0)
		client:SetMaxHealth(100)
		client:SetHealth(100)
		client:SetMaxArmor(0)
		client:SetArmor(0)
		client:GetCharacter():SetAttrib("str", math.Clamp(str + 3, 0, 10))
		client:GetCharacter():SetAttrib("end", math.Clamp(endurance + 3, 0, 10))
		client:GetCharacter():SetAttrib("stm", math.Clamp(stm + 3, 0, 10))
		client:GetCharacter():SetAttrib("int", math.Clamp(int + 3, 0, 10))
	else
		client:SetMaxHealth(40)
		client:SetHealth(40)
		client:SetMaxArmor(0)
		client:SetArmor(0)
	end
end

function Schema:PrePlayerLoadedCharacter(client, character, oldCharacter)
	-- Fallback: If they are in a uniform faction but lost the flag, revert them to citizen
	local faction = ix.faction.indices[character:GetFaction()]

	if (faction and faction.IsUniformCitizenDuty and faction:IsUniformCitizenDuty(character)) then
		local requiredFlag = (faction.uniqueID == "metropolice") and "M" or (faction.uniqueID == "conscript") and "C" or nil

		if (requiredFlag and !character:HasFlags(requiredFlag)) then
			-- They don't have the flag anymore, remove the outfit effects using layered logic
			local inventory = character:GetInventory()
			local items = inventory:GetItems()
			local lookups = {}
			for _, v in pairs(items) do lookups[v:GetID()] = v end

			-- 1. Identify items from the appearance stack and remove them in order (top to bottom)
			local stack = table.Copy(character:GetData("appearanceStack", {}))
			local originalModel = character:GetModel()

			for _, itemID in ipairs(stack) do
				local item = lookups[itemID]
				if (item and item:GetData("equip")) then
					-- If it's a sub-item (not the uniform itself) that might be incompatible once we revert
					if (item.uniqueID != "metropolice" and item.uniqueID != "conscript") then
						local bIncompatible = false
						if (item.allowedBaseFactions and !item.allowedBaseFactions[FACTION_CITIZEN] and !item.allowedBaseFactions["citizen"]) then
							bIncompatible = true
						elseif (item.allowedModels and !table.HasValue(item.allowedModels, originalModel)) then
							bIncompatible = true
						end

						if (bIncompatible) then
							if (isfunction(item.RemoveOutfit)) then
								item:RemoveOutfit(client)
							else
								item:SetData("equip", nil)
							end
						end
					end
				end
			end

			-- 2. Finally, locate and remove the main uniform item itself
			local uniformItem = nil
			for _, item in pairs(items) do
				if (item:GetData("equip") and (item.uniqueID == "metropolice" or item.uniqueID == "conscript")) then
					uniformItem = item
					break
				end
			end

			if (uniformItem) then
				-- This will revert faction, name, description, etc.
				uniformItem:RemoveOutfit(client)
			else
				-- Absolute last-resort fallback for faction/state
				local returnFaction = faction:GetUniformReturnFaction(character) or FACTION_CITIZEN
				character:SetFaction(returnFaction)
				character:SetData("mpfUniformState", nil)
				character:SetData("conscriptUniformState", nil)
			end

			-- 3. Nuclear cleanup of any leftover Better Outfits metadata
			for k, _ in pairs(character:GetData()) do
				if (isstring(k) and (k:sub(1, 8) == "oldModel" or k:sub(1, 7) == "oldSkin" or k:sub(1, 9) == "oldGroups")) then
					character:SetData(k, nil)
				end
			end
		end
	end
end

function Schema:PlayerLoadedCharacter(client, character, oldCharacter)
	local faction = character:GetFaction()

	self:SyncCitizenID(client, character)
	self:RefreshFlashlight(client)

	if (faction == FACTION_CITIZEN) then
		self:AddCombineDisplayMessage("@cCitizenLoaded", Color(255, 100, 255, 45))
	elseif (client:IsCombine()) then
		client:AddCombineDisplayMessage("@cCombineLoaded")
	end

	self:UpdateAllRelations()
end

function Schema:UpdateAllRelations()
	for _, ent in ipairs(ents.FindByClass("npc_turret_floor")) do
		for _, v in ipairs(player.GetAll()) do
			if (ent.ixIsResistance) then
				if (v:IsCombine() or v:Team() == FACTION_ADMIN or v:Team() == FACTION_CONSCRIPT) then
					ent:AddEntityRelationship(v, D_HT, 99)
				else
					ent:AddEntityRelationship(v, D_LI, 99)
				end
			else
				if (v:IsCombine() or v:Team() == FACTION_ADMIN or v:Team() == FACTION_CONSCRIPT) then
					ent:AddEntityRelationship(v, D_LI, 99)
				else
					ent:AddEntityRelationship(v, D_HT, 99)
				end
			end
		end
	end
end

function Schema:CharacterVarChanged(character, key, oldValue, value)
	local client = character:GetPlayer()

	if (key == "faction" and IsValid(client)) then
		self:RefreshFlashlight(client)
		client:SetupHands()

		timer.Simple(0, function()
			if (IsValid(client) and client:GetCharacter() == character) then
				hook.Run("UpdateAllRelations")
			end
		end)
	end

	if (key == "model" and IsValid(client)) then
		client:SetupHands()
	end

	if (key == "name" and IsValid(client)) then
		local factionTable = ix.faction.Get(client:Team())

		if (factionTable.OnNameChanged) then
			factionTable:OnNameChanged(client, oldValue, value)
		end
	end

	if (key == "description" and IsValid(client)) then
		local factionTable = ix.faction.Get(client:Team())

		if (factionTable.OnDescriptionChanged) then
			factionTable:OnDescriptionChanged(client, oldValue, value)
		end
	end
end

function Schema:PlayerFootstep(client, position, foot, soundName, volume)
	local factionTable = ix.faction.Get(client:Team())

	if (factionTable.runSounds and client:IsRunning()) then
		client:EmitSound(factionTable.runSounds[foot])
		return true
	end

	--client:EmitSound(soundName)
	return false
end

function Schema:PlayerSpawn(client)
	local character = client:GetCharacter()
	local inv = character and character:GetInventory()

	client:SetCanZoom(character and (client:IsCombine() or client:IsAdmin() or (inv and inv:HasItem("binoculars"))))
	self:RefreshFlashlight(client)

	-- Clear name panels from any existing corpses upon spawning
	for _, v in ipairs(ents.FindByClass("prop_ragdoll")) do
		if (v:GetNetVar("player") == client) then
			v:SetNetVar("player", nil)
		end
	end
end

function Schema:DoPlayerDeath(client, attacker, damageinfo)
	client.ixDeathAmmo = client:GetAmmo()
	client.ixDeathWeapons = {}
	client.ixDeathHunger = client.GetHunger and client:GetHunger() or nil
	client.ixDeathThirst = client.GetThirst and client:GetThirst() or nil

	for _, v in ipairs(client:GetWeapons()) do
		client.ixDeathWeapons[v:GetClass()] = {
			clip1 = v:Clip1(),
			clip2 = v:Clip2()
		}
	end
end

-- function Schema:PlayerNoClip(client)
-- 	if (IsValid(client.ixScanner)) then
-- 		return false
-- 	end
-- end

function Schema:EntityTakeDamage(entity, dmgInfo)
	-- if (IsValid(entity.ixPlayer) and entity.ixPlayer:IsScanner()) then
	-- 	entity.ixPlayer:SetHealth( math.max(entity:Health(), 0) )

	-- 	hook.Run("PlayerHurt", entity.ixPlayer, dmgInfo:GetAttacker(), entity.ixPlayer:Health(), dmgInfo:GetDamage())
	-- end

	if (entity:IsPlayer()) then
		if entity:GetCharacter() and entity:Team() == FACTION_OTA then
			if dmgInfo:IsDamageType(DMG_RADIATION) then
				dmgInfo:SetDamage(dmgInfo:GetDamage() * 0.1)
			end
		end
	end
end

local defaultPainSounds
local drownPainSounds
local metrocopPainSounds
local combinePainSounds

function Schema:PlayerHurt(client, attacker, health, damage)
	if (health > 0) then
		if (client:IsCombine() and (client.ixTraumaCooldown or 0) < CurTime()) then
			local text = "cDamageExternal"

			if (damage > 50) then
				text = "cDamageSevere"
			end

			client:AddCombineDisplayMessage("@cTrauma", Color(255, 0, 0, 45), L(text, client))

			if (health < 25) then
				client:AddCombineDisplayMessage("@cDroppingVitals", Color(255, 0, 0, 45))
			end

			client.ixTraumaCooldown = CurTime() + 15
		end

		if ((client.ixNextPain or 0) < CurTime()) then
			local painSound = hook.Run("GetPlayerPainSound", client)

			if (painSound != false) then
				painSound = painSound or defaultPainSounds[math.random(1, #defaultPainSounds)]

				if (client:IsFemale() and !painSound:find("female")) then
					painSound = painSound:gsub("male", "female")
				end

				client:EmitSound(painSound)
			end

			client.ixNextPain = CurTime() + 0.33
		end
	end

	ix.log.Add(client, "playerHurt", damage, attacker:GetName() ~= "" and attacker:GetName() or attacker:GetClass())

	return true
end

function Schema:PlayerStaminaLost(client)
	client:AddCombineDisplayMessage("@cStaminaLost", Color(255, 255, 0, 45))
end

function Schema:PlayerStaminaGained(client)
	client:AddCombineDisplayMessage("@cStaminaGained", Color(0, 255, 0, 45))
end

defaultPainSounds = {
	Sound("vo/npc/male01/pain01.wav"),
	Sound("vo/npc/male01/pain02.wav"),
	Sound("vo/npc/male01/pain03.wav"),
	Sound("vo/npc/male01/pain04.wav"),
	Sound("vo/npc/male01/pain05.wav"),
	Sound("vo/npc/male01/pain06.wav")
}

drownPainSounds = {
	Sound("player/pl_drown1.wav"),
	Sound("player/pl_drown2.wav"),
	Sound("player/pl_drown3.wav")
}

metrocopPainSounds = {
	Sound("npc/metropolice/knockout2.wav"),
	Sound("npc/metropolice/pain1.wav"),
	Sound("npc/metropolice/pain2.wav"),
	Sound("npc/metropolice/pain3.wav"),
	Sound("npc/metropolice/pain1.wav")
}

combinePainSounds = {
	Sound("npc/combine_soldier/pain1.wav"),
	Sound("npc/combine_soldier/pain2.wav"),
	Sound("npc/combine_soldier/pain3.wav")
}

local function GetCombinePainSound(client)
	if (client:Team() == FACTION_OTA) then
		return combinePainSounds[math.random(1, #combinePainSounds)]
	end

	return metrocopPainSounds[math.random(1, #metrocopPainSounds)]
end

local function GetCombineDeathSound(client)
	if (client:Team() == FACTION_OTA) then
		return "npc/combine_soldier/die" .. math.random(1, 3) .. ".wav"
	end

	return "npc/metropolice/die" .. math.random(1, 4) .. ".wav"
end

function Schema:GetPlayerPainSound(client)
	if (client:IsAdmin() and client:GetMoveType() == MOVETYPE_NOCLIP) then
		return false
	end

	if (client:IsCombine() and Schema:CanPlayerSeeCombineOverlay(client)) then
		return GetCombinePainSound(client)
	end

	if (client:WaterLevel() >= 3) then
		return drownPainSounds[math.random(1, #drownPainSounds)]
	end
end

-- function Schema:PlayerDeath(client, inflicter, attacker)
-- 	if (client:IsCombine()) then
-- 		local location = client:GetAreaName() != "" and client:GetAreaName() or L("unknown location", client)

-- 		self:AddCombineDisplayMessage("@cLostBiosignal")
-- 		self:AddCombineDisplayMessage("@cLostBiosignalLocation", Color(255, 0, 0, 255), location)

-- 		local sounds = {"npc/overwatch/radiovoice/on1.wav", "npc/overwatch/radiovoice/lostbiosignalforunit.wav"}
-- 		local chance = math.random(1, 7)

-- 		if (chance == 2) then
-- 			sounds[#sounds + 1] = "npc/overwatch/radiovoice/remainingunitscontain.wav"
-- 		elseif (chance == 3) then
-- 			sounds[#sounds + 1] = "npc/overwatch/radiovoice/reinforcementteamscode3.wav"
-- 		end

-- 		sounds[#sounds + 1] = "npc/overwatch/radiovoice/off4.wav"

-- 		for _, player in ipairs(player.GetAll()) do
-- 			if (player:IsCombine()) then
-- 				ix.util.EmitQueuedSounds(player, sounds, 2, nil, player == client and 100 or 80)
-- 			end
-- 		end
-- 	end
-- end

function Schema:GetPlayerDeathSound(client)
	if (client:IsAdmin() and client:GetMoveType() == MOVETYPE_NOCLIP) then
		return false
	end

	if (client:IsCombine() and Schema:CanPlayerSeeCombineOverlay(client)) then
		local sound = GetCombineDeathSound(client)
		local receivers = {}
		local maxDistance = 10 * 39.37

		for _, player in ipairs(player.GetAll()) do
			if (
				player:IsCombine()
				and player != client
				and player:GetPos():DistToSqr(client:GetPos()) > (maxDistance * maxDistance)
			) then
				receivers[#receivers + 1] = player
			end
		end

		if (#receivers > 0) then
			netstream.Start(receivers, "PlayPrivateSound", sound, 75, 100, 0.5)
		end

		return sound
	end
end

function Schema:OnNPCKilled(npc, attacker, inflictor)
	if (IsValid(npc.ixPlayer)) then
		hook.Run("PlayerDeath", npc.ixPlayer, inflictor, attacker)
	end
end

-- function Schema:PlayerMessageSend(speaker, chatType, text, anonymous, receivers, rawText)
-- 	if (chatType == "ic" or chatType == "w" or chatType == "y" or chatType == "radio" or chatType == "radio_yell" or chatType == "radio_whisper" or chatType == "radio_eavesdrop" or chatType == "radio_eavesdrop_yell" or chatType == "radio_eavesdrop_whisper" or chatType == "dispatch" or chatType == "broadcast" or chatType == "request" or chatType == "request_eavesdrop") then
-- 		local class = self.voices.GetClass(speaker)

-- 		for k, v in ipairs(class) do
-- 			local info = self.voices.Get(v, rawText)

-- 			if (info) then
-- 				local volume = 80

-- 				if (chatType == "w" or chatType == "radio_whisper" or chatType == "radio_eavesdrop_whisper") then
-- 					volume = 30
-- 				elseif (chatType == "y" or chatType == "radio_yell" or chatType == "radio_eavesdrop_yell") then
-- 					volume = 150
-- 				end

-- 				if (info.sound) then
-- 					if (info.global) then
-- 						netstream.Start(nil, "PlaySound", info.sound)
-- 					else
-- 						if (chatType == "radio" or chatType == "radio_yell" or chatType == "radio_whisper") then
-- 							for k, v in pairs(receivers) do
-- 								ix.util.EmitQueuedSounds(receivers, {info.sound, nil}, nil, nil, volume)
-- 							end
-- 						else
-- 							local sounds = {info.sound}

-- 							if (speaker:IsCombine()) then
-- 								speaker.bTypingBeep = nil
-- 								sounds[#sounds + 1] = "NPC_MetroPolice.Radio.Off"
-- 							end

-- 							ix.util.EmitQueuedSounds(speaker, sounds, nil, nil, volume)
-- 						end
-- 					end
-- 				end

-- 				if (speaker:IsCombine()) then
-- 					return string.format("<:: %s ::>", info.text)
-- 				else
-- 					return info.text
-- 				end
-- 			end
-- 		end

-- 		if (speaker:IsCombine()) then
-- 			return string.format("<:: %s ::>", text)
-- 		end
-- 	end
-- end

function Schema:CanPlayerJoinClass(client, class, info)
	if (client:IsRestricted()) then
		client:NotifyLocalized("cantChangeClassTied")

		return false
	end
end

-- local SCANNER_SOUNDS = {
-- 	"npc/scanner/scanner_blip1.wav",
-- 	"npc/scanner/scanner_scan1.wav",
-- 	"npc/scanner/scanner_scan2.wav",
-- 	"npc/scanner/scanner_scan4.wav",
-- 	"npc/scanner/scanner_scan5.wav",
-- 	"npc/scanner/combat_scan1.wav",
-- 	"npc/scanner/combat_scan2.wav",
-- 	"npc/scanner/combat_scan3.wav",
-- 	"npc/scanner/combat_scan4.wav",
-- 	"npc/scanner/combat_scan5.wav",
-- 	"npc/scanner/cbot_servoscared.wav",
-- 	"npc/scanner/cbot_servochatter.wav"
-- }

-- function Schema:KeyPress(client, key)
-- 	if (IsValid(client.ixScanner) and (client.ixScannerDelay or 0) < CurTime()) then
-- 		local source

-- 		if (key == IN_USE) then
-- 			source = SCANNER_SOUNDS[math.random(1, #SCANNER_SOUNDS)]
-- 			client.ixScannerDelay = CurTime() + 1.75
-- 		elseif (key == IN_RELOAD) then
-- 			source = "npc/scanner/scanner_talk"..math.random(1, 2)..".wav"
-- 			client.ixScannerDelay = CurTime() + 10
-- 		elseif (key == IN_WALK) then
-- 			if (client:GetViewEntity() == client.ixScanner) then
-- 				client:SetViewEntity(NULL)
-- 			else
-- 				client:SetViewEntity(client.ixScanner)
-- 			end
-- 		end

-- 		if (source) then
-- 			client.ixScanner:EmitSound(source)
-- 		end
-- 	end
-- end

function Schema:PlayerSpawnObject(client)
	if (client:IsRestricted()) then
		return false
	end
end

function Schema:PlayerSpray(client)
	local character = client:GetCharacter()
	local inventory = character:GetInventory()
	local hasItem = inventory:HasItem("spraycan")

	if (client:IsAdmin() or hasItem) then
		return true
	else
		return false
	end
end

function Schema:CanPlayerViewCharacter(client, character)
	local faction = ix.faction.indices[character:GetFaction()]

	if (faction and faction.IsUniformCitizenDuty and faction:IsUniformCitizenDuty(character)) then
		local requiredFlag = (faction.uniqueID == "metropolice") and "M" or (faction.uniqueID == "conscript") and "C" or nil

		if (requiredFlag and character:HasFlags(requiredFlag)) then
			return true
		end
	end
end

function Schema:CanPlayerUseCharacter(client, character)
	if client:IsAdmin() then return end

	if (client:IsRestricted()) then
		client:NotifyLocalized("cantChangeCharTied")
		return false
	end

	local faction = ix.faction.indices[character:GetFaction()]

	if (faction and faction.IsUniformCitizenDuty and faction:IsUniformCitizenDuty(character)) then
		local requiredFlag = (faction.uniqueID == "metropolice") and "M" or (faction.uniqueID == "conscript") and "C" or nil

		-- If they have the flag, allow it (will bypass whitelist via sh_schema override)
		if (requiredFlag and (character:HasFlags(requiredFlag) or client:HasFlags(requiredFlag))) then
			return true
		end

		-- If they don't have the flag, we still allow it so PrePlayerLoadedCharacter can revert them
		-- instead of leaving them with a character they can never select.
		return true
	end
end

function Schema:CanPlayerHold(ply, entity)
	if (ply:GetCharacter() and entity:GetClass() == "npc_turret_floor" and entity:GetRelationship(ply) == D_LI) then
		return true
	end
end

-- netstream.Hook("PlayerChatTextChanged", function(client, key)
-- 	if (client:IsCombine() and !client.bTypingBeep
-- 	and (key == "y" or key == "w" or key == "r" or key == "t")) then
-- 		client:EmitSound("NPC_MetroPolice.Radio.On")
-- 		client.bTypingBeep = true
-- 	end
-- end)

-- netstream.Hook("PlayerFinishChat", function(client)
-- 	if (client:IsCombine() and client.bTypingBeep) then
-- 		client:EmitSound("NPC_MetroPolice.Radio.Off")
-- 		client.bTypingBeep = nil
-- 	end
-- end)

netstream.Hook("ViewDataUpdate", function(client, target, text)
	if (ix.plugin.Get("interactive_computers")) then
		return
	end

	if (IsValid(target) and hook.Run("CanPlayerEditData", client, target) and client:GetCharacter() and target:GetCharacter()) then
		local data = {
			text = string.Trim(text:sub(1, 1000)),
			editor = client:GetCharacter():GetName()
		}

		target:GetCharacter():SetData("combineData", data)
		Schema:AddCombineDisplayMessage("@cViewDataFiller", nil, client)
	end
end)

netstream.Hook("ViewObjectivesUpdate", function(client, text)
	if (ix.plugin.Get("interactive_computers")) then
		return
	end

	if (client:GetCharacter() and hook.Run("CanPlayerEditObjectives", client)) then
		local date = ix.date.Get()
		local data = {
			text = text:sub(1, 1000),
			lastEditPlayer = client:GetCharacter():GetName(),
			lastEditDate = ix.date.GetSerialized(date)
		}

		ix.data.Set("combineObjectives", data, false, true)
		Schema.CombineObjectives = data
		Schema:AddCombineDisplayMessage("@cViewObjectivesFiller", nil, client, date:spanseconds())
	end
end)
