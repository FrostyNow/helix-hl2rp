PLUGIN.name = "Universal Bullet Penetration Fixes"
PLUGIN.author = "Frosty"
PLUGIN.description = "Patches to stop lua errors from Universal Bullet Penetration."

PLUGIN.license = [[
Copyright © 2026 Frosty

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/
]]

-- Weapon bases with their own penetration system.
-- UBP will be skipped for any weapon whose class starts with one of these prefixes,
-- or whose inheritance chain includes the corresponding base class.
local EXCLUDED_BASES = {
	{ prefix = "arc9_" },
	{ prefix = "arccw_" },
	{ prefix = "m9k_" },
	{ prefix = "cw_" },
	{ base = "fas2_base" },
}

if SERVER then
	timer.Simple(0, function()
		local ubpHooks = hook.GetTable()["EntityFireBullets"]
		if not ubpHooks or not ubpHooks["ubp"] then return end

		local original = ubpHooks["ubp"]

		hook.Add("EntityFireBullets", "ubp", function(ent, bullet)
			if ent:IsPlayer() then
				local weapon = ent:GetActiveWeapon()
				if not IsValid(weapon) then return end

				local class = weapon:GetClass()
				for _, entry in ipairs(EXCLUDED_BASES) do
					if (entry.prefix and string.sub(class, 1, #entry.prefix) == entry.prefix)
					or (entry.base and weapons.IsBasedOn(class, entry.base)) then
						return
					end
				end
			end
			return original(ent, bullet)
		end)
	end)
end
