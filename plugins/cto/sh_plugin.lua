
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
	notCombine = "You are not the Combine!",
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
})

ix.lang.AddTable("korean", {
	["Camera Terminal"] = "카메라 단말기",
	cameraTerminalDesc = "감시 카메라와 연결된 단말기입니다.",
	notCombine = "당신은 콤바인이 아닙니다!",
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
	["Within Sights"] = "명 시야에 들어옴",
	["Violations Within Sights"] = "시야 내 위반 행위 포착",
	["Possible Violation"] = "발생 가능 위반 행위",
	MovementViolation = "C-i%s에 의해 위반 행위(들) 포착...",
	NoBiosignalNote = "알림: 당신의 캐릭터는 현재 생체 신호가 두절되었습니다.",
	DownloadingTrauma = "신체 손상 패킷 내려받는 중...",
	UnitLostConsciousness = "위험! 보호 기동대 %s, %s에서 의식 소실...",
	DownloadingLostBiosignal = "두절된 생체 신호 내려받는 중...",
	BiosignalLostForUnit = "위험! 보호 기동대 %s, %s에서 생체 신호 두절...",
	ConnectionRestored = "연결 복구됨...",
	DownloadingFoundBiosignal = "새 생체 신호 내려받는 중...",
	NoncohesiveBiosignalFound = "경고! 보호 기동대 %s, %s에서 생체 신호 발견...",
	ErrorShuttingDown = "오류! 전원 종료 중...",
	AssistanceRequestRecv = "지원 요청 수신됨...",
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

-- Camera controlling enums.
PLUGIN.CAMERA_VIEW = 0
PLUGIN.CAMERA_DISABLE = 1
PLUGIN.CAMERA_ENABLE = 2

function PLUGIN:isCameraEnabled(camera)
	return camera:GetSequenceName(camera:GetSequence()) == "idlealert"
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