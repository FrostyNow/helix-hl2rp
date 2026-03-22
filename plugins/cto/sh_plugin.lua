
PLUGIN.name = "Combine Technology Overlay"
PLUGIN.author = "Trudeau & Aspect™"
PLUGIN.description = "A Helix port of the modern overhaul of Combine technology designed with non-intrusiveness and responsiveness in mind."

ix.util.Include("cl_hooks.lua")
ix.util.Include("cl_plugin.lua")
ix.util.Include("sh_commands.lua")
ix.util.Include("sh_configs.lua")
ix.util.Include("sv_hooks.lua")
ix.util.Include("sv_plugin.lua")

ix.lang.AddTable("english", {
	["Camera Terminal"] = "Camera Terminal",
	cameraTerminalDesc = "A terminal connected to surveillance cameras.",
	["Unauthorized Weapon Possession"] = "Unauthorized Weapon Possession",
	["Suspected Violent Act"] = "Suspected Violent Act",
	["Missing CID"] = "Missing CID",
	MovementViolation = "Movement violation(s) sighted by C-i%s...",
	NoBiosignalNote = "Note: Your character currently has no biosignal.",
	DownloadingTrauma = "Downloading trauma packet...",
	UnitLostConsciousness = "WARNING! Protection team unit %s lost consciousness at %s...",
	DownloadingLostBiosignal = "Downloading lost biosignal...",
	BiosignalLostForUnit = "WARNING! Biosignal lost for protection team unit %s at %s...",
	ConnectionRestored = "Connection restored...",
	DownloadingFoundBiosignal = "Downloading found biosignal...",
	NoncohesiveBiosignalFound = "ALERT! Noncohesive biosignal found for protection team unit %s at %s...",
	ErrorShuttingDown = "ERROR! Shutting down...",
	AssistanceRequestRecv = "Assistance request received...",
	requestCooldown = "You must wait %s second(s) before requesting assistance again.",
	requestDesc = "Request assistance from Civil Protection.",
	charSetBioDesc = "Turn a character's biosignal on or off. Will alert other units.",
	bioDesc = "Turn your biosignal on or off. Will alert all other units.",
	bioAlreadyOn = "Your biosignal is already enabled!",
	bioAlreadyOff = "Your biosignal is already disabled!",
	targetBioAlreadyOn = "%s's biosignal is already enabled!",
	targetBioAlreadyOff = "%s's biosignal is already disabled!",
	bioSet = "You have %s %s's biosignal.",
	socioInvalid = "That is not a valid sociostatus!",
	socioStatusDesc = "Update the sociostability status of the city.",
	cameraEnableDesc = "Remotely enable a Combine camera - IDs are shown on the HUD.",
	cameraInvalid = "There is no Combine camera with that ID!",
	cameraAlreadyEnabled = "That camera is already enabled!",
	cameraEnabled = "Enabling C-i%s...",
	cameraDisabled = "Disabling C-i%s...",
	cameraAlreadyDisabled = "That camera is already disabled!",
	cameraDisableDesc = "Remotely disable a Combine camera - IDs are shown on the HUD.",
	socioStatusUpdated = "ALERT! Sociostatus updated to %s!",
})

