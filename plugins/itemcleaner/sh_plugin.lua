local PLUGIN = PLUGIN

PLUGIN.name = "Item Cleaner"
PLUGIN.author = "Frosty"
PLUGIN.description = "Automatically cleans items that haven't been touched for a while."

PLUGIN.license = [[
Copyright © 2026 Frosty

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/
]]

ix.util.Include("sv_plugin.lua")

ix.config.Add("itemCleanerEnabled", true, "Whether or not the item cleaner is enabled.", nil, {
	category = "Item Cleaner"
})

ix.config.Add("itemCleanerMinItems", 30, "The minimum number of items on the map before cleaning starts.", nil, {
	data = {min = 1, max = 1000},
	category = "Item Cleaner"
})

ix.config.Add("itemCleanerInterval", 30, "How often (in minutes) the item cleaner should run.", nil, {
	data = {min = 5, max = 120},
	category = "Item Cleaner"
})

ix.config.Add("itemCleanerMaxAge", 10, "How long (in minutes) an item must be untouched before it's eligible for cleaning.", nil, {
	data = {min = 1, max = 60},
	category = "Item Cleaner"
})

ix.config.Add("itemCleanerProximity", 15, "The distance (in meters) from players within which items will not be cleaned.", nil, {
	data = {min = 1, max = 150},
	category = "Item Cleaner"
})

ix.lang.AddTable("english", {
	itemCleanerConfig = "Item Cleaner",
	itemCleanerRemoved = "Removed %d items from the map for inactivity.",
	noopItemsRemoved = "No items were eligible for cleaning.",
	cmdItemCleanForce = "Manually triggers the item cleaner cleaning sequence.",
	areaNoCleanup = "Keep Items"
})

ix.lang.AddTable("korean", {
	itemCleanerConfig = "아이템 청소기",
	itemCleanerRemoved = "비활성화된 아이템 %d개를 맵에서 제거했습니다.",
	noopItemsRemoved = "청소할 수 있는 아이템이 없습니다.",
	cmdItemCleanForce = "아이템 청소기의 청소 시퀀스를 수동으로 실행합니다.",
	areaNoCleanup = "아이템 유지"
})

function PLUGIN:SetupAreaProperties()
	ix.area.AddProperty("noItemCleanup", ix.type.bool, false, {
		name = "areaNoCleanup"
	})
end

ix.command.Add("ItemCleanForce", {
	description = "@cmdItemCleanForce",
	superAdminOnly = true,
	OnRun = function(self, client)
		if (PLUGIN.PerformCleanup) then
			PLUGIN:PerformCleanup()
		end
	end
})
