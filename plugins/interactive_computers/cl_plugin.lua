local PLUGIN = PLUGIN

surface.CreateFont("ixComputerDOSHeader", {
	font = "Courier New",
	size = 24,
	weight = 700,
	extended = true,
	antialias = true
})

surface.CreateFont("ixComputerDOSBody", {
	font = "Courier New",
	size = 18,
	weight = 600,
	extended = true,
	antialias = true
})

surface.CreateFont("ixComputerDOSTiny", {
	font = "Courier New",
	size = 15,
	weight = 500,
	extended = true,
	antialias = true
})

local COLOR_BG = Color(5, 10, 5, 245)
local COLOR_PANEL = Color(10, 18, 10, 240)
local COLOR_TEXT = Color(110, 255, 110)
local COLOR_DIM = Color(65, 150, 65)
local COLOR_ACCENT = Color(45, 255, 45, 35)
local TYPE_SOUND = "buttons/blip1.wav"
local COMBINE_BG = Color(8, 16, 28, 246)
local COMBINE_PANEL = Color(14, 24, 38, 240)
local COMBINE_TEXT = Color(115, 200, 255)
local COMBINE_DIM = Color(90, 138, 178)

local StyleLine
local OpenComputerUI
local PANEL = {}

local function GetTerminalTime()
	if (ix and ix.date and ix.date.GetLocalizedTime) then
		return ix.date.GetLocalizedTime()
	end

	return os.date("%Y-%m-%d %H:%M:%S")
end

