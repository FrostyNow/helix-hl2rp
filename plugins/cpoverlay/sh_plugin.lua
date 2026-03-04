
local pl = PLUGIN

pl.name = "Combine Overlay"
pl.description = "Adds an overlay for the Combine team."
pl.author = "Nforce"

ix.util.Include("cl_overlay.lua")

ix.lang.AddTable("english", {
	cIdleConnection = "Idle connection...",
    cPingingLoopback = "Pinging loopback...",
    cUpdatingBiosignal = "Updating biosignal coordinates...",
    cEstablishingDC = "Establishing DC link...",
    cCheckingExodus = "Checking exodus protocol status...",
    cSendingCommdata = "Sending commdata to dispatch...",
    cCheckingBiosignal = "Checking biosignal data...",
    cCheckingBOL = "Checking BOL list...",
    cPurportingDisp = "Purporting disp updates...",
})
ix.lang.AddTable("korean", {
	["9mm Pistol"] = "9mm 권총",
	["Standard Issue Pulse Rifle"] = "제식 펄스 소총",
    ["Submachine Gun"] = "기관단총",
    [".357 Revolver"] = ".357 리볼버",
    ["Grenade"] = "수류탄",
    ["Unknown"] = "미확인",
    ["LOCAL UNIT: "] = "현장 병력: ",
    ["PROTECTION TEAM"] = "보호 기동대",
    ["STABILIZATION TEAM"] = "진압 팀",
    ["ASSET HEALTH: "] = "자산 체력: ",
    ["ASSET ARMOR: "] = "자산 방어력: ",
    ["ASSET TOKENS: "] = "자산 토큰: ",
    ["BIOSIGNAL ZONE: "] = "생체 신호 구역: ",
    ["BIOSIGNAL GRID: "] = "생체 신호 좌표: ",
    ["ARM: "] = "무장: ",
    cIdleConnection = "대기 연결...",
    cPingingLoopback = "되돌림 신호 중...",
    cUpdatingBiosignal = "생체 신호 좌표 갱신 중...",
    cEstablishingDC = "DC 연결 수립 중...",
    cCheckingExodus = "이주 프로토콜 상태 확인 중...",
    cSendingCommdata = "디스패치에 통신 정보 보내는 중...",
    cCheckingBiosignal = "생체 신호 확인 중...",
    cCheckingBOL = "BOL 목록 확인 중...",
    cPurportingDisp = "디스패치 업데이트 적용 중...",
})