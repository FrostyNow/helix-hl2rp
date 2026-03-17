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

if (CLIENT) then
	local spinnerMaterial = Material("vgui/white")

	ix.lang.AddTable("korean", {
		collections = "모음집",
		rpGuide = "안내서",
		webLoading = "불러오는 중..."
	})

	ix.lang.AddTable("english", {
		collections = "Collections",
		rpGuide = "RP Guide",
		webLoading = "Loading..."
	})

	local function PaintSpinner(panel, width, height)
		local centerX = width * 0.5
		local centerY = height * 0.5 - 12
		local radius = 22
		local spokeWidth = 4
		local spokeHeight = 14
		local rotation = RealTime() * 240

		surface.SetMaterial(spinnerMaterial)

		for i = 1, 12 do
			local fraction = i / 12
			local alpha = 35 + math.floor(fraction * 185)
			local spokeAngle = rotation + (i * 30)
			local radians = math.rad(spokeAngle)
			local x = centerX + math.cos(radians) * radius
			local y = centerY + math.sin(radians) * radius

			surface.SetDrawColor(255, 255, 255, alpha)
			surface.DrawTexturedRectRotated(x, y, spokeWidth, spokeHeight, spokeAngle + 90)
		end

		draw.SimpleText(
			L("webLoading"),
			"ixMediumFont",
			centerX,
			centerY + 34,
			color_white,
			TEXT_ALIGN_CENTER,
			TEXT_ALIGN_TOP
		)
	end

	local function PopulateWebTab(container, url)
		container:DisableScrolling()

		local canvas = container:Add("EditablePanel")
		canvas:Dock(FILL)

		local html = canvas:Add("DHTML")
		html:Dock(FILL)

		local overlay = canvas:Add("DPanel")
		overlay:Dock(FILL)
		overlay:SetZPos(1000)
		overlay:SetMouseInputEnabled(false)
		overlay:SetKeyboardInputEnabled(false)

		function overlay:Paint(width, height)
			surface.SetDrawColor(18, 20, 24, 235)
			surface.DrawRect(0, 0, width, height)
			PaintSpinner(self, width, height)
		end

		local function SetLoadingState(isLoading)
			if (IsValid(overlay)) then
				overlay:SetVisible(isLoading)
			end
		end

		function html:OnBeginLoadingDocument()
			SetLoadingState(true)
		end

		function html:OnDocumentReady()
			SetLoadingState(false)
		end

		function html:OnFinishLoadingDocument()
			SetLoadingState(false)
		end

		html:OpenURL(url)
	end

	hook.Add("PopulateHelpMenu", "ixWebview", function(tabs)
		tabs["collections"] = function(container)
			PopulateWebTab(
				container,
				ix.config.Get("collectionsURL", "https://steamcommunity.com/sharedfiles/filedetails/?id=389031629")
			)
		end

		tabs["rpGuide"] = function(container)
			PopulateWebTab(
				container,
				ix.config.Get("rpGuideURL", "https://steamcommunity.com/sharedfiles/filedetails/?id=268714411")
			)
		end
	end)
end

