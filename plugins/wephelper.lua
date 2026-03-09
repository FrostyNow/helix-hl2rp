local PLUGIN = PLUGIN

PLUGIN.name = "Webview In Help Tabs"
PLUGIN.author = "Frosty"
PLUGIN.desc = "Adds custom websites view to help tabs."

ix.config.Add("collectionsURL", "https://steamcommunity.com/sharedfiles/filedetails/?id=389031629", "The URL for the collections tab in help menu.", nil, {
	category = "general"
})

ix.config.Add("rpGuideURL", "https://steamcommunity.com/sharedfiles/filedetails/?id=268714411", "The URL for the RP Guide tab in help menu.", nil, {
	category = "general"
})

if (CLIENT) then
	ix.lang.AddTable("korean", {
		collections = "모음집",
		rpGuide = "안내서"
	})

	ix.lang.AddTable("english", {
		collections = "Collections",
		rpGuide = "RP Guide"
	})

	hook.Add("PopulateHelpMenu", "ixWebview", function(tabs)
		tabs["collections"] = function(container)
			container:DisableScrolling()

			local html = container:Add("DHTML")
			html:Dock(FILL)
			html:OpenURL(ix.config.Get("collectionsURL", "https://steamcommunity.com/sharedfiles/filedetails/?id=389031629"))
		end

		tabs["rpGuide"] = function(container)
			container:DisableScrolling()

			local html = container:Add("DHTML")
			html:Dock(FILL)
			html:OpenURL(ix.config.Get("rpGuideURL", "https://steamcommunity.com/sharedfiles/filedetails/?id=268714411"))
		end
	end)
end

