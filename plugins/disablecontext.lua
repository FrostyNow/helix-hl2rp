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

if ix.config.Get("disableContext", true) then
	function PLUGIN:ContextMenuOpen()
		return LocalPlayer():IsAdmin()
	end
end