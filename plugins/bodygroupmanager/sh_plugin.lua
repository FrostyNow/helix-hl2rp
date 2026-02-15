
local PLUGIN = PLUGIN

PLUGIN.name = "Bodygroup Manager"
PLUGIN.author = "Gary Tate"
PLUGIN.description = "Allows players and administration to have an easier time customising bodygroups."

ix.lang.AddTable("english", {
	cmdEditBodygroup = "Customise the bodygroups of a target.",
	cmdBodygroup = "Customise your own bodygroups (requires the b flag)."
})

ix.lang.AddTable("korean", {
	cmdEditBodygroup = "대상의 바디그룹을 수정합니다.",
	cmdBodygroup = "자신의 바디그룹을 수정합니다. (b 플래그 필요)"
})

ix.command.Add("CharEditBodygroup", {
	description = "@cmdEditBodygroup",
	adminOnly = true,
	arguments = {
		bit.bor(ix.type.player, ix.type.optional)
	},
	OnRun = function(self, client, target)
		net.Start("ixBodygroupView")
			net.WriteEntity(target or client)
		net.Send(client)
	end
})

ix.command.Add("Bodygroup", {
	description = "@cmdBodygroup",
	OnRun = function(self, client)
		local character = client:GetCharacter()

		if (!character or !character:HasFlags("b")) then
			return "@flagNoMatch", "b"
		end

		net.Start("ixBodygroupView")
			net.WriteEntity(client)
		net.Send(client)
	end
})

properties.Add("ixEditBodygroups", {
	MenuLabel = "#Edit Bodygroups",
	Order = 10,
	MenuIcon = "icon16/user_edit.png",

	Filter = function(self, entity, client)
		return (entity:IsPlayer() and #entity:GetBodyGroups() > 1 and ix.command.HasAccess(client, "CharEditBodygroup"))
	end,

	Action = function(self, entity)
		local panel = vgui.Create("ixBodygroupView")
		panel:Display(entity)
	end
})

ix.util.Include("sv_hooks.lua")
ix.util.Include("cl_hooks.lua")
