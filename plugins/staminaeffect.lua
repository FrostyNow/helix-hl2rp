PLUGIN.name = "Stamina Effect"
PLUGIN.description = "Creates a Effect for when you are about and when you are out of Stamina."
PLUGIN.author = "Riggs Mackay | Modified by Frosty"
PLUGIN.schema = "Any"
PLUGIN.license = [[
Copyright 2022 Riggs Mackay

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

function PLUGIN:PlayerTick(ply)
	if not ply.NextStaminaBreathe or ply.NextStaminaBreathe <= CurTime() then
		local stamina = ply:GetLocalVar("stm", 100)
		if ( stamina <= 10 ) then
			local pitch = 100
			local dsp = 0

			if (ply:IsFemale()) then
				pitch = 110
			end

			if (Schema:CanPlayerSeeCombineOverlay(ply) or ply:GetNetVar("gasmask")) then
				dsp = 14
			end

			-- Emit breathing sound from the server so others can hear it
			if (SERVER) then
				if (!ply.ixBreatheSoundServer) then
					ply.ixBreatheSoundServer = CreateSound(ply, "player/breathe1.wav")
				end

				ply.ixBreatheSoundServer:Stop()
				ply.ixBreatheSoundServer:PlayEx(0.6, pitch)
				ply.ixBreatheSoundServer:SetDSP(dsp)
			end

			-- Local effects for the player themselves
			if (CLIENT and ply == LocalPlayer()) then
				if (!ply.ixBreatheSoundClient) then
					ply.ixBreatheSoundClient = CreateSound(ply, "player/breathe1.wav")
				end

				if (!ply.ixHeartbeatSound) then
					ply.ixHeartbeatSound = CreateSound(ply, "player/heartbeat1.wav")
				end

				ply.ixBreatheSoundClient:Stop()
				ply.ixBreatheSoundClient:PlayEx(0.4, pitch)
				ply.ixBreatheSoundClient:SetDSP(dsp)

				ply.ixHeartbeatSound:Stop()
				ply.ixHeartbeatSound:PlayEx(0.6, 100)

				ply.ixStaminaBreathe = true
			end

			timer.Simple(3.8, function()
				if ( IsValid(ply) ) then
					if (SERVER and ply.ixBreatheSoundServer) then
						ply.ixBreatheSoundServer:FadeOut(0.2)
					end

					if (CLIENT and ply == LocalPlayer()) then
						if (ply.ixBreatheSoundClient) then ply.ixBreatheSoundClient:FadeOut(0.2) end
						if (ply.ixHeartbeatSound) then ply.ixHeartbeatSound:FadeOut(0.2) end
						ply.ixStaminaBreathe = false
					end
				end
			end)

			ply.NextStaminaBreathe = CurTime() + 4
		end
	end
end

function PLUGIN:PlayerDeath(ply)
	if (SERVER and ply.ixBreatheSoundServer) then
		ply.ixBreatheSoundServer:Stop()
	end
end

function PLUGIN:EntityRemoved(entity)
	if (entity:IsPlayer()) then
		if (SERVER and entity.ixBreatheSoundServer) then
			entity.ixBreatheSoundServer:Stop()
			entity.ixBreatheSoundServer = nil
		end

		if (CLIENT and entity == LocalPlayer()) then
			if (entity.ixBreatheSoundClient) then
				entity.ixBreatheSoundClient:Stop()
				entity.ixBreatheSoundClient = nil
			end

			if (entity.ixHeartbeatSound) then
				entity.ixHeartbeatSound:Stop()
				entity.ixHeartbeatSound = nil
			end
		end
	end
end

if ( CLIENT ) then
	local staminabluralpha = 0
	local staminabluramount = 0
	local staminablurmaxamount = 5
	
	function PLUGIN:HUDPaint()
		local frametime = RealFrameTime()

		if (!LocalPlayer()) then return end
		if (!LocalPlayer():GetCharacter()) then return end
		if (LocalPlayer():Team() == FACTION_OTA) then return end
		
		if ( ix.option.Get("cheapBlur", false) ) then
			staminablurmaxamount = 10
		end
		
		if ( LocalPlayer().ixStaminaBreathe ) then
			staminabluralpha = Lerp(frametime / 2, staminabluralpha, 255)
			staminabluramount = Lerp(frametime / 2, staminabluramount, staminablurmaxamount)
		else
			staminabluralpha = Lerp(frametime / 2, staminabluralpha, 0)
			staminabluramount = Lerp(frametime / 2, staminabluramount, 0)
		end
		
		ix.util.DrawBlurAt(0, 0, ScrW(), ScrH(), staminabluramount, 0.2, staminabluralpha)
	end
end