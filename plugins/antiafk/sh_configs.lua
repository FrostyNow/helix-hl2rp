
ix.config.Add("afkTime", 300, "The amount of seconds it takes for someone to be flagged as AFK.", function(oldValue, newValue)
	if (SERVER) then
		for _, v in ipairs(player.GetAll()) do
			if (v:GetCharacter()) then
				timer.Adjust("ixAntiAFK"..v:SteamID64(), newValue)
			end
		end
	end
end, {
	data = {min = 60, max = 3600},
	category = "antiafk"
})

ix.config.Add("afkMapScene", true, "Show map scenes when the player is AFK.", nil, {
	category = "antiafk"
})

ix.config.Add("afkMapSceneInterval", 30, "The amount of seconds each map scene is displayed while AFK.", nil, {
	data = {min = 5, max = 300},
	category = "antiafk"
})
