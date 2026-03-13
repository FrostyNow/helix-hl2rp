PLUGIN.name = "Vortigaunt Faction"
PLUGIN.author = "JohnyReaper | Voicelines: sQubany | Modified by Frosty"
PLUGIN.description = "Adds some features for vortigaunts."

ix.config.Add("VortHealMin", 5, "Minimum health value that can be healed by vortigaunt" , nil, {
	data = {min = 1, max = 100},
	category = "Vortigaunt"
})

ix.config.Add("VortHealMax", 20, "Maximum health value that can be healed by vortigaunt" , nil, {
	data = {min = 1, max = 100},
	category = "Vortigaunt"
})

ix.lang.AddTable("english", {
	vortigauntDesc = "An extra-dimensional creature from Xen.",
	vortigeseFormat = "%s says in vortigese \"%s.\"",
	vortessenceFormat = "%s connects through Vortessence \"%s.\"",
	dontKnowVort = "You don't know Vortigese!",
	notVortigaunt = "You are not a Vortigaunt!",
	vortDescription = "Says in vortigaunt language",
	vortIndicator = "Vortigesing",
	vortessenceDescription = "Communicates through Vortessence.",
	vortessenceIndicator = "Connecting to Vortessence...",
	vortWords = {
		"Agorr",
		"Taarr",
		"Rit",
		"Lon-ga",
		"Gon",
		"Galanga",
		"Gala-lon",
		"Churr galing churr ala gon",
		"Churr lon gon challa gurr"
	},
	vortessenceName = "Vortessence",
	vortUnintelligible = "*(unintelligible vortigese)*"
})

ix.lang.AddTable("korean", {
	["Enslaved Vortigaunt"] = "노예 보르티곤트",
	["Vortigaunt"] = "보르티곤트",
	vortigauntDesc = "젠에서 온 이차원 생물입니다.",
	vortigeseFormat = "%s의 보르트어 \"%s.\"",
	vortessenceFormat = "%s의 보르티곤트 정수 연결 \"%s.\"",
	dontKnowVort = "당신은 보르트어를 모릅니다!",
	notVortigaunt = "당신은 보르티곤트가 아닙니다!",
	vortDescription = "보르트어로 말합니다.",
	vortIndicator = "보르트어로 말하는 중",
	vortessenceDescription = "보르티곤트 정수를 통해 대화합니다.",
	vortessenceIndicator = "보르티곤트 정수에 연결 중...",
	vortWords = {
		"아고르",
		"타아르",
		"릿",
		"롱가",
		"공",
		"갈랑가",
		"갈라롱",
		"추르 갈링 추르 알라 공",
		"추르 롱 공 챌라 구르"
	},
	vortessenceName = "보르티곤트 정수",
	vortUnintelligible = "*(알아들을 수 없는 보르티곤트 언어)*"
})


-- Fix default vortigaunt animations
ix.anim.vort = {
	normal = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY},
		[ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
		[ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK},
		["attack"] = ACT_MELEE_ATTACK1
	},
	melee = {
		["attack"] = ACT_MELEE_ATTACK1,
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY},
		[ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM},
		[ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK},
	},
	grenade = {
		["attack"] = ACT_MELEE_ATTACK1,
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY},
		[ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
		[ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK}
	},
	pistol = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, "TCidlecombat"},
		[ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
		["reload"] = ACT_IDLE,
		[ACT_MP_RUN] = {ACT_RUN, "run_all_TC"},
		[ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK},
		[ACT_MP_WALK] = {ACT_WALK, "Walk_all_TC"}
	},
	shotgun = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, "TCidlecombat"},
		[ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
		["reload"] = ACT_IDLE,
		[ACT_MP_RUN] = {ACT_RUN, "run_all_TC"},
		[ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK},
		[ACT_MP_WALK] = {ACT_WALK, "Walk_all_TC"}
	},
	smg = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, "TCidlecombat"},
		[ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
		["reload"] = ACT_IDLE,
		[ACT_MP_RUN] = {ACT_RUN, "run_all_TC"},
		[ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK},
		[ACT_MP_WALK] = {ACT_WALK, "Walk_all_TC"}
	},
	beam = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY},
		[ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
		[ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK},
		attack = ACT_GESTURE_RANGE_ATTACK1,
		["reload"] = ACT_IDLE,
		["glide"] = {ACT_RUN, ACT_RUN}
	},
	sweep = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, "sweep_idle"},
		[ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
		[ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK},
		[ACT_MP_WALK] = {"Walk_all_HoldBroom", "Walk_all_HoldBroom"},
		-- attack = "sweep",
	},
	heal = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE},
		[ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
		[ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK},
	},
	glide = ACT_GLIDE
}

//Default vorts
ix.anim.SetModelClass("models/vortigaunt.mdl", "vort")
ix.anim.SetModelClass("models/vortigaunt_slave.mdl", "vort")
ix.anim.SetModelClass("models/vortigaunt_blue.mdl", "vort")
ix.anim.SetModelClass("models/vortigaunt_doctor.mdl", "vort")

