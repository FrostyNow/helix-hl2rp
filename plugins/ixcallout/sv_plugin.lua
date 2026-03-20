local PLUGIN = PLUGIN

local GRENADE_CLASS = "npc_grenade_frag"
local GRENADE_SCAN_INTERVAL = 0.2
local GRENADE_REACTION_RADIUS = 220
local GRENADE_REST_SPEED = 80
local GRENADE_WORLD_CONTACT_DISTANCE = 20
local DEATH_REACTION_RADIUS = 700
local SQUAD_RADIUS = 900
local PLAYER_COOLDOWN = 2.5
local DEATH_EVENT_COOLDOWN = 0.4
local IC_RANGE = 280

local COMBINE_TEMPLATE_SETS = {
	throwGrenade = {
		{
			sounds = {
				"npc/combine_soldier/vo/extractoraway.wav"
			},
			suffix = "수류탄 준비."
		},
		{
			sounds = {
				"npc/combine_soldier/vo/extractorislive.wav"
			},
			suffix = "수류탄 투척."
		},
		{
			sounds = {
				"npc/combine_soldier/vo/flush.wav",
				"npc/combine_soldier/vo/sharpzone.wav"
			},
			suffix = "플러시. 이동 구역."
		},
		{
			sounds = {
				"npc/combine_soldier/vo/extractoraway.wav",
				"npc/combine_soldier/vo/sharpzone.wav"
			},
			suffix = "수류탄 준비. 이동 구역."
		},
		{
			sounds = {
				"npc/combine_soldier/vo/six.wav",
				"npc/combine_soldier/vo/five.wav",
				"npc/combine_soldier/vo/four.wav",
				"npc/combine_soldier/vo/three.wav",
				"npc/combine_soldier/vo/two.wav",
				"npc/combine_soldier/vo/one.wav",
				"npc/combine_soldier/vo/flash.wav",
				"npc/combine_soldier/vo/flash.wav",
				"npc/combine_soldier/vo/flash.wav"
			},
			suffix = "육, 오, 사, 삼, 이, 일. 플래시, 플래시, 플래시."
		}
	},
	danger = {
		{
			sounds = {
				"npc/combine_soldier/vo/displace.wav"
			},
			text = "흩어져라!"
		},
		{
			sounds = {
				"npc/combine_soldier/vo/displace2.wav"
			},
			text = "분산하라!"
		},
		{
			sounds = {
				"npc/combine_soldier/vo/ripcordripcord.wav"
			},
			text = "립코드! 립코드!"
		}
	},
	lastSquad = {
		{
			sounds = {
				"npc/combine_soldier/vo/overwatchrequestreserveactivation.wav"
			},
			text = "감시인, 예비 병력 활성화를 요청한다."
		},
		{
			sounds = {
				"npc/combine_soldier/vo/overwatch.wav",
				"npc/combine_soldier/vo/sectorisnotsecure.wav"
			},
			text = "감시인, 구역 미확보다."
		},
		{
			sounds = {
				"npc/combine_soldier/vo/sector.wav",
				"npc/combine_soldier/vo/outbreak.wav",
				"npc/combine_soldier/vo/outbreak.wav",
				"npc/combine_soldier/vo/outbreak.wav"
			},
			usesSector = true,
			suffix = "확산. 확산. 확산."
		},
		{
			sounds = {
				"npc/combine_soldier/vo/isfinalteamunitbackup.wav"
			},
			suffix = "최종 분대원이다. 지원 바란다."
		},
		{
			sounds = {
				"npc/combine_soldier/vo/overwatchteamisdown.wav"
			},
			text = "감시인, 분대가 쓰러졌다."
		},
		{
			sounds = {
				"npc/combine_soldier/vo/overwatchsectoroverrun.wav"
			},
			text = "감시인, 구역이 돌파당했다."
		},
		{
			sounds = {
				"npc/combine_soldier/vo/overwatchrequestskyshield.wav"
			},
			text = "감시인, 스카이쉴드 요청."
		},
		{
			sounds = {
				"npc/combine_soldier/vo/overwatchrequestwinder.wav"
			},
			text = "감시인, 와인더 요청."
		}
	}
}

