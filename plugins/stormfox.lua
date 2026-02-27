PLUGIN.name = "StormFox 2 Support"
PLUGIN.description = "Something new thing, now supports proper time sync."
PLUGIN.author = "Bilwin, Totally rewritten by Frosty"
PLUGIN.schema = "Any"
PLUGIN.version = 1.0

if not StormFox2 then return end

local function PerformTimeSync()
	if not StormFox2 then return end

	local helixTimeStr = ix.date.GetFormatted("%H:%M")
	local sfTime = StormFox2.Time.StringToTime(helixTimeStr)
		
	if sfTime then
		StormFox2.Time.Set(sfTime)
	end

	local helixTimeScale = ix.config.Get("secondsPerMinute", 60)

	if helixTimeScale > 0 then
		local phaseLength = 12 * helixTimeScale
		
		if StormFox2.Setting then
			StormFox2.Setting.Set("day_length", phaseLength)
			StormFox2.Setting.Set("night_length", phaseLength)
			print("[Helix] StormFox2 day/night length synchronized to " .. tostring(phaseLength) .. " minutes each.")
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
end

ix.lang.AddTable("english", {
	timeSync = "StormFox and Helix time has been synchronized.",
	cmdTimeSync = "Sync StormFox and Helix time.",
	cmdTime = "Check current Helix time.",
	cmdTimeSet = "Set the current time.",
	timeSet = "The time has been set to %s.",
	invalidTime = "Invalid time format! Use HHMM (e.g., 2330).",
})

ix.lang.AddTable("korean", {
	timeSync = "StormFox와 Helix의 시간이 동기화되었습니다.",
	cmdTimeSync = "StormFox의 시간과 배수를 Helix 시스템에 동기화합니다.",
	cmdTime = "Helix 시간을 확인합니다.",
	cmdTimeSet = "현재 시간을 설정합니다.",
	timeSet = "시간이 %s으로 설정되었습니다.",
	invalidTime = "잘못된 시간 형식입니다! HHMM 형식을 사용하세요 (예: 2330).",
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