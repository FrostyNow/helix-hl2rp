
function Schema:LoadData()
	self:LoadRationDispensers()
	self:LoadVendingMachines()
	self:LoadCombineLocks()
	self:LoadForceFields()
	self:LoadCoffeeMachines()
	self:LoadPepsiMachines()

	Schema.CombineObjectives = ix.data.Get("combineObjectives", {}, false, true)
end

function Schema:SaveData()
	self:SaveRationDispensers()
	self:SaveVendingMachines()
	self:SaveCombineLocks()
	self:SaveForceFields()
	self:SaveCoffeeMachines()
	self:SavePepsiMachines()
end

function Schema:PlayerSwitchFlashlight(client, enabled)
	return false
end

function Schema:PlayerUse(client, entity)
	local character = client:GetCharacter()
	local inv = character and character:GetInventory()

	if ((client:IsCombine() or (inv and (inv:HasItem("comkey") or inv:HasItem("unionkey")))) and entity:IsDoor() and IsValid(entity.ixLock) and client:KeyDown(IN_SPEED)) then
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
			client:SetMaxArmor(100)
			client:SetArmor(self:IsCombineRank(client:Name(), "RCT") and 50 or 100)
		-- elseif (client:IsScanner()) then
		-- 	client:SetMaxHealth(30)
		-- 	client:SetHealth(30)
		-- 	client:SetMaxArmor(200)
		-- 	client:SetArmor(200)
		-- 	client:GetCharacter():SetAttrib("str", 0)
		-- 	client:GetCharacter():SetAttrib("end", 0)
		-- 	client:GetCharacter():SetAttrib("stm", 0)
		-- 	client:GetCharacter():SetAttrib("int", 0)

		-- 	client.ixScanner:SetHealth(client:Health())
		-- 	client.ixScanner:SetMaxHealth(client:GetMaxHealth())
		-- 	client:StripWeapons()
		else
			client:SetArmor(100)
		end

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
		client:GetCharacter():SetAttrib("str", math.Clamp(str + 3, 0, 10))
		client:GetCharacter():SetAttrib("end", math.Clamp(endurance + 3, 0, 10))
		client:GetCharacter():SetAttrib("stm", math.Clamp(stm + 3, 0, 10))
		client:GetCharacter():SetAttrib("int", math.Clamp(int + 3, 0, 10))
	else
		client:SetMaxHealth(40)
		client:SetHealth(40)
	end
end

-- function Schema:PrePlayerLoadedCharacter(client, character, oldCharacter)
-- 	if (IsValid(client.ixScanner)) then
-- 		client.ixScanner:Remove()
-- 	end
-- end

function Schema:PlayerLoadedCharacter(client, character, oldCharacter)
	local faction = character:GetFaction()

	if (faction == FACTION_CITIZEN) then
		self:AddCombineDisplayMessage("@cCitizenLoaded", Color(255, 100, 255, 255))
	elseif (client:IsCombine()) then
		client:AddCombineDisplayMessage("@cCombineLoaded")
	end
end

function Schema:CharacterVarChanged(character, key, oldValue, value)
	local client = character:GetPlayer()
	if (key == "name") then
		local factionTable = ix.faction.Get(client:Team())

		if (factionTable.OnNameChanged) then
			factionTable:OnNameChanged(client, oldValue, value)
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

	-- Clear name panels from any existing corpses upon spawning
	for _, v in ipairs(ents.FindByClass("prop_ragdoll")) do
		if (v:GetNetVar("player") == client) then
			v:SetNetVar("player", nil)
		end
	end
end