local COMBINE_CALLSIGN_KEYS = {
	BLADE = "블레이드",
	DAGGER = "대거",
	DEFENDER = "디펜더",
	FIST = "피스트",
	FLASH = "플래시",
	HAMMER = "해머",
	HERO = "히어로",
	HUNTER = "헌터",
	JURY = "주리",
	KING = "킹",
	LEADER = "리더",
	LINE = "라인",
	PATROL = "패트롤",
	QUICK = "퀵",
	RANGER = "레인저",
	RAZOR = "레이저",
	SAVAGE = "새비지",
	SLASH = "슬래시",
	SPEAR = "스피어",
	STAB = "스탭",
	STICK = "스틱",
	STRIKER = "스트라이커",
	SWEEPER = "스위퍼",
	SWIFT = "스위프트",
	SWORD = "소드",
	TAP = "탭",
	TRACKER = "트래커",
	UNION = "유니온",
	VICE = "바이스",
	VICTOR = "빅터",
	XRAY = "엑스레이",
	YELLOW = "옐로우"
}

local COMBINE_MAN_DOWN_VARIANTS = {
	{
		sounds = {"npc/combine_soldier/vo/onedown.wav"},
		suffix = "쓰러졌다."
	},
	{
		sounds = {"npc/combine_soldier/vo/onedutyvacated.wav"},
		suffix = "이탈했다."
	},
	{
		sounds = {"npc/combine_soldier/vo/heavyresistance.wav"},
		suffix = "근처 저항이 거세다."
	},
	{
		sounds = {"npc/combine_soldier/vo/overwatchrequestreinforcement.wav"},
		suffix = "증원을 요청한다."
	},
	{
		sounds = {"npc/combine_soldier/vo/onedown.wav", "npc/combine_soldier/vo/hardenthatposition.wav"},
		suffix = "쓰러졌다. 현 위치를 사수하라."
	}
}

function PLUGIN:InitializedPlugins()
	self.ixVoicePlugin = ix.plugin.list["ixvoice"]
	self.reactedGrenades = self.reactedGrenades or {}
	self.playerCooldowns = self.playerCooldowns or {}
	self.nextGrenadeScan = 0
	self.nextDeathReaction = 0

	if (self.voiceTypes and self.voiceTypes.combine) then
		self.voiceTypes.combine.factions = {
			[FACTION_OTA] = true
			-- [FACTION_MPF] = true
		}
	end

	self:AssignAreaSectors()
end

function PLUGIN:IsVoicePluginAvailable()
	return self.ixVoicePlugin != nil
end

