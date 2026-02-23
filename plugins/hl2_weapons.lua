local PLUGIN = PLUGIN
PLUGIN.name = "HL2 Weapon Tweaks"
PLUGIN.author = "Frosty"
PLUGIN.description = "Override hl2 weapons."

local weaponDamage = {
	["weapon_pistol"] = 5,
	["weapon_smg1"] = 4,
	["weapon_ar2"] = 8,
	["weapon_357"] = 10 --40
}

if (SERVER) then
	function PLUGIN:ScalePlayerDamage(target, hitgroup, dmgInfo)
		local attacker = dmgInfo:GetAttacker()
		local inflictor = dmgInfo:GetInflictor()

		if (IsValid(attacker) and (attacker:IsPlayer() or attacker:IsNPC())) then
			local weapon = attacker:GetActiveWeapon()

			if (IsValid(weapon) and weaponDamage[weapon:GetClass()] and (inflictor == weapon or inflictor == attacker)) then
				if (dmgInfo:IsDamageType(DMG_BULLET) or dmgInfo:IsDamageType(DMG_CLUB)) then
					dmgInfo:SetDamage(weaponDamage[weapon:GetClass()])
				end
			end
		end
	end

	function PLUGIN:ScaleNPCDamage(target, hitgroup, dmgInfo)
		local attacker = dmgInfo:GetAttacker()
		local inflictor = dmgInfo:GetInflictor()

		if (IsValid(attacker) and (attacker:IsPlayer() or attacker:IsNPC())) then
			local weapon = attacker:GetActiveWeapon()

			if (IsValid(weapon) and weaponDamage[weapon:GetClass()] and (inflictor == weapon or inflictor == attacker)) then
				if (dmgInfo:IsDamageType(DMG_BULLET) or dmgInfo:IsDamageType(DMG_CLUB)) then
					dmgInfo:SetDamage(weaponDamage[weapon:GetClass()])
				end
			end
		end
	end

	function PLUGIN:EntityTakeDamage(target, dmgInfo)
		if (target:IsPlayer() or target:IsNPC()) then return end

		local attacker = dmgInfo:GetAttacker()
		local inflictor = dmgInfo:GetInflictor()

		if (IsValid(attacker) and (attacker:IsPlayer() or attacker:IsNPC())) then
			local weapon = attacker:GetActiveWeapon()

			if (IsValid(weapon) and weaponDamage[weapon:GetClass()] and (inflictor == weapon or inflictor == attacker)) then
				if (dmgInfo:IsDamageType(DMG_BULLET) or dmgInfo:IsDamageType(DMG_CLUB)) then
					dmgInfo:SetDamage(weaponDamage[weapon:GetClass()])
				end
			end
		end
	end
end
