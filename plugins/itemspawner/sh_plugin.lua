
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
	category = "observer",
	phrase = "optSpawnerESP",
	description = "optSpawnerESPDesc",
	hidden = function()
		return !CAMI.PlayerHasAccess(LocalPlayer(), "Helix - Item Spawner", nil)
	end
})

ix.lang.AddTable("english", {
	optSpawnerESP = "Item Spawner ESP",
	optSpawnerESPDesc = "Whether or not to show the item spawner ESP while in observer.",
	spawnerESPTitle = "Spawner: %s",
	spawnerESPInfo = "Delay: %sm | Rarity: %s%%",
})

ix.lang.AddTable("korean", {
	optSpawnerESP = "아이템 생성 지점 ESP",
	optSpawnerESPDesc = "옵저버 상태일 때 아이템 생성 지점 ESP를 표시할지 여부입니다.",
	spawnerESPTitle = "생성 지점: %s",
	spawnerESPInfo = "대기 시간: %s분 | 희귀 확률: %s%%",
})