ix.lang.AddTable("korean", {
	["Camera Terminal"] = "카메라 단말기",
	cameraTerminalDesc = "감시 카메라와 연결된 단말기입니다.",
	["All Clear"] = "이상 없음",
	["Watching..."] = "감시 중...",
	["Violation!"] = "위반 행위!",
	["Disabled"] = "비활성화",
	["no signal(?)"] = "신호 없음(?)",
	["Sociostatus"] = "사회 기조",
	["Lost"] = "두절",
	["Removing"] = "제거 중",
	["Received"] = "수신됨",
	["Unconscious"] = "의식 불명",
	["Assistance Request"] = "지원 요청",
	["Running"] = "달리기",
	["Jumping"] = "점프",
	["Ducking"] = "앉기",
	["Laying"] = "드러누움",
	["Unauthorized Weapon Possession"] = "비인가 무기 소지",
	["Suspected Violent Act"] = "폭력 행위 의심",
	["Missing CID"] = "CID 미소지",
	["Within Sights"] = "명 시야에 들어옴",
	["Violations Within Sights"] = "시야 내 위반 행위 포착",
	["Possible Violation"] = "위반 행위 의심",
	MovementViolation = "C-i%s에 의해 위반 행위(들) 포착...",
	NoBiosignalNote = "알림: 당신의 캐릭터는 현재 생체 신호가 두절되었습니다.",
	DownloadingTrauma = "신체 손상 패킷 내려받는 중...",
	UnitLostConsciousness = "위험! 병력 %s, %s에서 의식 소실...",
	DownloadingLostBiosignal = "두절된 생체 신호 내려받는 중...",
	BiosignalLostForUnit = "위험! 병력 %s, %s에서 생체 신호 두절...",
	ConnectionRestored = "연결 복구됨...",
	DownloadingFoundBiosignal = "새 생체 신호 내려받는 중...",
	NoncohesiveBiosignalFound = "경고! 병력 %s, %s에서 생체 신호 발견...",
	ErrorShuttingDown = "오류! 전원 종료 중...",
	AssistanceRequestRecv = "지원 요청 수신됨...",
	requestCooldown = "지원 요청을 다시 보내려면 %s초 더 기다려야 합니다.",
	requestDesc = "시민 보호 기동대에 지원을 요청합니다.",
	charSetBioDesc = "캐릭터의 생체 신호를 전환합니다. 다른 병력에 알림이 전송됩니다.",
	bioDesc = "생체 신호를 전환합니다. 다른 병력에 알림이 전송됩니다.",
	bioAlreadyOn = "생체 신호가 이미 켜져 있습니다!",
	bioAlreadyOff = "생체 신호가 이미 꺼져 있습니다!",
	targetBioAlreadyOn = "%s님의 생체 신호가 이미 켜져 있습니다!",
	targetBioAlreadyOff = "%s님의 생체 신호가 이미 꺼져 있습니다!",
	bioSet = "당신은 %s님의 생체 신호를 %s로 전환했습니다.",
	["enabled"] = "활성화",
	["disabled"] = "비활성화",
	socioInvalid = "올바른 사회 기조가 아닙니다!",
	socioStatusDesc = "도시의 사회 기조를 갱신합니다.",
	cameraEnableDesc = "콤바인 카메라를 원격으로 전환합니다. ID는 HUD에 표시되어 있습니다.",
	cameraInvalid = "해당하는 ID의 콤바인 카메라가 없습니다!",
	cameraAlreadyEnabled = "카메라가 이미 활성화되어 있습니다!",
	cameraEnabled = "C-i%s 활성화 중...",
	cameraDisabled = "C-i%s 비활성화 중...",
	cameraAlreadyDisabled = "카메라가 이미 비활성화되어 있습니다!",
	cameraDisableDesc = "콤바인 카메라를 원격으로 비활성화합니다. ID는 HUD에 표시되어 있습니다.",
	socioStatusUpdated = "경고! 사회 기조가 %s(으)로 갱신되었습니다!",
})

PLUGIN.sociostatusColors = {
	GREEN = Color(0, 255, 0),
	BLUE = Color(0, 128, 255),
	YELLOW = Color(255, 255, 0),
	RED = Color(255, 0, 0),
	BLACK = Color(128, 128, 128)
}

-- Biosignal change enums, used for player/admin command language variations.
PLUGIN.ERROR_NONE = 0
PLUGIN.ERROR_NOT_COMBINE = 1
PLUGIN.ERROR_ALREADY_ENABLED = 2
PLUGIN.ERROR_ALREADY_DISABLED = 3

