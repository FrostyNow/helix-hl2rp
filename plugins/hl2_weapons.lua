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
	-- Vanilla
	["weapon_pistol"] = 5,
	["weapon_smg1"] = 4,
	["weapon_ar2"] = 8,
	["weapon_357"] = 10 --40
}

local function GetDamageWeaponClass(attacker, inflictor)
	local weapon = IsValid(attacker) and attacker.GetActiveWeapon and attacker:GetActiveWeapon() or nil

	if (IsValid(weapon)) then
		return weapon:GetClass(), weapon
	end

	if (IsValid(inflictor)) then
		local class = inflictor:GetClass()

		if (weaponDamage[class]) then
			return class, inflictor
		end
	end
end

if (SERVER) then
	function PLUGIN:EntityTakeDamage(target, dmgInfo)
		local attacker = dmgInfo:GetAttacker()
		local inflictor = dmgInfo:GetInflictor()

		if (IsValid(attacker) and (attacker:IsPlayer() or attacker:IsNPC())) then
			// Antlion
			-- if (attacker:IsNPC() and attacker:GetClass() == "npc_antlion") then
			-- 	local damage = dmgInfo:GetDamage()
			-- 	damage = damage * 2

			-- 	dmgInfo:SetBaseDamage(damage)
			-- 	dmgInfo:SetDamage(damage)
			-- end

			local weaponClass, weapon = GetDamageWeaponClass(attacker, inflictor)

			local inflictorMatches = inflictor == weapon or inflictor == attacker
				or (IsValid(inflictor) and inflictor:GetClass() == weaponClass)

			if (weaponClass and inflictorMatches) then
				if (dmgInfo:IsDamageType(DMG_BULLET) or dmgInfo:IsDamageType(DMG_CLUB)) then
					local damage = weaponDamage[weaponClass]

					if (!damage) then
						return
					end

					if (attacker:IsNPC()) then
						damage = damage * ix.config.Get("npcDamageMultiplier", 0.5)
					end

					-- Cap HL2 weapon damage without undoing reductions already applied by armor or other hooks.
					damage = math.min(dmgInfo:GetDamage(), damage)
					dmgInfo:SetBaseDamage(damage)
					dmgInfo:SetDamage(damage)
				end
			end
		end
	end
end
