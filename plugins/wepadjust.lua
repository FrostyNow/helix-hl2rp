local PLUGIN = PLUGIN

local MELEE_DAMAGE_OVERRIDES = {
	["weapon_hl2axe"] = {8, 10},
	["weapon_hl2bottle"] = {5, 8},
	["weapon_hl2brokenbottle"] = {5, 8},
	["weapon_hl2hook"] = {8, 15},
	["weapon_hl2pan"] = {4, 7},
	["weapon_hl2pickaxe"] = {8, 15},
	["weapon_hl2pipe"] = {4, 7},
	["weapon_hl2pot"] = {4, 7},
	["weapon_hl2shovel"] = {5, 8}
}

local STRENGTH_MELEE_WEAPONS = {
	["ix_hands"] = true,
	["ix_stunstick"] = true,
	["weapon_crowbar"] = true,
	["weapon_hl2axe"] = true,
	["weapon_hl2bottle"] = true,
	["weapon_hl2brokenbottle"] = true,
	["weapon_hl2hook"] = true,
	["weapon_hl2pan"] = true,
	["weapon_hl2pickaxe"] = true,
	["weapon_hl2pipe"] = true,
	["weapon_hl2pot"] = true,
	["weapon_hl2shovel"] = true
}

local BASH_MELEE_WEAPONS = {
	["arc9_rtb_akm"] = true,
	["arc9_hla_irifle"] = true,
	["arc9_hl2_smg1"] = true,
	["arc9_hla_hmg"] = true,
	["arc9_hl2_pistol"] = true,
	["arc9_hl2_sniper"] = true,
	["arc9_l4d2_mp5"] = true,
	["arc9_rtb_oicw"] = true,
}

PLUGIN.name = "Weapon Stats Override"
PLUGIN.author = "Ronald and Frosty"
PLUGIN.desc = "Overrides weapon stats and ammo types."

PLUGIN.license = [[
Copyright © 2026 Frosty

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/
]]

function PLUGIN:OnLoaded()
    if SERVER then
		GetConVar("arc9_mult_defaultammo"):SetInt(0)
	end
end

