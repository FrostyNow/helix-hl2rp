--[[
! NOTICE ! 

Page switching will not work unless you update the file:
garrysmod/gamemodes/helix/gamemode/core/libs/thirdparty/sv_mysql.lua

to the latest verson in the helix repo. The latest version has added 
functionality which allows database querying to be more optimal. (pagination)
--]]



local PLUGIN = PLUGIN

PLUGIN.name = "CharacterList"
PLUGIN.author = "https://github.com/peyton2465 | Modified by Frosty"
PLUGIN.description = "Provides a superadmin command to view all characters in the database with filtering and pagination."

ix.lang.AddTable("english", {
	failedQuery = "Failed to query character data.",
	charDeleted = "Character '\" %s \"' (ID: \" %s \") has been deleted.",
	yourCharDeleted = "Your character '\" %s \"' has been deleted by an admin.",
	charNotFound = "Character ID \" %s \" not found.",
	cmdCharacterList = "Opens a UI to list all characters in the database with filtering and pagination.",
})

ix.lang.AddTable("korean", {
	failedQuery = "캐릭터 정보를 불러오지 못했습니다.",
	charDeleted = "캐릭터 '\" %s \"' (ID: \" %s \")가 삭제되었습니다.",
	yourCharDeleted = "당신의 캐릭터 '\" %s \"'가 관리자에 의해 삭제되었습니다.",
	charNotFound = "캐릭터 ID \" %s \"(을)를 찾을 수 없습니다.",
	cmdCharacterList = "데이터베이스에 있는 모든 캐릭터를 필터와 페이지로 볼 수 있는 UI를 엽니다.",
})

local CHARS_PER_PAGE = 25

