local PLUGIN = PLUGIN

PLUGIN.name        = "YouTube Audio"
PLUGIN.author      = "Frosty"
PLUGIN.description = "Plays YouTube videos only with audio for server-wide."

PLUGIN.license = [[
Copyright © 2026 Frosty

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/
]]

-- ---------------------------------------------------------------------------
-- YouTube Video ID Extraction
-- Supports: watch?v=, shorts/, youtu.be/
-- ---------------------------------------------------------------------------

function PLUGIN:ExtractVideoId(url)
	if not isstring(url) then return nil end

	-- youtube.com/watch?v=ID  (possibly with other query params before/after)
	local id = string.match(url, "[?&]v=([%a%d%-_]+)")
	if id then return id end

	-- youtube.com/shorts/ID
	id = string.match(url, "youtube%.com/shorts/([%a%d%-_]+)")
	if id then return id end

	-- youtu.be/ID
	id = string.match(url, "youtu%.be/([%a%d%-_]+)")
	if id then return id end

	return nil
end

-- ---------------------------------------------------------------------------
-- Options
-- ---------------------------------------------------------------------------

if CLIENT then
	ix.option.Add("ytaudioVolume", ix.type.number, 80, {
		category = "YouTube Audio",
		min = 0,
		max = 100,
		OnChanged = function(oldValue, newValue)
			local plugin = ix.plugin.Get("ytaudio")
			if plugin and plugin.UpdateLocalVolume then
				plugin:UpdateLocalVolume()
			end
		end
	})
end

-- ---------------------------------------------------------------------------
-- Config
-- ---------------------------------------------------------------------------

ix.config.Add(
	"ytaudioDefaultVolume", 80,
	"YouTube 재생 시 서버 기본 마스터 볼륨 (0~100).",
	nil,
	{ data = { min = 0, max = 100 }, category = "YouTube Audio" }
)

ix.config.Add(
	"ytaudioPlayerURL",
	"https://mediaplayer.purrcoding.com/youtube.html",
	"YouTube Player HTML page URL. Default is an externally hosted public page.",
	nil,
	{ category = "YouTube Audio" }
)

ix.config.Add(
	"ytaudioShowNotifications", false,
	"Wether to notify players about YouTube playback.",
	nil,
	{ category = "YouTube Audio" }
)

-- ---------------------------------------------------------------------------
-- Language Tables
-- ---------------------------------------------------------------------------

ix.lang.AddTable("english", {
	ytaudioStarted = "♪  Now playing: %s",
	ytaudioStopped = "YouTube audio stopped.",
	ytaudioNoVideo = "No YouTube audio is currently playing.",
	ytaudioInvalidURL = "Invalid YouTube URL. Supported formats: watch?v=, shorts/, youtu.be/",
	ytaudioVolSet = "YouTube audio volume set to %d%%.",
	ytaudioSynced = "YouTube audio re-synced for all players.",
	ytaudioMuted = "YouTube audio has been muted for you.",
	ytaudioUnmuted = "YouTube audio has been unmuted for you.",
	cmdYTMute = "Mutes or unmutes YouTube audio for yourself.",
	cmdYTSync = "Forces all players to re-sync to the current playback position.",
	cmdYTPlay = "Plays a YouTube URL server-wide.",
	cmdYTStop = "Stops server-wide playback.",
	cmdYTSkip = "Skips the current YouTube video.",
	ytaudioQueued = "♪  Queued: %s",
	ytaudioSkipped = "YouTube audio skipped.",
	optYtaudioVolume = "YouTube Audio Volume",
	optdYtaudioVolume = "Sets the volume of YouTube audio.",
})

ix.lang.AddTable("korean", {
	ytaudioStarted = "♪  재생 시작: %s",
	ytaudioStopped = "YouTube 오디오가 중지되었습니다.",
	ytaudioNoVideo = "현재 재생 중인 영상이 없습니다.",
	ytaudioInvalidURL = "유효하지 않은 YouTube URL입니다. (watch?v=, shorts/, youtu.be/ 형식 지원)",
	ytaudioVolSet = "YouTube 오디오 음량이 %d%%로 설정되었습니다.",
	ytaudioSynced = "모든 플레이어의 YouTube 오디오가 재동기화되었습니다.",
	ytaudioMuted = "YouTube 오디오를 음소거했습니다.",
	ytaudioUnmuted = "YouTube 오디오 음소거를 해제했습니다.",
	cmdYTMute = "YouTube 오디오를 음소거하거나 음소거를 해제합니다.",
	cmdYTSync = "모든 플레이어를 현재 재생 위치로 강제 재동기화합니다.",
	cmdYTPlay = "YouTube URL을 서버 전역으로 재생합니다.",
	cmdYTStop = "서버 YouTube 오디오를 정지합니다.",
	cmdYTSkip = "현재 재생 중인 YouTube 영상을 건너뜁니다.",
	ytaudioQueued = "♪  대기열 추가: %s",
	ytaudioSkipped = "YouTube 오디오를 건너뛰었습니다.",
	optYtaudioVolume = "YouTube 오디오 음량",
	optdYtaudioVolume = "YouTube 오디오의 음량을 설정합니다.",
})