//Ozaxi's vortigaunt
ix.anim.SetModelClass("models/vortigaunt_ozaxi.mdl", "vort")

//Better Vortigaunts addon
ix.anim.SetModelClass("models/kw/kw_vortigaunt.mdl", "vort")
ix.anim.SetModelClass("models/kw/vortigaunt_nobgslave.mdl", "vort")
ALWAYS_RAISED["swep_vortigaunt_sweep"] = true
ALWAYS_RAISED["swep_vortigaunt_beam_edit"] = true
ALWAYS_RAISED["swep_vortigaunt_heal"] = true

local CHAR = ix.meta.character

function CHAR:IsVortigaunt()
	local faction = self:GetFaction()
	return faction == FACTION_VORTIGAUNT or faction == FACTION_ENSLAVEDVORTIGAUNT
end

function PLUGIN:GetPlayerPainSound(client)
	local character = client:GetCharacter()

	if (character and character:IsVortigaunt()) then
		return table.Random({
			"vo/npc/vortigaunt/vortigese11.wav",
			"vo/npc/vortigaunt/vortigese07.wav",
			"vo/npc/vortigaunt/vortigese03.wav"
		})
	end
end

function PLUGIN:GetPlayerDeathSound(client)
	local character = client:GetCharacter()

	if (character and character:IsVortigaunt()) then
		return false
	end
end

if CLIENT then
	randomVortSounds = {
		"vo/npc/vortigaunt/vortigese02.wav",
		"vo/npc/vortigaunt/vortigese03.wav",
		"vo/npc/vortigaunt/vortigese04.wav",
		"vo/npc/vortigaunt/vortigese05.wav",
		"vo/npc/vortigaunt/vortigese07.wav",
		"vo/npc/vortigaunt/vortigese08.wav",
		"vo/npc/vortigaunt/vortigese09.wav",
		"vo/npc/vortigaunt/vortigese11.wav",
		"vo/npc/vortigaunt/vortigese12.wav"
	}
end

ix.chat.Register("Vortigese", {
	format = "vortigeseFormat",
	GetColor = function(self, speaker, text)
		-- If you are looking at the speaker, make it greener to easier identify who is talking.
		if (LocalPlayer():GetEyeTrace().Entity == speaker) then
			return ix.config.Get("chatListenColor")
		end

		-- Otherwise, use the normal chat color.
		return ix.config.Get("chatColor")
	end,
	CanHear = ix.config.Get("chatRange", 280),
	CanSay = function(self, speaker,text)
		if (speaker:GetCharacter():IsVortigaunt()) then
			return true
		else
			speaker:NotifyLocalized("dontKnowVort")
			return false
		end
	end,
	OnChatAdd = function(self, speaker, text, anonymous, info)
		local color = self:GetColor(speaker, text, info)
		local name = anonymous and
				L"someone" or hook.Run("GetCharacterName", speaker, self.uniqueID) or
				(IsValid(speaker) and speaker:Name() or "Console")
		
		local randomSound = table.Random(randomVortSounds)
		if (IsValid(speaker)) then
			speaker:EmitSound(randomSound, 60)
		else
			surface.PlaySound(randomSound)
		end

		local character = LocalPlayer():GetCharacter()
		if (character and !character:IsVortigaunt()) then
			text = L("vortUnintelligible")
		end

		local placeholder = "@@NAME@@"
		local translated = L(self.format, placeholder, text)
		local nameStart, nameEnd = translated:find(placeholder, 1, true)

		if (nameStart and nameEnd) then
			local nameColor = color

			local bAnonymous = anonymous or (info and info.anonymous)

			if (IsValid(speaker) and !bAnonymous) then
				nameColor = speaker:GetClassColor() or team.GetColor(speaker:Team())
			end

			chat.AddText(color, translated:sub(1, nameStart - 1), nameColor, name, color, translated:sub(nameEnd + 1))
		else
			chat.AddText(color, L(self.format, name, text))
		end
	end,	
	prefix = {"/v", "/vort"},
	description = "@vortDescription",
	indicator = "vortIndicator",
	deadCanChat = false
})

ix.chat.Register("Vortessence", {
	format = "vortessenceFormat",
	color = Color(77, 158, 154),
	CanHear = function(self, speaker, listener)
		return listener:GetCharacter():IsVortigaunt()
	end,
	CanSay = function(self, speaker)
		if (!speaker:GetCharacter():IsVortigaunt()) then
			speaker:NotifyLocalized("notVortigaunt")
			return false
		end

		return true
	end,
	OnChatAdd = function(self, speaker, text)
		local color = self.color
		local name = L"vortessenceName"

		if (IsValid(speaker) and speaker:GetCharacter()) then
			name = speaker:GetCharacter():GetName()
		end

			chat.AddText(color, L(self.format, name, text))
	end,
	prefix = {"/ve", "/vortessence"},
	description = "@vortessenceDescription",
	indicator = "vortessenceIndicator",
	deadCanChat = false
})