if (SERVER) then
	util.AddNetworkString("ixCharacterListOpen")
	util.AddNetworkString("ixCharacterListRequestPage")
	util.AddNetworkString("ixCharacterListPageData")
	util.AddNetworkString("ixCharacterListDelete")
	
	-- Page cache to avoid repeated identical queries
	-- Format: pageCache[client][cacheKey] = {data, timestamp}
	PLUGIN.pageCache = PLUGIN.pageCache or {}
	local CACHE_DURATION = 30 -- seconds
	
	-- Generate cache key from filters
	local function GetCacheKey(page, steamIDFilter, nameFilter, cidFilter, sortColumn, sortOrder)
		return string.format("%d_%s_%s_%s_%s_%s", page, steamIDFilter or "", nameFilter or "", cidFilter or "", sortColumn or "id", sortOrder or "asc")
	end
	
	-- Clean up page cache when player disconnects
	function PLUGIN:PlayerDisconnected(client)
		PLUGIN.pageCache[client] = nil
	end
	
	-- Function to query database and send page to client
	local function QueryAndSendPage(client, page, steamIDFilter, nameFilter, cidFilter, sortColumn, sortOrder)
		sortColumn = sortColumn or "id"
		sortOrder = sortOrder or "asc"
		
		local cacheKey = GetCacheKey(page, steamIDFilter, nameFilter, cidFilter, sortColumn, sortOrder)
		PLUGIN.pageCache[client] = PLUGIN.pageCache[client] or {}
		
		local cached = PLUGIN.pageCache[client][cacheKey]
		if (cached and (CurTime() - cached.timestamp) < CACHE_DURATION) then
			net.Start("ixCharacterListPageData")
				net.WriteUInt(cached.page, 16)
				net.WriteUInt(cached.totalPages, 16)
				net.WriteUInt(cached.totalCount, 16)
				net.WriteUInt(cached.count, 8)
				net.WriteString(sortColumn)
				net.WriteString(sortOrder)
				
				for _, char in ipairs(cached.characters) do
					net.WriteUInt(char.id, 32)
					net.WriteString(char.steamid)
					net.WriteString(char.name)
					net.WriteString(char.cid)
				end
			net.Send(client)
			return
		end
		
		local offset = (page - 1) * CHARS_PER_PAGE
		local dataQuery = mysql:Select("ix_characters")
			dataQuery:Select("id")
			dataQuery:Select("steamid")
			dataQuery:Select("name")
			dataQuery:Select("data")
			
			if (sortOrder:lower() == "desc") then
				dataQuery:OrderByDesc(sortColumn)
			else
				dataQuery:OrderByAsc(sortColumn)
			end
			
			dataQuery:Limit(CHARS_PER_PAGE + 1)
			dataQuery:Offset(offset)
			
			if (steamIDFilter and steamIDFilter != "") then
				dataQuery:WhereLike("steamid", "%" .. mysql:Escape(steamIDFilter) .. "%")
			end
			if (nameFilter and nameFilter != "") then
				dataQuery:WhereLike("name", "%" .. mysql:Escape(nameFilter) .. "%")
			end
			if (cidFilter and cidFilter != "") then
				dataQuery:WhereLike("data", "%\"cid\"%" .. mysql:Escape(cidFilter) .. "%")
			end
			
			dataQuery:Callback(function(dataResult)
				if (!dataResult) then
					client:NotifyLocalized("failedQuery")
					return
				end
				
				local hasNextPage = #dataResult > CHARS_PER_PAGE
				
				if (hasNextPage) then
					table.remove(dataResult, #dataResult)
				end
				
				if (#dataResult == 0 and page > 1) then
					net.Start("ixCharacterListPageData")
						net.WriteUInt(1, 16)
						net.WriteUInt(1, 16)
						net.WriteUInt(0, 16)
						net.WriteUInt(0, 8)
					net.Send(client)
					return
				end
				
				local estimatedTotalPages = page
				if (hasNextPage) then
					estimatedTotalPages = page + 1
				end
				
				local estimatedTotalCount = (page - 1) * CHARS_PER_PAGE + #dataResult
				if (hasNextPage) then
					estimatedTotalCount = estimatedTotalCount + 1
				end
				
				local characters = {}
				for _, row in ipairs(dataResult) do
					local data = util.JSONToTable(row.data or "") or {}
					local cid = data.cid or "N/A"
					
					characters[#characters + 1] = {
						id = tonumber(row.id),
						steamid = row.steamid or "",
						name = row.name or "Unknown",
						cid = tostring(cid)
					}
				end
				
				PLUGIN.pageCache[client][cacheKey] = {
					page = page,
					totalPages = estimatedTotalPages,
					totalCount = estimatedTotalCount,
					count = #characters,
					characters = characters,
					timestamp = CurTime()
				}
				
				net.Start("ixCharacterListPageData")
					net.WriteUInt(page, 16)
					net.WriteUInt(estimatedTotalPages, 16)
					net.WriteUInt(estimatedTotalCount, 16)
					net.WriteUInt(#characters, 8)
					net.WriteString(sortColumn)
					net.WriteString(sortOrder)
					
					for _, char in ipairs(characters) do
						net.WriteUInt(char.id, 32)
						net.WriteString(char.steamid)
						net.WriteString(char.name)
						net.WriteString(char.cid)
					end
				net.Send(client)
			end)
		dataQuery:Execute()
	end
	
	net.Receive("ixCharacterListRequestPage", function(len, client)
		if (!client:IsSuperAdmin()) then
			client:Kick("Attempted to access CharacterList without permission.")
			return
		end
		
		local page = net.ReadUInt(16)
		local steamIDFilter = net.ReadString()
		local nameFilter = net.ReadString()
		local cidFilter = net.ReadString()
		local sortColumn = net.ReadString()
		local sortOrder = net.ReadString()
		
		page = math.Clamp(tonumber(page) or 1, 1, 9999)
		steamIDFilter = string.sub(steamIDFilter or "", 1, 100)
		nameFilter = string.sub(nameFilter or "", 1, 100)
		cidFilter = string.sub(cidFilter or "", 1, 100)
		sortColumn = string.sub(sortColumn or "id", 1, 20)
		sortOrder = string.sub(sortOrder or "asc", 1, 4)
		
		-- Validate sort column to prevent SQL injection or errors
		local validColumns = {["id"] = true, ["name"] = true, ["steamid"] = true}
		if (!validColumns[sortColumn]) then
			sortColumn = "id"
		end
		
		if (sortOrder != "asc" and sortOrder != "desc") then
			sortOrder = "asc"
		end
		
		QueryAndSendPage(client, page, steamIDFilter, nameFilter, cidFilter, sortColumn, sortOrder)
	end)

	net.Receive("ixCharacterListDelete", function(len, client)
		if (!client:IsSuperAdmin()) then
			client:Kick("Attempted to delete character without permission.")
			return
		end

		local charID = net.ReadUInt(32)
		local page = net.ReadUInt(16)
		local steamIDFilter = net.ReadString()
		local nameFilter = net.ReadString()
		local cidFilter = net.ReadString()
		local sortColumn = net.ReadString()
		local sortOrder = net.ReadString()

		local query = mysql:Select("ix_characters")
			query:Select("id")
			query:Select("steamid")
			query:Select("name")
			query:Where("id", charID)
			query:Callback(function(result)
				if (result and #result > 0) then
					local charData = result[1]
					local characterName = charData.name
					local ownerSteamID = charData.steamid
					local ownerPlayer = player.GetBySteamID64(ownerSteamID)
					
					local character = ix.char.loaded[charID]
					local isCurrentChar = false
					
					if (character) then
						local charPlayer = character:GetPlayer()
						if (IsValid(charPlayer)) then
							isCurrentChar = charPlayer:GetCharacter() and charPlayer:GetCharacter():GetID() == charID
						end
						hook.Run("PreCharacterDeleted", ownerPlayer, character)
					end
					
					ix.char.loaded[charID] = nil
					
					net.Start("ixCharacterDelete")
						net.WriteUInt(charID, 32)
					net.Broadcast()
					
					local deleteQuery = mysql:Delete("ix_characters")
						deleteQuery:Where("id", charID)
						deleteQuery:Callback(function()
							client:NotifyLocalized("charDeleted", characterName, charID)
							
							if (IsValid(ownerPlayer)) then
								ownerPlayer:NotifyLocalized("yourCharDeleted", characterName, charID)
								
								if (ownerPlayer.ixCharList) then
									for k, v in ipairs(ownerPlayer.ixCharList) do
										if (v == charID) then
											table.remove(ownerPlayer.ixCharList, k)
											break
										end
									end
								end
							end

							-- Clear cache for the admin so they get fresh data
							PLUGIN.pageCache[client] = {}
							-- Refresh the page for them
							QueryAndSendPage(client, page, steamIDFilter, nameFilter, cidFilter, sortColumn, sortOrder)
						end)
					deleteQuery:Execute()
					
					local invQuery = mysql:Select("ix_inventories")
						invQuery:Select("inventory_id")
						invQuery:Where("character_id", charID)
						invQuery:Callback(function(invResult)
							if (istable(invResult)) then
								for _, v in ipairs(invResult) do
									local itemQuery = mysql:Delete("ix_items")
										itemQuery:Where("inventory_id", v.inventory_id)
									itemQuery:Execute()
									
									ix.item.inventories[tonumber(v.inventory_id)] = nil
								end
							end
							
							local deleteInvQuery = mysql:Delete("ix_inventories")
								deleteInvQuery:Where("character_id", charID)
							deleteInvQuery:Execute()
						end)
					invQuery:Execute()
					
					hook.Run("CharacterDeleted", ownerPlayer, charID, isCurrentChar)
					
					if (isCurrentChar and IsValid(ownerPlayer)) then
						ownerPlayer:SetNetVar("char", nil)
						ownerPlayer:KillSilent()
						ownerPlayer:StripAmmo()
					end
				else
					client:NotifyLocalized("charNotFound", charID)
				end
			end)
		query:Execute()
	end)
end

ix.command.Add("CharacterList", {
	description = "@cmdCharacterList",
	superAdminOnly = true,
	OnRun = function(self, client)
		if (SERVER) then
			PLUGIN.pageCache[client] = {}
			net.Start("ixCharacterListOpen")
			net.Send(client)
		end
	end
})

if (CLIENT) then
	local PANEL = {}

	AccessorFunc(PANEL, "currentPage", "CurrentPage", FORCE_NUMBER)
	AccessorFunc(PANEL, "totalPages", "TotalPages", FORCE_NUMBER)
	AccessorFunc(PANEL, "totalCount", "TotalCount", FORCE_NUMBER)

	function PANEL:Init()
		self:SetSize(ScrW() * 0.6, ScrH() * 0.7)
		self:SetTitle("Character List")
		self:MakePopup()
		self:Center()

		self.currentPage = 1
		self.totalPages = 1
		self.totalCount = 0
		self.characters = {}
		self.sortColumn = "id"
		self.sortOrder = "asc"

		-- Filter section
		local filterPanel = self:Add("DPanel")
		filterPanel:Dock(TOP)
		filterPanel:SetTall(40)
		filterPanel:DockMargin(4, 4, 4, 4)
		filterPanel:SetPaintBackground(false)

		local cidLabel = filterPanel:Add("DLabel")
		cidLabel:SetText("Char ID:")
		cidLabel:SetTextColor(color_white)
		cidLabel:SetFont("ixSmallFont")
		cidLabel:Dock(LEFT)
		cidLabel:SetWide(100)
		cidLabel:SetContentAlignment(6)
		cidLabel:DockMargin(0, 0, 4, 0)

		self.cidFilter = filterPanel:Add("DTextEntry")
		self.cidFilter:Dock(LEFT)
		self.cidFilter:SetWide(100)
		self.cidFilter:SetPlaceholderText("Filter by CID...")
		self.cidFilter:DockMargin(0, 4, 8, 4)
		self.cidFilter.OnEnter = function()
			self:RequestPage(1)
		end

		local nameLabel = filterPanel:Add("DLabel")
		nameLabel:SetText("Name:")
		nameLabel:SetTextColor(color_white)
		nameLabel:SetFont("ixSmallFont")
		nameLabel:Dock(LEFT)
		nameLabel:SetWide(80)
		nameLabel:SetContentAlignment(6)
		nameLabel:DockMargin(0, 0, 4, 0)

		self.nameFilter = filterPanel:Add("DTextEntry")
		self.nameFilter:Dock(LEFT)
		self.nameFilter:SetWide(200)
		self.nameFilter:SetPlaceholderText("Filter by Character Name...")
		self.nameFilter:DockMargin(0, 4, 8, 4)
		self.nameFilter.OnEnter = function()
			self:RequestPage(1)
		end

		local steamIDLabel = filterPanel:Add("DLabel")
		steamIDLabel:SetText("Steam ID:")
		steamIDLabel:SetTextColor(color_white)
		steamIDLabel:SetFont("ixSmallFont")
		steamIDLabel:Dock(LEFT)
		steamIDLabel:SetWide(100)
		steamIDLabel:SetContentAlignment(6)
		steamIDLabel:DockMargin(0, 0, 4, 0)

		self.steamIDFilter = filterPanel:Add("DTextEntry")
		self.steamIDFilter:Dock(LEFT)
		self.steamIDFilter:SetWide(150)
		self.steamIDFilter:SetPlaceholderText("Filter by Steam ID...")
		self.steamIDFilter:DockMargin(0, 4, 8, 4)
		self.steamIDFilter.OnEnter = function()
			self:RequestPage(1)
		end

		local filterButton = filterPanel:Add("DButton")
		filterButton:SetText("Apply Filter")
		filterButton:Dock(LEFT)
		filterButton:SetWide(100)
		filterButton:DockMargin(8, 4, 0, 4)
		filterButton.DoClick = function()
			self:RequestPage(1)
		end

		local clearButton = filterPanel:Add("DButton")
		clearButton:SetText("Clear")
		clearButton:Dock(LEFT)
		clearButton:SetWide(60)
		clearButton:DockMargin(4, 4, 0, 4)
		clearButton.DoClick = function()
			self.steamIDFilter:SetText("")
			self.nameFilter:SetText("")
			self.cidFilter:SetText("")
			self:RequestPage(1)
		end

		-- Page info label
		self.pageInfoLabel = filterPanel:Add("DLabel")
		self.pageInfoLabel:SetText("Page 1 of 1")
		self.pageInfoLabel:SetTextColor(color_white)
		self.pageInfoLabel:SetFont("ixSmallFont")
		self.pageInfoLabel:Dock(RIGHT)
		self.pageInfoLabel:SetWide(120)
		self.pageInfoLabel:SetContentAlignment(6)
		self.pageInfoLabel:DockMargin(0, 0, 4, 0)


		-- Character list header
		local headerPanel = self:Add("DPanel")
		headerPanel:Dock(TOP)
		headerPanel:SetTall(28)
		headerPanel:DockMargin(4, 0, 4, 2)
		
		local headers = {
			{name = "DB ID", column = "id"},
			{name = "Citizen ID", column = nil},
			{name = "Name", column = "name"},
			{name = "Steam ID", column = "steamid"},
			{name = "Delete", column = nil}
		}
		local widths = {0.06, 0.10, 0.35, 0.44, 0.04}
		
		headerPanel.Paint = function(panel, w, h)
			surface.SetDrawColor(40, 40, 40, 255)
			surface.DrawRect(0, 0, w, h)
		end

		local x = 0
		for i, hInfo in ipairs(headers) do
			local header = hInfo.name
			local column = hInfo.column
			
			local btn = headerPanel:Add("DButton")
			btn:SetText(header)
			btn:SetFont("ixSmallFont")
			btn:SetTextColor(color_white)
			btn:SetContentAlignment(4)
			btn:SetTextInset(4, 0)
			
			btn.xFrac = x
			btn.widthFrac = widths[i]
			btn.PerformLayout = function(s)
				local p = s:GetParent()
				s:SetPos(s.xFrac * p:GetWide(), 0)
				s:SetSize(s.widthFrac * p:GetWide(), p:GetTall())
			end
			
			btn.Paint = function(s, w, h)
				if (column) then
					if (s:IsHovered()) then
						surface.SetDrawColor(255, 255, 255, 10)
						surface.DrawRect(0, 0, w, h)
					end
					
					if (self.sortColumn == column) then
						surface.SetDrawColor(ix.config.Get("color"))
						surface.DrawRect(0, h - 2, w, 2)
						
						surface.SetFont("ixSmallFont")
						local arrow = (self.sortOrder == "asc") and "▲" or "▼"
						local tw, th = surface.GetTextSize(header)
						surface.SetTextPos(tw + 8, h * 0.5 - th * 0.5)
						surface.DrawText(arrow)
					end
				end
			end
			
			if (column) then
				btn.DoClick = function()
					if (self.sortColumn == column) then
						self.sortOrder = (self.sortOrder == "asc") and "desc" or "asc"
					else
						self.sortColumn = column
						self.sortOrder = "asc"
					end
					
					surface.PlaySound("buttons/button14.wav")
					self:RequestPage(1)
				end
			else
				btn:SetMouseInputEnabled(false)
			end
			
			x = x + widths[i]
		end

		-- Scroll panel for character list
		self.scrollPanel = self:Add("DScrollPanel")
		self.scrollPanel:Dock(FILL)
		self.scrollPanel:DockMargin(4, 2, 4, 4)

		self.characterList = self.scrollPanel:Add("DListLayout")
		self.characterList:Dock(TOP)

		-- Footer with pagination buttons
		local footerPanel = self:Add("DPanel")
		footerPanel:Dock(BOTTOM)
		footerPanel:SetTall(40)
		footerPanel:DockMargin(4, 4, 4, 4)
		footerPanel:SetPaintBackground(false)

		self.prevButton = footerPanel:Add("DButton")
		self.prevButton:SetText("< Previous")
		self.prevButton:SetFont("ixSmallFont")
		self.prevButton:Dock(LEFT)
		self.prevButton:SetWide(120)
		self.prevButton:DockMargin(0, 4, 4, 4)
		self.prevButton.DoClick = function()
			if (self.currentPage > 1) then
				self:RequestPage(self.currentPage - 1)
			end
		end

		self.nextButton = footerPanel:Add("DButton")
		self.nextButton:SetText("Next >")
		self.nextButton:SetFont("ixSmallFont")
		self.nextButton:Dock(RIGHT)
		self.nextButton:SetWide(120)
		self.nextButton:DockMargin(4, 4, 0, 4)
		self.nextButton.DoClick = function()
			if (self.currentPage < self.totalPages) then
				self:RequestPage(self.currentPage + 1)
			end
		end

		-- Character count label
		self.countLabel = footerPanel:Add("DLabel")
		self.countLabel:SetText("0 characters")
		self.countLabel:SetTextColor(color_white)
		self.countLabel:SetFont("ixSmallFont")
		self.countLabel:Dock(FILL)
		self.countLabel:SetContentAlignment(5)
	end

	function PANEL:RequestPage(page)
		self.currentPage = page
		
		net.Start("ixCharacterListRequestPage")
			net.WriteUInt(page, 16)
			net.WriteString(self.steamIDFilter:GetText())
			net.WriteString(self.nameFilter:GetText())
			net.WriteString(self.cidFilter:GetText())
			net.WriteString(self.sortColumn)
			net.WriteString(self.sortOrder)
		net.SendToServer()
	end

	function PANEL:UpdateList(characters, page, totalPages, totalCount, sortColumn, sortOrder)
		local parentPanel = self
		self.characterList:Clear()
		self.characters = characters
		self.currentPage = page
		self.totalPages = totalPages
		self.totalCount = totalCount
		self.sortColumn = sortColumn or self.sortColumn
		self.sortOrder = sortOrder or self.sortOrder

		local widths = {0.06, 0.10, 0.35, 0.44, 0.04}

		for i, char in ipairs(characters) do
			local values = {tostring(char.id), tostring(char.cid), char.name, char.steamid}
			
			local row = self.characterList:Add("DPanel")
			row:Dock(TOP)
			row:SetTall(28)
			row:DockMargin(0, 0, 0, 2)
			
			local bgColor = (i % 2 == 0) and Color(30, 30, 30, 255) or Color(45, 45, 45, 255)
			
			row.Paint = function(panel, w, h)
				surface.SetDrawColor(bgColor)
				surface.DrawRect(0, 0, w, h)
			end
			
			-- Create clickable buttons for each cell
			local x = 0
			for j, value in ipairs(values) do
				local btn = row:Add("DButton")
				btn:SetText("")
				btn.value = value
				btn.columnIndex = j
				btn.isHovered = false
				
				btn.xFrac = x
				btn.widthFrac = widths[j]
				btn.PerformLayout = function(self)
					local parent = self:GetParent()
					self:SetPos(self.xFrac * parent:GetWide(), 0)
					self:SetSize(self.widthFrac * parent:GetWide(), parent:GetTall())
				end
				btn:InvalidateLayout(true)
				
				btn.Paint = function(self, w, h)
					if (self.isHovered) then
						surface.SetDrawColor(255, 255, 255, 15)
						surface.DrawRect(0, 0, w, h)
					end
					
					surface.SetFont("ixSmallFont")
					surface.SetTextColor(color_white)
					
					local textX = 4
					local textY = h * 0.5 - draw.GetFontHeight("ixSmallFont") * 0.5
					surface.SetTextPos(textX, textY)
					surface.DrawText(self.value)
				end
				
				btn.OnCursorEntered = function(self)
					self.isHovered = true
				end
				
				btn.OnCursorExited = function(self)
					self.isHovered = false
				end
				
				btn.DoClick = function(self)
					SetClipboardText(self.value)
					surface.PlaySound("buttons/button14.wav")
					
					local oldColor = bgColor
					bgColor = Color(60, 120, 60, 255)
					timer.Simple(0.15, function()
						if (IsValid(row)) then
							bgColor = oldColor
						end
					end)
					
					chat.AddText(Color(100, 255, 100), "[CharacterList] ", color_white, "Copied to clipboard: ", Color(200, 200, 255), self.value)
				end
				
				if (j == 4) then -- Steam ID is the 4th column
					btn.DoRightClick = function(self)
						local steamURL = "https://steamcommunity.com/profiles/" .. self.value
						gui.OpenURL(steamURL)
						surface.PlaySound("buttons/button14.wav")
						chat.AddText(Color(100, 200, 255), "[CharacterList] ", color_white, "Opening Steam profile for: ", Color(200, 200, 255), self.value)
					end
				end
				
				x = x + widths[j]
			end

			-- Delete button
			local deleteBtn = row:Add("DButton")
			deleteBtn:SetText("×")
			deleteBtn:SetTextColor(Color(255, 100, 100))
			deleteBtn:SetFont("ixSmallFont")
			deleteBtn.xFrac = x
			deleteBtn.widthFrac = widths[5]
			deleteBtn.PerformLayout = function(self)
				local parent = self:GetParent()
				self:SetPos(self.xFrac * parent:GetWide(), 0)
				self:SetSize(self.widthFrac * parent:GetWide(), parent:GetTall())
			end
			deleteBtn.Paint = function(self, w, h)
				if (self:IsHovered()) then
					surface.SetDrawColor(255, 0, 0, 30)
					surface.DrawRect(0, 0, w, h)
				end
			end
			deleteBtn.DoClick = function(self)
				Derma_Query(
					string.format("Are you sure you want to delete character '%s' (%s)?", char.name, char.id),
					"Confirm Deletion",
					"Delete", function()
						net.Start("ixCharacterListDelete")
							net.WriteUInt(char.id, 32)
							net.WriteUInt(parentPanel.currentPage, 16)
							net.WriteString(parentPanel.steamIDFilter:GetText())
							net.WriteString(parentPanel.nameFilter:GetText())
							net.WriteString(parentPanel.cidFilter:GetText())
							net.WriteString(parentPanel.sortColumn)
							net.WriteString(parentPanel.sortOrder)
						net.SendToServer()
					end,
					"Cancel"
				)
			end
		end

		self.pageInfoLabel:SetText(string.format("Page %d of %d", page, totalPages))
		self.countLabel:SetText(string.format("%d character(s) found", totalCount))

		self.prevButton:SetEnabled(page > 1)
		self.nextButton:SetEnabled(page < totalPages)
	end

	function PANEL:OnKeyCodePressed(key)
		if (key == KEY_ESCAPE) then
			self:Remove()
			return true
		end
	end

	vgui.Register("ixCharacterList", PANEL, "DFrame")

	net.Receive("ixCharacterListOpen", function()
		if (IsValid(ix.gui.characterList)) then
			ix.gui.characterList:Remove()
		end

		ix.gui.characterList = vgui.Create("ixCharacterList")
		ix.gui.characterList:RequestPage(1)
	end)

	net.Receive("ixCharacterListPageData", function()
		if (!IsValid(ix.gui.characterList)) then
			return
		end

		local page = net.ReadUInt(16)
		local totalPages = net.ReadUInt(16)
		local totalCount = net.ReadUInt(16)
		local count = net.ReadUInt(8)
		local sortColumn = net.ReadString()
		local sortOrder = net.ReadString()

		local characters = {}
		for i = 1, count do
			characters[i] = {
				id = net.ReadUInt(32),
				steamid = net.ReadString(),
				name = net.ReadString(),
				cid = net.ReadString()
			}
		end

		ix.gui.characterList:UpdateList(characters, page, totalPages, totalCount, sortColumn, sortOrder)
	end)
end
