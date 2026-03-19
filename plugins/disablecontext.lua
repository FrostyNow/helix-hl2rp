PLUGIN.name = "Disable Context Menu"
PLUGIN.author = "Frosty"
PLUGIN.description = "Disables context menu."

PLUGIN.license = [[
Copyright © 2026 Frosty

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/
]]

ix.config.Add("disableContext", true, "Whether or not context menu is enabled.", nil, {
	category = "appearance"
})

local allowedWeapons = {
	["gmod_tool"] = true,
	["weapon_physgun"] = true
}

function PLUGIN:ContextMenuOpen()
	if (LocalPlayer():IsAdmin()) then
		return true
	end

	if (ix.config.Get("disableContext", true)) then
		local weapon = LocalPlayer():GetActiveWeapon()

		if (IsValid(weapon) and allowedWeapons[weapon:GetClass()]) then
			return true
		end

		if (LocalPlayer():IsWepRaised()) then
			return false
		end
	end
end