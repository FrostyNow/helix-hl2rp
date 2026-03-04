
local PLUGIN = PLUGIN

PLUGIN.name = "Item Spawner System"
PLUGIN.author = "Gary Tate"
PLUGIN.description = "Allows staff to select item spawn points with great configuration."

CAMI.RegisterPrivilege({
	Name = "Helix - Item Spawner",
	MinAccess = "admin"
})

ix.util.Include("sh_config.lua")
ix.util.Include("sh_commands.lua")
ix.util.Include("sv_hooks.lua")
ix.util.Include("cl_hooks.lua")

ix.option.Add("spawnerESP", ix.type.bool, false, {
	category = "Item Spawner"
})

ix.lang.AddTable("english", {
	spawnerESPTitle = "Spawner: %s",
	spawnerESPInfo = "Delay: %sm | Rarity: %s%%",
})

ix.lang.AddTable("korean", {
	spawnerESPTitle = "스폰 지점: %s",
	spawnerESPInfo = "대기 시간: %s분 | 희귀 확률: %s%%",
})
