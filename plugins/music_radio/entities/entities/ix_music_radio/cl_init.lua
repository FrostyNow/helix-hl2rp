include("shared.lua")
local PLUGIN = PLUGIN

local GLOW_MATERIAL = Material("sprites/glow04_noz")
local COLOR_ACTIVE = Color(0, 255, 0)
local COLOR_INACTIVE = Color(255, 0, 0)

function ENT:Draw()
	self:DrawModel()

	local position = self:GetPos() + self:GetForward() * 10 + self:GetUp() * 11 + self:GetRight() * 9.5

	render.SetMaterial(GLOW_MATERIAL)
	render.DrawSprite(position, 14, 14, self:GetNetVar("power") and COLOR_ACTIVE or COLOR_INACTIVE)
end


function ENT:Think()
	local power = self:GetNetVar("power")
	local currentFreq = self:GetNetVar("channel", 88.0)
	
	if (power and not self.started) then
		self:StartStream()
	elseif (not power and self.started) then
		self:StopStream()
	end

	if (self.started) then
		local bestDist = 1000
		local bestCh = nil
		for _, k in pairs(PLUGIN.channels) do
			local d = math.abs(k.freq - currentFreq)
			if d < bestDist then
				bestDist = d
				bestCh = k
			end
		end

		-- Check if we should switch stream URL
		if (bestCh and self.lastFreq != bestCh.freq) then
			self.lastFreq = bestCh.freq
			self:StopStream()
			self:StartStream()
		end

		if (self.channel and self.channel:IsValid()) then
			local threshold = 0.5
			local signalLevel = 1 - math.Clamp(bestDist / threshold, 0, 1)
			local targetVol = (self:GetNetVar("volume", 100) / 100) * signalLevel
			
			-- Jitter the audio when signal is weak but present
			if signalLevel < 1.0 and signalLevel > 0 then
				targetVol = targetVol * math.Rand(0.6, 1.0)
				if math.random(1, 100) > 90 then
				   self.channel:SetPlaybackRate(math.Rand(0.9, 1.1))
				else
				   self.channel:SetPlaybackRate(1)
				end
			else
				self.channel:SetPlaybackRate(1)
			end
			
			self.channel:SetVolume(targetVol)
			self.channel:SetPos(self:GetPos())
		end

		-- Play continuous physical static when not exactly on channel
		if bestDist > 0.05 then
			self.staticDuration = self.staticDuration or (SoundDuration("ambient/levels/prison/radio_random1.wav") > 0 and SoundDuration("ambient/levels/prison/radio_random1.wav") or 9.4)

			if (not self.staticLoop) then
				self.staticLoop = CreateSound(self, "ambient/levels/prison/radio_random1.wav")
				self.staticLoop:Play()
				self.staticLoop:ChangeVolume(0.1)
				self.nextStaticLoop = CurTime() + self.staticDuration - 0.1
			elseif (self.nextStaticLoop and CurTime() >= self.nextStaticLoop) then
				self.staticLoop:Stop()
				self.staticLoop:Play()
				self.staticLoop:ChangeVolume(0.1)
				self.nextStaticLoop = CurTime() + self.staticDuration - 0.1
			end
			
			local staticVol = math.Clamp(bestDist / 0.5, 0.1, 1) * (self:GetNetVar("volume", 100) / 100)
			self.staticLoop:ChangeVolume(staticVol, 0.1)
		else
			if (self.staticLoop) then
				self.staticLoop:Stop()
				self.staticLoop = nil
			end
		end
	end
end

function ENT:StartStream()
	local currentFreq = self:GetNetVar("channel", 88.0)
	
	local bestDist = 1000
	local bestCh = nil
	for _, k in pairs(PLUGIN.channels) do
		local d = math.abs(k.freq - currentFreq)
		if d < bestDist then
			bestDist = d
			bestCh = k
		end
	end

	local expectedFreq = bestCh and bestCh.freq or 88.0
	self.lastFreq = expectedFreq
	local url = bestCh and bestCh.url or ix.config.Get("radioUrl")

	sound.PlayURL( url, "3d", function(channel)
		if ( channel and IsValid(self) ) then
			if (self.lastFreq != expectedFreq or not self.started) then
				channel:Stop()
				return
			end
			if (self.channel and self.channel:IsValid()) then
				self.channel:Stop()
			end

			self.channel = channel
			channel:SetPos( self:GetPos() )
			channel:Set3DFadeDistance(ix.config.Get("radioDist") * 0.5, ix.config.Get("radioDist"))
			channel:Play()
		elseif (channel) then
			channel:Stop()
		end
	end)

	self.started = true
end

function ENT:StopStream()
	if ( self.channel and self.channel:IsValid() ) then
		self.channel:Stop()
	end
	if (self.staticLoop) then
		self.staticLoop:Stop()
		self.staticLoop = nil
	end

	self.started = false
end

function ENT:OnRemove()
	self:StopStream()
	table.RemoveByValue(PLUGIN.activeRadios, self)
end

function ENT:OnPopulateEntityInfo(container)
	local name = container:AddRow("name")
	name:SetImportant()
	name:SetText(L("Music Radio"))
	name:SizeToContents()

	local desc = container:AddRow("desc")
	desc:SetText(L("musicRadioDesc"))
	desc:SizeToContents()

	local status = container:AddRow("status")
	status:SetText(self:GetNetVar("power") and L("radioOn") or L("radioOff"))
	status:SetBackgroundColor(self:GetNetVar("power") and Color(0, 255, 0, 50) or Color(255, 0, 0, 50))
	status:SizeToContents()
	
	status.Think = function(panel)
		local isActive = self:GetNetVar("power")
		panel:SetText(isActive and L("radioOn") or L("radioOff"))
		panel:SetBackgroundColor(isActive and Color(0, 255, 0, 50) or Color(255, 0, 0, 50))
		panel:SizeToContents()
	end
end