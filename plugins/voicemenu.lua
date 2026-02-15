local PLUGIN = PLUGIN

PLUGIN.name = "Menu Voces"
PLUGIN.author = "UltraDev"
PLUGIN.description = "View menu voices press [N]."

PLUGIN.bind = KEY_N

ix.lang.AddTable("english", {
	voiceMenuTitle = "Voice Menu",
	voiceMenuSearch = "Search by command or text...",
	voiceMenuFavorites = "Favorites",
	voiceMenuNoClasses = "No available voice classes.",
	voiceMenuNoEntries = "No voice entries found.",
	voiceMenuModeNormal = "Normal",
	voiceMenuModeRadio = "Radio",
	voiceMenuModeBroadcast = "Broadcast",
	voiceMenuModeDispatch = "Dispatch",
	voiceMenuRadioUnavailable = "Cannot send by radio right now.",
	voiceMenuBroadcastUnavailable = "Cannot send broadcast right now.",
	voiceMenuDispatchUnavailable = "Cannot send dispatch right now.",
	voiceMenuInfoFavorites = "Click the star to save your favorites. They will be saved in the client and will only be displayed when the voice is available for playback.",
	voiceMenuInfoBreencast = "Breencast. This is a broadcast channel only.",
	voiceMenuInfoDispatch = "Overwatch Dispatch. This is a dispatch channel only.",
	voiceMenuInfoOverwatch = "Overwatch Radio. This is a radio channel only.",
	voiceMenuInfoDefault = "You can select a general/radio channel on left lick."
})

ix.lang.AddTable("korean", {
	voiceMenuTitle = "음성 메뉴",
	voiceMenuSearch = "명령어 또는 출력 텍스트 검색...",
	voiceMenuFavorites = "즐겨찾기",
	voiceMenuNoClasses = "사용 가능한 음성 클래스가 없습니다.",
	voiceMenuNoEntries = "음성 항목이 없습니다.",
	voiceMenuModeNormal = "일반",
	voiceMenuModeRadio = "라디오",
	voiceMenuModeBroadcast = "브로드캐스트",
	voiceMenuModeDispatch = "디스패치",
	voiceMenuRadioUnavailable = "현재 라디오로 전송할 수 없습니다.",
	voiceMenuBroadcastUnavailable = "현재 브로드캐스트로 전송할 수 없습니다.",
	voiceMenuDispatchUnavailable = "현재 디스패치로 전송할 수 없습니다.",
	voiceMenuInfoFavorites = "별표를 클릭해 즐겨찾는 항목을 저장합니다. 클라이언트에 저장되며 해당 음성을 재생할 수 있는 경우에만 표시됩니다.",
	voiceMenuInfoBreencast = "브린 박사의 방송입니다. 브로드캐스트 채널 전용입니다.",
	voiceMenuInfoDispatch = "감시인 디스패치 방송입니다. 디스패치 채널 전용입니다.",
	voiceMenuInfoOverwatch = "감시인 무전입니다. 라디오 채널 전용입니다.",
	voiceMenuInfoDefault = "항목을 선택하면 일반/라디오 채널을 선택하실 수 있습니다."
})

