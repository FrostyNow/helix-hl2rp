PLUGIN.name = "StormFox 2 Support"
PLUGIN.description = "Something new thing, now supports proper time sync."
PLUGIN.author = "Bilwin, Totally rewritten by Frosty"
PLUGIN.schema = "Any"
PLUGIN.version = 1.0

if not StormFox2 then return end

ix.config.Add("notifyTimeChange", true, "Whether or not to notify players when the time changes (Day/Night).", nil, {
	category = "StormFox 2"
})

ix.config.Add("dayLength", 14, "The length of the day in hours.", nil, {
	data = {min = 1, max = 23},
	category = "StormFox 2"
})

ix.config.Add("nightLength", 10, "The length of the night in hours.", nil, {
	data = {min = 1, max = 23},
	category = "StormFox 2"
})

ix.config.Add("notifyCurfew", true, "Whether or not to automatically announce the night curfew.", nil, {
	category = "StormFox 2"
})

local function PerformTimeSync()
	if not StormFox2 then return end

	local helixTimeStr = ix.date.GetFormatted("%H:%M")
	local sfTime = StormFox2.Time.StringToTime(helixTimeStr)
		
	if sfTime then
		StormFox2.Time.Set(sfTime)
	end

	local helixTimeScale = ix.config.Get("secondsPerMinute", 60)

	if helixTimeScale > 0 then
		local dayLength = ix.config.Get("dayLength", 12)
		local nightLength = ix.config.Get("nightLength", 12)
		local dayPhase = dayLength * helixTimeScale
		local nightPhase = nightLength * helixTimeScale
		
		if StormFox2.Setting then
			StormFox2.Setting.Set("day_length", dayPhase)
			StormFox2.Setting.Set("night_length", nightPhase)
			print(string.format("[Helix] StormFox2 synchronized: Day %dh (%dm), Night %dh (%dm)", dayLength, dayPhase, nightLength, nightPhase))
		end
	end
end

if SERVER then
	local bHasSync = false
	hook.Add("PlayerInitialSpawn", "ix_StormFox2_AutoSync", function(client)
		if not bHasSync then
			PerformTimeSync()
			bHasSync = true
		end
	end)

	PLUGIN.nextDayCheck = 0
	PLUGIN.isDay = nil
	PLUGIN.lastCurfewMinute = -1

	function PLUGIN:Tick()
		if (self.nextDayCheck > CurTime()) then return end
		self.nextDayCheck = CurTime() + 1

		if (not StormFox2) then return end

		-- Day/Night change notification
		if (ix.config.Get("notifyTimeChange", false)) then
			local bIsDay = StormFox2.Time.IsDay()

			if (self.isDay == nil) then
				self.isDay = bIsDay
			elseif (bIsDay ~= self.isDay) then
				local phrase = bIsDay and "dayNotify" or "nightNotify"
				local playersByLang = {}

				for _, v in ipairs(player.GetAll()) do
					if (v:GetCharacter()) then
						local lang = ix.option.Get(v, "language", "english")
						playersByLang[lang] = playersByLang[lang] or {}
						table.insert(playersByLang[lang], v)
					end
				end

				for lang, receivers in pairs(playersByLang) do
					ix.chat.Send(nil, "event", L(phrase, receivers[1]), nil, receivers)
				end

				self.isDay = bIsDay
			end
		end

		-- Curfew logic
		local date = ix.date.Get()
		local hour = date:gethours()
		local minute = date:getminutes()

		if (minute != self.lastCurfewMinute) then
			if (ix.config.Get("notifyCurfew", false)) then
				local phrase
				if (hour == 23 and minute == 0) then
					phrase = "curfewWarningNotify"
				elseif (hour == 0 and minute == 0) then
					phrase = "curfewStartNotify"
				elseif (minute == 0 and (hour == 2 or hour == 4)) then
					phrase = "curfewReminderNotify"
				elseif (hour == 6 and minute == 0) then
					phrase = "curfewEndNotify"
				end

				if (phrase) then
					local bHasDispatcher = false
					for _, v in ipairs(player.GetAll()) do
						if (v:GetCharacter() and v:IsDispatch()) then
							bHasDispatcher = true
							break
						end
					end

					if (bHasDispatcher) then
						local playersByLang = {}
						local soundFile
						
						if (phrase == "curfewWarningNotify") then 
							soundFile = "npc/overwatch/cityvoice/curfew_warning.wav"
						elseif (phrase == "curfewStartNotify") then 
							soundFile = "npc/overwatch/cityvoice/curfew.wav"
						elseif (phrase == "curfewReminderNotify") then 
							soundFile = "npc/overwatch/cityvoice/curfew_reminder.wav"
						elseif (phrase == "curfewEndNotify") then 
							soundFile = "npc/overwatch/cityvoice/curfew_end.wav"
						end

						for _, v in ipairs(player.GetAll()) do
							if (v:GetCharacter()) then
								local lang = ix.option.Get(v, "language", "english")
								playersByLang[lang] = playersByLang[lang] or {}
								table.insert(playersByLang[lang], v)

								if (soundFile) then
									v:SendLua(string.format("surface.PlaySound('%s')", soundFile))
								end
							end
						end

						for lang, receivers in pairs(playersByLang) do
							ix.chat.Send(nil, "dispatch", L(phrase, receivers[1]), nil, receivers)
						end
					end
				end
			end
			self.lastCurfewMinute = minute
		end
	end
