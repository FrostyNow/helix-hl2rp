PLUGIN.name = "StormFox 2 Support"
PLUGIN.description = "Something new thing"
PLUGIN.author = "Bilwin, heavily modified by Frosty"
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
			print("[TimeSync] StormFox2 낮/밤 길이가 각각 " .. tostring(phaseLength) .. "분으로 동기화되었습니다.")
		end
	end
end

if SERVER then
	hook.Add("StormFox2.InitPostEntity", "ix_StormFox2_AutoSync", function()
		PerformTimeSync()
	end)
end

ix.lang.AddTable("english", {
	timeSync = "StormFox and Helix time has been synchronized.",
	cmdTimeSync = "Sync StormFox and Helix time."
})

ix.lang.AddTable("korean", {
	timeSync = "StormFox와 Helix의 시간이 동기화되었습니다.",
	cmdTimeSync = "StormFox의 시간과 배수를 Helix 시스템에 동기화합니다."
})

ix.command.Add("TimeSync", {
	description = "cmdTimeSync",
	adminOnly = true,
	OnRun = function(self, client)
		if (not StormFox2) then return client:NotifyLocalized("noStormFox") end

		PerformTimeSync()
		
		return client:NotifyLocalized("timeSync")
	end
})