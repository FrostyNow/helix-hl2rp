local PLUGIN = PLUGIN
PLUGIN.name = "Event Helper"
PLUGIN.author = "Frosty"
PLUGIN.description = "Provides few commands to proceed events."

ix.lang.AddTable("english", {
	cmdToggleBlackout = "Toggle global screen blackout for all players.",
	cmdEarthquake = "Cause an earthquake for all players.",
	blackoutEnabled = "Blackout has been enabled for all players.",
	blackoutDisabled = "Blackout has been disabled for all players.",
	blackoutUsage = "Usage: /ToggleBlackout [duration]",
	earthquakeStarted = "An earthquake has started!",
	earthquakeUsage = "Usage: /Earthquake <magnitude> <duration> [sound]",
	earthquakeTriggered = "Earthquake triggered (Magnitude: %s, Duration: %s)"
})

ix.lang.AddTable("korean", {
	cmdToggleBlackout = "모든 플레이어의 화면 암전 상태를 토글합니다.",
	cmdEarthquake = "모든 플레이어에게 지진 효과를 일으킵니다.",
	blackoutEnabled = "모든 플레이어의 화면이 암전되었습니다.",
	blackoutDisabled = "모든 플레이어의 화면 암전이 해제되었습니다.",
	blackoutUsage = "사용법: /ToggleBlackout [지속시간]",
	earthquakeStarted = "지진이 발생했습니다!",
	earthquakeUsage = "사용법: /Earthquake <강도> <지속시간> [사운드 여부]",
	earthquakeTriggered = "지진 발생 (강도: %s, 지속시간: %s초)"
})

local earthquakeSounds = {
	"ambient/levels/streetwar/building_rubble1.wav",
	"ambient/levels/streetwar/building_rubble2.wav",
	"ambient/levels/streetwar/building_rubble3.wav",
	"ambient/levels/streetwar/building_rubble4.wav",
	"ambient/levels/streetwar/building_rubble5.wav"
}

if (SERVER) then
	util.AddNetworkString("ixBlackoutSync")
	util.AddNetworkString("ixEarthquake")

	function PLUGIN:PlayerInitialSpawn(client)
		net.Start("ixBlackoutSync")
			net.WriteBool(self.bBlackout or false)
			net.WriteFloat(0)
		net.Send(client)
	end
	
	function PLUGIN:SetBlackout(bState, duration)
		self.bBlackout = bState
		duration = duration or 1
		
		net.Start("ixBlackoutSync")
			net.WriteBool(bState)
			net.WriteFloat(duration)
		net.Broadcast()
	end
end

