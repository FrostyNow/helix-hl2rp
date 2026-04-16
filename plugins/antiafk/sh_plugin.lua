
PLUGIN.name = "Anti-AFK"
PLUGIN.author = "Gr4Ss | Modified by Frosty"
PLUGIN.description = "Stops AFK players from earning wages and kicks when server is full."
PLUGIN.license = [[
(c) 2016 by Gr4Ss (greengr4ss@gmail.com)
This plugin is licensed under the Creative Commons Attribution-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/4.0/
]]

ix.util.Include("cl_hooks.lua")
ix.util.Include("sh_configs.lua")
ix.util.Include("sv_plugin.lua")
ix.util.Include("sv_hooks.lua")

ix.command.Add("AFK", {
	description = "@cmdAFK",
	OnRun = function(self, client)
		if (client.isManualAFK) then
			client.isManualAFK = nil
			client.isAFK = nil
			client:SetNetVar("IsAFK", false)
			client.ixLastAimVector = client:GetAimVector()
			client.ixLastPosition = client:GetPos()
			return "@afkOff"
		else
			client.isManualAFK = true
			client.isAFK = CurTime()
			client:SetNetVar("IsAFK", true)
			return "@afkOn"
		end
	end
})