function PLUGIN:AssignAreaSectors()
	if (!ix.area or !ix.area.stored) then
		return
	end

	local areaIDs = {}

	for areaID in pairs(ix.area.stored) do
		areaIDs[#areaIDs + 1] = areaID
	end

	table.sort(areaIDs, function(a, b)
		return tostring(a) < tostring(b)
	end)

	local usedSectors = {}
	local nameToSector = {}
	local needsSave = false

	for _, areaID in ipairs(areaIDs) do
		local area = ix.area.stored[areaID]
		local properties = area and area.properties or nil
		local areaName = tostring((properties and properties.name) or areaID or "")
		local sector = self:GetAreaSectorNumber(areaID)

		if (sector) then
			usedSectors[sector] = true

			if (areaName != "") then
				nameToSector[areaName] = nameToSector[areaName] or sector
			end
		end
	end

	local nextSector = 1

	for _, areaID in ipairs(areaIDs) do
		local area = ix.area.stored[areaID]

		if (!area) then
			continue
		end

		area.properties = area.properties or {}

		if (!self:GetAreaSectorNumber(areaID)) then
			local areaName = tostring(area.properties.name or areaID or "")
			local sharedSector = areaName != "" and nameToSector[areaName] or nil

			if (sharedSector) then
				area.properties.sector = sharedSector
			else
				while (usedSectors[nextSector]) do
					nextSector = nextSector + 1
				end

				area.properties.sector = nextSector
				usedSectors[nextSector] = true
				nameToSector[areaName] = nextSector
				nextSector = nextSector + 1
			end
			needsSave = true
		end
	end

	if (needsSave) then
		local areaPlugin = ix.plugin.list["area"]

		if (areaPlugin and areaPlugin.SaveData) then
			areaPlugin:SaveData()
		end
	end
end

function PLUGIN:GetVoiceType(client)
	if (!IsValid(client)) then
		return nil
	end

	for uniqueID, data in pairs(self.voiceTypes or {}) do
		if (data.factions and data.factions[client:Team()]) then
			return uniqueID, data
		end
	end
end

function PLUGIN:CanAutoVoice(client)
	if (!self:IsVoicePluginAvailable() or !IsValid(client) or !client:IsPlayer()) then
		return false
	end

	if (!client:Alive() or client:GetMoveType() == MOVETYPE_NOCLIP or client:IsRagdoll()) then
		return false
	end

	if (!client:GetCharacter() or ix.option.Get(client, "autoVoiceEnabled", true) == false) then
		return false
	end

	local voiceType = self:GetVoiceType(client)

	return voiceType == "combine" and Schema:CanPlayerSeeCombineOverlay(client)
end

function PLUGIN:CanUsePlayerCooldown(client, key, delay)
	self.playerCooldowns[client] = self.playerCooldowns[client] or {}

	local currentTime = CurTime()
	local nextUse = self.playerCooldowns[client][key] or 0

	if (nextUse > currentTime) then
		return false
	end

	self.playerCooldowns[client][key] = currentTime + (delay or PLAYER_COOLDOWN)

	return true
end

function PLUGIN:GetVoiceInfo(className, key)
	local classData = Schema.voices.stored[string.lower(className or "")]

	if (!classData) then
		return nil
	end

	return classData[string.lower(key or "")]
end

function PLUGIN:GetVoiceSound(className, key)
	local info = self:GetVoiceInfo(className, key)

	if (!info) then
		return nil
	end

	if (info.table) then
		local selected = table.Random(info.table)

		return istable(selected) and selected[2] or nil
	end

	if (istable(info.sound)) then
		return table.Random(info.sound)
	end

	return info.sound
end

function PLUGIN:GetVoiceText(className, key)
	local info = self:GetVoiceInfo(className, key)

	if (!info) then
		return nil
	end

	if (info.table) then
		local selected = table.Random(info.table)

		return istable(selected) and selected[1] or nil
	end

	return info.text
end

function PLUGIN:GetGridNumbers(position)
	position = position or vector_origin

	return math.Round(position.x / 100), math.Round(position.y / 100)
end

function PLUGIN:BuildNumberSounds(value)
	local sounds = {}
	local normalized = tostring(math.abs(math.Round(tonumber(value) or 0)))

	if (normalized == "0") then
		local zeroSound = self:GetVoiceSound("Combine", "0")

		if (zeroSound) then
			sounds[#sounds + 1] = zeroSound
		end

		return sounds
	end

	for i = 1, #normalized do
		local soundPath = self:GetVoiceSound("Combine", normalized:sub(i, i))

		if (soundPath) then
			sounds[#sounds + 1] = soundPath
		end
	end

	return sounds
end

function PLUGIN:GetCombineDesignationParts(client)
	local _, info = Schema:GetCombineUnitID(client)

	if (!info) then
		return nil, nil, nil
	end

	local callsignKey = COMBINE_CALLSIGN_KEYS[info.callsign]
	local callsignSound = callsignKey and self:GetVoiceSound("Combine", callsignKey) or nil
	local callsignText = callsignKey and self:GetVoiceText("Combine", callsignKey) or info.callsign
	local numberSounds = self:BuildNumberSounds(info.number or 0)

	return {
		sound = callsignSound,
		text = callsignText
	}, numberSounds, info
end

function PLUGIN:BuildTemplateEvent(client, templateName, context)
	local templates = COMBINE_TEMPLATE_SETS[templateName]

	if (!istable(templates) or #templates == 0) then
		return nil
	end

	local variant = table.Random(templates)

	if (!variant) then
		return nil
	end

	local sequence = {}
	local parts = {}
	local callsignPart, numberSounds, info = self:GetCombineDesignationParts(client)

	if (callsignPart and callsignPart.sound) then
		sequence[#sequence + 1] = callsignPart.sound
	end

	if (callsignPart and callsignPart.text and callsignPart.text != "") then
		parts[#parts + 1] = string.Trim(callsignPart.text)
	end

	for _, soundPath in ipairs(numberSounds or {}) do
		sequence[#sequence + 1] = soundPath
	end

	if (info and info.number) then
		parts[#parts + 1] = tostring(info.number)
	end

	for _, soundPath in ipairs(variant.sounds or {}) do
		sequence[#sequence + 1] = soundPath
	end

	if (variant.usesSector) then
		local sectorLabel = self:GetAreaSectorLabel(client:GetArea())
		local sectorNumber = self:GetAreaSectorNumber(client:GetArea())

		if (sectorLabel) then
			parts[#parts + 1] = sectorLabel .. ","
		end

		if (sectorNumber) then
			local sectorSounds = self:BuildNumberSounds(sectorNumber)

			for _, soundPath in ipairs(sectorSounds) do
				sequence[#sequence + 1] = soundPath
			end
		end
	end

	if (variant.text and variant.text != "") then
		parts[#parts + 1] = variant.text
	elseif (variant.suffix and variant.suffix != "") then
		parts[#parts + 1] = variant.suffix
	end

	if (#sequence == 0 or #parts == 0) then
		return nil
	end

	return {
		sounds = sequence,
		text = table.concat(parts, " ")
	}
end

function PLUGIN:BuildCombineSpeech(sounds)
	local sequence = {"Vocoder.On"}

	for _, soundPath in ipairs(sounds) do
		if (isstring(soundPath) and soundPath != "") then
			sequence[#sequence + 1] = soundPath
		end
	end

	sequence[#sequence + 1] = "Vocoder.Off"

	return sequence
end

function PLUGIN:PlayCombineSequence(client, sounds, volume, isRadioTransmission)
	if (!self:CanAutoVoice(client) or !istable(sounds) or #sounds == 0) then
		return false
	end

	netstream.Start(nil, "voicePlay", self:BuildCombineSpeech(sounds), volume or 75, client:EntIndex(), isRadioTransmission == true, "combine")

	return true
end

function PLUGIN:GetActiveRadioState(client)
	local character = client:GetCharacter()

	if (!character) then
		return nil
	end

	local inventory = character:GetInventory()

	if (!inventory) then
		return nil
	end

	local radios = inventory:GetItemsByUniqueID("handheld_radio", true)
	local enabledRadio

	for _, radio in ipairs(radios) do
		if (radio:GetData("enabled", false)) then
			enabledRadio = enabledRadio or radio

			if (radio:GetData("active", false)) then
				if (radio:GetData("scanning", false) and !radio:GetData("broadcast", false)) then
					return nil
				end

				local frequency = character:GetData("frequency", radio:GetData("frequency", "100.0"))

				if (!frequency or frequency == "") then
					return nil
				end

				return {
					item = radio,
					freq = frequency,
					chan = character:GetData("channel", "1"),
					broadcast = radio:GetData("broadcast", false),
					walkie = radio.walkietalkie == true,
					lrange = radio.longrange == true,
					quiet = radio:GetData("silenced", false),
					callsign = ix.config.Get("enableCallsigns", true) and character:GetData("callsign", client:Name()) or nil
				}
			end
		end
	end

	if (ix.plugin.list["radio_extended"]) then
		return nil
	end

	if (enabledRadio) then
		local frequency = character:GetData("frequency", enabledRadio:GetData("frequency", "100.0"))

		if (!frequency or frequency == "") then
			return nil
		end

		return {
			item = enabledRadio,
			freq = frequency,
			chan = character:GetData("channel", "1"),
			broadcast = false,
			walkie = false,
			lrange = false,
			quiet = false,
			callsign = nil
		}
	end

	return nil
end

function PLUGIN:HasNearbyCombineICListener(client)
	local range = ix.config.Get("chatRange", IC_RANGE)
	local rangeSqr = range * range
	local origin = client:GetPos()

	for _, target in ipairs(player.GetAll()) do
		if (target == client or !IsValid(target) or !target:IsPlayer()) then
			continue
		end

		if (!target:Alive() or target:IsRagdoll() or !target:IsCombine()) then
			continue
		end

		if (origin:DistToSqr(target:GetPos()) <= rangeSqr) then
			return true
		end
	end

	return false
end

function PLUGIN:SendChatForVoice(client, text, radioData)
	if (!isstring(text) or text == "") then
		return false
	end

	local wrappedText = Schema:WrapCombineChatText(text)

	if (radioData) then
		local eavesdropData = {
			quiet = radioData.quiet == true,
			walkie = radioData.walkie == true
		}

		ix.chat.Send(client, "radio", wrappedText, false, nil, radioData)
		ix.chat.Send(client, "radio_eavesdrop", wrappedText, false, nil, eavesdropData)

		return true, true
	end

	if (self:HasNearbyCombineICListener(client)) then
		ix.chat.Send(client, "ic", wrappedText)

		return true, false
	end

	return false
end

function PLUGIN:EmitVoiceEvent(client, text, sounds, volume)
	if (!self:CanAutoVoice(client)) then
		return false
	end

	local radioData = self:GetActiveRadioState(client)
	local didSend, usedRadio = self:SendChatForVoice(client, text, radioData)

	if (!didSend) then
		return false
	end

	return self:PlayCombineSequence(client, sounds, volume, usedRadio)
end

function PLUGIN:IsGrenadeRestingOnWorld(entity)
	if (!IsValid(entity)) then
		return false
	end

	local velocity = entity.GetVelocity and entity:GetVelocity() or vector_origin

	if (velocity:LengthSqr() > (GRENADE_REST_SPEED * GRENADE_REST_SPEED)) then
		return false
	end

	local origin = entity:GetPos()
	local directions = {
		Vector(0, 0, -1),
		Vector(1, 0, 0),
		Vector(-1, 0, 0),
		Vector(0, 1, 0),
		Vector(0, -1, 0)
	}

	for _, direction in ipairs(directions) do
		local trace = util.TraceLine({
			start = origin,
			endpos = origin + direction * GRENADE_WORLD_CONTACT_DISTANCE,
			filter = entity,
			mask = MASK_SOLID_BRUSHONLY
		})

		if (trace.HitWorld) then
			return true
		end
	end

	return false
end

function PLUGIN:TryGrenadeReaction(client, grenade)
	if (!self:CanAutoVoice(client) or !IsValid(grenade) or grenade:GetClass() != GRENADE_CLASS) then
		return
	end

	if (grenade:GetPos():DistToSqr(client:GetPos()) > (GRENADE_REACTION_RADIUS * GRENADE_REACTION_RADIUS)) then
		return
	end

	local owner = grenade.GetOwner and grenade:GetOwner() or nil

	if (owner == client) then
		return
	end

	if (!self:IsGrenadeRestingOnWorld(grenade) or !self:CanUsePlayerCooldown(client, "grenade")) then
		return
	end

	local reactedPlayers = self.reactedGrenades[grenade] or {}

	if (reactedPlayers[client]) then
		return
	end

	reactedPlayers[client] = true
	self.reactedGrenades[grenade] = reactedPlayers

	local event = self:BuildTemplateEvent(client, "danger")

	if (event) then
		self:EmitVoiceEvent(client, event.text, event.sounds)
	end
end

function PLUGIN:BuildManDownSequence(target)
	local _, info = Schema:GetCombineUnitID(target)

	if (!info) then
		return nil
	end

	local callsignKey = COMBINE_CALLSIGN_KEYS[info.callsign]
	local callsignSound = callsignKey and self:GetVoiceSound("Combine", callsignKey) or nil
	local callsignText = callsignKey and self:GetVoiceText("Combine", callsignKey) or info.callsign
	local numberSound = self:GetVoiceSound("Combine", tostring(info.number or ""))
	local variant = table.Random(COMBINE_MAN_DOWN_VARIANTS) or {}
	local sequence = {}
	local parts = {}

	if (callsignSound) then
		sequence[#sequence + 1] = callsignSound
	end

	if (callsignText and callsignText != "") then
		parts[#parts + 1] = string.Trim(callsignText)
	end

	if (numberSound) then
		sequence[#sequence + 1] = numberSound
	end

	if (info.number) then
		parts[#parts + 1] = tostring(info.number)
	end

	for _, soundPath in ipairs(variant.sounds or {}) do
		sequence[#sequence + 1] = soundPath
	end

	if (variant.suffix and variant.suffix != "") then
		parts[#parts + 1] = variant.suffix
	end

	if (#sequence == 0 or #parts == 0) then
		return nil
	end

	return {
		sounds = sequence,
		text = table.concat(parts, " ")
	}
end

function PLUGIN:GetNearbyAutoVoiceCount(client, radius)
	local count = 0
	local radiusSqr = (radius or SQUAD_RADIUS) ^ 2
	local origin = client:GetPos()

	for _, target in ipairs(player.GetAll()) do
		if (!self:CanAutoVoice(target)) then
			continue
		end

		if (origin:DistToSqr(target:GetPos()) <= radiusSqr) then
			count = count + 1
		end
	end

	return count
end

function PLUGIN:HandleThrownGrenade(grenade)
	if (!IsValid(grenade) or grenade:GetClass() != GRENADE_CLASS) then
		return
	end

	if (grenade.ixAutoVoiceThrowHandled) then
		return
	end

	local owner = grenade.GetOwner and grenade:GetOwner() or nil

	if (!self:CanAutoVoice(owner) or !self:CanUsePlayerCooldown(owner, "throw_grenade", 1.5)) then
		return
	end

	grenade.ixAutoVoiceThrowHandled = true

	local event = self:BuildTemplateEvent(owner, "throwGrenade")

	if (event) then
		self:EmitVoiceEvent(owner, event.text, event.sounds)
	end
end

function PLUGIN:Think()
	if (!self:IsVoicePluginAvailable()) then
		return
	end

	local currentTime = CurTime()

	if (self.nextGrenadeScan > currentTime) then
		return
	end

	self.nextGrenadeScan = currentTime + GRENADE_SCAN_INTERVAL

	for _, grenade in ipairs(ents.FindByClass(GRENADE_CLASS)) do
		if (!IsValid(grenade) or !self:IsGrenadeRestingOnWorld(grenade)) then
			if (IsValid(grenade)) then
				self:HandleThrownGrenade(grenade)
			end

			continue
		end

		self:HandleThrownGrenade(grenade)

		for _, client in ipairs(player.GetAll()) do
			self:TryGrenadeReaction(client, grenade)
		end
	end
end

function PLUGIN:PlayerDeath(client)
	if (!self:IsVoicePluginAvailable() or !IsValid(client) or !client:IsCombine()) then
		return
	end

	local currentTime = CurTime()

	if (self.nextDeathReaction > currentTime) then
		return
	end

	self.nextDeathReaction = currentTime + DEATH_EVENT_COOLDOWN

	local event = self:BuildManDownSequence(client)

	if (!event) then
		return
	end

	local clientPos = client:GetPos()

	for _, listener in ipairs(player.GetAll()) do
		if (!self:CanAutoVoice(listener)) then
			continue
		end

		if (listener == client or listener:GetPos():DistToSqr(clientPos) > (DEATH_REACTION_RADIUS * DEATH_REACTION_RADIUS)) then
			continue
		end

		if (self:CanUsePlayerCooldown(listener, "death")) then
			local lastSquadEvent

			if (self:GetNearbyAutoVoiceCount(listener, SQUAD_RADIUS) <= 1) then
				lastSquadEvent = self:BuildTemplateEvent(listener, "lastSquad")
			end

			if (lastSquadEvent) then
				self:EmitVoiceEvent(listener, lastSquadEvent.text, lastSquadEvent.sounds)
			else
				self:EmitVoiceEvent(listener, event.text, event.sounds)
			end
		end
	end
end

function PLUGIN:EntityRemoved(entity)
	if (self.reactedGrenades) then
		self.reactedGrenades[entity] = nil
	end

	if (self.playerCooldowns and IsValid(entity) and entity:IsPlayer()) then
		self.playerCooldowns[entity] = nil
	end
end
