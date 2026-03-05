local PLUGIN = PLUGIN
PLUGIN.name = "Jukeboxes & Radios"
PLUGIN.desc = "Add jukeboxes and radios (handle stream urls)"
PLUGIN.author = "Abel Witz"

PLUGIN.channels = {
	{freq = 88.5, name = "Oldies", url = "http://fallout.fm:8000/falloutfm3.ogg"},
	{freq = 91.2, name = "Modern", url = "http://streaming.radionomy.com/hammerhead?.mp3"},
	{freq = 99.6, name = "Chicago", url = "http://whpk-stream.uchicago.edu/stream"},
	-- {freq = 103.1, name = "Easy Listening", url = "https://lounge-radio.com/listen128.m3u"},
	{freq = 107.3, name = "Classic", url = "https://14623.live.streamtheworld.com/KUSCMP32.mp3"},
}

ix.config.Add("radioDist", 550, "Maximum radios/jukeboxes hear distance.", function(old, new)
	if ( CLIENT ) then
		for _, v in pairs(PLUGIN.activeRadios) do
			local channel = v.channel
			if ( channel and channel:IsValid() ) then
				channel:Set3DFadeDistance(new * 0.5, new)
			end
		end
	end
end, {data = {min = 1, max = 2000}, category = "Jukeboxes & Radios"})

ix.config.Add("radioUrl", "http://fallout.fm:8000/falloutfm3.ogg", "The radio url used by radios and jukeboxes.", function()
	if ( CLIENT ) then
		for _, v in pairs(PLUGIN.activeRadios) do
			v:StopStream()
			v:StartStream()
		end
	end
end, {category = "Jukeboxes & Radios"})


ix.lang.AddTable("english", {
	musicRadioDesc = "A stationary radio that recieves music channel.",
	alreadyUsingRadio = "Someone is already using this radio.",
})

ix.lang.AddTable("korean", {
	["Music Radio"] = "음악 라디오",
	musicRadioDesc = "음악 채널을 수신하는 고정식 라디오입니다.",
	alreadyUsingRadio = "누군가 이 라디오를 사용하고 있습니다.",
})


ix.util.Include("cl_plugin.lua")

if (SERVER) then
	util.AddNetworkString("ixMusicRadioOpenUI")
	util.AddNetworkString("ixMusicRadioCloseUI")
	util.AddNetworkString("ixMusicRadioUpdate")

	net.Receive("ixMusicRadioCloseUI", function(len, ply)
		local entity = net.ReadEntity()
		if (IsValid(entity) and entity.occupier == ply) then
			entity.occupier = nil
		end
	end)

	net.Receive("ixMusicRadioUpdate", function(len, ply)
		local entity = net.ReadEntity()
		local power = net.ReadBool()
		local channel = net.ReadFloat()
		local volume = net.ReadUInt(8)

		if (IsValid(entity) and entity.isMusicRadio and ply:GetPos():DistToSqr(entity:GetPos()) < 100000) then
			if (IsValid(entity.occupier) and entity.occupier != ply) then return end
			entity.occupier = ply
			
			local oldPower = entity:GetNetVar("power", false)
			
			entity:SetNetVar("power", power)
			entity:SetNetVar("channel", channel)
			entity:SetNetVar("volume", volume)

			if (oldPower != power) then
				if (power) then
					entity:EmitSound("radio/radio_on.ogg")
				else
					entity:EmitSound("radio/radio_off.ogg")
				end
			end
		end
	end)

	function PLUGIN:SaveData()
		local data = {}

		for _, v in ipairs(ents.FindByClass("ix_music_radio")) do
			data[#data + 1] = {
				pos = v:GetPos(),
				angles = v:GetAngles(),
				power = v:GetNetVar("power", false),
				channel = v:GetNetVar("channel", 88.0),
				volume = v:GetNetVar("volume", 100)
			}
		end

		ix.data.Set("music_radios", data)
	end

	function PLUGIN:LoadData()
		local data = ix.data.Get("music_radios") or {}

		for _, v in ipairs(data) do
			local entity = ents.Create("ix_music_radio")
			entity:SetPos(v.pos)
			entity:SetAngles(v.angles)
			entity:Spawn()
			entity:SetNetVar("power", v.power)
			entity:SetNetVar("channel", v.channel)
			entity:SetNetVar("volume", v.volume)

			local physicsObject = entity:GetPhysicsObject()

			if (IsValid(physicsObject)) then
				physicsObject:Wake()
			end
		end
	end
end