function PLUGIN:InitializedPlugins()
	
	// ARC9
	local swep = weapons.GetStored("arc9_rtb_akm")
	if (swep) then
		swep.DamageMax = 7
		swep.DamageMin = 5
		swep.BashDamage = 10
		swep.Ammo = "7.62x39mm"
		swep.ForceDefaultClip = 0
	end

	-- Just like a combat rifle
	local swep = weapons.GetStored("arc9_hla_irifle")
	if (swep) then
		swep.DamageMax = 10
		swep.DamageMin = 8
		swep.BashDamage = 10
		swep.ForceDefaultClip = 0
		swep.RPM = 500
	end

	local swep = weapons.GetStored("arc9_hl2_smg1")
	if (swep) then
		swep.DamageMax = 6
		swep.DamageMin = 4
		swep.BashDamage = 10
		swep.ForceDefaultClip = 0
	end

	local swep = weapons.GetStored("arc9_hla_hmg")
	if (swep) then
		swep.DamageMax = 8
		swep.DamageMin = 6
		swep.BashDamage = 10
		swep.ForceDefaultClip = 0
	end

	local swep = weapons.GetStored("arc9_l4d2_mp5")
	if (swep) then
		swep.DamageMax = 6
		swep.DamageMin = 4
		swep.BashDamage = 10
		swep.ForceDefaultClip = 0
	end

	local swep = weapons.GetStored("arc9_hl2_pistol")
	if (swep) then
		swep.DamageMax = 6
		swep.DamageMin = 4
		swep.BashDamage = 10
		swep.ForceDefaultClip = 0
	end

	local swep = weapons.GetStored("arc9_rtb_oicw")
	if (swep) then
		swep.DamageMax = 8
		swep.DamageMin = 6
		swep.BashDamage = 10
		swep.Ammo = "5.56x45mm"
		swep.ForceDefaultClip = 0
		swep.UBGLAmmo = "20x28mm grenade"
		swep.Secondary.DefaultClip = 0
	end

	local swep = weapons.GetStored("arc9_hl2_sniper")
	if (swep) then
		swep.DamageMax = 40
		swep.DamageMin = 20
		swep.BashDamage = 10
		swep.ForceDefaultClip = 0
		swep.Ammo = "AR2"
	end

	// VJ
	local swep = weapons.GetStored("weapon_vj_hlr2_rpg")
	if (swep) then
		swep.Primary.DefaultClip = 0
	end

	// Raising the Bar Redux
	local swep = weapons.GetStored("weapon_rtbr_oicw")
	if (swep) then
		swep.BulletDamage = 8
		swep.Primary.Ammo = "5.56x45mm"
		swep.Primary.DefaultClip = 0
	end

	local swep = weapons.GetStored("weapon_rtbr_flaregun")
	if (swep) then
		swep.Primary.Ammo = "Flares"
		swep.Primary.DefaultClip = 0
	end

	local swep = weapons.GetStored("weapon_rtbr_pistol")
	if (swep) then
		swep.BulletDamage = 5
		swep.Primary.DefaultClip = 0
	end

	local swep = weapons.GetStored("weapon_rtbr_shotgun")
	if (swep) then
		swep.Primary.DefaultClip = 0
	end

	local swep = weapons.GetStored("weapon_rtbr_hmg")
	if (swep) then
		swep.BulletDamage = 8
		swep.Primary.DefaultClip = 0
	end

	local swep = weapons.GetStored("weapon_rtbr_357")
	if (swep) then
		swep.BulletDamage = 10
		swep.Primary.DefaultClip = 0
	end

	//vFire
	local swep = weapons.GetStored("weapon_vfire_molotov")
	if (swep) then
		swep.Primary.DefaultClip = 0
	end

	// HL2 Melee Weapons
	local swep = weapons.GetStored("weapon_hl2axe")
	if (swep) then
		swep.MinDamage = 8
		swep.MaxDamage = 10
	end

	local swep = weapons.GetStored("weapon_hl2bottle")
	if (swep) then
		swep.MinDamage = 5
		swep.MaxDamage = 8
	end

	local swep = weapons.GetStored("weapon_hl2brokenbottle")
	if (swep) then
		swep.MinDamage = 5
		swep.MaxDamage = 8
	end

	local swep = weapons.GetStored("weapon_hl2hook")
	if (swep) then
		swep.MinDamage = 8
		swep.MaxDamage = 15
	end

	local swep = weapons.GetStored("weapon_hl2pan")
	if (swep) then
		swep.MinDamage = 4
		swep.MaxDamage = 7
	end

	local swep = weapons.GetStored("weapon_hl2pickaxe")
	if (swep) then
		swep.MinDamage = 8
		swep.MaxDamage = 15
	end

	local swep = weapons.GetStored("weapon_hl2pipe")
	if (swep) then
		swep.MinDamage = 4
		swep.MaxDamage = 7
	end

	local swep = weapons.GetStored("weapon_hl2pot")
	if (swep) then
		swep.MinDamage = 4
		swep.MaxDamage = 7
	end

	local swep = weapons.GetStored("weapon_hl2shovel")
	if (swep) then
		swep.MinDamage = 5
		swep.MaxDamage = 8
	end
end

local function GetMeleeClass(attacker, inflictor)
	if (IsValid(inflictor) and inflictor ~= attacker) then
		return inflictor:GetClass()
	end

	if (IsValid(attacker) and attacker:IsPlayer()) then
		local weapon = attacker:GetActiveWeapon()

		if (IsValid(weapon)) then
			return weapon:GetClass()
		end
	end
end

local function IsStrengthMeleeDamage(class, dmgInfo)
	if (STRENGTH_MELEE_WEAPONS[class]) then
		return true
	end

	return BASH_MELEE_WEAPONS[class] and dmgInfo:IsDamageType(DMG_CLUB)
end

function PLUGIN:EntityTakeDamage(entity, dmgInfo)
	local attacker = dmgInfo:GetAttacker()
	local inflictor = dmgInfo:GetInflictor()

	if (IsValid(attacker) and attacker:IsPlayer() and IsValid(inflictor)) then
		local class = GetMeleeClass(attacker, inflictor)

		if (!class) then
			return
		end

		local damageOverride = MELEE_DAMAGE_OVERRIDES[class]
		local character = attacker:GetCharacter()
		local bonusDamage = 0

		if (character and IsStrengthMeleeDamage(class, dmgInfo)) then
			local strength = character:GetAttribute("str", 0)
			local multiplier = ix.config.Get("strengthMeleeMultiplier", 0.3)

			bonusDamage = strength * multiplier
		end

		if (damageOverride) then
			dmgInfo:SetDamage(math.Rand(damageOverride[1], damageOverride[2]) + bonusDamage)
		elseif (bonusDamage > 0) then
			dmgInfo:SetDamage(dmgInfo:GetDamage() + bonusDamage)
		end
	end
end
