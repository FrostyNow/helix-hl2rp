local PLUGIN = PLUGIN

PLUGIN.name = "Glow Flashlight"
PLUGIN.description = "Replaces the default Gmod Flashlight with a glowy light."
PLUGIN.author = "Riggs | Modified by Frosty"
PLUGIN.schema = "Any"
PLUGIN.license = [[
Copyright 2026 Riggs

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

if ( CLIENT ) then
	PLUGIN.flashlights = PLUGIN.flashlights or {}
	PLUGIN.lastFlashlightStates = PLUGIN.lastFlashlightStates or {}

	local function GetLightPosition(client)
		if ( client == LocalPlayer() and !client:ShouldDrawLocalPlayer() ) then
			local vm = client:GetViewModel()
			if ( IsValid(vm) ) then
				local attach = vm:GetAttachment(vm:LookupAttachment("muzzle"))
				if ( !attach ) then attach = vm:GetAttachment(vm:LookupAttachment("1")) end
				if ( attach ) then
					return attach.Pos
				end
			end
			return client:GetShootPos() + client:GetAimVector() * 10
		end

		local wep = client:GetActiveWeapon()
		if ( IsValid(wep) ) then
			local attach = wep:GetAttachment(wep:LookupAttachment("muzzle"))
			if ( !attach ) then attach = wep:GetAttachment(wep:LookupAttachment("1")) end
			if ( attach ) then
				return attach.Pos
			end
		end

		local boneId = client:LookupBone("ValveBiped.Bip01_R_Hand")
		if ( boneId ) then
			local matrix = client:GetBoneMatrix(boneId)
			if ( matrix ) then
				return matrix:GetTranslation()
			end
		end

		return client:GetShootPos() + client:GetAimVector() * 10
	end

	function PLUGIN:Think()
		for _, client in ipairs(player.GetAll()) do
			local bFlashlight = client:GetNetVar("flashlight", false)
			local bNoclip = client:GetMoveType() == MOVETYPE_NOCLIP

			self.lastFlashlightStates = self.lastFlashlightStates or {}

			if (self.lastFlashlightStates[client] != bFlashlight) then
				if (self.lastFlashlightStates[client] != nil) then
					if (client == LocalPlayer() or !bNoclip) then
						client:EmitSound("items/flashlight1.wav", 60, bFlashlight and 100 or 70)
					end
				end

				self.lastFlashlightStates[client] = bFlashlight
			end

			if ( !bFlashlight or !client:Alive() or (bNoclip and client != LocalPlayer()) ) then
				if ( IsValid(self.flashlights[client]) ) then
					self.flashlights[client]:Remove()
					self.flashlights[client] = nil
				end
				continue
			end

			if ( !IsValid(self.flashlights[client]) ) then
				local flashlight = ProjectedTexture()
				flashlight:SetTexture("effects/flashlight001")
				flashlight:SetFarZ(1000)
				flashlight:SetNearZ(12)
				flashlight:SetFOV(70)
				flashlight:SetBrightness(4)
				flashlight:SetColor(Color(255, 255, 255))
				flashlight:SetEnableShadows(false)
				
				self.flashlights[client] = flashlight
			end

			local flashlight = self.flashlights[client]
			if ( IsValid(flashlight) ) then
				local startPos = GetLightPosition(client)
				local endPos = client:GetEyeTraceNoCursor().HitPos
				local dir = (endPos - startPos):GetNormalized()
				if ( endPos:Distance(startPos) < 50 ) then
					dir = client:GetAimVector()
				end

				flashlight:SetPos(startPos)
				flashlight:SetAngles(dir:Angle())
				flashlight:Update()
			end
		end
	end

	function PLUGIN:EntityRemoved(ent)
		if ( ent:IsPlayer() ) then
			if ( IsValid(self.flashlights[ent]) ) then
				self.flashlights[ent]:Remove()
			end

			self.flashlights[ent] = nil
			self.lastFlashlightStates[ent] = nil
		end
	end

	local glowMaterial = Material("sprites/glow04_noz")

	function PLUGIN:PostDrawTranslucentRenderables()
		for client, flashlight in pairs(self.flashlights) do
			if ( IsValid(flashlight) and IsValid(client) ) then
				if ( (client == LocalPlayer() and !client:ShouldDrawLocalPlayer()) or (client:GetMoveType() == MOVETYPE_NOCLIP and client != LocalPlayer()) ) then continue end

				local startPos = GetLightPosition(client)
				local endPos = client:GetEyeTraceNoCursor().HitPos
				local dir = (endPos - startPos):GetNormalized()
				if ( endPos:Distance(startPos) < 50 ) then
					dir = client:GetAimVector()
				end

				render.SetMaterial(glowMaterial)
				render.DrawSprite(startPos, 16, 16, Color(255, 255, 255, 150))
				render.DrawSprite(startPos, 8, 8, Color(255, 255, 255, 255))

				local beamDist = math.min(endPos:Distance(startPos), 100)
				render.DrawBeam(startPos, startPos + dir * beamDist, 12, 0, 1, Color(255, 255, 255, 5))
				render.DrawBeam(startPos, startPos + dir * (beamDist * 0.7), 24, 0, 1, Color(255, 255, 255, 2))
				render.DrawBeam(startPos, startPos + dir * (beamDist * 0.4), 48, 0, 1, Color(255, 255, 255, 3))
			end
		end
	end
end

if ( SERVER ) then
	function PLUGIN:PlayerInitialSpawn(client)
		client:SetNetVar("flashlight", false)
	end

	function PLUGIN:PlayerSpawn(client)
		client:SetNetVar("flashlight", false)
	end

	function PLUGIN:DoPlayerDeath(client)
		client:SetNetVar("flashlight", false)
	end

	function PLUGIN:PlayerDeath(client)
		client:SetNetVar("flashlight", false)
	end

	function PLUGIN:OnPlayerRagdoll(client)
		client:SetNetVar("flashlight", false)
	end

	function PLUGIN:CharacterLoaded(character)
		local client = character:GetPlayer()
		client:SetNetVar("flashlight", false)
	end

	function PLUGIN:PlayerSwitchFlashlight(client, enabled)
		local character = client:GetCharacter()
		local inventory = character and character:GetInventory()

		if (!character or client:IsRagdoll()) then
			return false
		end

		local bHasFlashlightItem = ix.item.list["flashlight"] != nil

		if (!bHasFlashlightItem or (inventory and inventory:GetItemCount("flashlight") > 0) or client:IsCombine()) then
			client:SetNetVar("flashlight", !client:GetNetVar("flashlight", false))
		end

		return false
	end
end
