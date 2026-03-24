local PLUGIN = PLUGIN

netstream.Hook("OpenWhitelistChecker", function(factionID, data)
	local faction = ix.faction.teams[factionID]
	local factionName = faction and L(faction.name) or factionID

	local frame = vgui.Create("DFrame")
	frame:SetSize(800, 600)
	frame:Center()
	frame:SetTitle(L("wlCheckerTitle", factionName))
	frame:MakePopup()

	local searchBar = frame:Add("DTextEntry")
	searchBar:Dock(TOP)
	searchBar:DockMargin(0, 0, 0, 5)
	searchBar:SetPlaceholderText(L("wlCheckerSearch"))

	local list = frame:Add("DListView")
	list:Dock(FILL)
	list:SetMultiSelect(false)
	list:AddColumn(L("wlCheckerName"))
	list:AddColumn(L("wlCheckerID"))
	list:AddColumn(L("wlCheckerWhitelisted")):SetFixedWidth(100)
	list:AddColumn(L("wlCheckerChars"))

	local function Populate(filter)
		list:Clear()
		filter = filter and filter:lower() or ""

		local sortedData = {}
		for sid, info in pairs(data) do
			info.sid = sid
			table.insert(sortedData, info)
		end
		
		table.sort(sortedData, function(a, b)
			if (a.online != b.online) then
				return a.online
			end
			return a.name < b.name
		end)

		for _, info in ipairs(sortedData) do
			if (filter != "" and !info.name:lower():find(filter) and !info.sid:find(filter)) then
				continue
			end

			local displayName = info.name
			if (info.rank and info.rank != "user") then
				displayName = displayName .. " (" .. info.rank .. ")"
			end

			local charList = table.concat(info.characters, ", ")
			local line = list:AddLine(displayName, info.sid, info.whitelisted and L("yes") or L("no"), charList)
			
			if (info.online) then
				for i = 1, 4 do
					line:SetColumnText(i, line:GetColumnText(i)) -- Trigger refresh
				end
				-- Color online players green
				line:SetSortValue(1, "0" .. info.name) -- Force sort even if clicked
			end

			if (!info.whitelisted) then
				line:SetColumnText(3, L("wlCheckerNoFlag"))
			end
		end
	end

	searchBar.OnTextChanged = function(self)
		Populate(self:GetValue())
	end

	Populate()

	-- Add right-click menu
	list.OnRowRightClick = function(panel, lineID, line)
		local steamID = line:GetColumnText(2)
		local info = data[steamID]
		local menu = Derma_Menu()

		menu:AddOption(L("wlCheckerCopyID"), function()
			SetClipboardText(steamID)
			LocalPlayer():NotifyLocalized("wlCheckerIDCopied")
		end):SetIcon("icon16/tag_blue.png")

		if (info and info.whitelisted) then
			menu:AddSpacer()
			menu:AddOption(L("wlCheckerRemove"), function()
				Derma_Query(
					L("wlCheckerRemoveConfirm", info.name, factionName),
					L("wlCheckerRemoveTitle"),
					L("yes"), function()
						netstream.Start("RemoveWhitelist", steamID, factionID)
						frame:Close()
					end,
					L("no")
				)
			end):SetIcon("icon16/user_delete.png")
		end

		menu:Open()
	end
end)

netstream.Hook("OpenFlagChecker", function(data)
	local frame = vgui.Create("DFrame")
	frame:SetSize(900, 600)
	frame:Center()
	frame:SetTitle(L("flCheckerTitle"))
	frame:MakePopup()

	local searchBar = frame:Add("DTextEntry")
	searchBar:Dock(TOP)
	searchBar:DockMargin(0, 0, 0, 5)
	searchBar:SetPlaceholderText(L("wlCheckerSearch"))

	local list = frame:Add("DListView")
	list:Dock(FILL)
	list:SetMultiSelect(false)
	list:AddColumn(L("wlCheckerName"))
	list:AddColumn(L("wlCheckerID"))
	list:AddColumn(L("flCheckerPlayerFlags")):SetFixedWidth(120)
	list:AddColumn(L("flCheckerCharFlags"))

	local function Populate(filter)
		list:Clear()
		filter = filter and filter:lower() or ""

		local sortedData = {}
		for sid, info in pairs(data) do
			info.sid = sid
			table.insert(sortedData, info)
		end
		
		table.sort(sortedData, function(a, b)
			if (a.online != b.online) then
				return a.online
			end
			return a.name < b.name
		end)

		for _, info in ipairs(sortedData) do
			if (filter != "" and !info.name:lower():find(filter) and !info.sid:find(filter)) then
				continue
			end

			-- Filter: Only show people who have at least one flag (player or character)
			local bHasAnyFlag = (info.playerFlags != "")
			if (!bHasAnyFlag and info.characters) then
				for _, c in ipairs(info.characters) do
					if (c.flags and c.flags != "") then
						bHasAnyFlag = true
						break
					end
				end
			end

			if (!bHasAnyFlag) then continue end

			local displayName = info.name
			if (info.rank and info.rank != "user") then
				displayName = displayName .. " (" .. info.rank .. ")"
			end

			local charFlagStr = ""
			for _, c in ipairs(info.characters) do
				charFlagStr = charFlagStr .. string.format("%s (%s), ", c.name, c.flags)
			end
			charFlagStr = charFlagStr:sub(1, -3)

			local line = list:AddLine(displayName, info.sid, info.playerFlags, charFlagStr)
			line.steamID = info.sid
			line.info = info
		end
	end

	searchBar.OnTextChanged = function(self)
		Populate(self:GetValue())
	end

	Populate()

	list.OnRowRightClick = function(panel, lineID, line)
		local menu = Derma_Menu()
		local steamID = line.steamID
		local info = line.info

		menu:AddOption(L("wlCheckerCopyID"), function()
			SetClipboardText(steamID)
			LocalPlayer():NotifyLocalized("wlCheckerIDCopied")
		end):SetIcon("icon16/tag_blue.png")

		menu:AddSpacer()

		menu:AddOption(L("flCheckerSetPlayerFlags"), function()
			Derma_StringRequest(
				L("flCheckerSetPlayerFlagsTitle", info.name),
				L("flCheckerFlagsInput"),
				info.playerFlags,
				function(text)
					netstream.Start("UpdatePlayerFlags", steamID, text)
					frame:Close()
				end
			)
		end):SetIcon("icon16/user_edit.png")

		if (info.characters and #info.characters > 0) then
			local charMenu, charMenuOption = menu:AddSubMenu(L("flCheckerCharFlags"))
			charMenuOption:SetIcon("icon16/group_edit.png")

			for _, c in ipairs(info.characters) do
				charMenu:AddOption(L("flCheckerSetCharFlags", c.name), function()
					Derma_StringRequest(
						L("flCheckerSetCharFlagsTitle", c.name),
						L("flCheckerFlagsInput"),
						c.flags,
						function(text)
							netstream.Start("UpdateCharFlags", c.id, text)
							frame:Close()
						end
					)
				end):SetIcon("icon16/bullet_edit.png")
			end
		end

		menu:Open()
	end
end)