if (CLIENT) then
	local RADIO_ITEM_IDS = {
		"handheld_radio",
		"longrange",
		"walkietalkie",
		"duplexradio",
		"duplexwalkie",
		"hybridradio",
		"hybridwalkie"
	}

	local MODE_NORMAL = "normal"
	local MODE_RADIO = "radio"
	local MODE_BROADCAST = "broadcast"
	local MODE_DISPATCH = "dispatch"
	local FAVORITES_CLASS = "__favorites"
	local FAVORITES_DIRECTORY = "ixhl2rp"
	local FAVORITES_FILE = FAVORITES_DIRECTORY .. "/voice_favorites.json"

	local function getFavoritesStorage()
		if (istable(PLUGIN.voiceMenuFavorites)) then
			return PLUGIN.voiceMenuFavorites
		end

		PLUGIN.voiceMenuFavorites = {}

		if (!file.Exists(FAVORITES_FILE, "DATA")) then
			return PLUGIN.voiceMenuFavorites
		end

		local raw = file.Read(FAVORITES_FILE, "DATA")
		local decoded = util.JSONToTable(raw or "")

		if (!istable(decoded)) then
			return PLUGIN.voiceMenuFavorites
		end

		for className, commandTable in pairs(decoded) do
			if (isstring(className) and istable(commandTable)) then
				local classKey = string.lower(className)

				PLUGIN.voiceMenuFavorites[classKey] = PLUGIN.voiceMenuFavorites[classKey] or {}

				for command, isFavorite in pairs(commandTable) do
					if (isstring(command) and isFavorite == true) then
						PLUGIN.voiceMenuFavorites[classKey][command] = true
					end
				end
			end
		end

		return PLUGIN.voiceMenuFavorites
	end

	local function saveFavoritesStorage()
		file.CreateDir(FAVORITES_DIRECTORY)
		file.Write(FAVORITES_FILE, util.TableToJSON(getFavoritesStorage()) or "{}")
	end

	local function TL(key, fallback, ...)
		local value = L(key, ...)

		if (value == key) then
			return fallback or key
		end

		return value
	end

	local function getVoicePreviewText(command, info)
		if (!istable(info)) then
			return command
		end

		if (isstring(info.text) and info.text != "") then
			return info.text
		end

		if (istable(info.table) and #info.table > 0) then
			local variant = info.table[1]

			if (istable(variant) and isstring(variant[1]) and variant[1] != "") then
				return variant[1] .. ((#info.table > 1) and " ..." or "")
			end
		end

		return command
	end

	local function getHeadingFromCommand(command)
		if (!isstring(command) or command == "") then
			return "#", 3
		end

		local first = command:utf8sub(1, 1)
		local upper = string.upper(first)
		local codepoint = utf8 and utf8.codepoint and utf8.codepoint(first) or nil

		if (upper:match("%a")) then
			return upper, 1
		end

		if (isnumber(codepoint) and codepoint >= 0xAC00 and codepoint <= 0xD7A3) then
			return first, 2
		end

		return "#", 3
	end

	local function splitSuffixNumber(text)
		local prefix, number = text:match("^(.-)(%d+)$")

		if (prefix) then
			return prefix, tonumber(number)
		end

		return text, nil
	end

	local function naturalCommandLess(a, b)
		local aLower = string.lower(a)
		local bLower = string.lower(b)
		local aPrefix, aNumber = splitSuffixNumber(aLower)
		local bPrefix, bNumber = splitSuffixNumber(bLower)

		if (aPrefix == bPrefix and aNumber and bNumber and aNumber != bNumber) then
			return aNumber < bNumber
		end

		return aLower < bLower
	end

	local function matchesSearchTerm(haystack, needle)
		local startIndex = string.find(haystack, needle, 1, true)

		if (!startIndex) then
			return false
		end

		-- "본능1" 검색 시 "본능10" 같은 숫자 연속 매칭은 제외
		if (needle:match("%d$")) then
			local endIndex = startIndex + needle:utf8len()
			local nextChar = haystack:utf8sub(endIndex, endIndex)

			if (nextChar != "" and nextChar:match("%d")) then
				return false
			end
		end

		return true
	end

	local function getAvailableClasses(client)
		local classes = {}

		for class, data in pairs(Schema.voices.classes) do
			if (data.condition(client)) then
				classes[#classes + 1] = class
			end
		end

		table.sort(classes, function(a, b)
			return a < b
		end)

		return classes
	end

	local function getClassColor(class)
		local lowerClass = string.lower(class or "")

		if (lowerClass == "breencast") then
			return ix.chat.classes.broadcast and ix.chat.classes.broadcast.color or Color(150, 125, 175)
		elseif (lowerClass == "dispatch") then
			return ix.chat.classes.dispatch and ix.chat.classes.dispatch.color or Color(150, 100, 100)
		elseif (lowerClass == "overwatch") then
			return (FACTION_OTA and ix.faction.indices[FACTION_OTA]) and ix.faction.indices[FACTION_OTA].color or Color(181, 110, 60)
		end

		return ix.config.Get("color")
	end

	local PANEL = {}

	function PANEL:Init()
		local width = math.Clamp(math.floor(ScrW() * 0.82), 980, ScrW() - 64)
		local height = math.Clamp(math.floor(ScrH() * 0.82), 660, ScrH() - 64)

		self:SetSize(width, height)
		self:Center()
		self:SetTitle("")
		self:ShowCloseButton(false)
		self:MakePopup()
		self:DockPadding(12, 12, 12, 12)

		self.selectedCommand = nil
		self.selectedClass = nil
		self.availableClasses = {}

		self.header = self:Add("DPanel")
		self.header:Dock(TOP)
		self.header:SetTall(52)
		self.header:DockMargin(0, 0, 0, 8)
		self.header.Paint = function(panel, w, h)
			surface.SetDrawColor(ColorAlpha(ix.config.Get("color"), 30))
			surface.DrawRect(0, 0, w, h)
		end

		self.title = self.header:Add("DLabel")
		self.title:Dock(LEFT)
		self.title:DockMargin(12, 0, 0, 0)
		self.title:SetFont("ixMenuButtonFont")
		self.title:SetTextColor(color_white)
		self.title:SetText(TL("voiceMenuTitle", "Voice Menu"))
		self.title:SizeToContents()

		self.searchEntry = self.header:Add("DTextEntry")
		self.searchEntry:Dock(FILL)
		self.searchEntry:DockMargin(18, 10, 10, 10)
		self.searchEntry:SetFont("ixMediumFont")
		self.searchEntry:SetPlaceholderText(TL("voiceMenuSearch", "Search by command or text..."))
		self.searchEntry.OnChange = function()
			self:PopulateCommandList()
		end

		self.closeButton = self.header:Add("DButton")
		self.closeButton:Dock(RIGHT)
		self.closeButton:DockMargin(0, 10, 10, 10)
		self.closeButton:SetWide(34)
		self.closeButton:SetText("X")
		self.closeButton:SetFont("ixMediumFont")
		self.closeButton.DoClick = function()
			self:Remove()
		end

		self.content = self:Add("DPanel")
		self.content:Dock(FILL)
		self.content.Paint = nil

		self.classContainer = self.content:Add("DPanel")
		self.classContainer:Dock(LEFT)
		self.classContainer:SetWide(250)
		self.classContainer:DockMargin(0, 0, 8, 0)
		self.classContainer.Paint = function(panel, w, h)
			surface.SetDrawColor(Color(12, 12, 12, 190))
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(ColorAlpha(ix.config.Get("color"), 25))
			surface.DrawOutlinedRect(0, 0, w, h, 1)
		end

		self.classScroll = self.classContainer:Add("DScrollPanel")
		self.classScroll:Dock(FILL)
		self.classScroll:DockMargin(8, 8, 8, 8)

		self.commandContainer = self.content:Add("DPanel")
		self.commandContainer:Dock(FILL)
		self.commandContainer.Paint = function(panel, w, h)
			surface.SetDrawColor(Color(12, 12, 12, 190))
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(ColorAlpha(ix.config.Get("color"), 25))
			surface.DrawOutlinedRect(0, 0, w, h, 1)
		end

		self.previewPanel = self.commandContainer:Add("DPanel")
		self.previewPanel:Dock(TOP)
		self.previewPanel:SetTall(68)
		self.previewPanel:DockMargin(8, 8, 8, 0)
		self.previewPanel.Paint = function(panel, w, h)
			local accent = self:GetCategoryAccentColor()

			surface.SetDrawColor(ColorAlpha(accent, 18))
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(ColorAlpha(accent, 55))
			surface.DrawOutlinedRect(0, 0, w, h, 1)
		end

		self.previewLabel = self.previewPanel:Add("DLabel")
		self.previewLabel:Dock(FILL)
		self.previewLabel:DockMargin(10, 6, 10, 6)
		self.previewLabel:SetFont("ixMediumFont")
		self.previewLabel:SetTextColor(Color(220, 220, 220))
		self.previewLabel:SetWrap(true)
		self.previewLabel:SetAutoStretchVertical(true)
		self.previewLabel:SetText("")

		self.commandScroll = self.commandContainer:Add("DScrollPanel")
		self.commandScroll:Dock(FILL)
		self.commandScroll:DockMargin(8, 8, 8, 8)

		self:PopulateClassList()
	end

	function PANEL:GetCategoryAccentColor()
		if (self.selectedClass == FAVORITES_CLASS or !isstring(self.selectedClass)) then
			return ix.config.Get("color")
		end

		return getClassColor(self.selectedClass)
	end

	function PANEL:UpdateCategoryInfoText()
		if (!IsValid(self.previewLabel)) then
			return
		end

		local accent = self:GetCategoryAccentColor()
		local textColor = Color(
			math.min(accent.r + 60, 255),
			math.min(accent.g + 60, 255),
			math.min(accent.b + 60, 255)
		)

		self.previewLabel:SetTextColor(textColor)

		local selectedClass = self.selectedClass

		if (selectedClass == FAVORITES_CLASS) then
			self.previewLabel:SetText(TL("voiceMenuInfoFavorites", "Favorites follow each voice class channel rule."))
			return
		end

		local lowered = string.lower(selectedClass or "")

		if (lowered == "breencast") then
			self.previewLabel:SetText(TL("voiceMenuInfoBreencast", "Channel: Broadcast only."))
		elseif (lowered == "dispatch") then
			self.previewLabel:SetText(TL("voiceMenuInfoDispatch", "Channel: Dispatch only."))
		elseif (lowered == "overwatch") then
			self.previewLabel:SetText(TL("voiceMenuInfoOverwatch", "Channel: Radio only."))
		else
			self.previewLabel:SetText(TL("voiceMenuInfoDefault", "Channels: Normal and Radio."))
		end
	end

	function PANEL:IsFavoriteCommand(class, command)
		local favorites = getFavoritesStorage()
		local classKey = string.lower(class or "")
		local classFavorites = favorites[classKey]

		return istable(classFavorites) and classFavorites[command] == true
	end

	function PANEL:SetFavoriteCommand(class, command, state)
		if (!isstring(class) or class == "" or !isstring(command) or command == "") then
			return
		end

		local favorites = getFavoritesStorage()
		local classKey = string.lower(class)

		favorites[classKey] = favorites[classKey] or {}

		if (state) then
			favorites[classKey][command] = true
		else
			favorites[classKey][command] = nil

			if (table.IsEmpty(favorites[classKey])) then
				favorites[classKey] = nil
			end
		end

		saveFavoritesStorage()
	end

	function PANEL:ToggleFavoriteCommand(class, command)
		local isFavorite = self:IsFavoriteCommand(class, command)

		self:SetFavoriteCommand(class, command, !isFavorite)
	end

	function PANEL:GetFavoriteEntries()
		local entries = {}
		local classLookup = {}

		for _, class in ipairs(self.availableClasses or {}) do
			classLookup[string.lower(class)] = class
		end

		for classKey, commands in pairs(getFavoritesStorage()) do
			local className = classLookup[classKey]
			local classVoices = className and Schema.voices.stored[className] or nil

			if (istable(classVoices)) then
				for command, isFavorite in pairs(commands) do
					local info = classVoices[command]

					if (isFavorite == true and info) then
						entries[#entries + 1] = {
							class = className,
							command = command,
							info = info
						}
					end
				end
			end
		end

		return entries
	end

	function PANEL:GetAllowedModesForClass(class)
		local lowered = string.lower(class or "")

		if (lowered == "breencast") then
			return {MODE_BROADCAST}
		end

		if (lowered == "dispatch") then
			return {MODE_DISPATCH}
		end

		if (lowered == "overwatch") then
			return {MODE_RADIO}
		end

		return {MODE_NORMAL, MODE_RADIO}
	end

	function PANEL:CanSendRadio()
		local client = LocalPlayer()

		if (!IsValid(client) or !client:GetCharacter() or client:IsRestricted()) then
			return false
		end

		if (!ix.command.HasAccess(client, "radio")) then
			return false
		end

		local inventory = client:GetCharacter():GetInventory()

		if (!inventory) then
			return false
		end

		local hasAnyRadio = false

		for _, uniqueID in ipairs(RADIO_ITEM_IDS) do
			for _, item in pairs(inventory:GetItemsByUniqueID(uniqueID, true) or {}) do
				hasAnyRadio = true

				if (item:GetData("enabled", false) and item:GetData("active", true)) then
					return true
				end
			end
		end

		return false, hasAnyRadio
	end

	function PANEL:CanSendBroadcast()
		local client = LocalPlayer()

		if (!IsValid(client) or client:IsRestricted()) then
			return false
		end

		if (!ix.command.HasAccess(client, "broadcast")) then
			return false
		end

		return (FACTION_ADMIN and client:Team() == FACTION_ADMIN) or false
	end

	function PANEL:CanSendDispatch()
		local client = LocalPlayer()

		if (!IsValid(client) or client:IsRestricted()) then
			return false
		end

		if (!ix.command.HasAccess(client, "dispatch")) then
			return false
		end

		return client:IsDispatch()
	end

	function PANEL:CanUseMode(mode)
		if (mode == MODE_RADIO) then
			return self:CanSendRadio()
		end

		if (mode == MODE_BROADCAST) then
			return self:CanSendBroadcast()
		end

		if (mode == MODE_DISPATCH) then
			return self:CanSendDispatch()
		end

		return true
	end

	function PANEL:SendVoice(command, mode)
		if (!isstring(command) or command == "") then
			return
		end

		if (mode == MODE_RADIO) then
			local canUseRadio = self:CanSendRadio()

			if (!canUseRadio) then
				LocalPlayer():Notify(TL("voiceMenuRadioUnavailable", "Cannot send by radio right now."))
				return
			end

			ix.command.Send("Radio", command)
		elseif (mode == MODE_BROADCAST) then
			local canUseBroadcast = self:CanSendBroadcast()

			if (!canUseBroadcast) then
				LocalPlayer():Notify(TL("voiceMenuBroadcastUnavailable", "Cannot send broadcast right now."))
				return
			end

			ix.command.Send("Broadcast", command)
		elseif (mode == MODE_DISPATCH) then
			local canUseDispatch = self:CanSendDispatch()

			if (!canUseDispatch) then
				LocalPlayer():Notify(TL("voiceMenuDispatchUnavailable", "Cannot send dispatch right now."))
				return
			end

			ix.command.Send("Dispatch", command)
		else
			RunConsoleCommand("say", command)
		end

		self:Remove()
	end

	function PANEL:CreateClassButton(class)
		local button = self.classScroll:Add("ixMenuButton")
		local count = (class == FAVORITES_CLASS)
			and #self:GetFavoriteEntries()
			or table.Count(Schema.voices.stored[class] or {})
		local className = (class == FAVORITES_CLASS)
			and TL("voiceMenuFavorites", "Favorites")
			or class:upper()
		local buttonText = string.format("%s (%d)", className, count)

		button:Dock(TOP)
		button:DockMargin(0, 0, 0, 6)
		button:SetTall(34)
		button:SetText("")
		button.displayText = buttonText
		button:SetFont("ixMediumFont")
		button.DoClick = function()
			self.selectedClass = class
			self:UpdateCategoryInfoText()
			self:PopulateCommandList()
		end
		button.Paint = function(panel, w, h)
			local buttonColor = getClassColor(class)
			local isSelected = self.selectedClass == class
			local backAlpha = isSelected and 60 or (panel:IsHovered() and 40 or 0)

			surface.SetDrawColor(ColorAlpha(buttonColor, backAlpha))
			surface.DrawRect(0, 0, w, h)

			if (isSelected) then
				surface.SetDrawColor(buttonColor)
				surface.DrawRect(0, 0, 2, h)
			end

			draw.SimpleText(panel.displayText or "", panel:GetFont(), 8, h / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end
	end

	function PANEL:CreateSectionHeader(text)
		local label = self.commandScroll:Add("DLabel")

		label:Dock(TOP)
		label:DockMargin(2, 8, 0, 4)
		label:SetFont("ixMediumFont")
		label:SetTextColor(ColorAlpha(ix.config.Get("color"), 235))
		label:SetText(text)
		label:SizeToContents()
	end

	function PANEL:OpenModeMenu(command, voiceClass, x, y)
		local modes = self:GetAllowedModesForClass(voiceClass or self.selectedClass)
		local labels = {
			[MODE_NORMAL] = TL("voiceMenuModeNormal", "Normal"),
			[MODE_RADIO] = TL("voiceMenuModeRadio", "Radio"),
			[MODE_BROADCAST] = TL("voiceMenuModeBroadcast", "Broadcast"),
			[MODE_DISPATCH] = TL("voiceMenuModeDispatch", "Dispatch")
		}

		if (#modes == 1) then
			self:SendVoice(command, modes[1])
			return
		end

		local menu = DermaMenu()

		for _, mode in ipairs(modes) do
			local canUseMode = self:CanUseMode(mode)
			local option = menu:AddOption(labels[mode] or mode, function()
				self:SendVoice(command, mode)
			end)

			option:SetEnabled(canUseMode == true)
		end

		menu:Open(x, y, false, self)
	end

	function PANEL:CreateCommandButton(class, command, info)
		local preview = getVoicePreviewText(command, info)
		local button = self.commandScroll:Add("DButton")
		local classPrefix = (self.selectedClass == FAVORITES_CLASS)
			and string.format("[%s] ", string.upper(class))
			or ""

		button:Dock(TOP)
		button:DockMargin(0, 0, 0, 6)
		button:SetTall(54)
		button:SetText("")
		button.voiceClass = class
		button.command = command
		button.preview = preview
		button.displayCommand = classPrefix .. string.upper(command)
		button.favoriteButton = button:Add("DButton")
		button.favoriteButton:Dock(RIGHT)
		button.favoriteButton:DockMargin(0, 10, 8, 10)
		button.favoriteButton:SetWide(30)
		button.favoriteButton:SetFont("ixMediumFont")
		button.favoriteButton:SetContentAlignment(5)
		button.favoriteButton:SetText("")
		button.favoriteButton.Paint = function(starPanel, w, h)
			if (starPanel:IsHovered()) then
				surface.SetDrawColor(Color(255, 255, 255, 10))
				surface.DrawRect(0, 0, w, h)
			end
		end

		local parentPanel = self
		local function updateFavoriteButtonText()
			local isFavorite = parentPanel:IsFavoriteCommand(button.voiceClass, button.command)

			button.favoriteButton:SetText(isFavorite and "★" or "☆")
			button.favoriteButton:SetTextColor(isFavorite and Color(255, 220, 90) or Color(175, 175, 175))
		end

		button.favoriteButton.DoClick = function()
			parentPanel:ToggleFavoriteCommand(button.voiceClass, button.command)
			updateFavoriteButtonText()
			parentPanel:PopulateClassList()
		end
		updateFavoriteButtonText()

		button.DoClick = function(panel)
			local x, y = input.GetCursorPos()
			self:OpenModeMenu(panel.command, panel.voiceClass, x, y)
		end
		button.Paint = function(panel, w, h)
			local alpha = panel:IsHovered() and 45 or 20
			local buttonColor = getClassColor(class)

			surface.SetDrawColor(ColorAlpha(buttonColor, alpha))
			surface.DrawRect(0, 0, w, h)

			draw.SimpleText(panel.displayCommand, "ixMediumFont", 10, 16, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText(panel.preview, "ixSmallFont", 10, 36, Color(180, 180, 180), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end
	end

	function PANEL:PopulateClassList()
		self.classScroll:Clear()

		local classes = getAvailableClasses(LocalPlayer())
		local favoriteCount
		local hasSelectedClass = false

		self.availableClasses = classes
		favoriteCount = #self:GetFavoriteEntries()

		if (favoriteCount < 1 and #classes < 1) then
			local empty = self.classScroll:Add("DLabel")
			empty:Dock(TOP)
			empty:SetFont("ixMediumFont")
			empty:SetTextColor(color_white)
			empty:SetText(TL("voiceMenuNoClasses", "No available voice classes."))
			empty:SizeToContents()
			return
		end

		self:CreateClassButton(FAVORITES_CLASS)

		for _, class in ipairs(classes) do
			self:CreateClassButton(class)

			if (self.selectedClass == class) then
				hasSelectedClass = true
			end
		end

		if (self.selectedClass == FAVORITES_CLASS) then
			hasSelectedClass = true
		end

		if (!hasSelectedClass) then
			self.selectedClass = (favoriteCount > 0) and FAVORITES_CLASS or classes[1]
		end

		self:UpdateCategoryInfoText()
		self:PopulateCommandList()
	end

	function PANEL:PopulateCommandList()
		self.commandScroll:Clear()

		local search = string.Trim(string.lower(self.searchEntry:GetValue() or ""))
		local entries = {}
		local found = 0

		if (self.selectedClass == FAVORITES_CLASS) then
			for _, entry in ipairs(self:GetFavoriteEntries()) do
				local commandLower = string.lower(entry.command)
				local preview = getVoicePreviewText(entry.command, entry.info):lower()
				local matches = (search == "")
					or matchesSearchTerm(commandLower, search)
					or matchesSearchTerm(preview, search)

				if (matches) then
					entries[#entries + 1] = entry
				end
			end
		else
			local classVoices = Schema.voices.stored[self.selectedClass]

			if (istable(classVoices)) then
				for command, info in SortedPairs(classVoices) do
					local commandLower = string.lower(command)
					local preview = getVoicePreviewText(command, info):lower()
					local matches = (search == "")
						or matchesSearchTerm(commandLower, search)
						or matchesSearchTerm(preview, search)

					if (matches) then
						entries[#entries + 1] = {
							class = self.selectedClass,
							command = command,
							info = info
						}
					end
				end
			end
		end

		table.sort(entries, function(a, b)
			local aHeading, aType = getHeadingFromCommand(a.command)
			local bHeading, bType = getHeadingFromCommand(b.command)

			if (aType != bType) then
				return aType < bType
			end

			if (aHeading != bHeading) then
				return aHeading < bHeading
			end

			return naturalCommandLess(a.command, b.command)
		end)

		local lastHeading = nil

		for _, entry in ipairs(entries) do
			local heading = getHeadingFromCommand(entry.command)

			if (heading != lastHeading) then
				self:CreateSectionHeader(heading)
				lastHeading = heading
			end

			self:CreateCommandButton(entry.class, entry.command, entry.info)
			found = found + 1
		end

		if (found < 1) then
			local empty = self.commandScroll:Add("DLabel")
			empty:Dock(TOP)
			empty:SetFont("ixMediumFont")
			empty:SetTextColor(color_white)
			empty:SetText(TL("voiceMenuNoEntries", "No voice entries found."))
			empty:SizeToContents()
		end
	end

	function PANEL:Paint(w, h)
		ix.util.DrawBlur(self, 2)

		surface.SetDrawColor(Color(8, 8, 8, 215))
		surface.DrawRect(0, 0, w, h)

		surface.SetDrawColor(ColorAlpha(ix.config.Get("color"), 70))
		surface.DrawOutlinedRect(0, 0, w, h, 1)
	end

	function PANEL:OnKeyCodePressed(keyCode)
		if (keyCode == KEY_ESCAPE or keyCode == KEY_TAB) then
			self:Remove()
			return
		end
	end

	vgui.Register("ixVoiceMenuLarge", PANEL, "DFrame")

	local function toggleVoiceMenu(client)
		if (!IsValid(client.menu)) then
			local menu = vgui.Create("ixVoiceMenuLarge")

			menu.OnRemove = function(panel)
				if (client.menu == panel) then
					client.menuOpen = false
					client.menu = nil
				end
			end

			client.menuOpen = true
			client.menu = menu
		else
			client.menu:Remove()
		end
	end

	function PLUGIN:PlayerButtonDown(client, button)
		local curTime = CurTime()

		if (button == self.bind) then
			if (IsValid(client.menu)) then
				return
			end

			if ((client.nextBindOpen or 0) > curTime) then
				return
			end

			toggleVoiceMenu(client)
			client.nextBindOpen = curTime + 0.2
			return
		end

		if (IsValid(client.menu) and (button == KEY_ESCAPE or button == KEY_TAB)) then
			client.menu:Remove()
			return
		end
	end
end