-- ---------------------------------------------------------------------------
-- Network Strings  (declared server-side; used client-side)
-- ixYTAudioPlay   : sv → cl  videoId, title, offset(s), volume
-- ixYTAudioStop   : sv → cl  (no payload)
-- ixYTAudioVolume : sv → cl  volume
-- ixYTAudioSync   : sv → cl  videoId, offset(s), volume
-- ---------------------------------------------------------------------------

if SERVER then
	util.AddNetworkString("ixYTAudioPlay")
	util.AddNetworkString("ixYTAudioStop")
	util.AddNetworkString("ixYTAudioVolume")
	util.AddNetworkString("ixYTAudioSync")
end

-- ---------------------------------------------------------------------------
-- Realm Includes
-- ---------------------------------------------------------------------------

ix.util.Include("sv_plugin.lua")
ix.util.Include("cl_plugin.lua")

-- ---------------------------------------------------------------------------
-- Commands
-- ---------------------------------------------------------------------------

---
-- /ytplay <url>
-- Plays a YouTube URL server-wide.
---
ix.command.Add("YTPlay", {
	description = "@cmdYTPlay",
	adminOnly   = true,
	arguments   = ix.type.text,

	OnRun = function(self, client, url)
		local plugin  = ix.plugin.Get("ytaudio")
		local videoId = plugin:ExtractVideoId(url)

		if not videoId then
			client:NotifyLocalized("ytaudioInvalidURL")
			return
		end

		-- Fetch the video title asynchronously via YouTube oEmbed API.
		-- oEmbed does not require an API key.
		local oembedURL = "https://www.youtube.com/oembed?url=https%3A%2F%2Fwww.youtube.com%2Fwatch%3Fv%3D"
						  .. videoId .. "&format=json"

		HTTP({
			url    = oembedURL,
			method = "GET",

			success = function(code, body)
				local data  = util.JSONToTable(body or "")
				local title = (data and isstring(data.title) and data.title != "")
							  and data.title
							  or ("Video: " .. videoId)
				plugin:PlayVideo(videoId, title)
			end,

			failed = function()
				-- Proceed without a title if the request fails
				plugin:PlayVideo(videoId, "Video: " .. videoId)
			end,
		})
	end,
})

---
-- /ytstop
-- Stops server-wide playback.
---
ix.command.Add("YTStop", {
	description = "@cmdYTStop",
	adminOnly   = true,

	OnRun = function(self, client)
		local plugin = ix.plugin.Get("ytaudio")
		plugin:StopVideo()
	end,
})

---
-- /ytsync
-- Forces all players to re-sync to the current playback position.
---
ix.command.Add("YTSync", {
	description = "@cmdYTSync",
	adminOnly   = true,

	OnRun = function(self, client)
		local plugin = ix.plugin.Get("ytaudio")

		if not plugin.ytState.playing then
			client:NotifyLocalized("ytaudioNoVideo")
			return
		end

		plugin:SyncAll()
		NotifyAll("ytaudioSynced")
	end,
})

---
-- /ytskip
-- Skips current video and plays the next one in queue.
---
ix.command.Add("YTSkip", {
	description = "@cmdYTSkip",
	adminOnly   = true,

	OnRun = function(self, client)
		local plugin = ix.plugin.Get("ytaudio")
		plugin:SkipVideo()
	end,
})

ix.command.Add("YTMute", {
	description = "@cmdYTMute",
	OnRun = function(self, client)
		PLUGIN.ytMuted = not PLUGIN.ytMuted

		if PLUGIN.ytMuted then
			client:NotifyLocalized("ytaudioMuted")
		else
			client:NotifyLocalized("ytaudioUnmuted")
		end

		-- Update volume immediately
		if IsValid(PLUGIN.ytBrowser) and PLUGIN.UpdateLocalVolume then
			PLUGIN:UpdateLocalVolume()
		end
	end
})
