local PLUGIN = PLUGIN
PLUGIN.name = "Easy Medikit"
PLUGIN.description = "A small base of medical kit (Heal yourself, heal others, works with medical attribute)"
PLUGIN.author = "Subleader | Modified by Frosty"

ix.util.Include("sv_hooks.lua", "server")

do
	ix.char.RegisterVar("bleeding", {
		field = "bleeding",
		fieldType = ix.type.bool,
		default = false,
		isLocal = false,
		bNoDisplay = true
	})

	ix.char.RegisterVar("fracture", {
		field = "fracture",
		fieldType = ix.type.bool,
		default = false,
		isLocal = false,
		bNoDisplay = true
	})
end

if (CLIENT) then
	PLUGIN.bleedNextEffect = PLUGIN.bleedNextEffect or {}
	local BLEED_BONES = {
		"ValveBiped.Bip01_Spine2",
		"ValveBiped.Bip01_R_UpperArm",
		"ValveBiped.Bip01_L_UpperArm",
		"ValveBiped.Bip01_R_Thigh",
		"ValveBiped.Bip01_L_Thigh"
	}

	function PLUGIN:PopulateCharacterInfo(player, character, tooltip)
		local bleeding = tooltip:AddRow("bleeding")
		bleeding:SetText(L("isBleeding"))
		bleeding:SetBackgroundColor(Color(200, 0, 0))
		bleeding:SetTextColor(color_white)
		bleeding:SizeToContents()
		function bleeding:Think()
			local bActive = character:GetBleeding()
			if (self:IsVisible() != bActive) then
				self:SetVisible(bActive)
			end
		end

		local fracture = tooltip:AddRow("fracture")
		fracture:SetText(L("isFractured"))
		fracture:SetBackgroundColor(Color(200, 0, 0))
		fracture:SetTextColor(color_white)
		fracture:SizeToContents()
		function fracture:Think()
			local bActive = character:GetFracture()
			if (self:IsVisible() != bActive) then
				self:SetVisible(bActive)
			end
		end
	end

	function PLUGIN:PostPlayerDraw(client)
		if (!client:Alive() or client:GetNoDraw() or client:GetMoveType() == MOVETYPE_NOCLIP) then return end

		local character = client:GetCharacter()
		if (!character or !character:GetBleeding()) then return end

		local curTime = CurTime()
		local lastEffect = self.bleedNextEffect[client] or 0

		if (lastEffect < curTime) then
			self.bleedNextEffect[client] = curTime + math.Rand(0.7, 1.5)

			local boneName = BLEED_BONES[math.random(#BLEED_BONES)]
			local bone = client:LookupBone(boneName)
			local pos = (bone and client:GetBonePosition(bone)) or (client:GetPos() + Vector(0, 0, 40))

			local emitter = ParticleEmitter(pos)
			if (emitter) then
				for _ = 1, math.random(1, 2) do
					local p = emitter:Add("effects/blood", pos + VectorRand() * 2)
					if (p) then
						p:SetVelocity(VectorRand() * 5 + Vector(0, 0, -15))
						p:SetDieTime(math.Rand(0.8, 1.2))
						p:SetStartAlpha(220)
						p:SetEndAlpha(0)
						p:SetStartSize(math.Rand(1, 3))
						p:SetEndSize(0.5)
						p:SetRoll(math.Rand(0, 360))
						p:SetColor(110, 0, 0)
						p:SetGravity(Vector(0, 0, -600))
						p:SetCollide(true)
						p:SetBounce(0.2)
					end
				end
				emitter:Finish()
			end

			if (client:GetVelocity():LengthSqr() > 100) then
				local trace = util.TraceLine({
					start = pos,
					endpos = pos - Vector(0, 0, 100),
					filter = client
				})

				if (trace.Hit and !trace.HitSky) then
					util.Decal("Blood", trace.HitPos + trace.HitNormal, trace.HitPos - trace.HitNormal, client)
				end
			end
		end
	end
end

ix.command.Add("Break", {
	description = "@cmdBreakDesc",
	adminOnly = true,
	arguments = ix.type.character,
	OnRun = function(self, client, target)
		local player = target:GetPlayer()

		if (IsValid(player) and player:Alive()) then
			PLUGIN:SetFracture(player, true)
		end
	end
})

ix.command.Add("Bleed", {
	description = "@cmdBleedDesc",
	adminOnly = true,
	arguments = ix.type.character,
	OnRun = function(self, client, target)
		local player = target:GetPlayer()

		if (IsValid(player) and player:Alive()) then
			PLUGIN:SetBleeding(player, true)
		end
	end
})