-- Movement violation enums, used when networking cameras.
PLUGIN.VIOLATION_RUNNING = 0
PLUGIN.VIOLATION_JUMPING = 1
PLUGIN.VIOLATION_CROUCHING = 2
PLUGIN.VIOLATION_FALLEN_OVER = 3
PLUGIN.VIOLATION_RAISED_WEAPON = 4
PLUGIN.VIOLATION_MISSING_CID = 5
PLUGIN.VIOLATION_SUSPECTED_VIOLENCE = 6

-- Camera controlling enums.
PLUGIN.CAMERA_VIEW = 0
PLUGIN.CAMERA_DISABLE = 1
PLUGIN.CAMERA_ENABLE = 2

PLUGIN.raisedWeaponWhitelist = {
	ix_hands = true,
	ix_keys = true,
	swep_vortigaunt_sweep = true,
	weapon_physgun = true,
	gmod_tool = true,
	ix_suitcase = true,
}

PLUGIN.weaponViolationFactionWhitelist = {
	[FACTION_ADMIN] = true,
	[FACTION_CONSCRIPT] = true
}

function PLUGIN:isCameraEnabled(camera)
	return camera:GetSequenceName(camera:GetSequence()) == "idlealert"
end

function PLUGIN:PlayerHasCID(target)
	if (!IsValid(target) or !target:IsPlayer()) then
		return false
	end

	local character = target:GetCharacter()

	if (!character) then
		return false
	end

	if (Schema.HasCharacterIdentification) then
		return Schema:HasCharacterIdentification(character)
	end

	local inventory = character.GetInventory and character:GetInventory()

	return inventory and inventory:HasItem("cid") or false
end

function PLUGIN:CanCombineIdentifyTarget(target)
	if (!IsValid(target) or !target:IsPlayer() or !target:GetCharacter()) then
		return false
	end

	if (self.weaponViolationFactionWhitelist[target:Team()]) then
		return false
	end

	if (target:IsCombine()) then
		return !target:GetNetVar("IsBiosignalGone", false)
	end

	return self:PlayerHasCID(target) != false
end

function PLUGIN:CanFlagTargetForViolation(target)
	if (!IsValid(target) or !target:IsPlayer() or !target:GetCharacter()) then
		return false
	end

	if (target:IsCombine()) then
		return false
	end

	if (self.weaponViolationFactionWhitelist[target:Team()]) then
		return false
	end

	return self:CanCombineIdentifyTarget(target)
end

function PLUGIN:IsVisibleWeaponViolation(target)
	if (!IsValid(target) or !target:IsPlayer()) then
		return false
	end

	if (self.weaponViolationFactionWhitelist[target:Team()]) then
		return false
	end

	local weapon = target:GetActiveWeapon()

	if (!IsValid(weapon)) then
		return false
	end

	return !self.raisedWeaponWhitelist[weapon:GetClass()]
end

function PLUGIN:IsSuspectedViolentAct(target)
	if (!IsValid(target) or !target:IsPlayer()) then
		return false
	end

	if (self.weaponViolationFactionWhitelist[target:Team()]) then
		return false
	end

	local weapon = target:GetActiveWeapon()

	if (!IsValid(weapon) or weapon:GetClass() != "ix_hands") then
		return false
	end

	return target:IsWepRaised()
end

if (SERVER) then
	function PLUGIN:SaveData()
		local data = {}

		for _, v in ipairs(ents.FindByClass("ix_ctocameraterminal")) do
			data[#data + 1] = {	
				pos = v:GetPos(),
				angles = v:GetAngles(),
				color = v:GetColor(),
			}
		end

		ix.data.Set("camera_terminals", data)
	end

	function PLUGIN:LoadData()
		local data = ix.data.Get("camera_terminals") or {}

		for _, v in ipairs(data) do
			local entity = ents.Create("ix_ctocameraterminal")
			entity:SetPos(v.pos)
			entity:SetAngles(v.angles)
			entity:SetColor(v.color)
			entity:Spawn()

			local physicsObject = entity:GetPhysicsObject()

			if (IsValid(physicsObject)) then
				physicsObject:Wake()
			end
		end
	end
end
