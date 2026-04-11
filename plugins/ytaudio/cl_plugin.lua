local PLUGIN = PLUGIN

-- ---------------------------------------------------------------------------
-- Client-side state
-- ---------------------------------------------------------------------------

-- Force cleanup of any orphaned browsers from previous sessions or reloads
for _, v in ipairs(vgui.GetWorldPanel():GetChildren()) do
	if v.ixYTAudio then
		v:Remove()
	end
end

PLUGIN.ytBrowser    = nil   -- hidden DHTML panel
PLUGIN.ytTitle      = nil   -- currently displayed title (nil = nothing playing)
PLUGIN.ytVideoId    = nil   -- for browser recreation on sync
PLUGIN.ytLocalStart = nil   -- CurTime() - offset at receive time; used for drift calc
PLUGIN.ytVolume     = 80    -- 0-100
PLUGIN.ytMuted      = (PLUGIN.ytMuted != nil) and PLUGIN.ytMuted or false

-- ---------------------------------------------------------------------------
-- JavaScript snippets
-- ---------------------------------------------------------------------------

local JS_SetVolumeAndPlay = [[
	if (window.MediaPlayer) {
		window.MediaPlayer.volume = %s;
		window.MediaPlayer.play();
	}
]]

local JS_SetVolume = [[
	if (window.MediaPlayer) {
		window.MediaPlayer.volume = %s;
	}
]]

-- Only seek if drift is larger than the threshold (seconds).
-- This avoids jarring seeks for minor clock differences.
local JS_SoftSeek = [[
	if (window.MediaPlayer) {
		var target  = %s;
		var current = window.MediaPlayer.currentTime;
		if (Math.abs(current - target) > 3) {
			window.MediaPlayer.currentTime = target;
		}
	}
]]

-- ---------------------------------------------------------------------------
-- Browser management
-- ---------------------------------------------------------------------------

function PLUGIN:UpdateLocalVolume()
	if not IsValid(self.ytBrowser) then return end

	-- masterVol: determined by admin via /ytvolume (server-side ytVolume)
	-- localOpt: individual player preference via F1 options
	local masterVol = self.ytVolume or 100
	local localOpt  = ix.option.Get("ytaudioVolume", 80)

	local finalVol = (masterVol / 100) * (localOpt / 100)
	if self.ytMuted then finalVol = 0 end

	self.ytBrowser:RunJavascript(JS_SetVolume:format(finalVol))
end

local function DestroyBrowser()
	if IsValid(PLUGIN.ytBrowser) then
		PLUGIN.ytBrowser:Remove()
		PLUGIN.ytBrowser = nil
	end
end

local function OpenBrowser(videoId, offset, volume)
	DestroyBrowser()

	local baseURL = ix.config.Get("ytaudioPlayerURL",
		"https://mediaplayer.purrcoding.com/youtube.html")

	-- Hash fragment: #v=VIDEO_ID&t=SECONDS
	-- youtube.html reads these to initialise the IFrame player.
	local url = string.format("%s#v=%s&t=%d", baseURL, videoId, math.max(0, math.floor(offset)))

	local panel = vgui.Create("DHTML")
	panel.ixYTAudio = true -- Identification tag for cleanup on reload
	panel:SetSize(16, 16)
	panel:SetPos(-200, -200)   -- completely off-screen
	panel:SetAlpha(0)
	panel:SetMouseInputEnabled(false)
	panel:SetKeyboardInputEnabled(false)

	-- Capture the volume at creation time for the closure below.
	local vol01 = math.Clamp(volume, 0, 100) / 100

	function panel:ConsoleMessage(msg)
		-- youtube.html fires "READY:" once the IFrame player is initialised.
		-- We start playback at volume 0 and fade in over 2 seconds.
		if string.StartWith(msg, "READY:") then
			panel:RunJavascript(JS_SetVolumeAndPlay:format(0))

			local duration = 2
			local steps = 40
			local interval = duration / steps
			local currentStep = 0

			timer.Create("ixYTAudioFade" .. tostring(panel), interval, steps, function()
				if not IsValid(panel) then return end
				currentStep = currentStep + 1
				
				local fract = currentStep / steps
				local localOpt = ix.option.Get("ytaudioVolume", 80)
				local vol = fract * (vol01 * (localOpt / 100))
				
				if PLUGIN.ytMuted then vol = 0 end
				panel:RunJavascript(JS_SetVolume:format(vol))
			end)
		end
	end

	panel:OpenURL(url)

	PLUGIN.ytBrowser    = panel
	PLUGIN.ytVideoId    = videoId
	PLUGIN.ytLocalStart = CurTime() - math.max(0, offset)
	PLUGIN.ytVolume     = volume
end

-- ---------------------------------------------------------------------------
-- Net receivers  (server → client)
-- ---------------------------------------------------------------------------

