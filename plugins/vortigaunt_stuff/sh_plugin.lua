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
	notEnoughStamina = "Not enough stamina!",
	targetSuitFull = "Target's suit is already full!",
	tooWeakToHeal = "You are too weak to heal someone!",
	targetFullHealth = "The target is perfectly healthy!",
	
	-- Vortigaunt Beam weapon
	vortBeamName = "Vortigaunt Beam",
	vortBeamPurpose = "Zap everything! Vortigaunt Style",
	vortBeamInstructions = "Primary: Vortigaunt zap.\nSecondary: Target energy charging.",
	
	-- Vortigaunt Heal weapon
	vortHealName = "Heal Ability",
	vortHealPurpose = "To healing people.",
	vortHealInstructions = "Primary Fire: Heal",
	
	-- Broom weapon
	Broom = "Broom",
	["Primary Fire: Sweep\\nSecondary Fire: Push/Knock"] = "Primary Fire: Sweep\\nSecondary Fire: Push/Knock",
	["To sweep up dirt and trash."] = "To sweep up dirt and trash.",

	vortigauntDesc = "An extra-dimensional creature from Xen.",
	vortigeseFormat = "%s says in vortigese \"%s.\"",
	vortessenceFormat = "%s connects through Vortessence \"%s.\"",
	dontKnowVort = "You don't know Vortigese!",
	notVortigaunt = "You are not a Vortigaunt!",
	vortClassManualDisabled = "Vortigaunt classes can only be changed automatically.",
	vortShackleAction = "Removing Vortigaunt shackles...",
	vortShackleTargetAction = "Your shackles are being removed...",
	vortShackleFreed = "You removed %s's shackles.",
	vortShackleFreedTarget = "%s removed your shackles.",
	vortShackleDenied = "You cannot remove this Vortigaunt's shackles.",
	vortTargetNotSlave = "That target is not an enslaved Vortigaunt.",
	vortTargetNotVort = "That target is not a Vortigaunt.",
	vortFreeCommandDesc = "Toggle whether a Vortigaunt target is enslaved.",
	vortFreeSet = "%s is now %s.",
	vortFreeSetTarget = "You are now %s.",
	vortReshackleAction = "Applying Vortigaunt shackles...",
	vortReshackleTargetAction = "Shackles are being placed on you...",
	vortReshackled = "You shackled %s.",
	vortReshackledTarget = "%s shackled you.",
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
	vortUnintelligible = "*(unintelligible vortigese)*",
	vortIDTitle = "<:: VORTIGAUNT IDENTIFICATION ::>",
})