function PANEL:Init()
	self:SetSize(math.min(ScrW() - 120, 1180), math.min(ScrH() - 120, 760))
	self:Center()
	self:MakePopup()
	self:SetTitle("")
	self:ShowCloseButton(false)
	self:SetDraggable(false)

	self.data = {categories = {}}
	self.selectedCategory = 1
	self.selectedEntry = 1
	self.nextTypeSound = 0
	self.suppressTyping = false

	self.closeButton = self:Add("DButton")
	self.closeButton:SetText("X")
	self.closeButton:SetFont("ixComputerDOSBody")
	self.closeButton:SetTextColor(COLOR_TEXT)
	self.closeButton.DoClick = function()
		self:Close()
	end

	self.powerButton = self:Add("DButton")
	self.powerButton:SetText("POWER")
	self.powerButton:SetFont("ixComputerDOSBody")
	self.powerButton:SetTextColor(COLOR_TEXT)
	self.powerButton.DoClick = function()
		if (!IsValid(self.entity)) then
			self:Close()
			return
		end

		netstream.Start("ixInteractiveComputerPower", self.entity, false)
		self:Close()
	end

	self.statusLabel = self:Add("DLabel")
	self.statusLabel:SetFont("ixComputerDOSTiny")
	self.statusLabel:SetTextColor(COLOR_DIM)
	self.statusLabel:SetText("")

	self.unlockButton = self:Add("DButton")
	self.unlockButton:SetText(L("interactiveComputerUnlock"))
	self.unlockButton:SetFont("ixComputerDOSBody")
	self.unlockButton:SetTextColor(COLOR_TEXT)
	self.unlockButton.DoClick = function()
		if (!IsValid(self.entity)) then
			return
		end

		Derma_StringRequest(
			L("interactiveComputerUnlock"),
			L(self.context and self.context.locked and "interactiveComputerLockedPrompt" or "interactiveComputerGuestPrompt"),
			"",
			function(text)
				netstream.Start("ixInteractiveComputerUnlock", self.entity, string.sub(text or "", 1, PLUGIN.maxPasswordLength))
			end
		)
	end

	self.securityButton = self:Add("DButton")
	self.securityButton:SetText(L("interactiveComputerSecurity"))
	self.securityButton:SetFont("ixComputerDOSBody")
	self.securityButton:SetTextColor(COLOR_TEXT)
	self.securityButton.DoClick = function()
		self:OpenComputerSecurityMenu()
	end

	self.entrySecurityButton = self:Add("DButton")
	self.entrySecurityButton:SetText(L("interactiveComputerEntrySecurity"))
	self.entrySecurityButton:SetFont("ixComputerDOSBody")
	self.entrySecurityButton:SetTextColor(COLOR_TEXT)
	self.entrySecurityButton.DoClick = function()
		self:OpenEntrySecurityMenu()
	end

	self.backButton = self:Add("DButton")
	self.backButton:SetText(L("interactiveComputerBack"))
	self.backButton:SetFont("ixComputerDOSBody")
	self.backButton:SetTextColor(COLOR_TEXT)
	self.backButton:SetVisible(false)
	self.backButton.DoClick = function()
		if (self.context and self.context.returnContext and OpenComputerUI) then
			OpenComputerUI(self.entity, nil, IsValid(self.entity) and self.entity:GetNetVar("powered", true), self.context.returnContext)
		end
	end

	self.leftPanel = self:Add("EditablePanel")
	self.middlePanel = self:Add("EditablePanel")
	self.rightPanel = self:Add("EditablePanel")

	self.categoryList = self.leftPanel:Add("DListView")
	self.categoryList:SetHeaderHeight(22)
	self.categoryList:SetDataHeight(24)
	self.categoryList:AddColumn("CATEGORIES")
	self.categoryList.OnRowSelected = function(_, rowID)
		self.selectedCategory = rowID
		self.selectedEntry = 1
		self:RefreshEntries()
		self:LoadSelectedEntry()
	end

	self.addCategoryButton = self.leftPanel:Add("DButton")
	self.addCategoryButton:SetText("+ CATEGORY")
	self.addCategoryButton:SetFont("ixComputerDOSBody")
	self.addCategoryButton:SetTextColor(COLOR_TEXT)
	self.addCategoryButton.DoClick = function()
		if (#self.data.categories >= PLUGIN.maxCategories) then
			return
		end

		self.data.categories[#self.data.categories + 1] = {
			name = "CATEGORY " .. (#self.data.categories + 1),
			entries = {
				{
					title = "ENTRY 1",
					body = "",
					updatedAt = os.time(),
					author = "",
					security = {
						mode = "none",
						password = ""
					}
				}
			}
		}

		self.selectedCategory = #self.data.categories
		self.selectedEntry = 1
		self:RefreshCategories()
		self:RefreshEntries()
		self:LoadSelectedEntry()
	end

	self.removeCategoryButton = self.leftPanel:Add("DButton")
	self.removeCategoryButton:SetText("- CATEGORY")
	self.removeCategoryButton:SetFont("ixComputerDOSBody")
	self.removeCategoryButton:SetTextColor(COLOR_TEXT)
	self.removeCategoryButton.DoClick = function()
		if (#self.data.categories <= 1) then
			return
		end

		table.remove(self.data.categories, self.selectedCategory)
		self.selectedCategory = math.Clamp(self.selectedCategory, 1, #self.data.categories)
		self.selectedEntry = 1
		self:RefreshCategories()
		self:RefreshEntries()
		self:LoadSelectedEntry()
	end

	self.entryList = self.middlePanel:Add("DListView")
	self.entryList:SetHeaderHeight(22)
	self.entryList:SetDataHeight(24)
	self.entryList:AddColumn("ENTRIES")
	self.entryList.OnRowSelected = function(_, rowID)
		self:WriteCurrentEntry()
		self.selectedEntry = rowID
		self:LoadSelectedEntry()
	end

	self.addEntryButton = self.middlePanel:Add("DButton")
	self.addEntryButton:SetText("+ ENTRY")
	self.addEntryButton:SetFont("ixComputerDOSBody")
	self.addEntryButton:SetTextColor(COLOR_TEXT)
	self.addEntryButton.DoClick = function()
		local category = self:GetSelectedCategory()
		if (!category or #category.entries >= PLUGIN.maxEntriesPerCategory) then
			return
		end

		category.entries[#category.entries + 1] = {
			title = "ENTRY " .. (#category.entries + 1),
			body = "",
			updatedAt = os.time(),
			author = "",
			security = {
				mode = "none",
				password = ""
			}
		}

		self.selectedEntry = #category.entries
		self:RefreshEntries()
		self:LoadSelectedEntry()
	end

	self.removeEntryButton = self.middlePanel:Add("DButton")
	self.removeEntryButton:SetText("- ENTRY")
	self.removeEntryButton:SetFont("ixComputerDOSBody")
	self.removeEntryButton:SetTextColor(COLOR_TEXT)
	self.removeEntryButton.DoClick = function()
		local category = self:GetSelectedCategory()
		if (!category or #category.entries <= 1) then
			return
		end

		table.remove(category.entries, self.selectedEntry)
		self.selectedEntry = math.Clamp(self.selectedEntry, 1, #category.entries)
		self:RefreshEntries()
		self:LoadSelectedEntry()
	end

	self.categoryNameEntry = self.rightPanel:Add("DTextEntry")
	self.categoryNameEntry:SetFont("ixComputerDOSBody")
	self.categoryNameEntry:SetUpdateOnType(true)
	self.categoryNameEntry.OnValueChange = function(entry)
		if (self.suppressTyping) then
			return
		end

		local category = self:GetSelectedCategory()
		if (!category) then
			return
		end

		category.name = string.upper(string.sub(entry:GetValue(), 1, PLUGIN.maxCategoryNameLength))
		self:PlayTypeSound()
		self:RefreshCategories(true)
	end

	self.entryTitleEntry = self.rightPanel:Add("DTextEntry")
	self.entryTitleEntry:SetFont("ixComputerDOSBody")
	self.entryTitleEntry:SetUpdateOnType(true)
	self.entryTitleEntry.OnValueChange = function(entry)
		if (self.suppressTyping) then
			return
		end

		local current = self:GetSelectedEntry()
		if (!current) then
			return
		end

		current.title = string.sub(entry:GetValue(), 1, PLUGIN.maxEntryTitleLength)
		current.updatedAt = os.time()
		self:PlayTypeSound()
		self:RefreshEntries(true)
	end

	self.entryAuthorEntry = self.rightPanel:Add("DTextEntry")
	self.entryAuthorEntry:SetFont("ixComputerDOSBody")
	self.entryAuthorEntry:SetUpdateOnType(true)
	self.entryAuthorEntry.OnValueChange = function(entry)
		if (self.suppressTyping) then
			return
		end

		local current = self:GetSelectedEntry()
		if (!current or (self.context and self.context.combineJournal)) then
			return
		end

		current.author = string.sub(entry:GetValue(), 1, PLUGIN.maxAuthorLength)
		self:PlayTypeSound()
	end

	self.entryBodyEntry = self.rightPanel:Add("DTextEntry")
	self.entryBodyEntry:SetMultiline(true)
	self.entryBodyEntry:SetFont("ixComputerDOSBody")
	self.entryBodyEntry:SetUpdateOnType(true)
	self.entryBodyEntry.OnValueChange = function(entry)
		if (self.suppressTyping) then
			return
		end

		local current = self:GetSelectedEntry()
		if (!current) then
			return
		end

		current.body = string.sub(string.gsub(entry:GetValue(), "\r", ""), 1, PLUGIN.maxEntryBodyLength)
		current.updatedAt = os.time()
		self:PlayTypeSound()
	end

	self.saveButton = self.rightPanel:Add("DButton")
	self.saveButton:SetText("SAVE LOG")
	self.saveButton:SetFont("ixComputerDOSBody")
	self.saveButton:SetTextColor(COLOR_TEXT)
	self.saveButton.DoClick = function()
		if (!IsValid(self.entity)) then
			self:Close()
			return
		end

		self:WriteCurrentEntry()

		if (self.context and self.context.combineJournal) then
			netstream.Start("ixInteractiveComputerSaveCombineJournal", self.entity, self.data)
		else
			netstream.Start("ixInteractiveComputerSave", self.entity, self.data)
		end
	end
end

function PANEL:Paint(width, height)
	surface.SetDrawColor(COLOR_BG)
	surface.DrawRect(0, 0, width, height)

	surface.SetDrawColor(COLOR_ACCENT)
		for y = 0, height, 4 do
			surface.DrawRect(0, y, width, 1)
		end

	surface.SetDrawColor(COLOR_TEXT.r, COLOR_TEXT.g, COLOR_TEXT.b, 50)
	surface.DrawOutlinedRect(0, 0, width, height, 2)

	draw.SimpleText("INTERACTIVE COMPUTERS :: DOS JOURNAL", "ixComputerDOSHeader", 20, 20, COLOR_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	draw.SimpleText(GetTerminalTime(), "ixComputerDOSTiny", width - 20, 24, COLOR_DIM, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

	surface.SetDrawColor(COLOR_TEXT.r, COLOR_TEXT.g, COLOR_TEXT.b, 20)
	surface.DrawRect(18, 56, width - 36, 1)
end

function PANEL:PerformLayout(width, height)
	self.closeButton:SetPos(width - 58, 14)
	self.closeButton:SetSize(40, 32)

	self.powerButton:SetPos(width - 168, 14)
	self.powerButton:SetSize(100, 32)

	self.backButton:SetPos(width - 278, 14)
	self.backButton:SetSize(100, 32)

	self.unlockButton:SetPos(18, 14)
	self.unlockButton:SetSize(120, 32)

	self.securityButton:SetPos(148, 14)
	self.securityButton:SetSize(170, 32)

	self.entrySecurityButton:SetPos(328, 14)
	self.entrySecurityButton:SetSize(170, 32)

	self.statusLabel:SetPos(22, height - 28)
	self.statusLabel:SetSize(width - 44, 20)

	local top = 72
	local bottom = 42
	local contentHeight = height - top - bottom
	local leftWidth = math.floor(width * 0.24)
	local middleWidth = math.floor(width * 0.24)
	local rightWidth = width - leftWidth - middleWidth - 56

	self.leftPanel:SetPos(18, top)
	self.leftPanel:SetSize(leftWidth, contentHeight)

	self.middlePanel:SetPos(28 + leftWidth, top)
	self.middlePanel:SetSize(middleWidth, contentHeight)

	self.rightPanel:SetPos(38 + leftWidth + middleWidth, top)
	self.rightPanel:SetSize(rightWidth, contentHeight)

	self:LayoutListPanel(self.leftPanel, self.categoryList, self.addCategoryButton, self.removeCategoryButton)
	self:LayoutListPanel(self.middlePanel, self.entryList, self.addEntryButton, self.removeEntryButton)

	self.categoryNameEntry:SetPos(0, 0)
	self.categoryNameEntry:SetSize(rightWidth, 28)

	self.entryTitleEntry:SetPos(0, 38)
	self.entryTitleEntry:SetSize(rightWidth, 28)

	self.entryAuthorEntry:SetPos(0, 76)
	self.entryAuthorEntry:SetSize(rightWidth, 28)

	self.entryBodyEntry:SetPos(0, 114)
	self.entryBodyEntry:SetSize(rightWidth, contentHeight - 162)

	self.saveButton:SetPos(rightWidth - 150, contentHeight - 38)
	self.saveButton:SetSize(150, 30)
end

function PANEL:LayoutListPanel(panel, list, addButton, removeButton)
	local width, height = panel:GetSize()

	list:SetPos(0, 0)
	list:SetSize(width, height - 40)

	addButton:SetPos(0, height - 32)
	addButton:SetSize(width * 0.5 - 4, 32)

	removeButton:SetPos(width * 0.5 + 4, height - 32)
	removeButton:SetSize(width * 0.5 - 4, 32)
end

function PANEL:PaintOver(width, height)
	draw.SimpleText("CATEGORY", "ixComputerDOSTiny", self.rightPanel.x, self.rightPanel.y - 18, COLOR_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	draw.SimpleText("ENTRY TITLE", "ixComputerDOSTiny", self.rightPanel.x, self.rightPanel.y + 20, COLOR_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	draw.SimpleText(L("interactiveComputerAuthor"), "ixComputerDOSTiny", self.rightPanel.x, self.rightPanel.y + 58, COLOR_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	draw.SimpleText("JOURNAL BODY", "ixComputerDOSTiny", self.rightPanel.x, self.rightPanel.y + 96, COLOR_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end

function PANEL:PaintPanelBackground(panel, width, height)
	surface.SetDrawColor(COLOR_PANEL)
	surface.DrawRect(0, 0, width, height)
	surface.SetDrawColor(COLOR_TEXT.r, COLOR_TEXT.g, COLOR_TEXT.b, 25)
	surface.DrawOutlinedRect(0, 0, width, height, 1)
end

function PANEL:GetSelectedCategory()
	return self.data.categories[self.selectedCategory]
end

function PANEL:GetSelectedEntry()
	local category = self:GetSelectedCategory()

	return category and category.entries[self.selectedEntry] or nil
end

function PANEL:PlayTypeSound()
	if (self.nextTypeSound > CurTime()) then
		return
	end

	surface.PlaySound(TYPE_SOUND)
	self.nextTypeSound = CurTime() + 0.045
end

function PANEL:WriteCurrentEntry()
	local category = self:GetSelectedCategory()
	local entry = self:GetSelectedEntry()
	if (!category or !entry) then
		return
	end

	category.name = string.upper(string.Trim(self.categoryNameEntry:GetValue()))
	entry.title = string.Trim(self.entryTitleEntry:GetValue())
	if (!(self.context and self.context.combineJournal)) then
		entry.author = string.Trim(self.entryAuthorEntry:GetValue())
	end
	entry.body = string.gsub(self.entryBodyEntry:GetValue(), "\r", "")
	entry.updatedAt = os.time()
end

function PANEL:LoadSelectedEntry()
	local category = self:GetSelectedCategory()
	local entry = self:GetSelectedEntry()

	self.suppressTyping = true

	if (!category or !entry) then
		self.categoryNameEntry:SetValue("")
		self.entryTitleEntry:SetValue("")
		self.entryAuthorEntry:SetValue("")
		self.entryBodyEntry:SetValue("")
		self.suppressTyping = false
		return
	end

	self.categoryNameEntry:SetValue(category.name or "")
	self.entryTitleEntry:SetValue(entry.title or "")
	self.entryAuthorEntry:SetValue(entry.author or "")
	self.entryBodyEntry:SetValue(entry.body or "")
	self.suppressTyping = false
	self:UpdateEditingState()
end

function PANEL:RefreshCategories(skipSelection)
	self.categoryList:Clear()

	for _, category in ipairs(self.data.categories) do
		StyleLine(self.categoryList:AddLine(category.name ~= "" and category.name or L("interactiveComputerNoCategories")))
	end

	if (!skipSelection and self.categoryList:GetLine(self.selectedCategory)) then
		self.categoryList:SelectItem(self.categoryList:GetLine(self.selectedCategory))
	end
end

function PANEL:RefreshEntries(skipSelection)
	self.entryList:Clear()

	local category = self:GetSelectedCategory()
	if (!category) then
		return
	end

	for _, entry in ipairs(category.entries) do
		local text = entry.title ~= "" and entry.title or L("interactiveComputerNoEntries")
		if (entry.locked) then
			text = L("interactiveComputerLockedEntry")
		elseif (entry.security and entry.security.mode == "readonly" and !(entry.canEdit == true)) then
			text = "[RO] " .. text
		end
		StyleLine(self.entryList:AddLine(text))
	end

	if (!skipSelection and self.entryList:GetLine(self.selectedEntry)) then
		self.entryList:SelectItem(self.entryList:GetLine(self.selectedEntry))
	end
end

function PANEL:LoadComputer(entity, data, powered)
	if (!powered) then
		self:Close()
		return
	end

	self.entity = entity
	self.data = PLUGIN:NormalizeData(table.Copy(data or {}))
	self.selectedCategory = math.Clamp(self.selectedCategory or 1, 1, #self.data.categories)
	self.selectedEntry = 1
	self:RefreshCategories()
	self:RefreshEntries()
	self:LoadSelectedEntry()
end

function PANEL:LoadComputerContext(entity, data, powered, context)
	self:LoadComputer(entity, data, powered)
	self.context = context or {}
	self.saveButton:SetText(self.context.combineJournal and L("interactiveComputerSavePersonalLog") or "SAVE LOG")
	self.backButton:SetVisible(self.context.fromCombine == true)
	self.unlockButton:SetVisible(self.context.combineJournal != true and self.context.hasComputerPassword == true and self.context.fullAccess != true)
	self.securityButton:SetVisible(self.context.combineJournal != true)
	self.entrySecurityButton:SetVisible(self.context.combineJournal != true)
	self:UpdateEditingState()
end

function PANEL:Think()
	if (IsValid(self.entity) and LocalPlayer():GetPos():DistToSqr(self.entity:GetPos()) > 190 * 190) then
		self:Close()
	end
end

function PANEL:OnRemove()
	if (IsValid(self.entity)) then
		netstream.Start("ixInteractiveComputerEndUse", self.entity)
	end

	if (ix.gui.interactiveComputer == self) then
		ix.gui.interactiveComputer = nil
	end
end

function PANEL:UpdateEditingState()
	local category = self:GetSelectedCategory()
	local entry = self:GetSelectedEntry()
	local combineJournal = self.context and self.context.combineJournal == true
	local canEditComputer = !self.context or combineJournal or self.context.canEdit == true
	local canEditEntry = canEditComputer and (!entry or entry.canEdit != false) and (!entry or entry.locked != true)
	local accessLabel = self.context and self.context.locked and L("interactiveComputerLocked")
		or (self.context and self.context.guest and L("interactiveComputerGuest"))
		or L("interactiveComputerFullAccess")

	self.categoryNameEntry:SetEnabled(canEditComputer and category != nil)
	self.entryTitleEntry:SetEnabled(canEditEntry and entry != nil)
	self.entryAuthorEntry:SetEnabled(canEditEntry and entry != nil and !combineJournal)
	self.entryBodyEntry:SetEnabled(canEditEntry and entry != nil)
	self.addCategoryButton:SetEnabled(canEditComputer)
	self.removeCategoryButton:SetEnabled(canEditComputer and #self.data.categories > 1)
	self.addEntryButton:SetEnabled(canEditComputer and category != nil)
	self.removeEntryButton:SetEnabled(canEditComputer and category != nil and #category.entries > 1)
	self.saveButton:SetEnabled(canEditComputer)
	self.securityButton:SetEnabled(canEditComputer and !combineJournal)
	self.entrySecurityButton:SetEnabled(canEditComputer and !combineJournal and entry != nil)
	self.unlockButton:SetEnabled(self.context and self.context.hasComputerPassword == true and self.context.fullAccess != true)

	if (entry and (entry.locked or (entry.security and entry.security.mode == "readonly" and entry.canEdit != true))) then
		self.entrySecurityButton:SetText(L("interactiveComputerEntryUnlock"))
	else
		self.entrySecurityButton:SetText(L("interactiveComputerEntrySecurity"))
	end

	if (category and entry) then
		local suffix = ""
		if (entry.locked) then
			suffix = " | " .. L("interactiveComputerLocked")
		elseif (entry.security and entry.security.mode == "readonly" and entry.canEdit != true) then
			suffix = " | " .. L("interactiveComputerSecurityReadOnly")
		end

		self.statusLabel:SetText(string.format("%s | CATEGORY %d/%d | ENTRY %d/%d%s", accessLabel, self.selectedCategory, #self.data.categories, self.selectedEntry, #category.entries, suffix))
	end
end

function PANEL:OpenPasswordModeMenu(options, onSelected)
	local menu = DermaMenu()

	for _, option in ipairs(options) do
		menu:AddOption(L(option.label), function()
			if (option.mode == "none") then
				onSelected(option.mode, "")
				return
			end

			Derma_StringRequest(
				L(option.label),
				L("interactiveComputerUnlock"),
				"",
				function(text)
					onSelected(option.mode, string.sub(text or "", 1, PLUGIN.maxPasswordLength))
				end
			)
		end)
	end

	menu:Open()
end

function PANEL:OpenComputerSecurityMenu()
	if (!IsValid(self.entity) or (self.context and self.context.combineJournal)) then
		return
	end

	self:OpenPasswordModeMenu({
		{label = "interactiveComputerSecurityNone", mode = "none"},
		{label = "interactiveComputerSecurityLocked", mode = "locked"},
		{label = "interactiveComputerSecurityGuest", mode = "guest"}
	}, function(mode, password)
		netstream.Start("ixInteractiveComputerSetSecurity", self.entity, mode, password)
	end)
end

function PANEL:OpenEntrySecurityMenu()
	local category = self:GetSelectedCategory()
	local entry = self:GetSelectedEntry()
	if (!IsValid(self.entity) or !category or !entry or (self.context and self.context.combineJournal)) then
		return
	end

	if (entry.locked or (entry.security and entry.security.mode == "readonly" and entry.canEdit != true)) then
		Derma_StringRequest(
			L("interactiveComputerEntryUnlock"),
			L(entry.security and entry.security.mode == "readonly" and "interactiveComputerEntryReadPrompt" or "interactiveComputerEntryLockedPrompt"),
			"",
			function(text)
				netstream.Start("ixInteractiveComputerUnlockEntry", self.entity, self.selectedCategory, self.selectedEntry, string.sub(text or "", 1, PLUGIN.maxPasswordLength))
			end
		)
		return
	end

	self:OpenPasswordModeMenu({
		{label = "interactiveComputerSecurityNone", mode = "none"},
		{label = "interactiveComputerSecurityPrivate", mode = "private"},
		{label = "interactiveComputerSecurityReadOnly", mode = "readonly"}
	}, function(mode, password)
		netstream.Start("ixInteractiveComputerSetEntrySecurity", self.entity, self.selectedCategory, self.selectedEntry, mode, password)
	end)
end

vgui.Register("ixInteractiveComputerTerminal", PANEL, "DFrame")

StyleLine = function(line)
	if (!line) then
		return
	end

	line.Paint = function(self, width, height)
		local selected = self:IsSelected()

		surface.SetDrawColor(selected and Color(24, 70, 24, 255) or Color(0, 0, 0, 0))
		surface.DrawRect(0, 0, width, height)
		surface.SetDrawColor(COLOR_TEXT.r, COLOR_TEXT.g, COLOR_TEXT.b, selected and 80 or 15)
		surface.DrawOutlinedRect(0, 0, width, height, 1)
	end

	if (line.Columns) then
		for _, column in ipairs(line.Columns) do
			column:SetTextColor(COLOR_TEXT)
			column:SetFont("ixComputerDOSTiny")
		end
	end
end

local function StyleListView(list)
	list:SetMultiSelect(false)
	list.Paint = function(_, width, height)
		surface.SetDrawColor(COLOR_PANEL)
		surface.DrawRect(0, 0, width, height)
		surface.SetDrawColor(COLOR_TEXT.r, COLOR_TEXT.g, COLOR_TEXT.b, 20)
		surface.DrawOutlinedRect(0, 0, width, height, 1)
	end

	local header = list:GetHeader()
	header:SetTall(22)
	header.Paint = function(_, width, height)
		surface.SetDrawColor(20, 40, 20, 240)
		surface.DrawRect(0, 0, width, height)
	end

	for _, column in ipairs(header.Columns or {}) do
		column:SetTextColor(COLOR_TEXT)
		column:SetFont("ixComputerDOSTiny")
	end

	list.OnRowRightClick = function() end

	function list:PerformLayout()
		self:FixColumnsLayout()
	end
end

local function StyleButton(button)
	button.Paint = function(_, width, height)
		local hovered = button:IsHovered()
		surface.SetDrawColor(hovered and Color(25, 60, 25, 255) or Color(14, 30, 14, 255))
		surface.DrawRect(0, 0, width, height)
		surface.SetDrawColor(COLOR_TEXT.r, COLOR_TEXT.g, COLOR_TEXT.b, hovered and 120 or 60)
		surface.DrawOutlinedRect(0, 0, width, height, 1)
	end
end

local function StyleTextEntry(entry)
	entry:SetTextColor(COLOR_TEXT)
	entry:SetHighlightColor(Color(70, 170, 70))
	entry:SetCursorColor(COLOR_TEXT)
	entry.Paint = function(self, width, height)
		surface.SetDrawColor(Color(8, 20, 8, 255))
		surface.DrawRect(0, 0, width, height)
		surface.SetDrawColor(COLOR_TEXT.r, COLOR_TEXT.g, COLOR_TEXT.b, 40)
		surface.DrawOutlinedRect(0, 0, width, height, 1)
		self:DrawTextEntryText(COLOR_TEXT, Color(70, 170, 70, 120), COLOR_TEXT)
	end
end

local function StyleCombineButton(button)
	button.Paint = function(_, width, height)
		local hovered = button:IsHovered()
		surface.SetDrawColor(hovered and Color(24, 56, 88, 255) or Color(16, 34, 54, 255))
		surface.DrawRect(0, 0, width, height)
		surface.SetDrawColor(COMBINE_TEXT.r, COMBINE_TEXT.g, COMBINE_TEXT.b, hovered and 130 or 70)
		surface.DrawOutlinedRect(0, 0, width, height, 1)
	end
end

local function StyleCombineTextEntry(entry)
	entry:SetTextColor(COMBINE_TEXT)
	entry:SetHighlightColor(Color(180, 120, 40))
	entry:SetCursorColor(COMBINE_TEXT)
	entry.Paint = function(self, width, height)
		surface.SetDrawColor(Color(10, 20, 34, 255))
		surface.DrawRect(0, 0, width, height)
		surface.SetDrawColor(COMBINE_TEXT.r, COMBINE_TEXT.g, COMBINE_TEXT.b, 45)
		surface.DrawOutlinedRect(0, 0, width, height, 1)
		self:DrawTextEntryText(COMBINE_TEXT, Color(90, 160, 220, 120), COMBINE_TEXT)
	end
end

local function StyleCombineListView(list)
	list:SetMultiSelect(false)
	list.Paint = function(_, width, height)
		surface.SetDrawColor(COMBINE_PANEL)
		surface.DrawRect(0, 0, width, height)
		surface.SetDrawColor(COMBINE_TEXT.r, COMBINE_TEXT.g, COMBINE_TEXT.b, 22)
		surface.DrawOutlinedRect(0, 0, width, height, 1)
	end

	local header = list.GetHeader and list:GetHeader() or nil
	if (!IsValid(header)) then
		return
	end

	header:SetTall(22)
	header.Paint = function(_, width, height)
		surface.SetDrawColor(20, 38, 58, 240)
		surface.DrawRect(0, 0, width, height)
	end

	for _, column in ipairs(header.Columns or {}) do
		column:SetTextColor(COMBINE_TEXT)
		column:SetFont("ixComputerDOSTiny")
	end
end

local function ApplyTerminalStyling(frame)
	frame.leftPanel.Paint = function(panel, width, height)
		frame:PaintPanelBackground(panel, width, height)
	end

	frame.middlePanel.Paint = function(panel, width, height)
		frame:PaintPanelBackground(panel, width, height)
	end

	frame.rightPanel.Paint = function(panel, width, height)
		frame:PaintPanelBackground(panel, width, height)
	end

	StyleListView(frame.categoryList)
	StyleListView(frame.entryList)

	StyleButton(frame.closeButton)
	StyleButton(frame.powerButton)
	StyleButton(frame.backButton)
	StyleButton(frame.addCategoryButton)
	StyleButton(frame.removeCategoryButton)
	StyleButton(frame.addEntryButton)
	StyleButton(frame.removeEntryButton)
	StyleButton(frame.saveButton)

	StyleTextEntry(frame.categoryNameEntry)
	StyleTextEntry(frame.entryTitleEntry)
	StyleTextEntry(frame.entryAuthorEntry)
	StyleTextEntry(frame.entryBodyEntry)
end

local function ApplyCombineStyling(frame)
	StyleCombineListView(frame.rosterList)
	StyleCombineButton(frame.closeButton)
	StyleCombineButton(frame.powerButton)
	StyleCombineButton(frame.objectiveSaveButton)
	StyleCombineButton(frame.dataSaveButton)
	StyleCombineButton(frame.personalLogButton)
	StyleCombineButton(frame.publicPanelButton)
	StyleCombineTextEntry(frame.objectivesEntry)
	StyleCombineTextEntry(frame.dataEntry)
end

local COMBINE = {}

function COMBINE:Init()
	self:SetSize(math.min(ScrW() - 160, 1220), math.min(ScrH() - 120, 780))
	self:Center()
	self:MakePopup()
	self:SetTitle("")
	self:ShowCloseButton(false)
	self:SetDraggable(false)

	self.nextTypeSound = 0
	self.selectedTarget = nil
	self.context = {}

	self.closeButton = self:Add("DButton")
	self.closeButton:SetText("X")
	self.closeButton:SetFont("ixComputerDOSBody")
	self.closeButton:SetTextColor(COMBINE_TEXT)
	self.closeButton.DoClick = function()
		self:Close()
	end

	self.powerButton = self:Add("DButton")
	self.powerButton:SetText("POWER")
	self.powerButton:SetFont("ixComputerDOSBody")
	self.powerButton:SetTextColor(COMBINE_TEXT)
	self.powerButton.DoClick = function()
		if (IsValid(self.entity)) then
			netstream.Start("ixInteractiveComputerPower", self.entity, false)
		end

		self:Close()
	end

	self.statusLabel = self:Add("DLabel")
	self.statusLabel:SetFont("ixComputerDOSTiny")
	self.statusLabel:SetTextColor(COMBINE_DIM)
	self.statusLabel:SetText("")

	self.rosterList = self:Add("DListView")
	self.rosterList:SetHeaderHeight(22)
	self.rosterList:SetDataHeight(24)
	self.rosterList:AddColumn("UNIT")
	self.rosterList.OnRowSelected = function(_, rowID, row)
		self.selectedTarget = row.ixTarget
		self:PopulateSelectedData()
	end

	self.objectivesEntry = self:Add("DTextEntry")
	self.objectivesEntry:SetMultiline(true)
	self.objectivesEntry:SetFont("ixComputerDOSBody")
	self.objectivesEntry:SetUpdateOnType(true)
	self.objectivesEntry.OnValueChange = function()
		self:PlayTypeSound()
	end

	self.dataEntry = self:Add("DTextEntry")
	self.dataEntry:SetMultiline(true)
	self.dataEntry:SetFont("ixComputerDOSBody")
	self.dataEntry:SetUpdateOnType(true)
	self.dataEntry.OnValueChange = function()
		self:PlayTypeSound()
	end

	self.objectiveSaveButton = self:Add("DButton")
	self.objectiveSaveButton:SetText(L("interactiveComputerSaveObjectives"))
	self.objectiveSaveButton:SetFont("ixComputerDOSBody")
	self.objectiveSaveButton:SetTextColor(COMBINE_TEXT)
	self.objectiveSaveButton.DoClick = function()
		if (!IsValid(self.entity) or !self.context.canEditObjectives) then
			return
		end

		netstream.Start("ixInteractiveComputerUpdateObjectives", self.entity, string.sub(self.objectivesEntry:GetValue(), 1, 2000))
	end

	self.dataSaveButton = self:Add("DButton")
	self.dataSaveButton:SetText(L("interactiveComputerSaveData"))
	self.dataSaveButton:SetFont("ixComputerDOSBody")
	self.dataSaveButton:SetTextColor(COMBINE_TEXT)
	self.dataSaveButton.DoClick = function()
		if (!IsValid(self.entity) or !self.context.canEditData or !IsValid(self.selectedTarget)) then
			return
		end

		netstream.Start("ixInteractiveComputerUpdateData", self.entity, self.selectedTarget, string.sub(self.dataEntry:GetValue(), 1, 1000))
	end

	self.personalLogButton = self:Add("DButton")
	self.personalLogButton:SetText(L("interactiveComputerPersonalLog"))
	self.personalLogButton:SetFont("ixComputerDOSBody")
	self.personalLogButton:SetTextColor(COMBINE_TEXT)
	self.personalLogButton.DoClick = function()
		if (!OpenComputerUI or !IsValid(self.entity)) then
			return
		end

		OpenComputerUI(self.entity, self.context.journalData or PLUGIN:CreateDefaultData(), self.entity:GetNetVar("powered", true), {
			combineJournal = true,
			fromCombine = true,
			returnContext = self.context
		})
	end

	self.publicPanelButton = self:Add("DButton")
	self.publicPanelButton:SetText(L("interactiveComputerPublicPanel"))
	self.publicPanelButton:SetFont("ixComputerDOSBody")
	self.publicPanelButton:SetTextColor(COMBINE_TEXT)
	self.publicPanelButton.DoClick = function()
		if (!OpenComputerUI or !IsValid(self.entity)) then
			return
		end

		OpenComputerUI(self.entity, self.entity:GetComputerData(), self.entity:GetNetVar("powered", true), {
			civicPanel = true,
			canEdit = LocalPlayer():IsCombine() or LocalPlayer():IsAdmin(),
			canAsk = true,
			data = self.context.civicData or {},
			fromCombine = true,
			returnContext = self.context
		})
	end
end

function COMBINE:PlayTypeSound()
	if (self.nextTypeSound > CurTime()) then
		return
	end

	surface.PlaySound(TYPE_SOUND)
	self.nextTypeSound = CurTime() + 0.05
end

function COMBINE:Paint(width, height)
	surface.SetDrawColor(COMBINE_BG)
	surface.DrawRect(0, 0, width, height)

	surface.SetDrawColor(COMBINE_TEXT.r, COMBINE_TEXT.g, COMBINE_TEXT.b, 28)
	for y = 0, height, 6 do
		surface.DrawRect(0, y, width, 1)
	end

	surface.SetDrawColor(COMBINE_TEXT.r, COMBINE_TEXT.g, COMBINE_TEXT.b, 70)
	surface.DrawOutlinedRect(0, 0, width, height, 2)

	draw.SimpleText(L("interactiveComputerCombineTitle"), "ixComputerDOSHeader", 22, 20, COMBINE_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	draw.SimpleText(GetTerminalTime(), "ixComputerDOSTiny", 22, 50, COMBINE_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	draw.SimpleText(L("interactiveComputerObjectives"), "ixComputerDOSTiny", width * 0.33, 74, COMBINE_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	draw.SimpleText(L("interactiveComputerCivilData"), "ixComputerDOSTiny", width * 0.33, height * 0.53, COMBINE_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end

function COMBINE:PerformLayout(width, height)
	self.closeButton:SetPos(width - 58, 14)
	self.closeButton:SetSize(40, 32)

	self.powerButton:SetPos(width - 168, 14)
	self.powerButton:SetSize(100, 32)

	self.statusLabel:SetPos(22, height - 28)
	self.statusLabel:SetSize(width - 44, 20)

	local left = 22
	local top = 92
	local rosterWidth = math.floor(width * 0.28)
	local rightX = left + rosterWidth + 18
	local rightWidth = width - rightX - 22
	local lowerY = math.floor(height * 0.56)

	self.rosterList:SetPos(left, top)
	self.rosterList:SetSize(rosterWidth, height - top - 54)

	self.objectivesEntry:SetPos(rightX, top)
	self.objectivesEntry:SetSize(rightWidth, math.floor(height * 0.34))

	self.objectiveSaveButton:SetPos(rightX + rightWidth - 200, top + math.floor(height * 0.34) + 8)
	self.objectiveSaveButton:SetSize(200, 30)

	self.dataEntry:SetPos(rightX, lowerY)
	self.dataEntry:SetSize(rightWidth, height - lowerY - 86)

	self.dataSaveButton:SetPos(rightX + rightWidth - 170, height - 68)
	self.dataSaveButton:SetSize(170, 30)

	self.personalLogButton:SetPos(left, 44)
	self.personalLogButton:SetSize(170, 30)

	self.publicPanelButton:SetPos(left + 180, 44)
	self.publicPanelButton:SetSize(170, 30)
end

function COMBINE:PopulateSelectedData()
	local selectedData = ""

	for _, entry in ipairs(self.context.roster or {}) do
		if (entry.target == self.selectedTarget) then
			selectedData = entry.data and entry.data.text or ""
			self.statusLabel:SetText(string.format("UNIT: %s | CID: %s", entry.name or "UNKNOWN", entry.cid or "00000"))
			break
		end
	end

	self.dataEntry:SetText(selectedData)
end

function COMBINE:LoadComputer(entity, _, powered, context)
	if (!powered) then
		self:Close()
		return
	end

	self.entity = entity
	self.context = context or {}
	self.rosterList:Clear()
	self.selectedTarget = nil

	for _, entry in ipairs(self.context.roster or {}) do
		local line = self.rosterList:AddLine(string.format("%s [#%s]", entry.name or "UNKNOWN", entry.cid or "00000"))
		line.Paint = function(self, width, height)
			local selected = self:IsSelected()

			surface.SetDrawColor(selected and Color(24, 52, 84, 255) or Color(0, 0, 0, 0))
			surface.DrawRect(0, 0, width, height)
			surface.SetDrawColor(COMBINE_TEXT.r, COMBINE_TEXT.g, COMBINE_TEXT.b, selected and 90 or 18)
			surface.DrawOutlinedRect(0, 0, width, height, 1)
		end

		if (line.Columns) then
			for _, column in ipairs(line.Columns) do
				column:SetTextColor(COMBINE_TEXT)
				column:SetFont("ixComputerDOSTiny")
			end
		end

		line.ixTarget = entry.target
	end

	self.objectivesEntry:SetText((self.context.objectives and self.context.objectives.text) or "")
	self.objectivesEntry:SetEnabled(self.context.canEditObjectives == true)
	self.dataEntry:SetEnabled(self.context.canEditData == true)
	self.objectiveSaveButton:SetVisible(self.context.canEditObjectives == true)
	self.dataSaveButton:SetVisible(self.context.canEditData == true)

	if (self.rosterList:GetLine(1)) then
		self.rosterList:SelectItem(self.rosterList:GetLine(1))
	end

	if (!self.selectedTarget) then
		self.dataEntry:SetText("")
		self.statusLabel:SetText(L("interactiveComputerNoRoster"))
	end
end

function COMBINE:Think()
	if (IsValid(self.entity) and LocalPlayer():GetPos():DistToSqr(self.entity:GetPos()) > 190 * 190) then
		self:Close()
	end
end

function COMBINE:OnRemove()
	if (IsValid(self.entity)) then
		netstream.Start("ixInteractiveComputerEndUse", self.entity)
	end

	if (ix.gui.interactiveComputer == self) then
		ix.gui.interactiveComputer = nil
	end
end

vgui.Register("ixInteractiveCombineTerminal", COMBINE, "DFrame")

local CIVIC = {}

function CIVIC:Init()
	self:SetSize(math.min(ScrW() - 180, 1120), math.min(ScrH() - 140, 760))
	self:SetTitle("")
	self:ShowCloseButton(false)
	self:SetDraggable(false)

	self.nextTypeSound = 0
	self.context = {}

	self.closeButton = self:Add("DButton")
	self.closeButton:SetText("X")
	self.closeButton:SetFont("ixComputerDOSBody")
	self.closeButton:SetTextColor(COMBINE_TEXT)
	self.closeButton.DoClick = function()
		self:Close()
	end

	self.powerButton = self:Add("DButton")
	self.powerButton:SetText("POWER")
	self.powerButton:SetFont("ixComputerDOSBody")
	self.powerButton:SetTextColor(COMBINE_TEXT)
	self.powerButton.DoClick = function()
		if (IsValid(self.entity)) then
			netstream.Start("ixInteractiveComputerPower", self.entity, false)
		end

		self:Close()
	end

	self.backButton = self:Add("DButton")
	self.backButton:SetText(L("interactiveComputerBack"))
	self.backButton:SetFont("ixComputerDOSBody")
	self.backButton:SetTextColor(COMBINE_TEXT)
	self.backButton:SetVisible(false)
	self.backButton.DoClick = function()
		if (self.context and self.context.returnContext and OpenComputerUI) then
			OpenComputerUI(self.entity, self.entity and self.entity:GetComputerData() or {}, IsValid(self.entity) and self.entity:GetNetVar("powered", true), self.context.returnContext)
		end
	end

	self.statusLabel = self:Add("DLabel")
	self.statusLabel:SetFont("ixComputerDOSTiny")
	self.statusLabel:SetTextColor(COMBINE_DIM)
	self.statusLabel:SetText("")

	self.announcementEntry = self:Add("DTextEntry")
	self.announcementEntry:SetMultiline(true)
	self.announcementEntry:SetFont("ixComputerDOSBody")
	self.announcementEntry:SetUpdateOnType(true)
	self.announcementEntry.OnValueChange = function()
		self:PlayTypeSound()
	end

	self.propagandaEntry = self:Add("DTextEntry")
	self.propagandaEntry:SetMultiline(true)
	self.propagandaEntry:SetFont("ixComputerDOSBody")
	self.propagandaEntry:SetUpdateOnType(true)
	self.propagandaEntry.OnValueChange = function()
		self:PlayTypeSound()
	end

	self.saveButton = self:Add("DButton")
	self.saveButton:SetText(L("interactiveComputerSaveCivic"))
	self.saveButton:SetFont("ixComputerDOSBody")
	self.saveButton:SetTextColor(COMBINE_TEXT)
	self.saveButton.DoClick = function()
		if (!IsValid(self.entity) or !self.context.canEdit) then
			return
		end

		netstream.Start(
			"ixInteractiveComputerSaveCivicPanel",
			self.entity,
			string.sub(self.announcementEntry:GetValue(), 1, 1500),
			string.sub(self.propagandaEntry:GetValue(), 1, 1500)
		)
	end

	self.questionEntry = self:Add("DTextEntry")
	self.questionEntry:SetFont("ixComputerDOSBody")
	self.questionEntry:SetUpdateOnType(true)
	self.questionEntry.OnValueChange = function()
		self:PlayTypeSound()
	end

	self.askButton = self:Add("DButton")
	self.askButton:SetText(L("interactiveComputerAskQuestion"))
	self.askButton:SetFont("ixComputerDOSBody")
	self.askButton:SetTextColor(COMBINE_TEXT)
	self.askButton.DoClick = function()
		if (!IsValid(self.entity) or !self.context.canAsk) then
			return
		end

		local text = string.Trim(self.questionEntry:GetValue())
		if (text == "") then
			return
		end

		netstream.Start("ixInteractiveComputerAskQuestion", self.entity, text)
		self.questionEntry:SetText("")
	end

	self.questionList = self:Add("DListView")
	self.questionList:SetHeaderHeight(22)
	self.questionList:SetDataHeight(48)
	self.questionList:AddColumn(L("interactiveComputerQuestions"))
	self.questionList.OnRowSelected = function(_, _, row)
		self.selectedQuestionIndex = row.ixQuestionIndex
		self.answerEntry:SetText(row.ixAnswer or "")
		self:UpdateStatus()
	end

	self.answerEntry = self:Add("DTextEntry")
	self.answerEntry:SetMultiline(true)
	self.answerEntry:SetFont("ixComputerDOSBody")
	self.answerEntry:SetUpdateOnType(true)
	self.answerEntry.OnValueChange = function()
		self:PlayTypeSound()
	end

	self.answerButton = self:Add("DButton")
	self.answerButton:SetText(L("interactiveComputerAnswerQuestion"))
	self.answerButton:SetFont("ixComputerDOSBody")
	self.answerButton:SetTextColor(COMBINE_TEXT)
	self.answerButton.DoClick = function()
		if (!IsValid(self.entity) or !self.context.canEdit or !self.selectedQuestionIndex) then
			return
		end

		netstream.Start(
			"ixInteractiveComputerAnswerQuestion",
			self.entity,
			self.selectedQuestionIndex,
			string.sub(self.answerEntry:GetValue(), 1, 500)
		)
	end

	self:Center()
	self:MakePopup()
end

function CIVIC:PlayTypeSound()
	if (self.nextTypeSound > CurTime()) then
		return
	end

	surface.PlaySound(TYPE_SOUND)
	self.nextTypeSound = CurTime() + 0.05
end

function CIVIC:Paint(width, height)
	surface.SetDrawColor(COMBINE_BG)
	surface.DrawRect(0, 0, width, height)

	surface.SetDrawColor(COMBINE_TEXT.r, COMBINE_TEXT.g, COMBINE_TEXT.b, 24)
	for y = 0, height, 6 do
		surface.DrawRect(0, y, width, 1)
	end

	surface.SetDrawColor(COMBINE_TEXT.r, COMBINE_TEXT.g, COMBINE_TEXT.b, 70)
	surface.DrawOutlinedRect(0, 0, width, height, 2)

	draw.SimpleText(L("interactiveComputerCivicTitle"), "ixComputerDOSHeader", 22, 20, COMBINE_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	draw.SimpleText(GetTerminalTime(), "ixComputerDOSTiny", 22, 50, COMBINE_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	draw.SimpleText(L("interactiveComputerAnnouncement"), "ixComputerDOSTiny", 22, 74, COMBINE_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	draw.SimpleText(L("interactiveComputerPropaganda"), "ixComputerDOSTiny", width * 0.5 + 12, 74, COMBINE_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	draw.SimpleText(L("interactiveComputerQuestions"), "ixComputerDOSTiny", 22, height * 0.47, COMBINE_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end

function CIVIC:PerformLayout(width, height)
	if (!self.closeButton or !self.powerButton or !self.backButton or !self.statusLabel) then
		return
	end

	self.closeButton:SetPos(width - 58, 14)
	self.closeButton:SetSize(40, 32)

	self.powerButton:SetPos(width - 168, 14)
	self.powerButton:SetSize(100, 32)

	self.backButton:SetPos(width - 278, 14)
	self.backButton:SetSize(100, 32)

	self.statusLabel:SetPos(22, height - 28)
	self.statusLabel:SetSize(width - 44, 20)

	local panelWidth = math.floor((width - 54) * 0.5)
	local top = 92
	local upperHeight = math.floor(height * 0.26)
	local questionY = math.floor(height * 0.5)
	local questionHeight = height - questionY - 108

	self.announcementEntry:SetPos(22, top)
	self.announcementEntry:SetSize(panelWidth, upperHeight)

	self.propagandaEntry:SetPos(32 + panelWidth, top)
	self.propagandaEntry:SetSize(panelWidth, upperHeight)

	self.saveButton:SetPos(width - 202, top + upperHeight + 8)
	self.saveButton:SetSize(180, 30)

	self.questionEntry:SetPos(22, questionY)
	self.questionEntry:SetSize(width * 0.55, 28)

	self.askButton:SetPos(30 + width * 0.55, questionY)
	self.askButton:SetSize(170, 28)

	self.questionList:SetPos(22, questionY + 38)
	self.questionList:SetSize(width * 0.55, questionHeight)

	self.answerEntry:SetPos(32 + width * 0.55, questionY + 38)
	self.answerEntry:SetSize(width - (54 + width * 0.55), questionHeight - 40)

	self.answerButton:SetPos(width - 212, height - 68)
	self.answerButton:SetSize(190, 30)
end

function CIVIC:PopulateQuestions()
	self.questionList:Clear()
	self.selectedQuestionIndex = nil
	self.answerEntry:SetText("")

	local questions = (self.context.data and self.context.data.questions) or {}
	for index, entry in ipairs(questions) do
		local asker = entry.asker or "UNKNOWN"
		local prompt = string.format("[%s] %s", asker, entry.question or "")
		local line = self.questionList:AddLine(prompt)
		line.ixQuestionIndex = index
		line.ixAnswer = entry.answer or ""
		line.Paint = function(row, rowWidth, rowHeight)
			local selected = row:IsSelected()

			surface.SetDrawColor(selected and Color(24, 52, 84, 255) or Color(0, 0, 0, 0))
			surface.DrawRect(0, 0, rowWidth, rowHeight)
			surface.SetDrawColor(COMBINE_TEXT.r, COMBINE_TEXT.g, COMBINE_TEXT.b, selected and 90 or 18)
			surface.DrawOutlinedRect(0, 0, rowWidth, rowHeight, 1)
		end

		if (line.Columns) then
			for _, column in ipairs(line.Columns) do
				column:SetTextColor(COMBINE_TEXT)
				column:SetFont("ixComputerDOSTiny")
			end
		end
	end

	if (self.questionList:GetLine(1)) then
		self.questionList:SelectItem(self.questionList:GetLine(1))
	else
		self.statusLabel:SetText(L("interactiveComputerNoQuestions"))
	end
end

function CIVIC:UpdateStatus()
	if (!self.selectedQuestionIndex) then
		self.statusLabel:SetText(L("interactiveComputerNoQuestions"))
		return
	end

	local question = self.context.data and self.context.data.questions and self.context.data.questions[self.selectedQuestionIndex]
	if (!question) then
		self.statusLabel:SetText(L("interactiveComputerNoQuestions"))
		return
	end

	self.statusLabel:SetText(string.format("ASKER: %s", question.asker or "UNKNOWN"))
end

function CIVIC:LoadComputer(entity, _, powered, context)
	if (!powered) then
		self:Close()
		return
	end

	self.entity = entity
	self.context = context or {}
	self.announcementEntry:SetText((self.context.data and self.context.data.announcement) or "")
	self.propagandaEntry:SetText((self.context.data and self.context.data.propaganda) or "")
	self.announcementEntry:SetEnabled(self.context.canEdit == true)
	self.propagandaEntry:SetEnabled(self.context.canEdit == true)
	self.saveButton:SetVisible(self.context.canEdit == true)
	self.questionEntry:SetEnabled(self.context.canAsk == true)
	self.askButton:SetVisible(self.context.canAsk == true)
	self.answerEntry:SetEnabled(self.context.canEdit == true)
	self.answerButton:SetVisible(self.context.canEdit == true)
	self.backButton:SetVisible(self.context.fromCombine == true)
	self:PopulateQuestions()
end

function CIVIC:Think()
	if (IsValid(self.entity) and LocalPlayer():GetPos():DistToSqr(self.entity:GetPos()) > 190 * 190) then
		self:Close()
	end
end

function CIVIC:OnRemove()
	if (IsValid(self.entity)) then
		netstream.Start("ixInteractiveComputerEndUse", self.entity)
	end

	if (ix.gui.interactiveComputer == self) then
		ix.gui.interactiveComputer = nil
	end
end

vgui.Register("ixInteractiveCivicTerminal", CIVIC, "DFrame")

local function ApplyCivicStyling(frame)
	StyleCombineButton(frame.closeButton)
	StyleCombineButton(frame.powerButton)
	StyleCombineButton(frame.backButton)
	StyleCombineButton(frame.saveButton)
	StyleCombineButton(frame.askButton)
	StyleCombineButton(frame.answerButton)
	StyleCombineTextEntry(frame.announcementEntry)
	StyleCombineTextEntry(frame.propagandaEntry)
	StyleCombineTextEntry(frame.questionEntry)
	StyleCombineTextEntry(frame.answerEntry)
	StyleCombineListView(frame.questionList)
end

OpenComputerUI = function(entity, data, powered, context)
	if (IsValid(ix.gui.interactiveComputer)) then
		ix.gui.interactiveComputer:Remove()
	end

	local frameClass = "ixInteractiveComputerTerminal"

	if (context and context.civicPanel) then
		frameClass = "ixInteractiveCivicTerminal"
	elseif (context and context.combineTerminal) then
		frameClass = "ixInteractiveCombineTerminal"
	end

	local frame = vgui.Create(frameClass)

	if (frameClass == "ixInteractiveCombineTerminal") then
		ApplyCombineStyling(frame)
		frame:LoadComputer(entity, data, powered, context)
	elseif (frameClass == "ixInteractiveCivicTerminal") then
		ApplyCivicStyling(frame)
		frame:LoadComputer(entity, data, powered, context)
	else
		ApplyTerminalStyling(frame)
		frame:LoadComputerContext(entity, data, powered, context)
	end

	ix.gui.interactiveComputer = frame
end

netstream.Hook("ixInteractiveComputerOpen", function(entity, data, powered, context)
	if (!IsValid(entity)) then
		return
	end

	OpenComputerUI(entity, data, powered, context)
end)

netstream.Hook("ixInteractiveComputerSync", function(entity, data, powered, context)
	if (!IsValid(entity)) then
		if (IsValid(ix.gui.interactiveComputer)) then
			ix.gui.interactiveComputer:Remove()
		end
		return
	end

	if (!IsValid(ix.gui.interactiveComputer) or ix.gui.interactiveComputer.entity ~= entity) then
		OpenComputerUI(entity, data, powered, context)
		return
	end

	ix.gui.interactiveComputer:LoadComputer(entity, data, powered, context)
end)

netstream.Hook("ixInteractiveComputerSyncCombineJournal", function(entity, data, context)
	if (!IsValid(entity)) then
		return
	end

	if (!IsValid(ix.gui.interactiveComputer) or !ix.gui.interactiveComputer.context or !ix.gui.interactiveComputer.context.combineJournal) then
		OpenComputerUI(entity, data, entity:GetNetVar("powered", true), {
			combineJournal = true,
			fromCombine = true,
			returnContext = context
		})
		return
	end

	ix.gui.interactiveComputer:LoadComputerContext(entity, data, entity:GetNetVar("powered", true), {
		combineJournal = true,
		fromCombine = true,
		returnContext = context
	})
end)
