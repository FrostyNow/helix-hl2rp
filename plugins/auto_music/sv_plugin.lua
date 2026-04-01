local PLUGIN = PLUGIN

if SERVER then
	function PLUGIN:InitializedPlugins()
		timer.Simple(1, function()
			if not MediaPlayer then return end

			-- Create the auto music player instance
			local mp = MediaPlayer.GetById("auto_music")
			if not mp then
				mp = MediaPlayer.Create("auto_music", "base")
			end
		end)
	end
end