end

ix.lang.AddTable("english", {
	timeSync = "StormFox and Helix time has been synchronized.",
	cmdTimeSync = "Sync StormFox and Helix time.",
	cmdTime = "Check current Helix time.",
	cmdTimeSet = "Set the current time.",
	timeSet = "The time has been set to %s.",
	invalidTime = "Invalid time format! Use HHMM (e.g., 2330).",
	dayNotify = "The sun begins to rise, signaling the start of a new day.",
	nightNotify = "The sun sets, and darkness begins to fall over the land.",
	curfewWarningNotify = "Attention citizens. 1 hour remaining until night curfew. Complete your assigned duties and move to your residential block immediately.",
	curfewStartNotify = "Attention citizens. A night curfew is now in effect. Move to your residential block immediately.",
	curfewReminderNotify = "Attention citizens. Night curfew is currently in effect. Avoid unnecessary travel outside of residential blocks.",
	curfewEndNotify = "Attention citizens. The night curfew has been lifted. Return to your assigned duties.",
})

ix.lang.AddTable("korean", {
	timeSync = "StormFox와 Helix의 시간이 동기화되었습니다.",
	cmdTimeSync = "StormFox의 시간과 배수를 Helix 시스템에 동기화합니다.",
	cmdTime = "Helix 시간을 확인합니다.",
	cmdTimeSet = "현재 시간을 설정합니다.",
	timeSet = "시간이 %s으로 설정되었습니다.",
	invalidTime = "잘못된 시간 형식입니다! HHMM 형식을 사용하세요 (예: 2330).",
	dayNotify = "지평선 위로 해가 뜨기 시작하며 새로운 아침이 밝아옵니다.",
	nightNotify = "해가 지고, 어둠이 서서히 내려앉기 시작합니다.",
	curfewWarningNotify = "시민에게 알린다. 야간 통행 금지령 발효까지 1시간 남았다. 지정된 업무를 마무리하고 시민 거주구로 즉시 이동하라.",
	curfewStartNotify = "시민에게 알린다. 야간 통행 금지령이 발효되었다. 시민 거주구로 즉시 이동하라.",
	curfewReminderNotify = "시민에게 알린다. 야간 통행 금지령이 발효 중이다. 시민 거주구 외로 불필요한 통행을 자제하라.",
	curfewEndNotify = "시민에게 알린다. 야간 통행 금지령이 해제되었다. 지정된 업무에 종사하라.",
})

ix.command.Add("TimeSync", {
	description = "@cmdTimeSync",
	adminOnly = true,
	OnRun = function(self, client)
		if (not StormFox2) then return client:NotifyLocalized("noStormFox") end

		PerformTimeSync()
		
		return client:NotifyLocalized("timeSync")
	end
})

ix.command.Add("TimeSet", {
	description = "@cmdTimeSet",
	adminOnly = true,
	arguments = ix.type.string,
	OnRun = function(self, client, time)
		local hours, minutes

		if (tonumber(time) and (#time == 3 or #time == 4)) then
			if #time == 4 then
				hours = tonumber(time:sub(1, 2))
				minutes = tonumber(time:sub(3, 4))
			else
				hours = tonumber(time:sub(1, 1))
				minutes = tonumber(time:sub(2, 3))
			end
		elseif (time:find(":")) then
			local exploding = string.Explode(":", time)
			hours = tonumber(exploding[1])
			minutes = tonumber(exploding[2])
		end

		if (not hours or not minutes or hours < 0 or hours > 23 or minutes < 0 or minutes > 59) then
			return "@invalidTime"
		end

		local date = ix.date.Get()
		date:sethours(hours, minutes, 0, 0)

		ix.date.current = date
		ix.date.start = CurTime()
		ix.date.Send()
		ix.date.Save()

		PerformTimeSync()

		return client:NotifyLocalized("timeSet", string.format("%02d:%02d", hours, minutes))
	end
})

ix.command.Add("Time", {
	description = "@cmdTime",
	OnRun = function(self, client)
		if (not client:GetCharacter()) then return client:NotifyLocalized("unknownError") end
		
		return client:NotifyLocalized(ix.date.GetLocalizedTime(client))
	end
})