--
-- ixYTAudioPlay
-- Payload: videoId(str), title(str), offset(float s), volume(uint8 0-100)
-- Sent when a new video starts OR when a newly-joined player needs the state.
--
net.Receive("ixYTAudioPlay", function()
	local videoId = net.ReadString()
	local title   = net.ReadString()
	local offset  = net.ReadFloat()
	local volume  = net.ReadUInt(8)

	PLUGIN.ytTitle  = (title != "" and title) or ("Video: " .. videoId)
	PLUGIN.ytVolume = volume

	OpenBrowser(videoId, offset, volume)
end)

--
-- ixYTAudioStop
-- No payload. Tears down the browser and clears the HUD.
--
net.Receive("ixYTAudioStop", function()
	PLUGIN.ytTitle      = nil
	PLUGIN.ytVideoId    = nil
	PLUGIN.ytLocalStart = nil

	if IsValid(PLUGIN.ytBrowser) then
		local panel = PLUGIN.ytBrowser
		local duration = 2
		local steps = 40
		local interval = duration / steps
		local currentStep = 0

		-- Stop any existing fade-in timer
		timer.Remove("ixYTAudioFade" .. tostring(panel))

		-- Determine start volume fract (0-1)
		local baseVol = PLUGIN.ytVolume or 100
		local localOpt  = ix.option.Get("ytaudioVolume", 80)
		local startVol01 = (baseVol / 100) * (localOpt / 100)
		if PLUGIN.ytMuted then startVol01 = 0 end

		timer.Create("ixYTAudioFadeOut" .. tostring(panel), interval, steps, function()
			if not IsValid(panel) then return end
			currentStep = currentStep + 1

			local fract = 1 - (currentStep / steps)
			panel:RunJavascript(JS_SetVolume:format(startVol01 * fract))

			if currentStep >= steps then
				panel:Remove()
				if PLUGIN.ytBrowser == panel then
					PLUGIN.ytBrowser = nil
				end
			end
		end)
	end
end)

--
-- ixYTAudioVolume
-- Payload: volume(uint8 0-100)
-- Volume-only update; does NOT restart the browser.
--
net.Receive("ixYTAudioVolume", function()
	local volume = net.ReadUInt(8)
	PLUGIN.ytVolume = volume

	PLUGIN:UpdateLocalVolume()
end)

--
-- ixYTAudioSync
-- Payload: videoId(str), offset(float s), volume(uint8 0-100)
-- Periodic drift-correction. Seeks in-place when possible; recreates the
-- browser only if it has been lost.
--
net.Receive("ixYTAudioSync", function()
	local videoId = net.ReadString()
	local offset  = net.ReadFloat()
	local volume  = net.ReadUInt(8)

	PLUGIN.ytVolume = volume

	if IsValid(PLUGIN.ytBrowser) then
		-- Prefer a soft JS seek to avoid reloading the whole page.
		PLUGIN.ytBrowser:RunJavascript(JS_SoftSeek:format(offset))
		
		PLUGIN:UpdateLocalVolume()
		
		PLUGIN.ytLocalStart = CurTime() - math.max(0, offset)
	else
		-- Browser was lost (e.g. panel was garbage-collected); recreate it.
		if PLUGIN.ytTitle then
			OpenBrowser(videoId, offset, volume)
		end
	end
end)

-- ---------------------------------------------------------------------------
-- HUD
-- ---------------------------------------------------------------------------

surface.CreateFont("ixYTAudioFont", {
	font = "NanumBarunGothic" or "Malgun Gothic" or "SegoeUI" or "Roboto",
	size = 14,
	weight = 400,
	antialias = true,
	extended = true,
})

local COLOR_WHITE  = Color(255, 255, 255, 128)
local COLOR_SHADOW = Color(0,   0,   0,   80)
local HUD_FONT     = "ixYTAudioFont"
local HUD_PAD      = 16

hook.Add("HUDPaint", "ixYTAudioHUD", function()
	if not PLUGIN.ytTitle then return end
	if not IsValid(LocalPlayer()) then return end

	local text = "♪  " .. PLUGIN.ytTitle

	surface.SetFont(HUD_FONT)
	local tw, th = surface.GetTextSize(text)

	-- Bottom-right corner, clear of the chat area.
	local sx = ScrW() - tw - HUD_PAD
	local sy = ScrH() - th - HUD_PAD

	-- Subtle drop-shadow for legibility against any background.
	surface.SetTextColor(COLOR_SHADOW)
	surface.SetTextPos(sx + 1, sy + 1)
	surface.DrawText(text)

	surface.SetTextColor(COLOR_WHITE)
	surface.SetTextPos(sx, sy)
	surface.DrawText(text)
end)

-- ---------------------------------------------------------------------------
-- Cleanup on map unload / plugin reload
-- ---------------------------------------------------------------------------

hook.Add("ShutDown", "ixYTAudioCleanup", function()
	DestroyBrowser()
end)
