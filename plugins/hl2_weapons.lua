local PLUGIN = PLUGIN
PLUGIN.name = "HL2 Weapon Tweaks"
PLUGIN.author = "Frosty"
PLUGIN.description = "Override hl2 weapons."

PLUGIN.license = [[
Copyright © 2026 Frosty

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/
]]

ix.config.Add("npcDamageMultiplier", 0.5, "Multiplies how much damage NPCs deal.", nil, {
	data = {min = 0, max = 2, decimal = 1},
	category = "HL2 Weapon Tweaks"
})

local weaponDamage = {
	-- Modded
	["weapon_ezt_mp5k"] = 5,
	
	-- Vanilla
	["weapon_pistol"] = 5,
	["weapon_smg1"] = 4,
	["weapon_ar2"] = 8,
	["weapon_357"] = 10 --40
}

if (SERVER) then
	function PLUGIN:EntityTakeDamage(target, dmgInfo)
		local attacker = dmgInfo:GetAttacker()
		local inflictor = dmgInfo:GetInflictor()

		if (IsValid(attacker) and (attacker:IsPlayer() or attacker:IsNPC())) then
			local weapon = attacker:GetActiveWeapon()

			if (IsValid(weapon) and weaponDamage[weapon:GetClass()] and (inflictor == weapon or inflictor == attacker)) then
				if (dmgInfo:IsDamageType(DMG_BULLET) or dmgInfo:IsDamageType(DMG_CLUB)) then
					local damage = weaponDamage[weapon:GetClass()]

					if (attacker:IsNPC()) then
						damage = damage * ix.config.Get("npcDamageMultiplier", 0.5)
					end

					dmgInfo:SetBaseDamage(damage)
					dmgInfo:SetDamage(damage)
				end
			end
		end
	end
end
