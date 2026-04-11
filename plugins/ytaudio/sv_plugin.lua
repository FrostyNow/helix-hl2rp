local PLUGIN = PLUGIN

-- ---------------------------------------------------------------------------
-- Server-side playback state
-- ---------------------------------------------------------------------------

IX_YTAUDIO_STATE = IX_YTAUDIO_STATE or {
	videoId 	= nil,	-- current YouTube video ID
	title 		= "",	-- fetched via oEmbed
	startedAt 	= 0,	-- CurTime() at the moment playback began
	volume 		= 80,	-- 0-100
	playing 	= false,
	queue 		= {},	-- playback queue
}
IX_YTAUDIO_STATE.queue = IX_YTAUDIO_STATE.queue or {}
PLUGIN.ytState = IX_YTAUDIO_STATE

-- ---------------------------------------------------------------------------
-- Internal helpers
-- ---------------------------------------------------------------------------

local function NotifyAll(key, ...)
	local args = { ... }

	-- Always log to server console
	MsgC(Color(255, 0, 0), "[YTAudio] ", Color(255, 255, 255), key .. " (" .. table.concat(args, ", ") .. ")\n")

	if ix.config.Get("ytaudioShowNotifications", true) then
		for _, ply in ipairs(player.GetAll()) do
			ply:NotifyLocalized(key, unpack(args))
		end
	end
end

---
-- Send a play message to `recipient` (player) or everyone (nil).
-- offset: seconds already elapsed in the video at the moment of sending.
---
local function SendPlay(recipient, videoId, title, offset, volume)
	net.Start("ixYTAudioPlay")
		net.WriteString(videoId)
		net.WriteString(title)
		net.WriteFloat(offset)
		net.WriteUInt(volume, 8)
	if recipient then
		net.Send(recipient)
	else
		net.Broadcast()
	end
end

local function SendStop(recipient)
	net.Start("ixYTAudioStop")
	if recipient then
		net.Send(recipient)
	else
		net.Broadcast()
	end
end

local function SendSync(recipient, videoId, offset, volume)
	net.Start("ixYTAudioSync")
		net.WriteString(videoId)
		net.WriteFloat(offset)
		net.WriteUInt(volume, 8)
	if recipient then
		net.Send(recipient)
	else
		net.Broadcast()
	end
end

-- ---------------------------------------------------------------------------
-- Core playback functions
-- ---------------------------------------------------------------------------

---
-- Begin playback of a video for all connected players.
---
function PLUGIN:PlayVideo(videoId, title, volume)
	local state = self.ytState

	if state.playing then
		table.insert(state.queue, {
			videoId	= videoId,
			title	= title or "Unknown",
			volume	= volume
		})
		NotifyAll("ytaudioQueued", title or videoId)
		return
	end

	state.videoId	= videoId
	state.title		= title or "Unknown"
	state.startedAt	= CurTime()
	state.volume	= volume or ix.config.Get("ytaudioDefaultVolume", 80)
	state.playing	= true

	SendPlay(nil, state.videoId, state.title, 0, state.volume)
	NotifyAll("ytaudioStarted", state.title)
end

---
-- Stop playback for all players.
---
function PLUGIN:StopVideo()
	local state = self.ytState
	local wasPlaying = state.playing

	state.playing = false
	state.videoId = nil
	state.title   = ""
	state.queue   = {} -- Clear queue on stop

	SendStop(nil) -- Always broadcast stop to kill any orphans on clients
	if wasPlaying then
		NotifyAll("ytaudioStopped")
	end
end

---
-- Skip current video and play the next one in queue.
---
function PLUGIN:SkipVideo()
	local state = self.ytState
	if not state.playing then return end

	if #state.queue > 0 then
		local nextItem = table.remove(state.queue, 1)
		NotifyAll("ytaudioSkipped")
		
		-- Temporarily set playing to false so PlayVideo doesn't re-queue
		state.playing = false
		self:PlayVideo(nextItem.videoId, nextItem.title, nextItem.volume)
	else
		self:StopVideo()
	end
end

---
-- Re-sync a single player to the current position.
---
function PLUGIN:SyncPlayer(client)
	local state = self.ytState
	if not state.playing or not state.videoId then return end

	local offset = CurTime() - state.startedAt
	if offset < 0 then offset = 0 end

	-- Use SendPlay so the client recreates the browser at the right offset
	-- if it somehow lost it; otherwise it will seek.
	SendPlay(client, state.videoId, state.title, offset, state.volume)
end

---
-- Re-sync every connected player.
---
function PLUGIN:SyncAll()
	local state = self.ytState
	if not state.playing or not state.videoId then return end

	local offset = CurTime() - state.startedAt
	if offset < 0 then offset = 0 end

	SendSync(nil, state.videoId, offset, state.volume)
end

-- ---------------------------------------------------------------------------
-- Network Receivers
-- ---------------------------------------------------------------------------

net.Receive("ixYTAudioVideoEnded", function(len, ply)
	local plugin = ix.plugin.Get("ytaudio")
	if not plugin then return end

	-- Only skip if something is actually playing
	if not plugin.ytState.playing then return end

	-- Debounce: ignore reports for 2 seconds after a skip to allow sync to stabilize
	if (plugin.lastAutoSkip or 0) > CurTime() then return end
	plugin.lastAutoSkip = CurTime() + 2

	plugin:SkipVideo()
end)

-- ---------------------------------------------------------------------------
-- Hooks
-- ---------------------------------------------------------------------------

---
-- Sync player after 8 seconds once their character is loaded.
---
function PLUGIN:OnCharacterLoaded(client)
	timer.Simple(8, function()
		if IsValid(client) then
			self:SyncPlayer(client)
		end
	end)
end

---
-- Periodic background sync every 60 seconds for all players.
---
timer.Create("ixYTAudioPeriodicSync", 60, 0, function()
	local plugin = ix.plugin.Get("ytaudio")
	if plugin then
		plugin:SyncAll()
	end
end)
