local PLUGIN = PLUGIN

function PLUGIN:CreateMusicPlayer()
	if not MediaPlayer then return end

	local mp = MediaPlayer.GetById("auto_music")
	if not mp then
		-- Create the auto music player instance
		mp = MediaPlayer.Create("auto_music", "base")
		
		if mp then
			mp:SetGlobal(true)
			mp:SetPersistent(true)
		end
	end
end

function PLUGIN:Initialize()
	self:CreateMusicPlayer()
end

function PLUGIN:InitializedPlugins()
	timer.Simple(1, function()
		self:CreateMusicPlayer()
	end)
end

function PLUGIN:InitPostEntity()
	self:CreateMusicPlayer()
end