function Schema:PlayerDeath(client, inflicter, attacker)
	if (client:IsCombine()) then
		local location = client:GetArea() or "unknown location"

		self:AddCombineDisplayMessage("@cLostBiosignal")
		self:AddCombineDisplayMessage("@cLostBiosignalLocation", Color(255, 0, 0, 255), location)

		-- if (IsValid(client.ixScanner) and client.ixScanner:Health() > 0) then
		-- 	client.ixScanner:TakeDamage(999)
		-- end

		local sounds = {"npc/overwatch/radiovoice/on1.wav", "npc/overwatch/radiovoice/lostbiosignalforunit.wav"}
		local chance = math.random(1, 7)

		if (chance == 2) then
			sounds[#sounds + 1] = "npc/overwatch/radiovoice/remainingunitscontain.wav"
		elseif (chance == 3) then
			sounds[#sounds + 1] = "npc/overwatch/radiovoice/reinforcementteamscode3.wav"
		end

		sounds[#sounds + 1] = "npc/overwatch/radiovoice/off4.wav"

		for k, v in ipairs(player.GetAll()) do
			if (v:IsCombine()) then
				ix.util.EmitQueuedSounds(v, sounds, 2, nil, v == client and 100 or 80)
			end
		end
	end
end

-- function Schema:PlayerNoClip(client)
-- 	if (IsValid(client.ixScanner)) then
-- 		return false
-- 	end
-- end

function Schema:EntityTakeDamage(entity, dmgInfo)
	if (IsValid(entity.ixPlayer) and entity.ixPlayer:IsScanner()) then
		entity.ixPlayer:SetHealth( math.max(entity:Health(), 0) )

		hook.Run("PlayerHurt", entity.ixPlayer, dmgInfo:GetAttacker(), entity.ixPlayer:Health(), dmgInfo:GetDamage())
	end
end

function Schema:PlayerHurt(client, attacker, health, damage)
	if (health <= 0) then
		return
	end

	if (client:IsCombine() and (client.ixTraumaCooldown or 0) < CurTime()) then
		local text = "External"

		if (damage > 50) then
			text = "Severe"
		end

		client:AddCombineDisplayMessage("@cTrauma", Color(255, 0, 0, 255), text)

		if (health < 25) then
			client:AddCombineDisplayMessage("@cDroppingVitals", Color(255, 0, 0, 255))
		end

		client.ixTraumaCooldown = CurTime() + 15
	end
end

function Schema:PlayerStaminaLost(client)
	client:AddCombineDisplayMessage("@cStaminaLost", Color(255, 255, 0, 255))
end

function Schema:PlayerStaminaGained(client)
	client:AddCombineDisplayMessage("@cStaminaGained", Color(0, 255, 0, 255))
end

function Schema:GetPlayerPainSound(client)
	if (client:IsCombine()) then
		local sound = "NPC_MetroPolice.Pain"

		-- if (Schema:IsCombineRank(client:Name(), "SCN")) then
		-- 	sound = "NPC_CScanner.Pain"
		-- elseif (Schema:IsCombineRank(client:Name(), "SHIELD")) then
		-- 	sound = "NPC_SScanner.Pain"
		-- end

		return sound
	elseif (client:GetCharacter() and client:GetCharacter():IsVortigaunt()) then
		return false
	end
end

function Schema:GetPlayerDeathSound(client)
	if (client:IsCombine()) then
		local sound = "NPC_MetroPolice.Die"

		-- if (Schema:IsCombineRank(client:Name(), "SCN")) then
		-- 	sound = "NPC_CScanner.Die"
		-- elseif (Schema:IsCombineRank(client:Name(), "SHIELD")) then
		-- 	sound = "NPC_SScanner.Die"
		-- end

		for k, v in ipairs(player.GetAll()) do
			if (v:IsCombine()) then
				v:EmitSound(sound)
			end
		end

		return sound
	elseif (client:GetCharacter() and client:GetCharacter():IsVortigaunt()) then
		return false
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

	if (client:IsAdmin() or hasIteam) then
		return true
	else
		return false
	end
end

function Schema:CanPlayerUseCharacter(client, character)
	if client:IsAdmin() then return end

	if (client:IsRestricted()) then
		client:NotifyLocalized("cantChangeCharTied")
		return false
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
