local PLUGIN = PLUGIN

PLUGIN.name = "Webview In Help Tabs"
PLUGIN.author = "Frosty"
PLUGIN.desc = "Adds custom websites view to help tabs."

PLUGIN.license = [[
Copyright © 2026 Frosty

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/
]]

ix.config.Add("collectionsURL", "https://steamcommunity.com/sharedfiles/filedetails/?id=389031629", "The URL for the collections tab in help menu.", nil, {
	category = "general"
})

ix.config.Add("rpGuideURL", "https://steamcommunity.com/sharedfiles/filedetails/?id=268714411", "The URL for the RP Guide tab in help menu.", nil, {
	category = "general"
})

ix.lang.AddTable("korean", {
	collections = "모음집",
	rpGuide = "안내서",
	worldSetting = "세계관",
	glossary = "용어집",
	webLoading = "불러오는 중..."
})

ix.lang.AddTable("english", {
	collections = "Collections",
	rpGuide = "RP Guide",
	worldSetting = "World Lore",
	glossary = "Glossary",
	webLoading = "Loading..."
})

ix.util.Include("cl_lore.lua")
ix.util.Include("cl_glossary.lua")
ix.util.Include("cl_plugin.lua")