if (CLIENT) then
	PLUGIN.blackoutAlpha = PLUGIN.blackoutAlpha or 0
	PLUGIN.blackoutTarget = PLUGIN.blackoutTarget or 0
	PLUGIN.blackoutStartAlpha = PLUGIN.blackoutStartAlpha or 0
	PLUGIN.blackoutStartTime = PLUGIN.blackoutStartTime or 0
	PLUGIN.blackoutDuration = PLUGIN.blackoutDuration or 0
	PLUGIN.earthquakeStart = PLUGIN.earthquakeStart or 0
	PLUGIN.earthquakeDuration = PLUGIN.earthquakeDuration or 0
	PLUGIN.earthquakeMagnitude = PLUGIN.earthquakeMagnitude or 0
	PLUGIN.matDust = Material("particle/smokesprites_0008")

	net.Receive("ixBlackoutSync", function()
		local bState = net.ReadBool()
		local duration = net.ReadFloat()

		PLUGIN.blackoutTarget = bState and 255 or 0
		PLUGIN.blackoutDuration = duration
		PLUGIN.blackoutStartTime = RealTime()
		PLUGIN.blackoutStartAlpha = PLUGIN.blackoutAlpha
	end)

	net.Receive("ixEarthquake", function()
		local magnitude = net.ReadFloat()
		local duration = net.ReadFloat()
		local bSound = net.ReadBool()

		PLUGIN.earthquakeStart = CurTime()
		PLUGIN.earthquakeDuration = duration
		PLUGIN.earthquakeMagnitude = magnitude

		util.ScreenShake(LocalPlayer():GetPos(), magnitude, 5, duration, 5000)

		-- Earthquake Dust Particles
		local timerID = "ixEarthquakeDust"
		local delay = 0.2
		local iterations = math.floor(duration / delay)

		timer.Create(timerID, delay, iterations, function()
			if (!IsValid(LocalPlayer()) or !LocalPlayer():Alive()) then return end

			-- Engine Native Dust Puffs (env_dustpuff equivalent)
			local ed = EffectData()
			ed:SetOrigin(LocalPlayer():GetPos() + Vector(math.random(-300, 300), math.random(-300, 300), math.random(50, 150)))
			ed:SetScale(math.Rand(0.5, 1.5) * (magnitude / 30))
			util.Effect("Dust", ed)

			-- Heavy Impact if high magnitude
			if (magnitude > 40 and math.random() > 0.7) then
				local ed2 = EffectData()
				ed2:SetOrigin(LocalPlayer():GetPos() + VectorRand() * 100)
				ed2:SetMagnitude(magnitude / 50)
				util.Effect("ThumperDust", ed2)
			end

			local emitter = ParticleEmitter(LocalPlayer():GetPos())
			if (emitter) then
				local count = math.Clamp(math.floor(magnitude / 15), 1, 8)

				for i = 1, count do
					-- Random Dust & Debris
					local isDebris = math.random() > 0.8
					local pos = LocalPlayer():EyePos() + LocalPlayer():GetForward() * math.random(10, 200) + LocalPlayer():GetRight() * math.random(-150, 150) + LocalPlayer():GetUp() * math.random(-100, 100)
					local mat = isDebris and "particle/particle_composite" or ("particle/smokesprites_000" .. math.random(1, 9))
					local p = emitter:Add(mat, pos)
					
					if (p) then
						p:SetVelocity(LocalPlayer():GetVelocity() * 0.8 + VectorRand() * 15 - Vector(0, 0, 15))
						p:SetDieTime(math.Rand(2, 4))
						p:SetStartAlpha(isDebris and 255 or math.random(30, 70))
						p:SetEndAlpha(0)
						p:SetStartSize(isDebris and math.random(1, 3) or math.random(20, 60))
						p:SetEndSize(isDebris and math.random(1, 3) or math.random(80, 160))
						p:SetRoll(math.random(0, 360))
						p:SetRollDelta(math.Rand(-1, 1))
						p:SetColor(isDebris and 60 or 110, isDebris and 55 or 100, isDebris and 50 or 85)
						p:SetAirResistance(100)
						p:SetGravity(Vector(0, 0, -20))
						p:SetBounce(0.3)
						p:SetCollide(true)
					end
				end
				emitter:Finish()
			end
		end)

		if (bSound) then
			LocalPlayer():EmitSound("ambient/atmosphere/city_rumble1.wav", 140, 100, 1)

			local timerID = "ixEarthquakeSound"
			local maxCount = math.max(1, math.floor(duration / 3))

			timer.Create(timerID, 1.5, maxCount, function()
				if (!LocalPlayer():Alive()) then return end
				LocalPlayer():EmitSound(table.Random(earthquakeSounds), 130, math.random(80, 110), 1)
			end)
		end
	end)

	function PLUGIN:RenderScreenspaceEffects()
		local curTime = CurTime()
		if (self.earthquakeStart > 0 and curTime < self.earthquakeStart + self.earthquakeDuration) then
			local elapsed = curTime - self.earthquakeStart
			local duration = self.earthquakeDuration
			local magnitude = self.earthquakeMagnitude or 10
			
			-- Calculate peak alpha (bell curve)
			local fraction = math.sin(math.Clamp(elapsed / duration, 0, 1) * math.pi)
			local strength = (magnitude / 100) * fraction

			-- Motion Blur Effect
			if (strength > 0.05) then
				DrawMotionBlur(0.1, strength * 0.9, 0.03)
			end

			-- Hazy Dust Bloom
			if (strength > 0.2) then
				DrawBloom(0.2 * strength, 2 * strength, 5, 5, 1, 1, 0.4, 0.4, 0.35)
			end

			DrawColorModify({
				["$pp_colour_addr"] = 0.08 * strength, -- Slightly more reddish/brown
				["$pp_colour_addg"] = 0.04 * strength,
				["$pp_colour_addb"] = 0.01 * strength,
				["$pp_colour_brightness"] = -0.06 * strength,
				["$pp_colour_contrast"] = 1 + (0.1 * strength),
				["$pp_colour_colour"] = 1 - (0.5 * strength), -- Desaturate
				["$pp_colour_mulr"] = 0,
				["$pp_colour_mulg"] = 0,
				["$pp_colour_mulb"] = 0
			})
		end
	end

	function PLUGIN:HUDPaint()
		if (self.blackoutAlpha > 0 or self.blackoutTarget > 0) then
			local fraction = 1
			
			if (self.blackoutDuration > 0) then
				fraction = math.Clamp((RealTime() - self.blackoutStartTime) / self.blackoutDuration, 0, 1)
			end

			self.blackoutAlpha = Lerp(fraction, self.blackoutStartAlpha, self.blackoutTarget)

			if (self.blackoutAlpha > 0) then
				surface.SetDrawColor(0, 0, 0, self.blackoutAlpha)
				surface.DrawRect(0, 0, ScrW(), ScrH())
			end
		end

		-- Earthquake Dust Overlay (Dynamic Atmospheric Effect)
		local curTime = CurTime()
		if (self.earthquakeStart > 0 and curTime < self.earthquakeStart + self.earthquakeDuration) then
			local elapsed = curTime - self.earthquakeStart
			local duration = self.earthquakeDuration
			local magnitude = self.earthquakeMagnitude or 10

			local fraction = math.sin(math.Clamp(elapsed / duration, 0, 1) * math.pi)
			local alpha = (magnitude / 100) * 120 * fraction
			
			if (alpha > 0) then
				local w, h = ScrW(), ScrH()
				local mat = self.matDust:IsError() and Material("particle/particle_composite") or self.matDust
				surface.SetMaterial(mat)

				-- Multi-layered Atmospheric Dust
				for i = 1, 3 do
					local seed = i * 123.456
					local scale = 1.2 + math.sin(curTime * 0.2 + seed) * 0.1
					local rotate = (curTime * (5 + i)) % 360
					local dx = math.sin(curTime * 0.1 + seed) * 50
					local dy = math.cos(curTime * 0.15 + seed) * 50
					
					surface.SetDrawColor(120, 110, 90, alpha * (0.6 / i))
					surface.DrawTexturedRectRotated(w / 2 + dx, h / 2 + dy, w * scale, h * scale, rotate)
				end

				-- Base Atmospheric Tint
				surface.SetDrawColor(80, 75, 60, alpha * 0.25)
				surface.DrawRect(0, 0, w, h)

				-- Subtle Vignette focus
				local vignette = Material("vgui/vignette_w")
				if (!vignette:IsError()) then
					surface.SetMaterial(vignette)
					surface.SetDrawColor(0, 0, 0, alpha * 0.8)
					surface.DrawTexturedRect(0, 0, w, h)
				end
			end
		end
	end
