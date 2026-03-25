local PLUGIN = PLUGIN
PLUGIN.name = "Event Helper"
PLUGIN.author = "Frosty"
PLUGIN.description = "Provides few commands to proceed events."

ix.lang.AddTable("english", {
	cmdToggleBlackout = "Toggle global screen blackout for all players.",
	cmdEarthquake = "Cause an earthquake for all players.",
	blackoutEnabled = "Blackout has been enabled for all players.",
	blackoutDisabled = "Blackout has been disabled for all players.",
	earthquakeStarted = "An earthquake has started!",
	earthquakeUsage = "Usage: /Earthquake <magnitude> <duration>",
	earthquakeTriggered = "Earthquake triggered (Magnitude: %s, Duration: %s)"
})

ix.lang.AddTable("korean", {
	cmdToggleBlackout = "모든 플레이어의 화면 암전 상태를 토글합니다.",
	cmdEarthquake = "모든 플레이어에게 지진 효과를 일으킵니다.",
	blackoutEnabled = "모든 플레이어의 화면이 암전되었습니다.",
	blackoutDisabled = "모든 플레이어의 화면 암전이 해제되었습니다.",
	earthquakeStarted = "지진이 발생했습니다!",
	earthquakeUsage = "사용법: /Earthquake <강도> <지속시간> [사운드 여부]",
	earthquakeTriggered = "지진 발생 (강도: %s, 지속시간: %s초)"
})

local earthquakeSounds = {
	"ambient/levels/streetwar/building_rubble1.wav",
	"ambient/levels/streetwar/building_rubble2.wav",
	"ambient/levels/streetwar/building_rubble3.wav",
	"ambient/levels/streetwar/building_rubble4.wav",
	"ambient/levels/streetwar/building_rubble5.wav"
}

if (SERVER) then
	util.AddNetworkString("ixBlackoutSync")

	function PLUGIN:PlayerInitialSpawn(client)
		net.Start("ixBlackoutSync")
			net.WriteBool(self.bBlackout or false)
		net.Send(client)
	end
	
	function PLUGIN:SetBlackout(bState)
		self.bBlackout = bState
		
		net.Start("ixBlackoutSync")
			net.WriteBool(bState)
		net.Broadcast()
	end
end

if (CLIENT) then
	net.Receive("ixBlackoutSync", function()
		local bBlackout = net.ReadBool()
		PLUGIN.bBlackout = bBlackout
	end)

	function PLUGIN:HUDPaint()
		if (self.bBlackout) then
			surface.SetDrawColor(0, 0, 0, 255)
			surface.DrawRect(0, 0, ScrW(), ScrH())
		end
	end
end

ix.command.Add("ToggleBlackout", {
	description = "@cmdToggleBlackout",
	superAdminOnly = true,
	OnRun = function(self, client)
		local bNewState = !PLUGIN.bBlackout
		PLUGIN:SetBlackout(bNewState)

		if (bNewState) then
			ix.util.NotifyLocalized("blackoutEnabled", nil)
		else
			ix.util.NotifyLocalized("blackoutDisabled", nil)
		end
	end
})

ix.command.Add("Earthquake", {
	description = "@cmdEarthquake",
	arguments = {
		ix.type.number, -- Magnitude
		ix.type.number, -- Duration
		bit.bor(ix.type.bool, ix.type.optional) -- bSound
	},
	superAdminOnly = true,
	OnRun = function(self, client, magnitude, duration, bSound)
		magnitude = math.Clamp(magnitude, 1, 100)
		duration = math.Clamp(duration, 1, 60)
		bSound = (bSound == nil) and true or bSound

		for _, v in ipairs(player.GetAll()) do
			util.ScreenShake(v:GetPos(), magnitude, 5, duration, 5000)

			if (bSound) then
				v:EmitSound("ambient/atmosphere/city_rumble1.wav", 100)
				
				-- Play crashing sounds randomly during the duration
				local timerID = "ixEarthquakeSound_" .. v:EntIndex()
				local maxCount = math.max(1, math.floor(duration / 3))

				timer.Create(timerID, 1.5, maxCount, function()
					if (IsValid(v)) then
						v:EmitSound(table.Random(earthquakeSounds), 100, math.random(90, 110))
					end
				end)
			end
		end

		ix.util.NotifyLocalized("earthquakeStarted", nil)
		return client:NotifyLocalized("earthquakeTriggered", magnitude, duration)
	end
})
