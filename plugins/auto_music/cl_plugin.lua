local PLUGIN = PLUGIN

function PLUGIN:Think()
	if not MediaPlayer then return end
	
	local mp = MediaPlayer.GetById("auto_music")
	if not mp then return end

	if not mp._musicPatched then
		local oldThink = mp.Think
		
		mp.Think = function(this)
			-- Base think logic
			if oldThink then
				oldThink(this)
			end
			
			local media = this:GetMedia()
			if not IsValid(media) then return end
			
			-- Use Garry's Mod native music volume setting
			local musicVolumeCvar = GetConVar("snd_musicvolume")
			local targetVol = musicVolumeCvar and musicVolumeCvar:GetFloat() or 0.5
			
			local mediaCurTime = media:CurrentTime()
			local mediaDur = media:Duration() or 0
			
			-- 4-second fade in/out interpolations
			if media:IsTimed() then
				if mediaCurTime < 4 then
					targetVol = targetVol * (math.max(0, mediaCurTime) / 4)
				elseif mediaDur > 0 and (mediaDur - mediaCurTime) < 4 then
					targetVol = targetVol * (math.max(0, mediaDur - mediaCurTime) / 4)
				end
			end
			
			this._curLocalVol = math.Approach(this._curLocalVol or 0, targetVol, FrameTime() * 0.5)
			
			-- Apply to actual media volume, overriding base functionality
			if this._cachedVolume ~= this._curLocalVol then
				media:Volume(this._curLocalVol)
				this._cachedVolume = this._curLocalVol
			end
		end
		
		mp._musicPatched = true
	end
end

function PLUGIN:HUDPaint()
	if not MediaPlayer then return end
	local mp = MediaPlayer.GetById("auto_music")
	if not mp then return end
	
	local media = mp:GetMedia()
	if not IsValid(media) then return end
	
	-- Native GM music volume logic
	local musicVolumeCvar = GetConVar("snd_musicvolume")
	local nativeVol = musicVolumeCvar and musicVolumeCvar:GetFloat() or 1
	
	if nativeVol <= 0.01 then return end
	
	local vol = mp._curLocalVol or 0
	if vol <= 0.01 then return end
	
	local title = media:Title() or "Loading Track..."
	local text = "Music: " .. title
	
	surface.SetFont("ixMediumFont")
	local tw, th = surface.GetTextSize(text)
	
	-- Top right position, slightly padded
	local x, y = ScrW() - tw - 20, 20
	
	-- Determine alpha multiplier to fade rapidly when close to 0
	local alpha = math.Clamp(vol * 255 * 3, 0, 255)
	
	draw.SimpleTextOutlined(text, "ixMediumFont", x, y, Color(255, 255, 255, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, Color(0, 0, 0, alpha))
end