end

ix.command.Add("ToggleBlackout", {
	description = "@cmdToggleBlackout",
	arguments = {
		bit.bor(ix.type.number, ix.type.optional)
	},
	superAdminOnly = true,
	OnRun = function(self, client, duration)
		local bNewState = !PLUGIN.bBlackout
		duration = duration or 2
		
		PLUGIN:SetBlackout(bNewState, duration)

		if (bNewState) then
			ix.util.NotifyLocalized("blackoutEnabled", nil)
		else
			ix.util.NotifyLocalized("blackoutDisabled", nil)
		end
	end
})

ix.command.Add("Earthquake", {
	description = "@cmdEarthquake",
	arguments = {
		ix.type.number, -- Magnitude
		ix.type.number, -- Duration
		bit.bor(ix.type.bool, ix.type.optional) -- bSound
	},
	superAdminOnly = true,
	OnRun = function(self, client, magnitude, duration, bSound)
		magnitude = math.Clamp(magnitude, 1, 50)
		duration = math.Clamp(duration, 1, 60)
		bSound = (bSound == nil) and true or bSound

		net.Start("ixEarthquake")
			net.WriteFloat(magnitude)
			net.WriteFloat(duration)
			net.WriteBool(bSound)
		net.Broadcast()

		-- Server-side Physics Shaking (Rattle props near players)
		local timerID = "ixEarthquakePhysics_" .. CurTime()
		local delay = 0.1
		local iterations = math.floor(duration / delay)
		local radiusSqr = 1200 * 1200 -- Approx 30 meters

		timer.Create(timerID, delay, iterations, function()
			local strength = (magnitude / 100) * 15
			local players = player.GetAll()
			local targets = {}
			
			-- Collect potential physics entities
			table.Add(targets, ents.FindByClass("prop_physics"))
			table.Add(targets, ents.FindByClass("prop_physics_multiplayer"))
			table.Add(targets, ents.FindByClass("prop_physics_respawnable"))
			table.Add(targets, ents.FindByClass("prop_ragdoll"))
			table.Add(targets, ents.FindByClass("ix_item"))
			table.Add(targets, ents.FindByClass("ix_money"))
			table.Add(targets, ents.FindByClass("ix_container"))
			
			for _, v in ipairs(targets) do
				if (IsValid(v)) then
					local phys = v:GetPhysicsObject()
					-- Condition: Valid physics, not frozen
					if (IsValid(phys) and phys:IsMotionEnabled()) then
						local bNearby = false
						local pos = v:GetPos()

						-- Distance Check: Only affect entities near ANY player (optimizes performance)
						for i = 1, #players do
							local ply = players[i]
							if (IsValid(ply) and pos:DistToSqr(ply:GetPos()) <= radiusSqr) then
								bNearby = true
								break
							end
						end

						if (bNearby) then
							phys:Wake() -- Specifically wake up objects near players
							
							-- Random jitter force relative to mass (multiplied for better impact)
							local jitter = VectorRand() * (phys:GetMass() * strength * 2)
							jitter.z = math.abs(jitter.z) * 0.8 -- More vertical bounce
							
							phys:ApplyForceOffset(jitter, v:GetPos() + VectorRand() * 5)
							phys:AddAngleVelocity(VectorRand() * (strength * 2.5))
						end
					end
				end
			end
		end)

		ix.util.NotifyLocalized("earthquakeStarted", nil)
		return client:NotifyLocalized("earthquakeTriggered", magnitude, duration)
	end
})
