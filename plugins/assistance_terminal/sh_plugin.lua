local PLUGIN = PLUGIN

PLUGIN.name = "Assistance Terminals"
PLUGIN.description = "Adds assistance terminals that citizens can use to request Combine officers to their location."
PLUGIN.author = "VictorK | Modified by Frosty"

ix.util.Include("cl_plugin.lua")
ix.util.Include("sv_hooks.lua")

ix.lang.AddTable("english", {
    assistanceTerminal = "Assistance Terminal",
    terminalUnknownLocation = "Unknown Location",
    terminalDispatch = "Attention all units, Assistance Terminal has been triggered at %s, requested by %s",
    terminalRequest = "Terminal Request - %s | %s",
    terminalNoOfficers = "There are no officers available at this time!",
    terminalNeedsCID = "You need an Identification Card to use the Assistance Terminal!",
    terminalOfficersDispatched = "OFFICERS HAVE BEEN DISPATCHED",
    terminalRequester = "REQUESTER: %s",
    terminalUnidentified = "Unidentified",
    terminalRemainInPlace = "REMAIN IN PLACE",
    terminalPressTo = "PRESS TO",
    terminalRequestAssistance = "REQUEST ASSISTANCE",
    terminalRequesting = "Requesting Assistance...",
    terminalCooldown = "This terminal is recharging. Please try again in %s seconds.",
    terminalOnlyRequesterCanCancel = "Only the reporting citizen can cancel this request.",
    terminalRequestCancelled = "The assistance request has been cancelled."
})

ix.lang.AddTable("korean", {
    assistanceTerminal = "지원 터미널",
    terminalUnknownLocation = "알 수 없는 위치",
    terminalDispatch = "모든 병력 주목, %s에서 지원 터미널이 작동되었다. 요청자: %s",
    terminalRequest = "터미널 요청 - %s | %s",
    terminalNoOfficers = "현재 출동 가능한 대원이 없습니다!",
    terminalNeedsCID = "지원 터미널을 사용하려면 신분증이 필요합니다!",
    terminalOfficersDispatched = "기동대 배치됨",
    terminalRequester = "요청자: %s",
    terminalUnidentified = "신원 미상",
    terminalRemainInPlace = "제자리에 대기하라",
    terminalPressTo = "버튼을 눌러",
    terminalRequestAssistance = "지원 요청",
    terminalRequesting = "지원 요청 중...",
    terminalCooldown = "터미널이 재충전 중입니다. %s초 후에 다시 시도하세요.",
    terminalOnlyRequesterCanCancel = "이 요청은 신고한 시민만 취소할 수 있습니다.",
    terminalRequestCancelled = "지원 요청이 취소되었습니다."
})

ix.config.Add("assistanceTerminalCooldown", 60, "The cooldown for each assistance terminal use (in seconds).", nil, {
    data = {min = 0, max = 3600},
    category = "Assistance Terminal"
})

ix.config.Add("assistanceTerminalActionTime", 5, "The time it takes to use an assistance terminal (in seconds).", nil, {
    data = {min = 0, max = 60},
    category = "Assistance Terminal"
})