ix.lang.AddTable("korean", {
	notEnoughStamina = "행동력이 부족합니다!",
	targetSuitFull = "대상의 수트가 이미 가득 찼습니다!",
	tooWeakToHeal = "너무 약해서 치유할 수 없습니다!",
	targetFullHealth = "대상이 완벽하게 건강합니다!",
	
	-- Vortigaunt Beam weapon
	vortBeamName = "보르티곤트 빔",
	vortBeamPurpose = "모든 것을 지져버립니다! 보르티곤트 스타일",
	vortBeamInstructions = "주 공격: 보르티곤트 전격.\n보조 공격: 대상 에너지 충전.",
	
	-- Vortigaunt Heal weapon
	vortHealName = "치유 능력",
	vortHealPurpose = "사람들을 치유합니다.",
	vortHealInstructions = "주 공격: 치유",
	
	-- Broom weapon
	Broom = "빗자루",
	["Primary Fire: Sweep\\nSecondary Fire: Push/Knock"] = "왼쪽 클릭: 청소하기\\n오른쪽 클릭: 밀기/노크하기",
	["To sweep up dirt and trash."] = "먼지와 쓰레기를 쓸어냅니다.",

	["Enslaved Vortigaunt"] = "노예 보르티곤트",
	["Vortigaunt"] = "보르티곤트",
	vortigauntDesc = "젠에서 온 이차원 생물입니다.",
	vortigeseFormat = "%s의 보르트어 \"%s.\"",
	vortessenceFormat = "%s의 보르티곤트 정수 연결 \"%s.\"",
	dontKnowVort = "당신은 보르트어를 모릅니다!",
	notVortigaunt = "당신은 보르티곤트가 아닙니다!",
	vortClassManualDisabled = "보르티곤트 클래스는 자동으로만 변경할 수 있습니다.",
	vortShackleAction = "보르티곤트 족쇄를 해제하는 중...",
	vortShackleTargetAction = "당신의 족쇄가 해제되는 중입니다...",
	vortShackleFreed = "%s의 족쇄를 해제했습니다.",
	vortShackleFreedTarget = "%s님이 당신의 족쇄를 해제했습니다.",
	vortShackleDenied = "이 보르티곤트의 족쇄를 해제할 수 없습니다.",
	vortTargetNotSlave = "대상이 노예 보르티곤트가 아닙니다.",
	vortTargetNotVort = "대상이 보르티곤트가 아닙니다.",
	vortFreeCommandDesc = "대상 보르티곤트의 노예 여부를 전환합니다.",
	vortFreeSet = "%s님은 이제 %s 상태입니다.",
	vortFreeSetTarget = "당신은 이제 %s 상태입니다.",
	vortReshackleAction = "보르티곤트에게 족쇄를 채우는 중...",
	vortReshackleTargetAction = "당신에게 족쇄가 채워지는 중입니다...",
	vortReshackled = "%s에게 족쇄를 채웠습니다.",
	vortReshackledTarget = "%s님이 당신에게 족쇄를 채웠습니다.",
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
	vortUnintelligible = "*(알아들을 수 없는 보르티곤트 언어)*",
	vortIDTitle = "<:: 보르티곤트 식별증 ::>",
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
local VORTIGAUNT_SLAVE_MODEL = "models/vortigaunt_slave.mdl"
local VORTIGAUNT_LIBERATION_TIME = 5
local VORTIGAUNT_WEAPONS = {
	"swep_vortigaunt_sweep",
	"swep_vortigaunt_beam_edit",
	"swep_vortigaunt_heal"
}
local VORTIGAUNT_CLASS_WEAPONS = {
	enslaved = {
		"swep_vortigaunt_sweep"
	},
	free = {
		"swep_vortigaunt_sweep",
		"swep_vortigaunt_beam_edit",
		"swep_vortigaunt_heal"
	}
}

function CHAR:IsVortigaunt()
	local faction = self:GetFaction()
	return faction == FACTION_VORT or faction == FACTION_SLAVE_VORT
end

function PLUGIN:GetPlayerPainSound(client)
	local character = client:GetCharacter()

	if (character and character:IsVortigaunt()) then
		return false
	end
end

function PLUGIN:GetPlayerDeathSound(client)
	local character = client:GetCharacter()

	if (character and character:IsVortigaunt()) then
		return false
	end
end

function PLUGIN:IsVortigauntFaction(faction)
	return faction == FACTION_VORT or faction == FACTION_SLAVE_VORT
end

function PLUGIN:IsVortigauntClass(classIndex)
	return classIndex == CLASS_VORT or classIndex == CLASS_SLAVE_VORT
end

function PLUGIN:GetDefaultVortigauntClass()
	return CLASS_SLAVE_VORT or CLASS_VORT
end

function PLUGIN:GetVortigauntWeaponSet(classIndex)
	if (classIndex == CLASS_VORT) then
		return VORTIGAUNT_CLASS_WEAPONS.free
	end

	return VORTIGAUNT_CLASS_WEAPONS.enslaved
end

function PLUGIN:IsEnslavedVortigaunt(character)
	return character and character:GetClass() == CLASS_SLAVE_VORT
end

function PLUGIN:CanManageSlaveVortigaunt(client, target)
	if (!IsValid(client) or !IsValid(target) or !target:IsPlayer()) then
		return false
	end

	local character = client:GetCharacter()
	local inventory = character and character:GetInventory()

	if (client:IsCombine()) then
		return true
	end

	return inventory and inventory:HasItem("comkey") or false
end

if SERVER then
	local function normalizeModel(model)
		return isstring(model) and model:gsub("\\", "/"):lower() or ""
	end

	local normalizedSlaveModel = normalizeModel(VORTIGAUNT_SLAVE_MODEL)

	function PLUGIN:GetVortigauntPartsIndex(client)
		if (!IsValid(client)) then
			return nil
		end

		local index = client:FindBodygroupByName("parts")

		if (index and index > -1) then
			return index
		end

		for _, bodygroup in ipairs(client:GetBodyGroups() or {}) do
			if (isstring(bodygroup.name) and bodygroup.name:gsub("[%s_%-]", ""):lower() == "parts") then
				return bodygroup.id
			end
		end
	end

	function PLUGIN:SetVortigauntStoredBodygroups(character, client, partsValue)
		if (!character or !IsValid(client)) then
			return
		end

		local index = self:GetVortigauntPartsIndex(client)
		local groups = character:GetData("groups", {})

		if (!index or index < 0) then
			return
		end

		groups = istable(groups) and table.Copy(groups) or {}
		groups[index] = partsValue

		local bodygroupPlugin = ix.plugin.Get("bodygroupmanager")

		if (bodygroupPlugin and bodygroupPlugin.SetPersistentAppearance) then
			bodygroupPlugin:SetPersistentAppearance(character, groups)
			bodygroupPlugin:ApplyResolvedAppearance(character, client)
		else
			character:SetData("groups", groups)
			client:SetBodygroup(index, partsValue)
		end
	end

	function PLUGIN:GetVortigauntIDClass(character)
		if (character and character:GetClass() == CLASS_VORT) then
			return "Vortigaunt"
		end

		return "Enslaved Vortigaunt"
	end

	function PLUGIN:EnsureVortigauntCID(character, client)
		if (!character) then
			return
		end

		local id = tostring(character:GetData("cid", ""))

		if (id == "") then
			id = Schema:ZeroNumber(math.random(1, 99999), 5)
			character:SetData("cid", id)
		end

		if (IsValid(client)) then
			Schema:SyncCitizenID(client, character)
		end
	end

	function PLUGIN:SyncVortigauntWeapons(character, client, classIndex)
		if (!character or !IsValid(client)) then
			return
		end

		local allowedWeapons = {}

		for _, weapon in ipairs(self:GetVortigauntWeaponSet(classIndex)) do
			allowedWeapons[weapon] = true

			if (!client:HasWeapon(weapon)) then
				character:GiveWeapon(weapon)
			end
		end

		for _, weapon in ipairs(VORTIGAUNT_WEAPONS) do
			if (!allowedWeapons[weapon] and client:HasWeapon(weapon)) then
				character:TakeWeapon(weapon)
			end
		end
	end

	function PLUGIN:ApplyVortigauntClassState(character, client, classIndex)
		if (!character) then
			return
		end

		classIndex = classIndex or character:GetClass()
		client = IsValid(client) and client or character:GetPlayer()

		if (!self:IsVortigauntClass(classIndex) or !IsValid(client)) then
			return
		end

		if (normalizeModel(character:GetModel()) != normalizedSlaveModel) then
			character:SetModel(VORTIGAUNT_SLAVE_MODEL)
			client:SetupHands()
		end

		self:SyncVortigauntWeapons(character, client, classIndex)
		self:SetVortigauntStoredBodygroups(character, client, classIndex == CLASS_VORT and 1 or 0)
		self:EnsureVortigauntCID(character, client)
	end

	function PLUGIN:SetVortigauntClass(character, classIndex, client)
		if (!character) then
			return false
		end

		classIndex = classIndex or self:GetDefaultVortigauntClass()

		if (!self:IsVortigauntClass(classIndex)) then
			return false
		end

		character:SetClass(classIndex)
		self:ApplyVortigauntClassState(character, client, classIndex)

		return true
	end

	function PLUGIN:SetVortigauntEnslaved(character, shouldBeSlave, client)
		local classIndex = shouldBeSlave and CLASS_SLAVE_VORT or CLASS_VORT

		return self:SetVortigauntClass(character, classIndex, client)
	end

	function PLUGIN:StartVortigauntLiberation(client, target)
		if (!self:CanManageSlaveVortigaunt(client, target)) then
			client:NotifyLocalized("vortShackleDenied")
			return false
		end

		local targetCharacter = target:GetCharacter()

		if (!targetCharacter or !targetCharacter:IsVortigaunt()) then
			client:NotifyLocalized("vortTargetNotVort")
			return false
		end

		if (!self:IsEnslavedVortigaunt(targetCharacter)) then
			client:NotifyLocalized("vortTargetNotSlave")
			return false
		end

		if (target:GetNetVar("vortShackleRemoving")) then
			return false
		end

		target:SetAction("@vortShackleTargetAction", VORTIGAUNT_LIBERATION_TIME)
		target:SetNetVar("vortShackleRemoving", true)
		client:SetAction("@vortShackleAction", VORTIGAUNT_LIBERATION_TIME)

		client:DoStaredAction(target, function()
			if (!IsValid(client) or !IsValid(target)) then
				return
			end

			local currentCharacter = target:GetCharacter()

			if (!currentCharacter or !self:IsEnslavedVortigaunt(currentCharacter)) then
				return
			end

			self:SetVortigauntEnslaved(currentCharacter, false, target)
			target:SetNetVar("vortShackleRemoving", nil)
			target:SetAction()
			client:SetAction()
			client:NotifyLocalized("vortShackleFreed", target:GetName())
			target:NotifyLocalized("vortShackleFreedTarget", client:GetName())
		end, VORTIGAUNT_LIBERATION_TIME, function()
			if (IsValid(target)) then
				target:SetNetVar("vortShackleRemoving", nil)
				target:SetAction()
			end

			if (IsValid(client)) then
				client:SetAction()
			end
		end)

		return true
	end

	function PLUGIN:StartVortigauntReshackle(client, target)
		if (!self:CanManageSlaveVortigaunt(client, target)) then
			client:NotifyLocalized("vortShackleDenied")
			return false
		end

		local targetCharacter = target:GetCharacter()

		if (!targetCharacter or !targetCharacter:IsVortigaunt()) then
			client:NotifyLocalized("vortTargetNotVort")
			return false
		end

		if (self:IsEnslavedVortigaunt(targetCharacter)) then
			client:NotifyLocalized("vortTargetNotSlave")
			return false
		end

		if (target:GetNetVar("vortShackleRemoving")) then
			return false
		end

		target:SetAction("@vortReshackleTargetAction", VORTIGAUNT_LIBERATION_TIME)
		target:SetNetVar("vortShackleRemoving", true)
		client:SetAction("@vortReshackleAction", VORTIGAUNT_LIBERATION_TIME)

		client:DoStaredAction(target, function()
			if (!IsValid(client) or !IsValid(target)) then
				return
			end

			local currentCharacter = target:GetCharacter()

			if (!currentCharacter or !currentCharacter:IsVortigaunt() or self:IsEnslavedVortigaunt(currentCharacter)) then
				return
			end

			self:SetVortigauntEnslaved(currentCharacter, true, target)
			target:SetNetVar("vortShackleRemoving", nil)
			target:SetAction()
			client:SetAction()
			client:NotifyLocalized("vortReshackled", target:GetName())
			target:NotifyLocalized("vortReshackledTarget", client:GetName())
		end, VORTIGAUNT_LIBERATION_TIME, function()
			if (IsValid(target)) then
				target:SetNetVar("vortShackleRemoving", nil)
				target:SetAction()
			end

			if (IsValid(client)) then
				client:SetAction()
			end
		end)

		return true
	end

	function PLUGIN:NormalizeVortigauntCharacter(character, client)
		if (!character) then
			return
		end

		if (character:GetFaction() == FACTION_SLAVE_VORT and FACTION_VORT) then
			character:SetFaction(FACTION_VORT)
		end

		if (!self:IsVortigauntFaction(character:GetFaction())) then
			return
		end

		if (!self:IsVortigauntClass(character:GetClass())) then
			character:SetClass(self:GetDefaultVortigauntClass())
		end

		self:ApplyVortigauntClassState(character, client or character:GetPlayer(), character:GetClass())
	end

	function PLUGIN:InitializedPlugins()
		local interactionPlugin = ix.plugin.list["playerinteraction"]

		if (interactionPlugin) then
			if (!interactionPlugin.interactions["free_vort_shackles"]) then
				interactionPlugin.interactions["free_vort_shackles"] = {
					name = "보르티곤트 족쇄 해제",
					description = "노예 보르티곤트의 족쇄를 해제합니다.",
					check = function(client, target)
						local targetCharacter = IsValid(target) and target:GetCharacter()

						return targetCharacter
							and targetCharacter:IsVortigaunt()
							and targetCharacter:GetClass() == CLASS_SLAVE_VORT
							and !target:GetNetVar("vortShackleRemoving")
							and PLUGIN:CanManageSlaveVortigaunt(client, target)
					end,
					action = function(client, target)
						PLUGIN:StartVortigauntLiberation(client, target)
					end
				}
			end

			if (!interactionPlugin.interactions["enslave_vort_shackles"]) then
				interactionPlugin.interactions["enslave_vort_shackles"] = {
					name = "보르티곤트 족쇄 채우기",
					description = "해방된 보르티곤트에게 다시 족쇄를 채웁니다.",
					check = function(client, target)
						local targetCharacter = IsValid(target) and target:GetCharacter()

						return targetCharacter
							and targetCharacter:IsVortigaunt()
							and targetCharacter:GetClass() == CLASS_VORT
							and !target:GetNetVar("vortShackleRemoving")
							and PLUGIN:CanManageSlaveVortigaunt(client, target)
					end,
					action = function(client, target)
						PLUGIN:StartVortigauntReshackle(client, target)
					end
				}
			end
		end
	end

	function PLUGIN:GetCharacterIdentificationData(character)
		if (!character or !character.IsVortigaunt or !character:IsVortigaunt()) then
			return
		end

		if (!self:IsEnslavedVortigaunt(character)) then
			return
		end

		self:EnsureVortigauntCID(character, character:GetPlayer())

		return {
			name = character:GetName(),
			id = tostring(character:GetData("cid", "00000")),
			class = self:GetVortigauntIDClass(character),
			title = "vortIDTitle"
		}
	end

	function PLUGIN:CharacterLoaded(character)
		self:NormalizeVortigauntCharacter(character, character:GetPlayer())
	end

	function PLUGIN:PlayerLoadedCharacter(client, character)
		self:NormalizeVortigauntCharacter(character, client)
	end

	function PLUGIN:PostPlayerLoadout(client)
		local character = client:GetCharacter()

		if (character) then
			self:NormalizeVortigauntCharacter(character, client)
		end
	end

	function PLUGIN:CharacterVarChanged(character, key, oldValue, value)
		if (key == "class" and self:IsVortigauntClass(value)) then
			local client = character:GetPlayer()

			timer.Simple(0, function()
				if (character and IsValid(client) and client:GetCharacter() == character) then
					self:ApplyVortigauntClassState(character, client, value)
				end
			end)
		elseif (key == "faction" and self:IsVortigauntFaction(value)) then
			self:NormalizeVortigauntCharacter(character, character:GetPlayer())
		end
	end

	function PLUGIN:CanPlayerJoinClass(client, class, info)
		local classIndex = isnumber(class) and class or (istable(class) and class.index)

		if (!self:IsVortigauntClass(classIndex)) then
			return
		end

		if (istable(info) and info.vortigauntAuto) then
			return
		end

		client:NotifyLocalized("vortClassManualDisabled")
		return false
	end

	do
		local COMMAND = {}
		COMMAND.description = "@vortFreeCommandDesc"
		COMMAND.adminOnly = true
		COMMAND.arguments = {
			ix.type.player,
			ix.type.bool
		}
		COMMAND.alias = {"vortfree"}

		function COMMAND:OnRun(client, target, shouldBeFree)
			local character = IsValid(target) and target:GetCharacter()

			if (!character or !character:IsVortigaunt()) then
				client:NotifyLocalized("vortTargetNotVort")
				return
			end

			PLUGIN:SetVortigauntEnslaved(character, !shouldBeFree, target)
			client:NotifyLocalized("vortFreeSet", target:GetName(), L(shouldBeFree and "Vortigaunt" or "Enslaved Vortigaunt"))
			target:NotifyLocalized("vortFreeSetTarget", L(shouldBeFree and "Vortigaunt" or "Enslaved Vortigaunt"))
		end

		ix.command.Add("VortFree", COMMAND)
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
