local PLUGIN = PLUGIN

PLUGIN.name = "Ambient Sounds"
PLUGIN.author = "Black Tea | Heavily modified and ported by Frosty"
PLUGIN.desc = "Ambient Sounds"

ix.config.Add("enableAmbientSounds", true, "Whether or not to enable ambient sounds.", nil, {
	category = "Ambient Sounds"
})
ix.config.Add("enableAmbientWind", false, "Enable outdoor wind ambient sound.", nil, {
	category = "Ambient Sounds"
})
ix.config.Add("enableAmbientInternal", false, "Enable indoor atmosphere ambient sound.", nil, {
	category = "Ambient Sounds"
})
ix.config.Add("enableAmbientGunshot", false, "Enable distant gunshot ambient sound.", nil, {
	category = "Ambient Sounds"
})
ix.config.Add("enableAmbientMarch", false, "Enable distant marching ambient sound.", nil, {
	category = "Ambient Sounds"
})
ix.config.Add("volumeAmbientGunshot", 1.0, "Volume for distant gunshot ambient sound (0-1).", nil, {
	category = "Ambient Sounds"
})
ix.config.Add("volumeAmbientMarch", 1.0, "Volume for distant marching ambient sound (0-1).", nil, {
	category = "Ambient Sounds"
})
ix.config.Add("volumeAmbientWind", 0.5, "Volume for outdoor wind ambient sound (0-1).", nil, {
	category = "Ambient Sounds"
})
ix.config.Add("volumeAmbientInternal", 1.0, "Volume for indoor atmosphere ambient sound (0-1).", nil, {
	category = "Ambient Sounds"
})

if CLIENT then

	PLUGIN.timeData = {}
	PLUGIN.sndWind = nil
	PLUGIN.sndInternal = nil

	local OPEN_DIRS = { Vector(1,0,0), Vector(-1,0,0), Vector(0,1,0), Vector(0,-1,0) }
	local traceData      = { start = Vector(), endpos = Vector(), filter = nil }
	local openTraceData  = { start = Vector(), endpos = Vector(), filter = nil }

	local function checkOpenness(pos, filter)
		local openCount = 0
		openTraceData.filter = filter
		for _, dir in ipairs(OPEN_DIRS) do
			openTraceData.start  = pos
			openTraceData.endpos = pos + dir * 1500
			if util.TraceLine(openTraceData).Fraction > 0.8 then
				openCount = openCount + 1
			end
		end
		return openCount >= 3
	end

	local function checkDoorCount(pos, minCount)
		local count = 0
		for _, ent in ipairs(ents.FindInSphere(pos, 3000)) do
			local class = ent:GetClass()
			if class == "prop_door_rotating" or class == "func_door" or class == "func_door_rotating" then
				count = count + 1
				if count >= minCount then return true end
			end
		end
		return false
	end

	function PLUGIN:Think()
		local cfg = ix.config.Get

		if !cfg("enableAmbientSounds") then
			if IsValid(self.sndWind)     and self.sndWind:IsPlaying()     then self.sndWind:Stop() end
			if IsValid(self.sndInternal) and self.sndInternal:IsPlaying() then self.sndInternal:Stop() end
			self.lastWindState     = nil
			self.lastInternalState = nil
			return
		end

		local ply = LocalPlayer()
		if !IsValid(ply) then return end

		PLUGIN.sndWind = PLUGIN.sndWind or CreateSound(ply, "vehicles/fast_windloop1.wav")
		PLUGIN.sndInternal = PLUGIN.sndInternal or CreateSound(ply, "ambient/atmosphere/town_ambience.wav")

		local now = CurTime()

		-- Distant gunshot ambience, plays on a random interval while enabled
		if cfg("enableAmbientGunshot") then
			if !self.timeData.sndGunshot or self.timeData.sndGunshot < now then
				local dir = VectorRand():GetNormalized()
				dir.z = 0
				local origin = ply:GetPos() + dir * math.random(3000, 6000) + Vector(0, 0, math.random(800, 1500))
				sound.Play(
					Format("ambient/levels/streetwar/city_battle%d.wav", math.random(1, 19)),
					origin, 150, 100, cfg("volumeAmbientGunshot")
				)
				self.timeData.sndGunshot = now + math.random(10, 120)
			end
		end

		-- Distant marching ambience, plays on a random interval while enabled
		if cfg("enableAmbientMarch") then
			if !self.timeData.sndMarch or self.timeData.sndMarch < now then
				local dir = VectorRand():GetNormalized()
				dir.z = 0
				local origin = ply:GetPos() + dir * math.random(3000, 6000) + Vector(0, 0, math.random(800, 1500))
				sound.Play(
					Format("ambient/levels/streetwar/marching_distant%d.wav", math.random(1, 2)),
					origin, 150, 100, cfg("volumeAmbientMarch")
				)
				self.timeData.sndMarch = now + math.random(30, 440)
			end
		end

		local windEnabled     = cfg("enableAmbientWind")
		local internalEnabled = cfg("enableAmbientInternal")

		if windEnabled or internalEnabled then
			-- Sky and openness check, runs every 0.5s
			if !self.timeData.skyTrace or self.timeData.skyTrace < now then
				local pos = ply:GetShootPos()
				traceData.start  = pos
				traceData.endpos = pos + Vector(0, 0, 10000)
				traceData.filter = ply
				self.cachedHitSky = util.TraceLine(traceData).HitSky
				self.cachedIsOpen = self.cachedHitSky and checkOpenness(pos, ply) or false
				self.timeData.skyTrace = now + 0.5
			end

			-- Door count check, runs every 2s only when indoors and internal is enabled
			if internalEnabled then
				if !self.timeData.doorTrace or self.timeData.doorTrace < now then
					self.cachedHasDoors = (self.cachedHitSky == false) and checkDoorCount(ply:GetPos(), 3) or false
					self.timeData.doorTrace = now + 2
				end
			else
				self.cachedHasDoors = false
			end

			local windShouldPlay     = windEnabled     and self.cachedHitSky          and self.cachedIsOpen
			local internalShouldPlay = internalEnabled and (self.cachedHitSky == false) and self.cachedHasDoors

			if windShouldPlay != self.lastWindState or internalShouldPlay != self.lastInternalState then
				if windShouldPlay then
					if !self.sndWind:IsPlaying() then self.sndWind:Play() end
					self.sndWind:ChangeVolume(cfg("volumeAmbientWind"), 4)
				else
					self.sndWind:ChangeVolume(0, 4)
				end

				if internalShouldPlay then
					if !self.sndInternal:IsPlaying() then self.sndInternal:Play() end
					self.sndInternal:ChangeVolume(cfg("volumeAmbientInternal"), 4)
				else
					self.sndInternal:ChangeVolume(0, 4)
				end

				self.lastWindState     = windShouldPlay
				self.lastInternalState = internalShouldPlay
			end
		else
			if IsValid(self.sndWind)     and self.sndWind:IsPlaying()     then self.sndWind:Stop() end
			if IsValid(self.sndInternal) and self.sndInternal:IsPlaying() then self.sndInternal:Stop() end
			self.lastWindState     = nil
			self.lastInternalState = nil
		end
	end

end
