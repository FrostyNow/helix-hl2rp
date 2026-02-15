local PLUGIN = PLUGIN
PLUGIN.name = "Jump Sound"
PLUGIN.author = "enaruu"

if SERVER then
	local jumpSounds = {
		["default"] = {
			"npc/zombie/foot1.wav",
			"npc/zombie/foot2.wav",
			"npc/zombie/foot3.wav"
		},
		["vort"] = {
			"npc/vort/vort_foot1.wav",
			"npc/vort/vort_foot2.wav",
			"npc/vort/vort_foot3.wav",
			"npc/vort/vort_foot4.wav"
		},
		["combine"] = {
			"npc/combine_soldier/gear1.wav",
			"npc/combine_soldier/gear2.wav",
			"npc/combine_soldier/gear3.wav",
			"npc/combine_soldier/gear4.wav",
			"npc/combine_soldier/gear6.wav",
			"npc/combine_soldier/gear6.wav"
		}
	}

	local jumpCooldown = {}

	hook.Add("KeyPress", "JumpSoundsPlugin", function(ply, key)
		if ply:IsValid() and key == IN_JUMP and ply:Alive() and ply:GetCharacter() and ply:IsOnGround() and ply:GetMoveType() ~= MOVETYPE_NOCLIP then

			local soundCategory = (ply:GetCharacter():IsVortigaunt() and "vort") or (ply:IsCombine() and "combine") or "default"
			local jumpSound = jumpSounds[soundCategory]
			local volume = soundCategory == "vort" and 0.5 or 1

			ply:EmitSound(jumpSound[math.random(1, #jumpSound)], 75, 100, volume)
		end
	end)

	hook.Add("OnLand", "JumpSoundsPlugin", function(ply, water, vec)
		if ply:IsValid() and ply:Alive() and ply:GetCharacter() and ply:IsOnGround() then
			local chance = math.random(1, 10)

			local soundCategory = (ply:GetCharacter():IsVortigaunt() and "vort") or (ply:IsCombine() and "combine") or "default"
			local jumpSound = jumpSounds[soundCategory]
			local volume = soundCategory == "vort" and 0.5 or 1

			ply:EmitSound(jumpSound[math.random(1, #jumpSound)], 75, 100, volume)
		end
	end)
end
