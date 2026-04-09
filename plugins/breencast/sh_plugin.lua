local PLUGIN = PLUGIN

PLUGIN.name = "Breencast"
PLUGIN.author = "Frosty"
PLUGIN.description = "Breencast relay scheduling built on top of ixVoice playback."

PLUGIN.license = [[
Copyright © 2026 Frosty

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/
]]

PLUGIN.defaultVolume = 80
PLUGIN.defaultSpacing = 0.1
PLUGIN.setLineDelay = 0.5
PLUGIN.repeatDelay = 300
PLUGIN.buttonID = 3889 // rp_industrial17_v1
PLUGIN.broadcastSourceName = "Dr. Wallace Breen"
PLUGIN.setAliases = {
	["welcome"] = "welcome",
	["환영"] = "welcome",
	["instinct"] = "instinct",
	["본능"] = "instinct",
	["collaboration"] = "collaboration",
	["collab"] = "collaboration",
	["협조자"] = "collaboration"
}
PLUGIN.setPrefixes = {
	welcome = "환영",
	instinct = "본능",
	collaboration = "협조자"
}
PLUGIN.setDisplayNames = {
	welcome = "환영",
	instinct = "본능",
	collaboration = "협조자"
}

ix.util.Include("sv_plugin.lua")

function PLUGIN:GetVoiceDuration(soundPath, text)
	local duration = SoundDuration(soundPath or "")

	if (duration and duration > 0) then
		return duration
	end

	text = tostring(text or "")

	return math.Clamp(3 + (#text * 0.045), 4, 14)
end

function PLUGIN:GetQueuedSoundDuration(sounds, delay, spacing)
	delay = delay or 0
	spacing = spacing or self.defaultSpacing

	for _, soundInfo in ipairs(sounds or {}) do
		local postSet, preSet = 0, 0
		local soundPath = soundInfo

		if (istable(soundInfo)) then
			postSet = soundInfo[2] or 0
			preSet = soundInfo[3] or 0
			soundPath = soundInfo[1]
		end

		delay = delay + preSet
		delay = delay + self:GetVoiceDuration(soundPath) + postSet + spacing
	end

	return delay
end

function PLUGIN:GetTextDisplayDuration(text, minimum)
	text = tostring(text or "")

	return math.max(minimum or 4, math.Clamp(3 + (#text * 0.05), 4, 18))
end

function PLUGIN:NormalizeSetName(name)
	name = string.Trim(string.lower(tostring(name or "")))

	return self.setAliases[name]
end

local function getEntryOrder(prefix, key)
	if (key == prefix) then
		return 1
	end

	local suffix = string.match(key, "^" .. prefix .. "(%d+)$")

	if (suffix) then
		return tonumber(suffix) or math.huge
	end

	return math.huge
end

function PLUGIN:GetSetEntries(setID)
	self.setEntries = self.setEntries or {}

	if (self.setEntries[setID]) then
		return self.setEntries[setID]
	end

	local prefix = self.setPrefixes[setID]
	local stored = Schema.voices.stored and Schema.voices.stored["breencast"] or {}
	local entries = {}

	if (!prefix) then
		return entries
	end

	for key, data in pairs(stored) do
		if (key == prefix or string.StartWith(key, prefix)) then
			local text = data.text
			local soundPath = data.sound

			if (data.table and istable(data.table[1])) then
				text = data.table[1][1]
				soundPath = data.table[1][2]
			end

			if (istable(soundPath)) then
				soundPath = soundPath[1]
			end

			if (isstring(text) and text != "" and isstring(soundPath) and soundPath != "") then
				entries[#entries + 1] = {
					key = key,
					text = text,
					sound = soundPath,
					duration = self:GetVoiceDuration(soundPath, text),
					order = getEntryOrder(prefix, key)
				}
			end
		end
	end

	table.sort(entries, function(a, b)
		if (a.order == b.order) then
			return a.key < b.key
		end

		return a.order < b.order
	end)

	self.setEntries[setID] = entries

	return entries
end

function PLUGIN:GetSetDisplayName(setID)
	return self.setDisplayNames[setID] or setID or ""
end

function PLUGIN:InitializedChatClasses()
	local CLASS = {}
	CLASS.color = (ix.chat.classes.broadcast and ix.chat.classes.broadcast.color) or Color(150, 125, 175)

	function CLASS:CanSay(speaker, text)
		return !IsValid(speaker)
	end

	function CLASS:OnChatAdd(speaker, text)
		chat.AddText(self.color, L("breenCastChatFormat", text))
	end

	ix.chat.Register("breencast", CLASS)
end

ix.lang.AddTable("english", {
	breenDesc = "Former administrator of Black Mesa Research Facility and administrator of the Combine Overwatch, colonial government of the Universal Union.",
	breenCast = "Breencast",
	breenCastDesc = "Public Dr. Breen relay terminal driven by ixVoice.",
	breenCastAutoplay = "Schedule",
	breenCastInterval = "Repeat Delay",
	breenCastLive = "LIVE",
	breenCastArchive = "SCHEDULED",
	breenCastStandby = "STANDBY",
	breenCastSpeaker = "Speaker",
	breenCastCurrentLine = "Current line",
	breenCastStatusLive = "Relaying live city broadcast",
	breenCastStatusAutoplay = "Breencast set armed",
	breenCastStatusIdle = "Standing by",
	breenCastUseHint = "Use /breencast <welcome|instinct|collaboration> to start a set.",
	breenCastChatFormat = "Dr. Breen broadcasts \"%s\"",
	breenCastNoRelay = "There are no Breencast relay entities on the server.",
	breenCastNoVoice = "Breencast requires the ixVoice plugin to be loaded.",
	breenCastUnknownSet = "Unknown Breencast set. Use welcome, instinct, collaboration, or false.",
	breenCastStarted = "Breencast set '%s' has been scheduled.",
	breenCastStopping = "Breencast will stop after the current set finishes.",
	breenCastStopped = "Breencast has stopped.",
	breenCastAlreadyStopped = "Breencast is already idle.",
	breenCastSwitched = "Breencast will switch to set '%s' after the current line.",
	breenCastNoLines = "That Breencast set has no registered lines."
})

ix.lang.AddTable("korean", {
	["Dr. Wallace Breen"] = "월리스 브린 박사",
	breenDesc = "전임 블랙 메사 연구소 행정관이자, 우주 공동체의 식민정부인 감시인 정부의 관리자입니다.",
	breenCast = "브린캐스트",
	breenCastDesc = "ixVoice 기반 브린 박사 공공 송출 장치입니다.",
	breenCastAutoplay = "스케줄",
	breenCastInterval = "반복 대기",
	breenCastLive = "실시간",
	breenCastArchive = "예정됨",
	breenCastStandby = "대기 중",
	breenCastSpeaker = "송출자",
	breenCastCurrentLine = "현재 대사",
	breenCastStatusLive = "실시간 시티 방송 송출 중",
	breenCastStatusAutoplay = "브린캐스트 세트 대기 중",
	breenCastStatusIdle = "대기 중",
	breenCastUseHint = "/breencast <환영|본능|협조자>로 세트를 시작하세요.",
	breenCastChatFormat = "브린 박사의 방송 \"%s\"",
	breenCastNoRelay = "서버에 브린캐스트 엔티티가 없습니다.",
	breenCastNoVoice = "브린캐스트는 ixvoice 플러그인이 필요합니다.",
	breenCastUnknownSet = "알 수 없는 브린캐스트 세트입니다. 환영, 본능, 협조자, false 중 하나를 사용하세요.",
	breenCastStarted = "브린캐스트 세트 '%s' 예약이 시작되었습니다.",
	breenCastStopping = "현재 세트가 끝나면 브린캐스트가 중지됩니다.",
	breenCastStopped = "브린캐스트가 중지되었습니다.",
	breenCastAlreadyStopped = "브린캐스트는 이미 대기 중입니다.",
	breenCastSwitched = "현재 대사가 끝나면 '%s' 세트로 전환합니다.",
	breenCastNoLines = "해당 브린캐스트 세트에 등록된 대사가 없습니다."
})

ix.command.Add("BreenCast", {
	description = "@breenCastUseHint",
	adminOnly = true,
	arguments = ix.type.text,
	OnRun = function(self, client, value)
		local plugin = ix.plugin.Get("breencast")
		local normalized = plugin:NormalizeSetName(value)

		if (!plugin:IsVoicePluginAvailable()) then
			return client:NotifyLocalized("breenCastNoVoice")
		end

		if (!plugin:HasRelayEntities()) then
			return client:NotifyLocalized("breenCastNoRelay")
		end

		if (string.lower(string.Trim(tostring(value or ""))) == "false") then
			local result = plugin:RequestStop()

			if (result == "idle") then
				return client:NotifyLocalized("breenCastAlreadyStopped")
			end

			if (result == "stopped") then
				return client:NotifyLocalized("breenCastStopped")
			end

			return client:NotifyLocalized("breenCastStopping")
		end

		if (!normalized) then
			return client:NotifyLocalized("breenCastUnknownSet")
		end

		local entries = plugin:GetSetEntries(normalized)

		if (!entries or #entries <= 0) then
			return client:NotifyLocalized("breenCastNoLines")
		end

		local result = plugin:StartSet(normalized)
		local displayName = plugin:GetSetDisplayName(normalized)

		if (result == "queued") then
			return client:NotifyLocalized("breenCastSwitched", displayName)
		end

		return client:NotifyLocalized("breenCastStarted", displayName)
	end
})
