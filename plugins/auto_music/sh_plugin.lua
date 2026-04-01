local PLUGIN = PLUGIN

PLUGIN.name = "Auto Music System"
PLUGIN.author = "Frosty"
PLUGIN.description = "A global music system synchronized via MediaPlayer Redux."

PLUGIN.license = [[
Copyright © 2026 Frosty

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/
]]

-- Pre-defined music categories
PLUGIN.MusicCategories = {
	["calm"] = {
		"https://www.youtube.com/watch?v=vy3KBgT1dRw", -- Triage at Dawn
		"https://www.youtube.com/watch?v=yLuSRTp3yF8", -- Brotherhood of Steel
		"https://www.youtube.com/watch?v=FM0YP2--8GM", -- Deference For Liber-tea
		"https://www.youtube.com/watch?v=tbpSvSe6xg0", -- Let You Down
	},
	["blue"] = {
		"https://www.youtube.com/watch?v=sxDtDcxwRfU", -- Ravenholm
		"https://www.youtube.com/watch?v=KR8IW2Z-zYg", -- Hazardous Environment
		"https://www.youtube.com/watch?v=PMpkFNL0o74", -- Slow Light
		"https://www.youtube.com/watch?v=CIq13K26hSo", -- Vague Voices
	},
	["aggressive"] = {
		"https://www.youtube.com/watch?v=t7Gz8jJOLAk", -- Guard Down
		"https://www.youtube.com/watch?v=D4DfQ8gUN68", -- Penultimatum
		"https://www.youtube.com/watch?v=r-eMVfiT8_c", -- Something Secret Steers Us
		"https://www.youtube.com/watch?v=VA4i-IoJcCI", -- CP Violation
		"https://www.youtube.com/watch?v=O9pZOhAvMss", -- Vortal Combat
		"https://www.youtube.com/watch?v=JYPg3pzCRKM", -- Sector Sweep
		"https://www.youtube.com/watch?v=Mo8Tlo2JBL4", -- You're Not Supposed To Be Here
		"https://www.youtube.com/watch?v=Lc3Y6jPYHWk", -- LG Orbifold
		"https://www.youtube.com/watch?v=ct_nyBIa0zQ", -- Last Legs
		"https://www.youtube.com/watch?v=U6673bY8sw8", -- Brane Scan
		"https://www.youtube.com/watch?v=qWDaRg-cPwE", -- Apprehension and Evasion
		"https://www.youtube.com/watch?v=3UiKY_e3qDQ", -- We've Got Hostiles
		"https://www.youtube.com/watch?v=Vr1xs92ySXQ", -- No One Rides For Free
		"https://www.youtube.com/watch?v=c8pQmdTCjg4", -- Klaxon Beat
		"https://www.youtube.com/watch?v=BLJZnJe7KgU", -- Ending Triumph
		"https://www.youtube.com/watch?v=G9UH9kWQdXw", -- Beats to spill oil on Cyberstan
	}
}

ix.command.Add("MusicPlay", {
	description = "Play a random music track from a specific category (e.g., calm, blue, aggressive).",
	privilege = "Manage Music",
	adminOnly = true,
	arguments = {
		ix.type.string
	},
	OnRun = function(self, client, categoryName)
		if not MediaPlayer then return "MediaPlayer addon is required." end

		local mp = MediaPlayer.GetById("auto_music")
		
		-- Try to create it if it doesn't exist yet (server-side)
		if not mp and SERVER then
			mp = MediaPlayer.Create("auto_music", "base")
		end

		if not mp then
			return "Music player not initialized. Ensure MediaPlayer addon is working."
		end
		
		local category = PLUGIN.MusicCategories[string.lower(categoryName)]
		if not category or #category == 0 then
			return "Invalid category or empty category. Available: " .. table.concat(table.GetKeys(PLUGIN.MusicCategories), ", ")
		end
		
		-- Select random track
		local url = category[math.random(#category)]
		
		local media = MediaPlayer.GetMediaForUrl(url)
		if not media then
			return "Failed to resolve selected URL format."
		end
		
		mp:AddMedia(media)
		return "Requested to play random track from '" .. categoryName .. "' category."
	end
})

ix.command.Add("MusicSkip", {
	description = "Skip the currently playing music track.",
	privilege = "Manage Music",
	adminOnly = true,
	OnRun = function(self, client)
		if not MediaPlayer then return "MediaPlayer addon is required." end

		local mp = MediaPlayer.GetById("auto_music")
		if not mp then return "Music player not initialized." end
		
		if mp:IsPlayerPrivileged(client) then
			mp:OnMediaFinished()
			return "Skipped current music track."
		end
		
		return "You do not have permission to skip."
	end
})

ix.command.Add("MusicClear", {
	description = "Clear the music queue.",
	privilege = "Manage Music",
	adminOnly = true,
	OnRun = function(self, client)
		if not MediaPlayer then return "MediaPlayer addon is required." end

		local mp = MediaPlayer.GetById("auto_music")
		if not mp then return "Music player not initialized." end
		
		mp:ClearMediaQueue()
		mp:OnMediaFinished()
		return "Cleared music queue and stopped playing."
	end
})
