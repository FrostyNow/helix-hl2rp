local PLUGIN = PLUGIN

PLUGIN.name = "Weapon Stats Override"
PLUGIN.author = "Ronald and Frosty"
PLUGIN.desc = "Overrides weapon stats and ammo types."

function PLUGIN:OnLoaded()
    if SERVER then
		GetConVar("arc9_mult_defaultammo"):SetInt(0)
	end
end

function PLUGIN:InitializedPlugins()
	
	
	for k, v in ipairs(weapons.GetList()) do
		local class = v.ClassName
	
		// ARC9
		local swep = weapons.GetStored("arc9_rtb_akm")
		if (swep) then
			swep.DamageMax = 7
			swep.DamageMin = 5
			swep.Ammo = "7.62x39mm"
			swep.ForceDefaultClip = 0
		end

		local swep = weapons.GetStored("arc9_hla_irifle")
		if (swep) then
			swep.DamageMax = 8
			swep.DamageMin = 6
			swep.ForceDefaultClip = 0
		end

		local swep = weapons.GetStored("arc9_hl2_smg1")
		if (swep) then
			swep.DamageMax = 6
			swep.DamageMin = 4
			swep.ForceDefaultClip = 0
		end

		local swep = weapons.GetStored("arc9_hla_hmg")
		if (swep) then
			swep.DamageMax = 8
			swep.DamageMin = 6
			swep.ForceDefaultClip = 0
		end

		// VJ
		local swep = weapons.GetStored("weapon_vj_hlr2_rpg")
		if (swep) then
			swep.Primary.DefaultClip = 0
		end

		// Raising the Bar Redux
		local swep = weapons.GetStored("weapon_rtbr_oicw")
		if (swep) then
			swep.Damage = 8
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
			swep.Primary.DefaultClip = 0
		end

		local swep = weapons.GetStored("weapon_rtbr_shotgun")
		if (swep) then
			swep.Primary.DefaultClip = 0
		end

		local swep = weapons.GetStored("weapon_rtbr_hmg")
		if (swep) then
			swep.Primary.DefaultClip = 0
		end
	end
end