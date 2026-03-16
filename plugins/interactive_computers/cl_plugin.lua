local PLUGIN = PLUGIN

surface.CreateFont("ixComputerDOSHeader", {
	font = "Lucida Console",
	size = 21,
	weight = 700,
	extended = true,
	antialias = true
})

surface.CreateFont("ixComputerDOSBody", {
	font = "Lucida Console",
	size = 16,
	weight = 600,
	extended = true,
	antialias = true
})

surface.CreateFont("ixComputerDOSTiny", {
	font = "Lucida Console",
	size = 13,
	weight = 500,
	extended = true,
	antialias = true
})

surface.CreateFont("ixComputerShellTitle", {
	font = "Verdana",
	size = 18,
	weight = 800,
	extended = true,
	antialias = true
})

surface.CreateFont("ixComputerShellBody", {
	font = "Verdana",
	size = 15,
	weight = 600,
	extended = true,
	antialias = true
})

surface.CreateFont("ixComputerCombineHeader", {
	font = "Trebuchet MS",
	size = 28,
	weight = 900,
	extended = true,
	antialias = true
})

surface.CreateFont("ixComputerCombineGrid", {
	font = "Combine 17",
	size = 26,
	weight = 700,
	extended = true,
	antialias = true
})

surface.CreateFont("ixComputerCombineBody", {
	font = "Trebuchet MS",
	size = 16,
	weight = 700,
	extended = true,
	antialias = true
})

local COLOR_BG = Color(190, 194, 198, 252)
local COLOR_PANEL = Color(170, 174, 178, 245)
local COLOR_TEXT = Color(80, 255, 118)
local COLOR_DIM = Color(45, 120, 62)
local COLOR_ACCENT = Color(46, 82, 164, 255)
local COLOR_SHELL = Color(196, 198, 202)
local COLOR_SHELL_DARK = Color(118, 122, 128)
local COLOR_SHELL_LIGHT = Color(238, 240, 244)
local COLOR_SHELL_FACE = Color(210, 214, 218)
local COLOR_CRT = Color(7, 18, 10, 255)
local COLOR_DOS_BG = Color(6, 10, 6, 252)
local COLOR_DOS_SCAN = Color(92, 236, 124, 10)
local COLOR_DOS_TEXT = Color(92, 236, 124)
local COLOR_DOS_DIM = Color(58, 146, 76)
local COMBINE_BG = Color(8, 16, 28, 246)
local COMBINE_PANEL = Color(14, 24, 38, 240)
local COMBINE_TEXT = Color(115, 200, 255)
local COMBINE_DIM = Color(90, 138, 178)
local COMBINE_ACCENT = Color(36, 104, 168)
local COMBINE_GLOW = Color(70, 170, 255, 35)
local COMBINE_LOGO = Material("vgui/hl2rp/terminal/cmb_logo_white.png", "smooth mips")
local COMBINE_LOGO_TEXTURE_OFFSET_X = -20
local COMBINE_JOURNAL_TOP = 84
local TYPE_SOUNDS = {
	"ambient/machines/keyboard1_clicks.wav",
	"ambient/machines/keyboard2_clicks.wav",
	"ambient/machines/keyboard3_clicks.wav",
	"ambient/machines/keyboard4_clicks.wav",
	"ambient/machines/keyboard5_clicks.wav",
	"ambient/machines/keyboard6_clicks.wav"
}
local TYPE_SOUND_ENTER = "ambient/machines/keyboard7_clicks_enter.wav"
local COMBINE_BOOT_SOUND = "ambient/machines/combine_terminal_idle3.wav"

local StyleLine
local OpenComputerUI
local PANEL = {}
local JOURNAL = {}
local UNIFIED_TERMINAL_WIDTH = math.min(ScrW() - 160, 1220)
local UNIFIED_TERMINAL_HEIGHT = math.min(ScrH() - 120, 780)

local function GetTerminalTime()
	if (ix and ix.date and ix.date.GetLocalizedTime) then
		return ix.date.GetLocalizedTime()
	end

	return os.date("%Y-%m-%d %H:%M:%S")
end

local function DrawInsetBox(x, y, width, height, dark, light, fill)
	surface.SetDrawColor(fill)
	surface.DrawRect(x, y, width, height)
	surface.SetDrawColor(dark)
	surface.DrawRect(x, y + height - 2, width, 2)
	surface.DrawRect(x + width - 2, y, 2, height)
	surface.SetDrawColor(light)
	surface.DrawRect(x, y, width, 2)
	surface.DrawRect(x, y, 2, height)
end

local function DrawRaisedBox(x, y, width, height, dark, light, fill)
	surface.SetDrawColor(fill)
	surface.DrawRect(x, y, width, height)
	surface.SetDrawColor(light)
	surface.DrawRect(x, y, width, 2)
	surface.DrawRect(x, y, 2, height)
	surface.SetDrawColor(dark)
	surface.DrawRect(x, y + height - 2, width, 2)
	surface.DrawRect(x + width - 2, y, 2, height)
end

local function ClearBootState(frame)
	frame.bootStartTime = nil
	frame.bootSendTime = nil
	frame.bootFinishTime = nil
	frame.bootRequested = false
end

local function IsBootSequenceActive(frame)
	return frame.bootFinishTime != nil
end

local function IsTerminalReady(frame)
	return frame.powered == true and !IsBootSequenceActive(frame)
end

local function SetTerminalPowerState(frame, powered)
	frame.powered = powered == true

	if (!frame.powered) then
		ClearBootState(frame)
		return
	end

	if (!IsBootSequenceActive(frame) or CurTime() >= frame.bootFinishTime) then
		ClearBootState(frame)
	end
end

local function StartBootSequence(frame, duration)
	if (frame.powered == true or IsBootSequenceActive(frame)) then
		return
	end

	duration = duration or 1.9
	frame.bootStartTime = CurTime()
	frame.bootSendTime = frame.bootStartTime + math.min(duration * 0.45, 0.9)
	frame.bootFinishTime = frame.bootStartTime + duration
	frame.bootRequested = false

	local screenMode = frame.GetPowerScreenMode and frame:GetPowerScreenMode() or "general"
	if (screenMode == "combine" or screenMode == "civic") then
		surface.PlaySound(COMBINE_BOOT_SOUND)
	end
end

local function PlayKeyboardSound(isEnter)
	surface.PlaySound(isEnter and TYPE_SOUND_ENTER or TYPE_SOUNDS[math.random(#TYPE_SOUNDS)])
end

local function BindEnterSound(entry, frame)
	if (!IsValid(entry) or !frame or entry.ixEnterSoundBound) then
		return
	end

	local oldOnKeyCodeTyped = entry.OnKeyCodeTyped
	entry.OnKeyCodeTyped = function(self, code)
		if (code == KEY_ENTER or code == KEY_PAD_ENTER) then
			frame:PlayTypeSound(true)
		end

		if (oldOnKeyCodeTyped) then
			return oldOnKeyCodeTyped(self, code)
		end
	end

	entry.ixEnterSoundBound = true
end

local function BindButtonClickSound(button, frame)
	if (!IsValid(button) or !frame or button.ixClickSoundBound) then
		return
	end

	local oldDoClick = button.DoClick
	button.DoClick = function(...)
		local shouldPlay = true
		if (button == frame.powerButton or button == frame.closeButton) then
			shouldPlay = IsTerminalReady(frame)
		elseif (!IsTerminalReady(frame)) then
			shouldPlay = false
		end

		if (shouldPlay) then
			frame:PlayTypeSound(true)
		end

		if (oldDoClick) then
			return oldDoClick(...)
		end
	end

	button.ixClickSoundBound = true
end

local function ScrollVBar(vBar, amount)
	if (IsValid(vBar)) then
		vBar:SetScroll(math.max(0, vBar:GetScroll() + amount))
	end
end

local function BindScrollHoldButton(button, getVBar, amount)
	if (!IsValid(button) or button.ixHoldScrollBound) then
		return
	end

	button.DoClick = function()
		ScrollVBar(getVBar(), amount)
	end

	button.OnDepressed = function(self)
		self.ixHoldScrollNext = CurTime() + 0.35
	end

	button.OnReleased = function(self)
		self.ixHoldScrollNext = nil
	end

	button.Think = function(self)
		if (!self:IsDown() or (self.ixHoldScrollNext or math.huge) > CurTime()) then
			return
		end

		ScrollVBar(getVBar(), amount)
		self.ixHoldScrollNext = CurTime() + 0.07
	end

	button.ixHoldScrollBound = true
end

local function HasInteractiveKeyboard(frame)
	if (!frame or !IsValid(frame.entity) or (frame.context and frame.context.combineJournal)) then
		return true
	end

	local definition = PLUGIN:GetComputerDefinition(frame.entity:GetClass())
	if (!definition or definition.family != "general") then
		return true
	end

	return IsValid(PLUGIN:FindNearestSupportComputer(frame.entity, "keyboard"))
end

local function UpdateBootSequence(frame)
	if (!IsBootSequenceActive(frame)) then
		return
	end

	local currentTime = CurTime()

	if (!frame.bootRequested and currentTime >= frame.bootSendTime and IsValid(frame.entity)) then
		frame.bootRequested = true
		netstream.Start("ixInteractiveComputerPower", frame.entity, true, frame.GetPowerScreenMode and frame:GetPowerScreenMode() or nil)
	end

	local powered = frame.powered == true or (IsValid(frame.entity) and frame.entity:GetNetVar("powered", false))
	if (powered and currentTime >= frame.bootFinishTime) then
		frame.powered = true
		ClearBootState(frame)
		return
	end

	if (!powered and frame.bootRequested and currentTime >= frame.bootFinishTime + 1.5) then
		frame.powered = false
		ClearBootState(frame)
	end
end

local function GetBootProgress(frame)
	if (!IsBootSequenceActive(frame) or !frame.bootStartTime or !frame.bootFinishTime) then
		return 0
	end

	return math.Clamp(math.TimeFraction(frame.bootStartTime, frame.bootFinishTime, CurTime()), 0, 1)
end

local function DrawFilledCircle(centerX, centerY, radius, segments)
	segments = math.max(segments or 48, 12)

	local points = {}
	points[1] = {x = centerX, y = centerY}

	for index = 0, segments do
		local angle = math.rad((index / segments) * -360)
		points[#points + 1] = {
			x = centerX + math.cos(angle) * radius,
			y = centerY + math.sin(angle) * radius
		}
	end

	surface.DrawPoly(points)
end

local function DrawCombineLogo(centerX, centerY, size, alpha)
	alpha = alpha or 255

	if (COMBINE_LOGO and !COMBINE_LOGO:IsError()) then
		local drawSize = size * 2.25
		surface.SetMaterial(COMBINE_LOGO)
		surface.SetDrawColor(COMBINE_TEXT.r, COMBINE_TEXT.g, COMBINE_TEXT.b, alpha)
		surface.DrawTexturedRect(centerX - drawSize * 0.5 + COMBINE_LOGO_TEXTURE_OFFSET_X, centerY - drawSize * 0.5, drawSize, drawSize)
		return
	end

	draw.NoTexture()
	surface.SetDrawColor(COMBINE_TEXT.r, COMBINE_TEXT.g, COMBINE_TEXT.b, alpha)

	surface.DrawPoly({
		{x = centerX - size * 0.20, y = centerY - size * 1.05},
		{x = centerX + size * 0.78, y = centerY - size * 0.16},
		{x = centerX + size * 0.78, y = centerY + size * 0.96},
		{x = centerX - size * 0.14, y = centerY + size * 0.96},
		{x = centerX - size * 0.42, y = centerY + size * 0.18},
		{x = centerX - size * 0.18, y = centerY - size * 0.18}
	})

	surface.DrawPoly({
		{x = centerX - size * 0.96, y = centerY - size * 0.28},
		{x = centerX - size * 0.42, y = centerY + size * 0.18},
		{x = centerX - size * 0.14, y = centerY + size * 0.96},
		{x = centerX - size * 0.62, y = centerY + size * 0.96}
	})

	DrawFilledCircle(centerX + size * 0.02, centerY + size * 0.12, size * 0.42, 48)

	surface.SetDrawColor(COMBINE_PANEL.r, COMBINE_PANEL.g, COMBINE_PANEL.b, alpha)
	DrawFilledCircle(centerX + size * 0.02, centerY + size * 0.12, size * 0.30, 48)
end

local function DrawCombineBackdrop(width, height, title, subtitle)
	surface.SetDrawColor(COMBINE_BG)
	surface.DrawRect(0, 0, width, height)

	surface.SetDrawColor(COMBINE_ACCENT.r, COMBINE_ACCENT.g, COMBINE_ACCENT.b, 24)
	for y = 0, height, 10 do
		surface.DrawRect(0, y, width, 1)
	end

	surface.SetDrawColor(COMBINE_ACCENT)
	surface.DrawRect(0, 0, width, 4)
	surface.DrawRect(0, 78, width, 1)
	surface.DrawRect(0, height - 42, width, 1)

	surface.SetDrawColor(COMBINE_TEXT.r, COMBINE_TEXT.g, COMBINE_TEXT.b, 70)
	surface.DrawOutlinedRect(0, 0, width, height, 2)

	draw.SimpleText(title, "ixComputerCombineHeader", 22, 16, COMBINE_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	if (subtitle and subtitle != "") then
		if (subtitle == "overwatch grid") then
			surface.SetFont("ixComputerCombineGrid")

			local subtitleWidth = surface.GetTextSize(subtitle)
			draw.SimpleText(subtitle, "ixComputerCombineGrid", 24, 48, COMBINE_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			draw.SimpleText(" - " .. GetTerminalTime(), "ixComputerCombineBody", 24 + subtitleWidth + 8, 52, COMBINE_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		else
			draw.SimpleText(subtitle .. " " .. GetTerminalTime(), "ixComputerCombineBody", 24, 52, COMBINE_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		end
	else
		draw.SimpleText(GetTerminalTime(), "ixComputerCombineBody", 24, 52, COMBINE_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end
end

local function PaintCombineContentBox(x, y, width, height)
	surface.SetDrawColor(COMBINE_PANEL)
	surface.DrawRect(x, y, width, height)
	surface.SetDrawColor(COMBINE_ACCENT.r, COMBINE_ACCENT.g, COMBINE_ACCENT.b, 14)
	for offsetY = y, y + height, 8 do
		surface.DrawRect(x, offsetY, width, 1)
	end
	surface.SetDrawColor(COMBINE_TEXT.r, COMBINE_TEXT.g, COMBINE_TEXT.b, 24)
	surface.DrawOutlinedRect(x, y, width, height, 1)
end

local function SplitCommandInput(rawText)
	rawText = string.Trim(tostring(rawText or ""))
	if (rawText == "") then
		return "", ""
	end

	local command, remainder = rawText:match("^(%S+)%s*(.-)%s*$")

	return string.lower(command or ""), remainder or ""
end

local function TokenizeArguments(rawText)
	local arguments = {}

	for argument in string.gmatch(rawText or "", "%S+") do
		arguments[#arguments + 1] = argument
	end

	return arguments
end

local function NormalizeLookupToken(rawText)
	return string.upper(string.Trim(tostring(rawText or "")))
end

function PANEL:Init()
	self:SetSize(UNIFIED_TERMINAL_WIDTH, UNIFIED_TERMINAL_HEIGHT)
	self:Center()
	self:MakePopup()
	self:SetTitle("")
	self:ShowCloseButton(false)
	self:SetDraggable(false)

	self.data = {categories = {}}
	self.selectedCategory = 1
	self.selectedEntry = 1
	self.nextTypeSound = 0
	self.powered = false
	self.suppressTyping = false
	self.commandHistory = {}
	self.historyIndex = nil
	self.shellInitialized = false

	self.closeButton = self:Add("DButton")
	self.closeButton:SetText("X")
	self.closeButton:SetFont("ixComputerDOSBody")
	self.closeButton:SetTextColor(Color(36, 40, 48))
	self.closeButton.DoClick = function()
		self:Close()
	end

	self.powerButton = self:Add("DButton")
	self.powerButton:SetText("⏻")
	self.powerButton:SetFont("ixComputerDOSBody")
	self.powerButton:SetTextColor(Color(36, 40, 48))
	self.powerButton.DoClick = function()
		if (!IsValid(self.entity)) then
			self:Close()
			return
		end

		if (IsTerminalReady(self)) then
			netstream.Start("ixInteractiveComputerPower", self.entity, false, self:GetPowerScreenMode())
			self:Close()
			return
		end

		StartBootSequence(self, 1.8)
		self:UpdateEditingState()
	end

	self.backButton = self:Add("DButton")
	self.backButton:SetText(L("interactiveComputerBack"))
	self.backButton:SetFont("ixComputerDOSBody")
	self.backButton:SetTextColor(COLOR_DOS_TEXT)
	self.backButton:SetVisible(false)
	self.backButton.DoClick = function()
		if (self.context and self.context.returnContext and OpenComputerUI) then
			OpenComputerUI(self.entity, nil, IsValid(self.entity) and self.entity:GetNetVar("powered", true), self.context.returnContext)
		end
	end

	self.statusLabel = self:Add("DLabel")
	self.statusLabel:SetVisible(false)

	self.output = self:Add("RichText")
	self.output.PerformLayout = function(panel)
		panel:SetFontInternal("ixComputerDOSBody")
		panel:SetFGColor(COLOR_DOS_TEXT)
		panel:SetBGColor(Color(0, 0, 0, 0))
	end

	self.promptLabel = self:Add("DLabel")
	self.promptLabel:SetFont("ixComputerDOSBody")
	self.promptLabel:SetTextColor(COLOR_DOS_TEXT)
	self.promptLabel:SetText("C:\\DOS>")

	self.commandEntry = self:Add("DTextEntry")
	self.commandEntry:SetFont("ixComputerDOSBody")
	self.commandEntry:SetUpdateOnType(true)
	self.commandEntry:SetDrawLanguageID(false)
	local oldCommandKeyCodeTyped = self.commandEntry.OnKeyCodeTyped
	self.commandEntry.OnValueChange = function()
		if (!self.suppressTyping) then
			self:PlayTypeSound()
		end
	end
	self.commandEntry.OnEnter = function(entry)
		local value = entry:GetValue()
		self.suppressTyping = true
		entry:SetText("")
		entry:SetValue("")
		self.suppressTyping = false
		self:RunCommand(value)
		timer.Simple(0, function()
			if (IsValid(entry)) then
				self:ResetCommandEntry()
			end
		end)
	end
	self.commandEntry.OnKeyCodeTyped = function(_, code)
		if (code == KEY_ENTER or code == KEY_PAD_ENTER) then
			self:PlayTypeSound(true)
		elseif (code == KEY_UP) then
			self:CycleHistory(-1)
			return
		elseif (code == KEY_DOWN) then
			self:CycleHistory(1)
			return
		end

		if (oldCommandKeyCodeTyped) then
			return oldCommandKeyCodeTyped(self.commandEntry, code)
		end
	end
end

function PANEL:Paint(width, height)
	surface.SetDrawColor(COLOR_DOS_BG)
	surface.DrawRect(0, 0, width, height)

	for y = 0, height, 3 do
		surface.SetDrawColor(COLOR_DOS_SCAN)
		surface.DrawRect(0, y, width, 1)
	end

	surface.SetDrawColor(255, 255, 255, 12)
	surface.DrawOutlinedRect(0, 0, width, height, 1)
end

function PANEL:PerformLayout(width, height)
	if (!IsValid(self.closeButton) or !IsValid(self.powerButton) or !IsValid(self.backButton) or !IsValid(self.output) or !IsValid(self.promptLabel) or !IsValid(self.commandEntry)) then
		return
	end

	self.closeButton:SetPos(width - 58, 14)
	self.closeButton:SetSize(40, 32)

	self.powerButton:SetPos(width - 112, 14)
	self.powerButton:SetSize(44, 32)

	self.backButton:SetPos(width - 166, 14)
	self.backButton:SetSize(44, 32)

	local top = 56
	local bottom = 18
	local inputHeight = 30

	self.output:SetPos(18, top)
	self.output:SetSize(width - 36, height - top - bottom - inputHeight)

	self.promptLabel:SizeToContents()
	self.promptLabel:SetPos(18, height - bottom - inputHeight + 4)

	local promptWidth = self.promptLabel:GetWide() + 8
	self.commandEntry:SetPos(18 + promptWidth, height - bottom - inputHeight)
	self.commandEntry:SetSize(width - 36 - promptWidth, inputHeight)
end

function PANEL:PaintOver(width, height)
	if (!IsTerminalReady(self)) then
		surface.SetDrawColor(6, 10, 6, 255)
		surface.DrawRect(18, 56, width - 36, height - 74)
		surface.SetDrawColor(COLOR_TEXT.r, COLOR_TEXT.g, COLOR_TEXT.b, 24)
		for y = 66, height - 24, 6 do
			surface.DrawRect(28, y, width - 56, 1)
		end
		surface.SetDrawColor(COLOR_TEXT.r, COLOR_TEXT.g, COLOR_TEXT.b, 40)
		surface.DrawOutlinedRect(18, 56, width - 36, height - 74, 1)

		local progress = GetBootProgress(self)
		local barY = math.floor(height * 0.58)
		local barWidth = width - 220

		draw.SimpleText(self.context and self.context.combineJournal and "PERSONAL LOG DOS" or "WORKSTATION DOS", "ixComputerDOSHeader", width * 0.5, height * 0.36, COLOR_DOS_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(L(IsBootSequenceActive(self) and "interactiveComputerBooting" or "interactiveComputerPowerOff"), "ixComputerDOSBody", width * 0.5, height * 0.46, COLOR_DOS_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(L(IsBootSequenceActive(self) and "interactiveComputerBooting" or "interactiveComputerPowerPrompt"), "ixComputerDOSTiny", width * 0.5, height * 0.51, COLOR_DOS_DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		DrawInsetBox(110, barY, barWidth, 18, Color(32, 32, 32), Color(120, 120, 120), Color(10, 10, 10, 255))
		surface.SetDrawColor(COLOR_DOS_TEXT.r, COLOR_DOS_TEXT.g, COLOR_DOS_TEXT.b, 120)
		surface.DrawRect(112, barY + 2, math.max(0, math.floor((barWidth - 4) * progress)), 14)
	elseif (!HasInteractiveKeyboard(self) and !(self.context and self.context.combineJournal)) then
		surface.SetDrawColor(6, 10, 6, 255)
		surface.DrawRect(18, 56, width - 36, height - 74)
		surface.SetDrawColor(COLOR_DOS_TEXT.r, COLOR_DOS_TEXT.g, COLOR_DOS_TEXT.b, 28)
		for y = 66, height - 24, 6 do
			surface.DrawRect(28, y, width - 56, 1)
		end
		surface.SetDrawColor(COLOR_DOS_TEXT.r, COLOR_DOS_TEXT.g, COLOR_DOS_TEXT.b, 40)
		surface.DrawOutlinedRect(18, 56, width - 36, height - 74, 1)
		draw.SimpleText("INPUT DEVICE NOT DETECTED", "ixComputerDOSHeader", width * 0.5, height * 0.42, COLOR_DOS_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("CONNECT A KEYBOARD TO RESUME COMMAND INPUT.", "ixComputerDOSTiny", width * 0.5, height * 0.49, COLOR_DOS_DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

function PANEL:GetSelectedCategory()
	return self.data.categories[self.selectedCategory]
end

function PANEL:GetSelectedEntry()
	local category = self:GetSelectedCategory()

	return category and category.entries[self.selectedEntry] or nil
end

function PANEL:PlayTypeSound(isEnter)
	if (self.nextTypeSound > CurTime()) then
		return
	end

	PlayKeyboardSound(isEnter == true)
	self.nextTypeSound = CurTime() + (isEnter and 0.08 or 0.045)
end

function PANEL:ResetCommandEntry()
	if (!IsValid(self.commandEntry)) then
		return
	end

	self.suppressTyping = true
	self.commandEntry:SetText("")
	self.commandEntry:SetValue("")
	self.commandEntry:OnTextChanged()
	self.suppressTyping = false
	self.commandEntry:RequestFocus()
	self.commandEntry:SetCaretPos(0)
end

function PANEL:QueueStatusPrint()
	timer.Simple(0.15, function()
		if (IsValid(self) and self.PrintStatus) then
			self:PrintStatus()
		end
	end)
end

function PANEL:GetPromptText()
	local entry = self:GetSelectedEntry()
	local base = self.context and self.context.combineJournal and "J:\\LOG" or "C:\\DOS"

	if (entry) then
		base = base .. "\\" .. string.upper(string.gsub(entry.title or "ENTRY", "%s+", "_"))
	end

	return base .. ">"
end

function PANEL:UpdatePrompt()
	if (IsValid(self.promptLabel)) then
		self.promptLabel:SetText(self:GetPromptText())
		self.promptLabel:SizeToContents()
	end
end

function PANEL:ClearConsole()
	if (IsValid(self.output)) then
		self.output:SetText("")
	end
end

function PANEL:AppendConsole(text, color)
	if (!IsValid(self.output)) then
		return
	end

	color = color or COLOR_DOS_TEXT
	self.output:InsertColorChange(color.r, color.g, color.b, color.a or 255)
	self.output:AppendText(tostring(text or ""))

	if (!string.EndsWith(tostring(text or ""), "\n")) then
		self.output:AppendText("\n")
	end

	self.output:GotoTextEnd()
end

function PANEL:AppendCommandEcho(text)
	self:AppendConsole(self:GetPromptText() .. text, COLOR_DOS_DIM)
	self:AppendConsole("")
end

function PANEL:AppendDivider()
	self:AppendConsole(string.rep("-", 72), COLOR_DOS_DIM)
end

function PANEL:PrintStatus()
	local category = self:GetSelectedCategory()
	local entry = self:GetSelectedEntry()
	local accessLabel = self.context and self.context.locked and L("interactiveComputerLocked")
		or (self.context and self.context.guest and L("interactiveComputerGuest"))
		or L("interactiveComputerFullAccess")
	local entryState = "NORMAL"
	local inputState = HasInteractiveKeyboard(self) and "READY" or "KEYBOARD MISSING"

	if (entry and entry.locked) then
		entryState = "LOCKED"
	elseif (entry and entry.security and entry.security.mode == "readonly" and entry.canEdit != true) then
		entryState = "READONLY"
	end

	self:AppendConsole("ACCESS    : " .. accessLabel, COLOR_DOS_DIM)
	self:AppendConsole("ENTRY     : " .. (entry and entry.title or "NONE"), COLOR_DOS_DIM)
	self:AppendConsole("INPUT     : " .. inputState, COLOR_DOS_DIM)
	self:AppendConsole("STATE     : " .. entryState, COLOR_DOS_DIM)
end

function PANEL:PrintWelcome()
	self:ClearConsole()
	self:AppendConsole(self.context and self.context.combineJournal and "<:: OVERWATCH PERSONAL LOG SHELL [Version 10.0.26200.6037]" or "Microsoft(R) MS-DOS(R) Version 6.22")
	self:AppendConsole("(C)Copyright Microsoft Corp 1981-1994.")
	self:AppendConsole("")
	self:AppendConsole(L("interactiveComputerHelpIntro"), COLOR_DOS_DIM)
	self:AppendDivider()
	self:PrintStatus()
	self:AppendConsole("")
end

function PANEL:FindCategoryIndex(token)
	token = NormalizeLookupToken(token)
	if (token == "") then
		return nil
	end

	local numericIndex = tonumber(token)
	if (numericIndex and self.data.categories[numericIndex]) then
		return numericIndex
	end

	for index, category in ipairs(self.data.categories) do
		if (NormalizeLookupToken(category.name) == token) then
			return index
		end
	end
end

function PANEL:FindEntryIndex(token, category)
	category = category or self:GetSelectedCategory()
	token = NormalizeLookupToken(token)
	if (!category or token == "") then
		return nil
	end

	local numericIndex = tonumber(token)
	if (numericIndex and category.entries[numericIndex]) then
		return numericIndex
	end

	for index, entry in ipairs(category.entries) do
		if (NormalizeLookupToken(entry.title) == token) then
			return index
		end
	end
end

function PANEL:GetEntryLines(entry)
	entry = entry or self:GetSelectedEntry()
	if (!entry or entry.body == "") then
		return {}
	end

	local body = string.gsub(entry.body or "", "\r", "")
	local lines = {}

	for line in string.gmatch(body .. "\n", "(.-)\n") do
		lines[#lines + 1] = line
	end

	return lines
end

function PANEL:SetEntryLines(lines, entry)
	entry = entry or self:GetSelectedEntry()
	if (!entry) then
		return
	end

	entry.body = string.sub(table.concat(lines or {}, "\n"), 1, PLUGIN.maxEntryBodyLength)
	entry.updatedAt = os.time()
end

function PANEL:CanEditComputer()
	return IsTerminalReady(self) and (!self.context or self.context.combineJournal == true or self.context.canEdit == true)
end

function PANEL:CanEditEntry()
	local entry = self:GetSelectedEntry()

	return self:CanEditComputer() and entry != nil and entry.locked != true and !(entry.security and entry.security.mode == "readonly" and entry.canEdit != true)
end

function PANEL:CycleHistory(direction)
	local historyCount = #self.commandHistory
	if (!IsValid(self.commandEntry) or historyCount == 0) then
		return
	end

	if (self.historyIndex == nil) then
		self.historyIndex = direction < 0 and historyCount or 1
	else
		self.historyIndex = math.Clamp(self.historyIndex + direction, 1, historyCount)
	end

	self.suppressTyping = true
	self.commandEntry:SetValue(self.commandHistory[self.historyIndex] or "")
	self.commandEntry:SetCaretPos(#self.commandEntry:GetValue())
	self.suppressTyping = false
end

function PANEL:SubmitSave()
	if (!IsValid(self.entity)) then
		self:Close()
		return
	end

	if (self.context and self.context.combineJournal) then
		netstream.Start("ixInteractiveComputerSaveCombineJournal", self.entity, self.data)
	else
		netstream.Start("ixInteractiveComputerSave", self.entity, self.data)
	end

	self:AppendConsole("SAVE REQUEST TRANSMITTED.", COLOR_DOS_DIM)
end

function PANEL:SelectCategory(index)
	index = math.Clamp(tonumber(index) or 1, 1, #self.data.categories)
	self.selectedCategory = index
	self.selectedEntry = 1
	self:UpdatePrompt()
end

function PANEL:SelectEntry(index)
	local category = self:GetSelectedCategory()
	if (!category) then
		return false
	end

	index = tonumber(index) or 1
	if (!category.entries[index]) then
		return false
	end

	self.selectedEntry = index
	self:UpdatePrompt()

	return true
end

function PANEL:RunCommand(rawText)
	rawText = string.Trim(tostring(rawText or ""))
	if (rawText == "") then
		return
	end

	self.commandHistory[#self.commandHistory + 1] = rawText
	self.historyIndex = nil

	if (!IsTerminalReady(self)) then
		self:AppendCommandEcho(rawText)
		self:AppendConsole("SYSTEM OFFLINE. PRESS POWER TO BOOT.", COLOR_DOS_TEXT)
		return
	end

	local command, remainder = SplitCommandInput(rawText)
	local arguments = TokenizeArguments(remainder)
	local category = self:GetSelectedCategory()
	local entry = self:GetSelectedEntry()

	if (command == "clear") then
		command = "clearbody"
	elseif (command == "login") then
		command = "unlock"
	elseif (command == "write") then
		command = "newentry"
	elseif (command == "edit") then
		command = "open"
	elseif (command == "delete") then
		command = "remove"
	elseif (command == "remove") then
		command = "delentry"
	elseif (command == "list") then
		command = "dir"
	end

	if (command == "cls") then
		self:ClearConsole()
		return
	end

	self:AppendCommandEcho(rawText)

	if (command == "help") then
		self:AppendConsole(L("interactiveComputerHelpStatus"))
		self:AppendConsole(L("interactiveComputerHelpLogin"))
		self:AppendConsole(L("interactiveComputerHelpLogoff"))
		self:AppendConsole(L("interactiveComputerHelpSecurity"))
		self:AppendConsole(L("interactiveComputerHelpList"))
		self:AppendConsole(L("interactiveComputerHelpOpen"))
		self:AppendConsole(L("interactiveComputerHelpRead"))
		self:AppendConsole(L("interactiveComputerHelpWrite"))
		self:AppendConsole(L("interactiveComputerHelpEdit"))
		self:AppendConsole(L("interactiveComputerHelpRemove"))
		self:AppendConsole(L("interactiveComputerHelpSave"))
		self:AppendConsole("")
		self:AppendConsole(L("interactiveComputerHelpTitle"))
		self:AppendConsole(L("interactiveComputerHelpAuthor"))
		self:AppendConsole(L("interactiveComputerHelpClearBody"))
		self:AppendConsole(L("interactiveComputerHelpPrivate"))
		self:AppendConsole(L("interactiveComputerHelpPublic"))
		self:AppendConsole("")
		self:AppendConsole(L("interactiveComputerHelpPrepend"))
		self:AppendConsole(L("interactiveComputerHelpAppend"))
		self:AppendConsole(L("interactiveComputerHelpPop"))
		self:AppendConsole(L("interactiveComputerHelpDelete"))
		self:AppendConsole(L("interactiveComputerHelpRevise"))
		return
	end

	if (command == "entryunlock") then
		command = "public"
	end

	if (command == "entrysecurity") then
		command = "private"
	end

	if (command == "status") then
		self:PrintStatus()
		return
	end

	if (command == "dir" or command == "ls") then
		local activeCategory = self:GetSelectedCategory()
		if (!activeCategory) then
			self:AppendConsole(L("interactiveComputerNoEntriesAvailable"))
			return
		end

		for index, listedEntry in ipairs(activeCategory.entries) do
			local flags = ""
			if (listedEntry.locked) then
				flags = " [LOCKED]"
			elseif (listedEntry.security and listedEntry.security.mode == "readonly" and listedEntry.canEdit != true) then
				flags = " [RO]"
			end

			self:AppendConsole(string.format("%02d  %s%s", index, listedEntry.title, flags))
		end
		return
	end

	if (command == "cd") then
		local targetIndex = self:FindCategoryIndex(remainder)
		if (!targetIndex) then
			self:AppendConsole("CATEGORY NOT FOUND.")
			return
		end

		self:SelectCategory(targetIndex)
		self:AppendConsole("CATEGORY SELECTED: " .. self:GetSelectedCategory().name, COLOR_DOS_DIM)
		return
	end

	if (command == "open") then
		local targetIndex = self:FindEntryIndex(remainder)
		if (!targetIndex or !self:SelectEntry(targetIndex)) then
			self:AppendConsole(L("interactiveComputerEntryNotFound"))
			return
		end

		self:AppendConsole("ENTRY SELECTED: " .. self:GetSelectedEntry().title, COLOR_DOS_DIM)
		return
	end

	if (command == "read" or command == "type") then
		if (!entry) then
			self:AppendConsole(L("interactiveComputerNoEntrySelected"))
			return
		end

		self:AppendDivider()
		self:AppendConsole("TITLE   : " .. (entry.title or ""))
		if (!(self.context and self.context.combineJournal)) then
			self:AppendConsole("AUTHOR  : " .. ((entry.author and entry.author != "") and entry.author or "UNSPECIFIED"))
		end
		self:AppendConsole("UPDATED : " .. os.date("%Y-%m-%d %H:%M:%S", tonumber(entry.updatedAt) or os.time()))
		self:AppendDivider()
		self:AppendConsole(entry.body != "" and entry.body or "[EMPTY]")
		self:AppendDivider()
		return
	end

	if (command == "newentry") then
		if (!self:CanEditComputer() or !category) then
			self:AppendConsole(L("interactiveComputerAccessDenied"))
			return
		end

		if (#category.entries >= PLUGIN.maxEntriesPerCategory) then
			self:AppendConsole(L("interactiveComputerEntryLimitReached"))
			return
		end

		local title = string.sub(string.Trim(remainder) != "" and remainder or ("ENTRY " .. (#category.entries + 1)), 1, PLUGIN.maxEntryTitleLength)
		category.entries[#category.entries + 1] = {
			title = title,
			body = "",
			updatedAt = os.time(),
			author = "",
			security = {
				mode = "none",
				password = ""
			}
		}
		self:SelectEntry(#category.entries)
		self:AppendConsole("ENTRY CREATED: " .. title, COLOR_DOS_DIM)
		return
	end

	if (command == "delentry") then
		if (!self:CanEditComputer() or !category or !entry) then
			self:AppendConsole(L("interactiveComputerAccessDenied"))
			return
		end

		if (#category.entries <= 1) then
			self:AppendConsole(L("interactiveComputerLastEntryProtected"))
			return
		end

		local removedTitle = entry.title or "UNKNOWN"
		table.remove(category.entries, self.selectedEntry)
		self.selectedEntry = math.Clamp(self.selectedEntry, 1, #category.entries)
		self:UpdatePrompt()
		self:AppendConsole("ENTRY REMOVED: " .. removedTitle, COLOR_DOS_DIM)
		return
	end

	if (command == "title") then
		if (!self:CanEditEntry() or !entry) then
			self:AppendConsole(L("interactiveComputerAccessDenied"))
			return
		end

		local title = string.sub(string.Trim(remainder), 1, PLUGIN.maxEntryTitleLength)
		if (title == "") then
			self:AppendConsole(L("interactiveComputerUsageTitle"))
			return
		end

		entry.title = title
		entry.updatedAt = os.time()
		self:UpdatePrompt()
		self:AppendConsole("TITLE UPDATED.", COLOR_DOS_DIM)
		return
	end

	if (command == "author") then
		if (self.context and self.context.combineJournal) then
			self:AppendConsole(L("interactiveComputerAuthorUnavailable"))
			return
		end

		if (!self:CanEditEntry() or !entry) then
			self:AppendConsole(L("interactiveComputerAccessDenied"))
			return
		end

		entry.author = string.sub(string.Trim(remainder), 1, PLUGIN.maxAuthorLength)
		self:AppendConsole("AUTHOR UPDATED.", COLOR_DOS_DIM)
		return
	end

	if (command == "append") then
		if (!self:CanEditEntry() or !entry) then
			self:AppendConsole(L("interactiveComputerAccessDenied"))
			return
		end

		local appendedLine = string.Trim(remainder)
		if (appendedLine == "") then
			self:AppendConsole(L("interactiveComputerUsageAppend"))
			return
		end

		local newBody = entry.body
		if (newBody != "") then
			newBody = newBody .. "\n"
		end

		entry.body = string.sub(newBody .. string.gsub(appendedLine, "\r", ""), 1, PLUGIN.maxEntryBodyLength)
		entry.updatedAt = os.time()
		self:AppendConsole("BODY APPENDED.", COLOR_DOS_DIM)
		return
	end

	if (command == "prepend") then
		if (!self:CanEditEntry() or !entry) then
			self:AppendConsole(L("interactiveComputerAccessDenied"))
			return
		end

		local prependedLine = string.Trim(remainder)
		if (prependedLine == "") then
			self:AppendConsole(L("interactiveComputerUsagePrepend"))
			return
		end

		local existingLines = self:GetEntryLines(entry)
		local lines = {string.gsub(prependedLine, "\r", "")}
		for _, line in ipairs(existingLines) do
			lines[#lines + 1] = line
		end
		self:SetEntryLines(lines, entry)
		self:AppendConsole("BODY PREPENDED.", COLOR_DOS_DIM)
		return
	end

	if (command == "pop" or command == "slice") then
		if (!self:CanEditEntry() or !entry) then
			self:AppendConsole(L("interactiveComputerAccessDenied"))
			return
		end

		local lines = self:GetEntryLines(entry)
		if (#lines == 0) then
			self:AppendConsole(L("interactiveComputerNoLines"))
			return
		end

		table.remove(lines, #lines)
		self:SetEntryLines(lines, entry)
		self:AppendConsole("LAST LINE REMOVED.", COLOR_DOS_DIM)
		return
	end

	if (command == "remove") then
		if (!self:CanEditEntry() or !entry) then
			self:AppendConsole(L("interactiveComputerAccessDenied"))
			return
		end

		local lineNumber = tonumber(arguments[1] or "")
		local lines = self:GetEntryLines(entry)
		if (!lineNumber or !lines[lineNumber]) then
			self:AppendConsole(L("interactiveComputerUsageDeleteLine"))
			return
		end

		table.remove(lines, lineNumber)
		self:SetEntryLines(lines, entry)
		self:AppendConsole("LINE REMOVED.", COLOR_DOS_DIM)
		return
	end

	if (command == "revice" or command == "revise") then
		if (!self:CanEditEntry() or !entry) then
			self:AppendConsole(L("interactiveComputerAccessDenied"))
			return
		end

		local lineNumber = tonumber(arguments[1] or "")
		local lines = self:GetEntryLines(entry)
		local replacement = string.Trim(string.sub(remainder, #(arguments[1] or "") + 1))
		if (!lineNumber or !lines[lineNumber] or replacement == "") then
			self:AppendConsole(L("interactiveComputerUsageRevise"))
			return
		end

		lines[lineNumber] = replacement
		self:SetEntryLines(lines, entry)
		self:AppendConsole("LINE REVISED.", COLOR_DOS_DIM)
		return
	end

	if (command == "clearbody") then
		if (!self:CanEditEntry() or !entry) then
			self:AppendConsole(L("interactiveComputerAccessDenied"))
			return
		end

		entry.body = ""
		entry.updatedAt = os.time()
		self:AppendConsole("BODY CLEARED.", COLOR_DOS_DIM)
		return
	end

	if (command == "save") then
		if (!self:CanEditComputer()) then
			self:AppendConsole(L("interactiveComputerAccessDenied"))
			return
		end

		self:SubmitSave()
		return
	end

	if (command == "unlock") then
		if (!IsValid(self.entity) or (self.context and self.context.combineJournal)) then
			self:AppendConsole(L("interactiveComputerCommandUnavailable"))
			return
		end

		local password = string.sub(remainder, 1, PLUGIN.maxPasswordLength)
		if (password == "") then
			self:AppendConsole(L("interactiveComputerUsageLogin"))
			return
		end

		netstream.Start("ixInteractiveComputerUnlock", self.entity, password)
		self:AppendConsole("UNLOCK REQUEST TRANSMITTED.", COLOR_DOS_DIM)
		self:QueueStatusPrint()
		return
	end

	if (command == "logoff") then
		self:AppendConsole("SESSION CLOSED.", COLOR_DOS_DIM)
		if (IsValid(self.entity)) then
			netstream.Start("ixInteractiveComputerLogoff", self.entity)
		end
		self:QueueStatusPrint()
		return
	end

	if (command == "public") then
		if (!IsValid(self.entity) or !entry or (self.context and self.context.combineJournal)) then
			self:AppendConsole(L("interactiveComputerCommandUnavailable"))
			return
		end

		local password = string.sub(remainder, 1, PLUGIN.maxPasswordLength)
		if (password == "") then
			self:AppendConsole(L("interactiveComputerUsagePublic"))
			return
		end

		netstream.Start("ixInteractiveComputerUnlockEntry", self.entity, self.selectedCategory, self.selectedEntry, password)
		self:AppendConsole("ENTRY UNLOCK REQUEST TRANSMITTED.", COLOR_DOS_DIM)
		return
	end

	if (command == "security") then
		if (!self:CanEditComputer() or !IsValid(self.entity) or (self.context and self.context.combineJournal)) then
			self:AppendConsole(L("interactiveComputerAccessDenied"))
			return
		end

		local mode = string.lower(arguments[1] or "")
		local password = string.sub(arguments[2] or "", 1, PLUGIN.maxPasswordLength)
		if (mode != "none" and mode != "locked") then
			self:AppendConsole(L("interactiveComputerUsageSecurity"))
			return
		end

		if (mode != "none" and password == "") then
			self:AppendConsole(L("interactiveComputerPasswordRequired"))
			return
		end

		netstream.Start("ixInteractiveComputerSetSecurity", self.entity, mode, password)
		self:AppendConsole("COMPUTER SECURITY REQUEST TRANSMITTED.", COLOR_DOS_DIM)
		return
	end

	if (command == "private") then
		if (!self:CanEditComputer() or !entry or !IsValid(self.entity) or (self.context and self.context.combineJournal)) then
			self:AppendConsole(L("interactiveComputerAccessDenied"))
			return
		end

		local mode = string.lower(arguments[1] or "")
		local password = string.sub(arguments[2] or "", 1, PLUGIN.maxPasswordLength)
		if (mode == "") then
			mode = "private"
		end
		if (mode != "none" and mode != "private" and mode != "readonly") then
			self:AppendConsole(L("interactiveComputerUsagePrivate"))
			return
		end

		if (mode != "none" and password == "") then
			self:AppendConsole(L("interactiveComputerPasswordRequired"))
			return
		end

		netstream.Start("ixInteractiveComputerSetEntrySecurity", self.entity, self.selectedCategory, self.selectedEntry, mode, password)
		self:AppendConsole("ENTRY SECURITY REQUEST TRANSMITTED.", COLOR_DOS_DIM)
		return
	end

	if (command == "back") then
		if (self.context and self.context.returnContext and OpenComputerUI) then
			OpenComputerUI(self.entity, nil, IsValid(self.entity) and self.entity:GetNetVar("powered", true), self.context.returnContext)
		else
			self:AppendConsole("NO RETURN TARGET.")
		end
		return
	end

	self:AppendConsole(L("interactiveComputerUnknownCommand", tostring(command or "")), COLOR_DOS_TEXT)
	self:AppendConsole(L("interactiveComputerUnknownCommandHint"), COLOR_DOS_DIM)
end

function PANEL:LoadComputer(entity, data, powered, context)
	local previousContext = self.context
	local shouldResetShell = self.shellInitialized != true
		or self.entity != entity
		or ((previousContext and previousContext.combineJournal) != (context and context.combineJournal))

	self.entity = entity
	self.context = context or previousContext or {}
	SetTerminalPowerState(self, powered)
	self.data = PLUGIN:NormalizeData(table.Copy(data or {}))
	self.selectedCategory = math.Clamp(self.selectedCategory or 1, 1, #self.data.categories)

	local category = self:GetSelectedCategory()
	local entryCount = category and #category.entries or 1
	self.selectedEntry = math.Clamp(self.selectedEntry or 1, 1, entryCount)
	self:UpdatePrompt()

	if (shouldResetShell) then
		self.shellInitialized = true
		self:PrintWelcome()
	end

	self:UpdateEditingState()
	timer.Simple(0, function()
		if (IsValid(self.commandEntry) and self.commandEntry:IsEnabled()) then
			self.commandEntry:RequestFocus()
		end
	end)
end

function PANEL:GetPowerScreenMode()
	return self.context and self.context.combineJournal and "combineJournal" or "general"
end

function PANEL:LoadComputerContext(entity, data, powered, context)
	self:LoadComputer(entity, data, powered, context)
	self.backButton:SetVisible(self.context.fromCombine == true)
	self:UpdateEditingState()
end

function PANEL:Think()
	if (IsValid(self.entity) and LocalPlayer():GetPos():DistToSqr(self.entity:GetPos()) > 190 * 190) then
		self:Close()
		return
	end

	local wasBooting = IsBootSequenceActive(self)
	UpdateBootSequence(self)

	local keyboardPresent = HasInteractiveKeyboard(self)
	if (self.lastKeyboardPresent == nil or self.lastKeyboardPresent != keyboardPresent or wasBooting != IsBootSequenceActive(self)) then
		self.lastKeyboardPresent = keyboardPresent
		self:UpdateEditingState()
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
	local isReady = IsTerminalReady(self)
	local accessLabel = self.context and self.context.locked and L("interactiveComputerLocked")
		or (self.context and self.context.guest and L("interactiveComputerGuest"))
		or L("interactiveComputerFullAccess")
	local hasKeyboard = HasInteractiveKeyboard(self)

	if (!isReady) then
		self.statusLabel:SetText(L(IsBootSequenceActive(self) and "interactiveComputerBooting" or "interactiveComputerPowerOff"))
	end

	self.commandEntry:SetEnabled(isReady and hasKeyboard)
	self.commandEntry:SetEditable(isReady and hasKeyboard)
	self:UpdatePrompt()

	if (isReady and category and entry) then
		local suffix = ""
		if (entry.locked) then
			suffix = " | " .. L("interactiveComputerLocked")
		elseif (entry.security and entry.security.mode == "readonly" and entry.canEdit != true) then
			suffix = " | " .. L("interactiveComputerSecurityReadOnly")
		end

		if (!hasKeyboard and !combineJournal) then
			suffix = suffix .. " | INPUT DEVICE NOT DETECTED"
		end

		self.statusLabel:SetText(string.format("%s | ENTRY %d/%d%s", accessLabel, self.selectedEntry, #category.entries, suffix))
	end
end

vgui.Register("ixInteractiveComputerTerminal", PANEL, "DFrame")
vgui.Register("ixInteractiveCombineJournalTerminal", JOURNAL, "ixInteractiveComputerTerminal")

StyleLine = function(line)
	if (!line) then
		return
	end

	line.Paint = function(self, width, height)
		local selected = self:IsSelected()

		surface.SetDrawColor(selected and Color(18, 46, 26, 255) or Color(0, 0, 0, 0))
		surface.DrawRect(0, 0, width, height)
		surface.SetDrawColor(COLOR_TEXT.r, COLOR_TEXT.g, COLOR_TEXT.b, selected and 120 or 20)
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
		DrawInsetBox(0, 0, width, height, COLOR_SHELL_DARK, COLOR_SHELL_LIGHT, COLOR_CRT)
	end

	local header = nil

	if (list.GetHeader) then
		header = list:GetHeader()
	end

	header = IsValid(header) and header or list.Header
	header = IsValid(header) and header or list.pnlHeader

	if (IsValid(header)) then
		header:SetTall(22)
		header.Paint = function(_, width, height)
			DrawRaisedBox(0, 0, width, height, COLOR_SHELL_DARK, COLOR_SHELL_LIGHT, Color(202, 206, 211))
		end

		for _, column in ipairs(header.Columns or {}) do
			column:SetTextColor(Color(42, 48, 54))
			column:SetFont("ixComputerDOSTiny")
		end
	end

	list.OnRowRightClick = function() end

	function list:PerformLayout()
		self:FixColumnsLayout()
	end
end

local function StyleButton(button)
	button.Paint = function(_, width, height)
		local hovered = button:IsHovered()
		DrawRaisedBox(0, 0, width, height, COLOR_SHELL_DARK, COLOR_SHELL_LIGHT, hovered and Color(220, 224, 228) or COLOR_SHELL_FACE)
	end
end

local function StyleTextEntry(entry)
	entry:SetTextColor(COLOR_TEXT)
	entry:SetHighlightColor(Color(70, 170, 70))
	entry:SetCursorColor(COLOR_TEXT)
	entry.Paint = function(self, width, height)
		DrawInsetBox(0, 0, width, height, COLOR_SHELL_DARK, COLOR_SHELL_LIGHT, COLOR_CRT)
		for y = 2, height - 2, 4 do
			surface.SetDrawColor(COLOR_TEXT.r, COLOR_TEXT.g, COLOR_TEXT.b, 10)
			surface.DrawRect(2, y, width - 4, 1)
		end
		self:DrawTextEntryText(COLOR_TEXT, Color(70, 170, 70, 120), COLOR_TEXT)
	end
end

local function StyleCombineButton(button)
	button.Paint = function(_, width, height)
		local hovered = button:IsHovered()
		local active = button.ixActive == true
		local enabled = button:IsEnabled()
		local fillColor = active and Color(18, 52, 84, 255) or (hovered and Color(18, 46, 74, 255) or Color(12, 28, 46, 255))
		if (!enabled) then
			fillColor = Color(10, 18, 30, 220)
		end

		surface.SetDrawColor(fillColor)
		surface.DrawRect(0, 0, width, height)
		surface.SetDrawColor(COMBINE_ACCENT)
		surface.DrawRect(0, 0, 4, height)
		surface.SetDrawColor(COMBINE_TEXT.r, COMBINE_TEXT.g, COMBINE_TEXT.b, active and 120 or (hovered and 130 or 70))
		surface.DrawOutlinedRect(0, 0, width, height, 1)
		if (hovered or active) then
			surface.SetDrawColor(COMBINE_GLOW)
			surface.DrawRect(0, 0, width, height)
		end
	end
end

local function StyleCombineTextEntry(entry)
	entry:SetTextColor(COMBINE_TEXT)
	entry:SetHighlightColor(Color(90, 160, 220))
	entry:SetCursorColor(COMBINE_TEXT)
	entry.Paint = function(self, width, height)
		surface.SetDrawColor(Color(8, 18, 32, 255))
		surface.DrawRect(0, 0, width, height)
		surface.SetDrawColor(COMBINE_ACCENT.r, COMBINE_ACCENT.g, COMBINE_ACCENT.b, 35)
		surface.DrawRect(0, 0, width, 3)
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
		surface.SetDrawColor(COMBINE_ACCENT.r, COMBINE_ACCENT.g, COMBINE_ACCENT.b, 18)
		for y = 0, height, 8 do
			surface.DrawRect(0, y, width, 1)
		end
		surface.SetDrawColor(COMBINE_TEXT.r, COMBINE_TEXT.g, COMBINE_TEXT.b, 22)
		surface.DrawOutlinedRect(0, 0, width, height, 1)
	end

	local header = list.GetHeader and list:GetHeader() or nil
	header = IsValid(header) and header or list.Header
	header = IsValid(header) and header or list.pnlHeader
	if (IsValid(header)) then
		header:SetTall(22)
		header.Paint = function(_, width, height)
			surface.SetDrawColor(8, 18, 12, 240)
			surface.DrawRect(0, 0, width, height)
		end

		for _, column in ipairs(header.Columns or {}) do
			column:SetTextColor(COLOR_DOS_TEXT)
			column:SetFont("ixComputerDOSTiny")
		end
	end

	local vBar = list.VBar
	if (IsValid(vBar)) then
		vBar:SetWide(8)
		vBar.Paint = function(_, width, height)
			surface.SetDrawColor(Color(6, 12, 6, 220))
			surface.DrawRect(0, 0, width, height)
		end
		vBar.btnUp:SetText("")
		vBar.btnDown:SetText("")
		vBar.btnGrip:SetText("")
		vBar.btnUp.Paint = function(_, width, height)
			surface.SetDrawColor(12, 36, 16, 220)
			surface.DrawRect(0, 0, width, height)
		end
		vBar.btnDown.Paint = vBar.btnUp.Paint
		vBar.btnGrip.Paint = function(_, width, height)
			surface.SetDrawColor(COLOR_DOS_TEXT.r, COLOR_DOS_TEXT.g, COLOR_DOS_TEXT.b, 110)
			surface.DrawRect(0, 0, width, height)
		end
	end
end

local function ApplyTerminalStyling(frame)
	frame.closeButton:SetTextColor(COLOR_DOS_TEXT)
	frame.powerButton:SetTextColor(COLOR_DOS_TEXT)
	frame.backButton:SetTextColor(COLOR_DOS_TEXT)
	frame.closeButton.Paint = function(_, width, height)
		surface.SetDrawColor(0, 0, 0, 0)
		surface.DrawRect(0, 0, width, height)
		surface.SetDrawColor(COLOR_DOS_TEXT.r, COLOR_DOS_TEXT.g, COLOR_DOS_TEXT.b, 140)
		surface.DrawOutlinedRect(0, 0, width, height, 1)
	end
	frame.powerButton.Paint = frame.closeButton.Paint
	frame.backButton.Paint = frame.closeButton.Paint
	BindButtonClickSound(frame.closeButton, frame)
	BindButtonClickSound(frame.powerButton, frame)
	BindButtonClickSound(frame.backButton, frame)
	frame.output.Paint = function(_, width, height)
		surface.SetDrawColor(COLOR_DOS_BG)
		surface.DrawRect(0, 0, width, height)
		for y = 0, height, 3 do
			surface.SetDrawColor(COLOR_DOS_SCAN)
			surface.DrawRect(0, y, width, 1)
		end
	end
	frame.commandEntry:SetTextColor(COLOR_DOS_TEXT)
	frame.commandEntry:SetHighlightColor(Color(210, 210, 210, 90))
	frame.commandEntry:SetCursorColor(COLOR_DOS_TEXT)
	frame.commandEntry.Paint = function(self, width, height)
		self:DrawTextEntryText(COLOR_DOS_TEXT, Color(230, 230, 230, 90), COLOR_DOS_TEXT)
	end
end

function JOURNAL:Paint(width, height)
	DrawCombineBackdrop(width, height, L("interactiveComputerComLogTitle"), "<:: COMBINE PERSONAL LOG ::>")
	PaintCombineContentBox(18, COMBINE_JOURNAL_TOP, width - 36, height - 138)
end

function JOURNAL:AppendConsole(text, color)
	return PANEL.AppendConsole(self, text, color or COMBINE_TEXT)
end

function JOURNAL:AppendDivider()
	return PANEL.AppendConsole(self, string.rep("-", 72), COMBINE_DIM)
end

function JOURNAL:PrintStatus()
	local entry = self:GetSelectedEntry()
	local accessLabel = self.context and self.context.locked and L("interactiveComputerLocked")
		or (self.context and self.context.guest and L("interactiveComputerGuest"))
		or L("interactiveComputerFullAccess")
	local entryState = "NORMAL"

	if (entry and entry.locked) then
		entryState = "LOCKED"
	elseif (entry and entry.security and entry.security.mode == "readonly" and entry.canEdit != true) then
		entryState = "READONLY"
	end

	self:AppendConsole("ACCESS    : " .. accessLabel, COMBINE_DIM)
	self:AppendConsole("ENTRY     : " .. (entry and entry.title or "NONE"), COMBINE_DIM)
	self:AppendConsole("STATE     : " .. entryState, COMBINE_DIM)
end

function JOURNAL:PrintWelcome()
	self:ClearConsole()
	self:AppendConsole("COMBINE PERSONAL LOG DOS INTERFACE v2.1")
	self:AppendConsole(GetTerminalTime(), COMBINE_DIM)
	self:AppendConsole(L("interactiveComputerHelpIntro"), COMBINE_DIM)
	self:AppendDivider()
	self:PrintStatus()
	self:AppendConsole("")
end

function JOURNAL:PaintOver(width, height)
	if (!IsTerminalReady(self)) then
		PaintCombineContentBox(18, COMBINE_JOURNAL_TOP, width - 36, height - 138)
		local progress = GetBootProgress(self)
		local barY = math.floor(height * 0.58)
		local barWidth = width - 220

		DrawCombineLogo(width * 0.5, height * 0.34, 78, 180)
		draw.SimpleText("PERSONAL LOG DOS", "ixComputerCombineHeader", width * 0.5, height * 0.44, COMBINE_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(L(IsBootSequenceActive(self) and "interactiveComputerBooting" or "interactiveComputerPowerOff"), "ixComputerDOSBody", width * 0.5, height * 0.51, COMBINE_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		DrawInsetBox(110, barY, barWidth, 18, Color(10, 24, 40), Color(38, 98, 146), Color(8, 18, 32, 255))
		surface.SetDrawColor(COMBINE_TEXT.r, COMBINE_TEXT.g, COMBINE_TEXT.b, 120)
		surface.DrawRect(112, barY + 2, math.max(0, math.floor((barWidth - 4) * progress)), 14)
	end
end

function JOURNAL:PerformLayout(width, height)
	if (!IsValid(self.closeButton) or !IsValid(self.powerButton) or !IsValid(self.backButton) or !IsValid(self.output) or !IsValid(self.promptLabel) or !IsValid(self.commandEntry)) then
		return
	end

	self.closeButton:SetPos(width - 58, 14)
	self.closeButton:SetSize(40, 32)

	self.powerButton:SetPos(width - 112, 14)
	self.powerButton:SetSize(44, 32)

	self.backButton:SetPos(width - 166, 14)
	self.backButton:SetSize(44, 32)

	local top = COMBINE_JOURNAL_TOP
	local bottom = 18
	local inputHeight = 30

	self.output:SetPos(18, top)
	self.output:SetSize(width - 36, height - top - bottom - inputHeight)

	self.promptLabel:SizeToContents()
	self.promptLabel:SetPos(18, height - bottom - inputHeight + 4)

	local promptWidth = self.promptLabel:GetWide() + 8
	self.commandEntry:SetPos(18 + promptWidth, height - bottom - inputHeight)
	self.commandEntry:SetSize(width - 36 - promptWidth, inputHeight)
end

local function ApplyCombineJournalStyling(frame)
	frame.closeButton:SetTextColor(COMBINE_TEXT)
	frame.powerButton:SetTextColor(COMBINE_TEXT)
	frame.backButton:SetTextColor(COMBINE_TEXT)
	frame.closeButton.Paint = function(_, width, height)
		surface.SetDrawColor(0, 0, 0, 0)
		surface.DrawRect(0, 0, width, height)
		surface.SetDrawColor(COMBINE_TEXT.r, COMBINE_TEXT.g, COMBINE_TEXT.b, 130)
		surface.DrawOutlinedRect(0, 0, width, height, 1)
	end
	frame.powerButton.Paint = frame.closeButton.Paint
	frame.backButton.Paint = frame.closeButton.Paint
	frame.promptLabel:SetTextColor(COMBINE_TEXT)
	frame.statusLabel:SetTextColor(COMBINE_DIM)
	frame.output.PerformLayout = function(panel)
		panel:SetFontInternal("ixComputerDOSBody")
		panel:SetFGColor(COMBINE_TEXT)
		panel:SetBGColor(Color(0, 0, 0, 0))
	end
	frame.output.Paint = function(_, width, height)
		surface.SetDrawColor(Color(8, 18, 32, 255))
		surface.DrawRect(0, 0, width, height)
		surface.SetDrawColor(COMBINE_ACCENT.r, COMBINE_ACCENT.g, COMBINE_ACCENT.b, 18)
		for y = 0, height, 8 do
			surface.DrawRect(0, y, width, 1)
		end
		surface.SetDrawColor(COMBINE_TEXT.r, COMBINE_TEXT.g, COMBINE_TEXT.b, 25)
		surface.DrawOutlinedRect(0, 0, width, height, 1)
	end
	StyleCombineTextEntry(frame.commandEntry)
	BindButtonClickSound(frame.closeButton, frame)
	BindButtonClickSound(frame.powerButton, frame)
	BindButtonClickSound(frame.backButton, frame)
end

local function ApplyCombineStyling(frame)
	StyleCombineListView(frame.rosterList)
	StyleCombineButton(frame.objectivesTabButton)
	StyleCombineButton(frame.civilDataTabButton)
	StyleCombineButton(frame.objectiveSaveButton)
	StyleCombineButton(frame.dataSaveButton)
	StyleCombineButton(frame.personalLogButton)
	StyleCombineButton(frame.publicPanelButton)
	StyleCombineButton(frame.rosterScrollUpButton)
	StyleCombineButton(frame.rosterScrollDownButton)
	frame.closeButton.Paint = function(_, width, height)
		surface.SetDrawColor(0, 0, 0, 0)
		surface.DrawRect(0, 0, width, height)
		surface.SetDrawColor(COMBINE_TEXT.r, COMBINE_TEXT.g, COMBINE_TEXT.b, 130)
		surface.DrawOutlinedRect(0, 0, width, height, 1)
	end
	frame.powerButton.Paint = frame.closeButton.Paint
	StyleCombineTextEntry(frame.objectivesEntry)
	StyleCombineTextEntry(frame.dataEntry)
	BindButtonClickSound(frame.closeButton, frame)
	BindButtonClickSound(frame.powerButton, frame)
	BindButtonClickSound(frame.objectivesTabButton, frame)
	BindButtonClickSound(frame.civilDataTabButton, frame)
	BindButtonClickSound(frame.objectiveSaveButton, frame)
	BindButtonClickSound(frame.dataSaveButton, frame)
	BindButtonClickSound(frame.personalLogButton, frame)
	BindButtonClickSound(frame.publicPanelButton, frame)
	BindButtonClickSound(frame.rosterScrollUpButton, frame)
	BindButtonClickSound(frame.rosterScrollDownButton, frame)
	BindEnterSound(frame.objectivesEntry, frame)
	BindEnterSound(frame.dataEntry, frame)
end

local COMBINE = {}

function COMBINE:Init()
	self:SetSize(UNIFIED_TERMINAL_WIDTH, UNIFIED_TERMINAL_HEIGHT)
	self:SetTitle("")
	self:ShowCloseButton(false)
	self:SetDraggable(false)

	self.nextTypeSound = 0
	self.selectedTarget = nil
	self.context = {}
	self.activeTab = nil
	self.powered = false

	self.closeButton = self:Add("DButton")
	self.closeButton:SetText("X")
	self.closeButton:SetFont("ixComputerDOSBody")
	self.closeButton:SetTextColor(COMBINE_TEXT)
	self.closeButton.DoClick = function()
		self:Close()
	end

	self.powerButton = self:Add("DButton")
	self.powerButton:SetText("⏻")
	self.powerButton:SetFont("ixComputerDOSBody")
	self.powerButton:SetTextColor(COMBINE_TEXT)
	self.powerButton.DoClick = function()
		if (!IsValid(self.entity)) then
			self:Close()
			return
		end

		if (IsTerminalReady(self)) then
			netstream.Start("ixInteractiveComputerPower", self.entity, false, self:GetPowerScreenMode())
			self:Close()
			return
		end

		StartBootSequence(self, 1.9)
		self:UpdateStatus()
	end

	self.statusLabel = self:Add("DLabel")
	self.statusLabel:SetFont("ixComputerDOSTiny")
	self.statusLabel:SetTextColor(COMBINE_DIM)
	self.statusLabel:SetText("")

	self.objectivesTabButton = self:Add("DButton")
	self.objectivesTabButton:SetText(L("interactiveComputerObjectives"))
	self.objectivesTabButton:SetFont("ixComputerDOSBody")
	self.objectivesTabButton:SetTextColor(COMBINE_TEXT)
	self.objectivesTabButton.DoClick = function()
		self:SetActiveTab("objectives")
	end

	self.civilDataTabButton = self:Add("DButton")
	self.civilDataTabButton:SetText(L("interactiveComputerCivilData"))
	self.civilDataTabButton:SetFont("ixComputerDOSBody")
	self.civilDataTabButton:SetTextColor(COMBINE_TEXT)
	self.civilDataTabButton.DoClick = function()
		self:SetActiveTab("civil")
	end

	self.rosterList = self:Add("DListView")
	self.rosterList:SetHeaderHeight(0)
	self.rosterList:SetDataHeight(24)
	self.rosterList:AddColumn("UNIT")
	self.rosterList.OnRowSelected = function(_, rowID, row)
		self.selectedTarget = row.ixTarget
		self:PopulateSelectedData()
	end

	self.rosterScrollUpButton = self:Add("DButton")
	self.rosterScrollUpButton:SetText("∧")
	self.rosterScrollUpButton:SetFont("ixComputerDOSBody")
	self.rosterScrollUpButton:SetTextColor(COMBINE_TEXT)

	self.rosterScrollDownButton = self:Add("DButton")
	self.rosterScrollDownButton:SetText("∨")
	self.rosterScrollDownButton:SetFont("ixComputerDOSBody")
	self.rosterScrollDownButton:SetTextColor(COMBINE_TEXT)
	BindScrollHoldButton(self.rosterScrollUpButton, function() return IsValid(self.rosterList) and self.rosterList.VBar or nil end, -72)
	BindScrollHoldButton(self.rosterScrollDownButton, function() return IsValid(self.rosterList) and self.rosterList.VBar or nil end, 72)

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

		OpenComputerUI(self.entity, {}, self.entity:GetNetVar("powered", true), {
			civicPanel = true,
			canEdit = LocalPlayer():IsCombine() or LocalPlayer():IsAdmin(),
			canAsk = true,
			data = self.context.civicData or {},
			fromCombine = true,
			returnContext = self.context
		})
	end

	self:Center()
	self:MakePopup()
end

function COMBINE:PlayTypeSound(isEnter)
	if (self.nextTypeSound > CurTime()) then
		return
	end

	PlayKeyboardSound(isEnter == true)
	self.nextTypeSound = CurTime() + (isEnter and 0.08 or 0.05)
end

function COMBINE:SetActiveTab(tabID)
	self.activeTab = self.activeTab == tabID and nil or tabID
	self:UpdateVisibleState()
	self:UpdateStatus()
end

function COMBINE:GetPowerScreenMode()
	return "combine"
end

function COMBINE:UpdateVisibleState()
	local isReady = IsTerminalReady(self)
	local showObjectives = isReady and self.activeTab == "objectives"
	local showCivil = isReady and self.activeTab == "civil"

	self.objectivesTabButton.ixActive = self.activeTab == "objectives"
	self.civilDataTabButton.ixActive = self.activeTab == "civil"

	self.objectivesTabButton:SetEnabled(isReady)
	self.civilDataTabButton:SetEnabled(isReady)
	self.personalLogButton:SetEnabled(isReady)
	self.publicPanelButton:SetEnabled(isReady)

	self.objectivesEntry:SetVisible(showObjectives)
	self.objectiveSaveButton:SetVisible(showObjectives and self.context.canEditObjectives == true)
	self.objectivesEntry:SetEnabled(showObjectives and self.context.canEditObjectives == true)

	self.rosterList:SetVisible(showCivil)
	self.rosterScrollUpButton:SetVisible(showCivil)
	self.rosterScrollDownButton:SetVisible(showCivil)
	self.dataEntry:SetVisible(showCivil)
	self.dataSaveButton:SetVisible(showCivil and self.context.canEditData == true)
	self.dataEntry:SetEnabled(showCivil and self.context.canEditData == true and self.selectedTarget != nil)
end

function COMBINE:UpdateStatus()
	if (!IsTerminalReady(self)) then
		self.statusLabel:SetText(L(IsBootSequenceActive(self) and "interactiveComputerBooting" or "interactiveComputerPowerOff"))
		return
	end

	if (self.activeTab == "objectives") then
		self.statusLabel:SetText(L("interactiveComputerObjectives"))
		return
	end

	if (self.activeTab == "civil") then
		if (self.selectedTarget) then
			for _, entry in ipairs(self.context.roster or {}) do
				if (entry.target == self.selectedTarget) then
					self.statusLabel:SetText(string.format("UNIT: %s | CID: %s", entry.name or "UNKNOWN", entry.cid or "00000"))
					return
				end
			end
		end

		self.statusLabel:SetText(L("interactiveComputerSelectUnit"))
		return
	end

	self.statusLabel:SetText(L("interactiveComputerSelectModule"))
end

function COMBINE:Paint(width, height)
	DrawCombineBackdrop(width, height, L("interactiveComputerCombineTitle"))

	local navX = 22
	local top = 92
	local navWidth = 214
	local contentX = navX + navWidth + 18
	local contentWidth = width - contentX - 22
	local contentHeight = height - top - 54

	PaintCombineContentBox(navX, top, navWidth, contentHeight)
	PaintCombineContentBox(contentX, top, contentWidth, contentHeight)
	draw.SimpleText("MODULES", "ixComputerCombineBody", navX + 14, top + 12, COMBINE_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

	if (IsTerminalReady(self) and self.activeTab == "objectives") then
		draw.SimpleText(L("interactiveComputerObjectives"), "ixComputerCombineBody", contentX + 18, top + 14, COMBINE_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	elseif (IsTerminalReady(self) and self.activeTab == "civil") then
		draw.SimpleText(L("interactiveComputerCivilData"), "ixComputerCombineBody", contentX + 18, top + 14, COMBINE_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end

	if (!IsTerminalReady(self) or !self.activeTab) then
		local centerX = contentX + contentWidth * 0.5
		local centerY = top + contentHeight * 0.42
		local progress = GetBootProgress(self)

		DrawCombineLogo(centerX, centerY - 30, math.min(contentWidth, contentHeight) * 0.15, 220)
		draw.SimpleText("overwatch grid", "ixComputerCombineGrid", centerX, centerY + 78, COMBINE_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(L(IsTerminalReady(self) and "interactiveComputerSelectModule" or (IsBootSequenceActive(self) and "interactiveComputerBooting" or "interactiveComputerPowerOff")), "ixComputerCombineBody", centerX, centerY + 116, COMBINE_DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(IsTerminalReady(self) and "OBJECTIVES / CIVIL DATA / PERSONAL LOG / PUBLIC PANEL" or L("interactiveComputerPowerPrompt"), "ixComputerDOSTiny", centerX, centerY + 144, COMBINE_DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		if (!IsTerminalReady(self)) then
			DrawInsetBox(contentX + 80, top + contentHeight - 86, contentWidth - 160, 18, Color(8, 24, 40), Color(26, 58, 88), Color(8, 18, 32))
			surface.SetDrawColor(COMBINE_TEXT.r, COMBINE_TEXT.g, COMBINE_TEXT.b, 110)
			surface.DrawRect(contentX + 82, top + contentHeight - 84, math.max(0, math.floor((contentWidth - 164) * progress)), 14)
		end
	end
end

function COMBINE:PerformLayout(width, height)
	if (!IsValid(self.closeButton) or !IsValid(self.powerButton) or !IsValid(self.statusLabel)
	or !IsValid(self.rosterList) or !IsValid(self.objectivesEntry) or !IsValid(self.dataEntry)
	or !IsValid(self.objectiveSaveButton) or !IsValid(self.dataSaveButton)
	or !IsValid(self.personalLogButton) or !IsValid(self.publicPanelButton)
	or !IsValid(self.rosterScrollUpButton) or !IsValid(self.rosterScrollDownButton)
	or !IsValid(self.objectivesTabButton) or !IsValid(self.civilDataTabButton)) then
		return
	end

	self.closeButton:SetPos(width - 58, 14)
	self.closeButton:SetSize(40, 32)

	self.powerButton:SetPos(width - 112, 14)
	self.powerButton:SetSize(44, 32)

	self.statusLabel:SetPos(22, height - 28)
	self.statusLabel:SetSize(width - 44, 20)

	local left = 22
	local top = 92
	local navWidth = 214
	local contentX = left + navWidth + 18
	local contentY = top
	local contentWidth = width - contentX - 22
	local contentHeight = height - top - 54
	local navButtonWidth = navWidth - 24
	local navButtonX = left + 12
	local navButtonY = top + 40
	local rosterWidth = math.floor(contentWidth * 0.36)
	local editorX = contentX + rosterWidth + 16
	local editorWidth = contentWidth - rosterWidth - 32

	self.objectivesTabButton:SetPos(navButtonX, navButtonY)
	self.objectivesTabButton:SetSize(navButtonWidth, 34)

	self.civilDataTabButton:SetPos(navButtonX, navButtonY + 42)
	self.civilDataTabButton:SetSize(navButtonWidth, 34)

	self.personalLogButton:SetPos(navButtonX, navButtonY + 104)
	self.personalLogButton:SetSize(navButtonWidth, 34)

	self.publicPanelButton:SetPos(navButtonX, navButtonY + 146)
	self.publicPanelButton:SetSize(navButtonWidth, 34)

	self.objectivesEntry:SetPos(contentX + 18, contentY + 44)
	self.objectivesEntry:SetSize(contentWidth - 36, contentHeight - 104)

	self.objectiveSaveButton:SetPos(contentX + contentWidth - 198, contentY + contentHeight - 46)
	self.objectiveSaveButton:SetSize(180, 30)

	self.rosterList:SetPos(contentX + 18, contentY + 44)
	self.rosterList:SetSize(rosterWidth - 34, contentHeight - 62)

	self.rosterScrollUpButton:SetPos(contentX + 18 + rosterWidth - 26, contentY + 44)
	self.rosterScrollUpButton:SetSize(24, 24)

	self.rosterScrollDownButton:SetPos(contentX + 18 + rosterWidth - 26, contentY + 74)
	self.rosterScrollDownButton:SetSize(24, 24)

	self.dataEntry:SetPos(editorX, contentY + 44)
	self.dataEntry:SetSize(editorWidth, contentHeight - 104)

	self.dataSaveButton:SetPos(contentX + contentWidth - 188, contentY + contentHeight - 46)
	self.dataSaveButton:SetSize(170, 30)

	self:UpdateVisibleState()
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
	self.dataEntry:SetEnabled(IsTerminalReady(self) and self.activeTab == "civil" and self.context.canEditData == true and self.selectedTarget != nil)
	self:UpdateStatus()
end

function COMBINE:LoadComputer(entity, _, powered, context)
	self.entity = entity
	self.context = context or {}
	SetTerminalPowerState(self, powered)
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
	self.dataEntry:SetText("")
	self.objectivesEntry:SetEnabled(self.context.canEditObjectives == true and IsTerminalReady(self))
	self:UpdateVisibleState()
	self:UpdateStatus()
end

function COMBINE:Think()
	if (IsValid(self.entity) and LocalPlayer():GetPos():DistToSqr(self.entity:GetPos()) > 190 * 190) then
		self:Close()
		return
	end

	local wasBooting = IsBootSequenceActive(self)
	UpdateBootSequence(self)

	if (wasBooting != IsBootSequenceActive(self)) then
		self:UpdateVisibleState()
		self:UpdateStatus()
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
	self:SetSize(UNIFIED_TERMINAL_WIDTH, UNIFIED_TERMINAL_HEIGHT)
	self:SetTitle("")
	self:ShowCloseButton(false)
	self:SetDraggable(false)

	self.nextTypeSound = 0
	self.context = {}
	self.activeTab = nil
	self.powered = false

	self.closeButton = self:Add("DButton")
	self.closeButton:SetText("X")
	self.closeButton:SetFont("ixComputerDOSBody")
	self.closeButton:SetTextColor(COMBINE_TEXT)
	self.closeButton.DoClick = function()
		self:Close()
	end

	self.powerButton = self:Add("DButton")
	self.powerButton:SetText("⏻")
	self.powerButton:SetFont("ixComputerDOSBody")
	self.powerButton:SetTextColor(COMBINE_TEXT)
	self.powerButton.DoClick = function()
		if (!IsValid(self.entity)) then
			self:Close()
			return
		end

		if (IsTerminalReady(self)) then
			netstream.Start("ixInteractiveComputerPower", self.entity, false, self:GetPowerScreenMode())
			self:Close()
			return
		end

		StartBootSequence(self, 1.9)
		self:UpdateStatus()
	end

	self.backButton = self:Add("DButton")
	self.backButton:SetText(L("interactiveComputerBack"))
	self.backButton:SetFont("ixComputerDOSBody")
	self.backButton:SetTextColor(COMBINE_TEXT)
	self.backButton:SetVisible(false)
	self.backButton.DoClick = function()
		if (self.context and self.context.returnContext and OpenComputerUI) then
			OpenComputerUI(self.entity, {}, IsValid(self.entity) and self.entity:GetNetVar("powered", true), self.context.returnContext)
		end
	end

	self.statusLabel = self:Add("DLabel")
	self.statusLabel:SetFont("ixComputerDOSTiny")
	self.statusLabel:SetTextColor(COMBINE_DIM)
	self.statusLabel:SetText("")

	self.announcementTabButton = self:Add("DButton")
	self.announcementTabButton:SetText(L("interactiveComputerAnnouncement"))
	self.announcementTabButton:SetFont("ixComputerDOSBody")
	self.announcementTabButton:SetTextColor(COMBINE_TEXT)
	self.announcementTabButton.DoClick = function()
		self:SetActiveTab("announcement")
	end

	self.propagandaTabButton = self:Add("DButton")
	self.propagandaTabButton:SetText(L("interactiveComputerPropaganda"))
	self.propagandaTabButton:SetFont("ixComputerDOSBody")
	self.propagandaTabButton:SetTextColor(COMBINE_TEXT)
	self.propagandaTabButton.DoClick = function()
		self:SetActiveTab("propaganda")
	end

	self.questionsTabButton = self:Add("DButton")
	self.questionsTabButton:SetText(L("interactiveComputerQuestions"))
	self.questionsTabButton:SetFont("ixComputerDOSBody")
	self.questionsTabButton:SetTextColor(COMBINE_TEXT)
	self.questionsTabButton.DoClick = function()
		self:SetActiveTab("questions")
	end

	self.postList = self:Add("DListView")
	self.postList:SetHeaderHeight(0)
	self.postList:SetDataHeight(36)
	self.postList:AddColumn(L("interactiveComputerPostList"))
	self.postList.OnRowSelected = function(_, _, row)
		self.selectedPostIndex = row.ixPostIndex
		self:LoadSelectedPost()
	end

	self.announcementEntry = self:Add("DTextEntry")
	self.announcementEntry:SetMultiline(false)
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

	self.postNewButton = self:Add("DButton")
	self.postNewButton:SetText(L("interactiveComputerNewPost"))
	self.postNewButton:SetFont("ixComputerDOSBody")
	self.postNewButton:SetTextColor(COMBINE_TEXT)
	self.postNewButton.DoClick = function()
		self:CreatePost()
	end

	self.postDeleteButton = self:Add("DButton")
	self.postDeleteButton:SetText(L("interactiveComputerDeletePost"))
	self.postDeleteButton:SetFont("ixComputerDOSBody")
	self.postDeleteButton:SetTextColor(COMBINE_TEXT)
	self.postDeleteButton.DoClick = function()
		self:DeleteSelectedPost()
	end

	self.saveButton = self:Add("DButton")
	self.saveButton:SetText(L("interactiveComputerSaveCivic"))
	self.saveButton:SetFont("ixComputerDOSBody")
	self.saveButton:SetTextColor(COMBINE_TEXT)
	self.saveButton.DoClick = function()
		if (!IsValid(self.entity) or !self.context.canEdit) then
			return
		end

		self:WriteSelectedPost()
		netstream.Start(
			"ixInteractiveComputerSaveCivicPanel",
			self.entity,
			{
				announcements = self.context.data and self.context.data.announcements or {},
				agendas = self.context.data and self.context.data.agendas or {}
			}
		)
	end

	self.postScrollUpButton = self:Add("DButton")
	self.postScrollUpButton:SetText("∧")
	self.postScrollUpButton:SetFont("ixComputerDOSBody")
	self.postScrollUpButton:SetTextColor(COMBINE_TEXT)

	self.postScrollDownButton = self:Add("DButton")
	self.postScrollDownButton:SetText("∨")
	self.postScrollDownButton:SetFont("ixComputerDOSBody")
	self.postScrollDownButton:SetTextColor(COMBINE_TEXT)
	BindScrollHoldButton(self.postScrollUpButton, function() return IsValid(self.postList) and self.postList.VBar or nil end, -72)
	BindScrollHoldButton(self.postScrollDownButton, function() return IsValid(self.postList) and self.postList.VBar or nil end, 72)

	self.questionEntry = self:Add("DTextEntry")
	self.questionEntry:SetFont("ixComputerDOSBody")
	self.questionEntry:SetUpdateOnType(true)
	self.questionEntry.OnValueChange = function()
		self:PlayTypeSound()
	end

	self.questionBodyEntry = self:Add("DTextEntry")
	self.questionBodyEntry:SetMultiline(true)
	self.questionBodyEntry:SetFont("ixComputerDOSBody")
	self.questionBodyEntry:SetUpdateOnType(true)
	self.questionBodyEntry.OnValueChange = function()
		self:PlayTypeSound()
	end

	self.questionNewButton = self:Add("DButton")
	self.questionNewButton:SetText(L("interactiveComputerNewQuestion"))
	self.questionNewButton:SetFont("ixComputerDOSBody")
	self.questionNewButton:SetTextColor(COMBINE_TEXT)
	self.questionNewButton.DoClick = function()
		self.selectedQuestionIndex = nil
		if (self.questionList.ClearSelection) then
			self.questionList:ClearSelection()
		end
		self.questionEntry:SetText("")
		self.questionBodyEntry:SetText("")
		self.answerEntry:SetText("")
		self:UpdateVisibleState()
		self:UpdateStatus()
	end

	self.askButton = self:Add("DButton")
	self.askButton:SetText(L("interactiveComputerAskQuestion"))
	self.askButton:SetFont("ixComputerDOSBody")
	self.askButton:SetTextColor(COMBINE_TEXT)
	self.askButton.DoClick = function()
		if (!IsValid(self.entity) or !self.context.canAsk) then
			return
		end

		local title = string.Trim(self.questionEntry:GetValue())
		local body = string.Trim(self.questionBodyEntry:GetValue())
		if (title == "" and body == "") then
			return
		end

		netstream.Start("ixInteractiveComputerAskQuestion", self.entity, title, body)
		self.selectedQuestionIndex = nil
		self.questionEntry:SetText("")
		self.questionBodyEntry:SetText("")
		self.answerEntry:SetText("")
		self:UpdateVisibleState()
	end

	self.questionList = self:Add("DListView")
	self.questionList:SetHeaderHeight(0)
	self.questionList:SetDataHeight(48)
	self.questionList:AddColumn(L("interactiveComputerQuestions"))
	self.questionList.OnRowSelected = function(_, _, row)
		self.selectedQuestionIndex = row.ixQuestionIndex
		self.questionEntry:SetText(row.ixQuestionTitle or "")
		self.questionBodyEntry:SetText(row.ixQuestionBody or "")
		self.answerEntry:SetText(row.ixAnswer or "")
		self:UpdateVisibleState()
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
			string.sub(self.answerEntry:GetValue(), 1, 1500)
		)
	end

	self.questionDeleteButton = self:Add("DButton")
	self.questionDeleteButton:SetText(L("interactiveComputerDeletePost"))
	self.questionDeleteButton:SetFont("ixComputerDOSBody")
	self.questionDeleteButton:SetTextColor(COMBINE_TEXT)
	self.questionDeleteButton.DoClick = function()
		if (!IsValid(self.entity) or !self.context.canEdit or !self.selectedQuestionIndex) then
			return
		end

		netstream.Start("ixInteractiveComputerDeleteQuestion", self.entity, self.selectedQuestionIndex)
	end

	self.questionScrollUpButton = self:Add("DButton")
	self.questionScrollUpButton:SetText("∧")
	self.questionScrollUpButton:SetFont("ixComputerDOSBody")
	self.questionScrollUpButton:SetTextColor(COMBINE_TEXT)

	self.questionScrollDownButton = self:Add("DButton")
	self.questionScrollDownButton:SetText("∨")
	self.questionScrollDownButton:SetFont("ixComputerDOSBody")
	self.questionScrollDownButton:SetTextColor(COMBINE_TEXT)
	BindScrollHoldButton(self.questionScrollUpButton, function() return IsValid(self.questionList) and self.questionList.VBar or nil end, -72)
	BindScrollHoldButton(self.questionScrollDownButton, function() return IsValid(self.questionList) and self.questionList.VBar or nil end, 72)

	self:Center()
	self:MakePopup()
end

function CIVIC:PlayTypeSound(isEnter)
	if (self.nextTypeSound > CurTime()) then
		return
	end

	PlayKeyboardSound(isEnter == true)
	self.nextTypeSound = CurTime() + (isEnter and 0.08 or 0.05)
end

function CIVIC:GetActivePostList()
	self.context.data = self.context.data or {}

	if (self.activeTab == "announcement") then
		self.context.data.announcements = self.context.data.announcements or {}
		return self.context.data.announcements
	elseif (self.activeTab == "propaganda") then
		self.context.data.agendas = self.context.data.agendas or {}
		return self.context.data.agendas
	end
end

function CIVIC:PopulateActivePostList()
	if (!IsValid(self.postList)) then
		return
	end

	local posts = self:GetActivePostList() or {}
	local previousSelection = self.selectedPostIndex
	self.postList:Clear()
	self.selectedPostIndex = nil

	for index, entry in ipairs(posts) do
		local title = string.Trim(entry.title or "")
		local author = string.Trim(entry.author or "")
		local row = self.postList:AddLine(string.format("%02d  %s", index, title != "" and title or "UNTITLED"))
		row.ixPostIndex = index
		row.Paint = function(line, rowWidth, rowHeight)
			local selected = line:IsSelected()

			surface.SetDrawColor(selected and Color(24, 52, 84, 255) or Color(0, 0, 0, 0))
			surface.DrawRect(0, 0, rowWidth, rowHeight)
			surface.SetDrawColor(COMBINE_TEXT.r, COMBINE_TEXT.g, COMBINE_TEXT.b, selected and 90 or 18)
			surface.DrawOutlinedRect(0, 0, rowWidth, rowHeight, 1)
		end

		if (row.Columns and row.Columns[1]) then
			row.Columns[1]:SetTextColor(COMBINE_TEXT)
			row.Columns[1]:SetFont("ixComputerDOSTiny")
			if (author != "") then
				row.Columns[1]:SetText(string.format("%02d  %s  [%s]", index, title != "" and title or "UNTITLED", author))
			end
		end
	end

	if (previousSelection and self.postList:GetLine(previousSelection)) then
		self.selectedPostIndex = previousSelection
		self.postList:SelectItem(self.postList:GetLine(previousSelection))
	elseif (self.postList:GetLine(1)) then
		self.selectedPostIndex = 1
		self.postList:SelectItem(self.postList:GetLine(1))
	else
		self.announcementEntry:SetText("")
		self.propagandaEntry:SetText("")
	end
end

function CIVIC:LoadSelectedPost()
	local posts = self:GetActivePostList() or {}
	local entry = posts[self.selectedPostIndex]

	self.announcementEntry:SetText(entry and (entry.title or "") or "")
	self.propagandaEntry:SetText(entry and (entry.body or "") or "")
	self:UpdateVisibleState()
	self:UpdateStatus()
end

function CIVIC:WriteSelectedPost()
	local posts = self:GetActivePostList() or {}
	local entry = posts[self.selectedPostIndex]
	if (!entry) then
		return
	end

	entry.title = string.Trim(string.sub(self.announcementEntry:GetValue(), 1, 80))
	entry.body = string.Trim(string.sub(self.propagandaEntry:GetValue(), 1, 4000))
	entry.author = LocalPlayer():Name()
	entry.updatedAt = os.time()
end

function CIVIC:CreatePost()
	if (!self.context.canEdit or (self.activeTab != "announcement" and self.activeTab != "propaganda")) then
		return
	end

	local posts = self:GetActivePostList()
	posts[#posts + 1] = {
		title = "",
		body = "",
		author = LocalPlayer():Name(),
		updatedAt = os.time()
	}

	self.selectedPostIndex = #posts
	self:PopulateActivePostList()
end

function CIVIC:DeleteSelectedPost()
	if (!self.context.canEdit or !self.selectedPostIndex) then
		return
	end

	local posts = self:GetActivePostList()
	if (!posts or !posts[self.selectedPostIndex]) then
		return
	end

	table.remove(posts, self.selectedPostIndex)
	self.selectedPostIndex = math.Clamp(self.selectedPostIndex, 1, #posts)
	self:PopulateActivePostList()
	self:UpdateVisibleState()
	self:UpdateStatus()

	if (IsValid(self.entity)) then
		netstream.Start(
			"ixInteractiveComputerSaveCivicPanel",
			self.entity,
			{
				announcements = self.context.data and self.context.data.announcements or {},
				agendas = self.context.data and self.context.data.agendas or {}
			}
		)
	end
end

function CIVIC:SetActiveTab(tabID)
	self.activeTab = self.activeTab == tabID and nil or tabID

	if (self.activeTab == "announcement" or self.activeTab == "propaganda") then
		self:PopulateActivePostList()
	end

	self:UpdateVisibleState()
	self:UpdateStatus()
end

function CIVIC:GetPowerScreenMode()
	return "civic"
end

function CIVIC:UpdateVisibleState()
	local isReady = IsTerminalReady(self)
	local showAnnouncement = isReady and self.activeTab == "announcement"
	local showPropaganda = isReady and self.activeTab == "propaganda"
	local showQuestions = isReady and self.activeTab == "questions"
	local showPosts = showAnnouncement or showPropaganda

	self.announcementTabButton.ixActive = self.activeTab == "announcement"
	self.propagandaTabButton.ixActive = self.activeTab == "propaganda"
	self.questionsTabButton.ixActive = self.activeTab == "questions"

	self.announcementTabButton:SetEnabled(isReady)
	self.propagandaTabButton:SetEnabled(isReady)
	self.questionsTabButton:SetEnabled(isReady)

	self.postList:SetVisible(showPosts)
	self.postScrollUpButton:SetVisible(showPosts)
	self.postScrollDownButton:SetVisible(showPosts)
	self.postNewButton:SetVisible(showPosts and self.context.canEdit == true)
	self.postDeleteButton:SetVisible(showPosts and self.context.canEdit == true and self.selectedPostIndex != nil)
	self.announcementEntry:SetVisible(showPosts)
	self.propagandaEntry:SetVisible(showPosts)
	self.saveButton:SetVisible(showPosts and self.context.canEdit == true)
	self.announcementEntry:SetEnabled(showPosts and self.context.canEdit == true and self.selectedPostIndex != nil)
	self.propagandaEntry:SetEnabled(showPosts and self.context.canEdit == true and self.selectedPostIndex != nil)

	self.questionEntry:SetVisible(showQuestions)
	self.questionBodyEntry:SetVisible(showQuestions)
	self.questionNewButton:SetVisible(showQuestions and self.context.canAsk == true)
	self.askButton:SetVisible(showQuestions and self.context.canAsk == true)
	self.questionList:SetVisible(showQuestions)
	self.questionScrollUpButton:SetVisible(showQuestions)
	self.questionScrollDownButton:SetVisible(showQuestions)
	self.answerEntry:SetVisible(showQuestions)
	self.questionDeleteButton:SetVisible(showQuestions and self.context.canEdit == true and self.selectedQuestionIndex != nil)
	self.answerButton:SetVisible(showQuestions and self.context.canEdit == true and self.selectedQuestionIndex != nil)
	self.questionEntry:SetEnabled(showQuestions and self.context.canAsk == true and self.selectedQuestionIndex == nil)
	self.questionBodyEntry:SetEnabled(showQuestions and self.context.canAsk == true and self.selectedQuestionIndex == nil)
	self.answerEntry:SetEnabled(showQuestions and self.context.canEdit == true and self.selectedQuestionIndex != nil)
end

function CIVIC:Paint(width, height)
	DrawCombineBackdrop(width, height, L("interactiveComputerCivicTitle"))

	local navX = 22
	local top = 92
	local navWidth = 214
	local contentX = navX + navWidth + 18
	local contentWidth = width - contentX - 22
	local contentHeight = height - top - 54

	PaintCombineContentBox(navX, top, navWidth, contentHeight)
	PaintCombineContentBox(contentX, top, contentWidth, contentHeight)
	draw.SimpleText("MODULES", "ixComputerCombineBody", navX + 14, top + 12, COMBINE_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

	if (IsTerminalReady(self) and self.activeTab == "announcement") then
		draw.SimpleText(L("interactiveComputerAnnouncementModule"), "ixComputerCombineBody", contentX + 18, top + 14, COMBINE_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	elseif (IsTerminalReady(self) and self.activeTab == "propaganda") then
		draw.SimpleText(L("interactiveComputerAgendaModule"), "ixComputerCombineBody", contentX + 18, top + 14, COMBINE_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	elseif (IsTerminalReady(self) and self.activeTab == "questions") then
		draw.SimpleText(L("interactiveComputerQuestionsModule"), "ixComputerCombineBody", contentX + 18, top + 14, COMBINE_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end

	if (!IsTerminalReady(self) or !self.activeTab) then
		local centerX = contentX + contentWidth * 0.5
		local centerY = top + contentHeight * 0.42
		local progress = GetBootProgress(self)

		DrawCombineLogo(centerX, centerY - 30, math.min(contentWidth, contentHeight) * 0.15, 220)
		draw.SimpleText("civic uplink", "ixComputerCombineGrid", centerX, centerY + 78, COMBINE_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(L(IsTerminalReady(self) and "interactiveComputerSelectModule" or (IsBootSequenceActive(self) and "interactiveComputerBooting" or "interactiveComputerPowerOff")), "ixComputerCombineBody", centerX, centerY + 116, COMBINE_DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(IsTerminalReady(self) and "NOTICE / AGENDA / Q&A" or L("interactiveComputerPowerPrompt"), "ixComputerDOSTiny", centerX, centerY + 144, COMBINE_DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		if (!IsTerminalReady(self)) then
			DrawInsetBox(contentX + 80, top + contentHeight - 86, contentWidth - 160, 18, Color(8, 24, 40), Color(26, 58, 88), Color(8, 18, 32))
			surface.SetDrawColor(COMBINE_TEXT.r, COMBINE_TEXT.g, COMBINE_TEXT.b, 110)
			surface.DrawRect(contentX + 82, top + contentHeight - 84, math.max(0, math.floor((contentWidth - 164) * progress)), 14)
		end
	end
end

function CIVIC:PerformLayout(width, height)
	if (!IsValid(self.closeButton) or !IsValid(self.powerButton) or !IsValid(self.backButton) or !IsValid(self.statusLabel)
	or !IsValid(self.announcementTabButton) or !IsValid(self.propagandaTabButton) or !IsValid(self.questionsTabButton)
	or !IsValid(self.questionDeleteButton)
	or !IsValid(self.postScrollUpButton) or !IsValid(self.postScrollDownButton)
	or !IsValid(self.questionScrollUpButton) or !IsValid(self.questionScrollDownButton)) then
		return
	end

	self.closeButton:SetPos(width - 58, 14)
	self.closeButton:SetSize(40, 32)

	self.powerButton:SetPos(width - 112, 14)
	self.powerButton:SetSize(44, 32)

	self.backButton:SetPos(width - 166, 14)
	self.backButton:SetSize(44, 32)

	self.statusLabel:SetPos(22, height - 28)
	self.statusLabel:SetSize(width - 44, 20)

	local top = 92
	local navWidth = 214
	local contentX = 22 + navWidth + 18
	local contentY = top
	local contentWidth = width - contentX - 22
	local contentHeight = height - top - 54
	local navButtonWidth = navWidth - 24
	local navButtonX = 34
	local navButtonY = top + 40
	local listWidth = math.floor(contentWidth * 0.34)
	local editorX = contentX + listWidth + 16
	local editorWidth = contentWidth - listWidth - 34

	self.announcementTabButton:SetPos(navButtonX, navButtonY)
	self.announcementTabButton:SetSize(navButtonWidth, 34)

	self.propagandaTabButton:SetPos(navButtonX, navButtonY + 42)
	self.propagandaTabButton:SetSize(navButtonWidth, 34)

	self.questionsTabButton:SetPos(navButtonX, navButtonY + 84)
	self.questionsTabButton:SetSize(navButtonWidth, 34)

	self.postList:SetPos(contentX + 18, contentY + 44)
	self.postList:SetSize(listWidth - 34, contentHeight - 62)

	self.postScrollUpButton:SetPos(contentX + 18 + listWidth - 26, contentY + 44)
	self.postScrollUpButton:SetSize(24, 24)

	self.postScrollDownButton:SetPos(contentX + 18 + listWidth - 26, contentY + 74)
	self.postScrollDownButton:SetSize(24, 24)

	self.announcementEntry:SetPos(editorX, contentY + 44)
	self.announcementEntry:SetSize(editorWidth, 28)

	self.propagandaEntry:SetPos(editorX, contentY + 84)
	self.propagandaEntry:SetSize(editorWidth, contentHeight - 146)

	self.postNewButton:SetPos(contentX + 18, contentY + contentHeight - 46)
	self.postNewButton:SetSize(120, 30)

	self.postDeleteButton:SetPos(contentX + 146, contentY + contentHeight - 46)
	self.postDeleteButton:SetSize(120, 30)

	self.saveButton:SetPos(contentX + contentWidth - 198, contentY + contentHeight - 46)
	self.saveButton:SetSize(180, 30)

	self.questionEntry:SetPos(contentX + 18, contentY + 44)
	self.questionEntry:SetSize(contentWidth - 344, 28)

	self.questionNewButton:SetPos(contentX + contentWidth - 318, contentY + 44)
	self.questionNewButton:SetSize(136, 28)

	self.askButton:SetPos(contentX + contentWidth - 170, contentY + 44)
	self.askButton:SetSize(152, 28)

	self.questionList:SetPos(contentX + 18, contentY + 84)
	self.questionList:SetSize(listWidth - 34, contentHeight - 102)

	self.questionScrollUpButton:SetPos(contentX + 18 + listWidth - 26, contentY + 84)
	self.questionScrollUpButton:SetSize(24, 24)

	self.questionScrollDownButton:SetPos(contentX + 18 + listWidth - 26, contentY + 114)
	self.questionScrollDownButton:SetSize(24, 24)

	self.questionBodyEntry:SetPos(editorX, contentY + 84)
	self.questionBodyEntry:SetSize(editorWidth, math.floor(contentHeight * 0.36))

	self.answerEntry:SetPos(editorX, contentY + 96 + math.floor(contentHeight * 0.36))
	self.answerEntry:SetSize(editorWidth, contentHeight - (154 + math.floor(contentHeight * 0.36)))

	self.questionDeleteButton:SetPos(contentX + contentWidth - 370, contentY + contentHeight - 46)
	self.questionDeleteButton:SetSize(172, 30)

	self.answerButton:SetPos(contentX + contentWidth - 190, contentY + contentHeight - 46)
	self.answerButton:SetSize(172, 30)

	self:UpdateVisibleState()
end

function CIVIC:PopulateQuestions()
	self.questionList:Clear()
	self.selectedQuestionIndex = nil
	self.questionEntry:SetText("")
	self.questionBodyEntry:SetText("")
	self.answerEntry:SetText("")

	local questions = (self.context.data and self.context.data.questions) or {}
	for index, entry in ipairs(questions) do
		local asker = entry.asker or "UNKNOWN"
		local prompt = string.format("[%s] %s", asker, entry.title or entry.question or "")
		local line = self.questionList:AddLine(prompt)
		line.ixQuestionIndex = index
		line.ixQuestionTitle = entry.title or entry.question or ""
		line.ixQuestionBody = entry.body or ""
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

	self:UpdateVisibleState()
	self:UpdateStatus()
end

function CIVIC:UpdateStatus()
	if (!IsTerminalReady(self)) then
		self.statusLabel:SetText(L(IsBootSequenceActive(self) and "interactiveComputerBooting" or "interactiveComputerPowerOff"))
		return
	end

	if (self.activeTab == "announcement") then
		local posts = self.context.data and self.context.data.announcements or {}
		self.statusLabel:SetText(string.format("%s | %d POSTS", L("interactiveComputerAnnouncementModule"), #posts))
		return
	end

	if (self.activeTab == "propaganda") then
		local posts = self.context.data and self.context.data.agendas or {}
		self.statusLabel:SetText(string.format("%s | %d POSTS", L("interactiveComputerAgendaModule"), #posts))
		return
	end

	if (self.activeTab != "questions") then
		self.statusLabel:SetText(L("interactiveComputerSelectModule"))
		return
	end

	if (!self.selectedQuestionIndex) then
		self.statusLabel:SetText(L("interactiveComputerSelectQuestion"))
		return
	end

	local question = self.context.data and self.context.data.questions and self.context.data.questions[self.selectedQuestionIndex]
	if (!question) then
		self.statusLabel:SetText(L("interactiveComputerNoQuestions"))
		return
	end

	self.statusLabel:SetText(string.format("ASKER: %s | %s", question.asker or "UNKNOWN", question.title or "QUESTION"))
end

function CIVIC:LoadComputer(entity, _, powered, context)
	self.entity = entity
	self.context = context or {}
	SetTerminalPowerState(self, powered)
	self.context.data = self.context.data or {}
	self.context.data.announcements = self.context.data.announcements or {}
	self.context.data.agendas = self.context.data.agendas or {}
	self.context.data.questions = self.context.data.questions or {}
	self.backButton:SetVisible(self.context.fromCombine == true)
	self:PopulateActivePostList()
	self:PopulateQuestions()
	self:UpdateVisibleState()
	self:UpdateStatus()
end

function CIVIC:Think()
	if (IsValid(self.entity) and LocalPlayer():GetPos():DistToSqr(self.entity:GetPos()) > 190 * 190) then
		self:Close()
		return
	end

	local wasBooting = IsBootSequenceActive(self)
	UpdateBootSequence(self)

	if (wasBooting != IsBootSequenceActive(self)) then
		self:UpdateVisibleState()
		self:UpdateStatus()
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
	StyleCombineButton(frame.announcementTabButton)
	StyleCombineButton(frame.propagandaTabButton)
	StyleCombineButton(frame.questionsTabButton)
	StyleCombineButton(frame.postNewButton)
	StyleCombineButton(frame.postDeleteButton)
	StyleCombineButton(frame.saveButton)
	StyleCombineButton(frame.questionNewButton)
	StyleCombineButton(frame.askButton)
	StyleCombineButton(frame.answerButton)
	StyleCombineButton(frame.questionDeleteButton)
	StyleCombineButton(frame.postScrollUpButton)
	StyleCombineButton(frame.postScrollDownButton)
	StyleCombineButton(frame.questionScrollUpButton)
	StyleCombineButton(frame.questionScrollDownButton)
	frame.closeButton.Paint = function(_, width, height)
		surface.SetDrawColor(0, 0, 0, 0)
		surface.DrawRect(0, 0, width, height)
		surface.SetDrawColor(COMBINE_TEXT.r, COMBINE_TEXT.g, COMBINE_TEXT.b, 130)
		surface.DrawOutlinedRect(0, 0, width, height, 1)
	end
	frame.powerButton.Paint = frame.closeButton.Paint
	frame.backButton.Paint = frame.closeButton.Paint
	StyleCombineListView(frame.postList)
	StyleCombineTextEntry(frame.announcementEntry)
	StyleCombineTextEntry(frame.propagandaEntry)
	StyleCombineTextEntry(frame.questionEntry)
	StyleCombineTextEntry(frame.questionBodyEntry)
	StyleCombineTextEntry(frame.answerEntry)
	StyleCombineListView(frame.questionList)
	BindButtonClickSound(frame.closeButton, frame)
	BindButtonClickSound(frame.powerButton, frame)
	BindButtonClickSound(frame.backButton, frame)
	BindButtonClickSound(frame.announcementTabButton, frame)
	BindButtonClickSound(frame.propagandaTabButton, frame)
	BindButtonClickSound(frame.questionsTabButton, frame)
	BindButtonClickSound(frame.postNewButton, frame)
	BindButtonClickSound(frame.postDeleteButton, frame)
	BindButtonClickSound(frame.saveButton, frame)
	BindButtonClickSound(frame.questionNewButton, frame)
	BindButtonClickSound(frame.askButton, frame)
	BindButtonClickSound(frame.answerButton, frame)
	BindButtonClickSound(frame.questionDeleteButton, frame)
	BindButtonClickSound(frame.postScrollUpButton, frame)
	BindButtonClickSound(frame.postScrollDownButton, frame)
	BindButtonClickSound(frame.questionScrollUpButton, frame)
	BindButtonClickSound(frame.questionScrollDownButton, frame)
	BindEnterSound(frame.announcementEntry, frame)
	BindEnterSound(frame.propagandaEntry, frame)
	BindEnterSound(frame.questionEntry, frame)
	BindEnterSound(frame.questionBodyEntry, frame)
	BindEnterSound(frame.answerEntry, frame)
end

OpenComputerUI = function(entity, data, powered, context)
	if (IsValid(ix.gui.interactiveComputer)) then
		ix.gui.interactiveComputer:Remove()
	end

	local frameClass = "ixInteractiveComputerTerminal"

	if (context and context.combineJournal) then
		frameClass = "ixInteractiveCombineJournalTerminal"
	elseif (context and context.civicPanel) then
		frameClass = "ixInteractiveCivicTerminal"
	elseif (context and context.combineTerminal) then
		frameClass = "ixInteractiveCombineTerminal"
	end

	local frame = vgui.Create(frameClass)

	if (frameClass == "ixInteractiveCombineJournalTerminal") then
		ApplyCombineJournalStyling(frame)
		frame:LoadComputerContext(entity, data, powered, context)
	elseif (frameClass == "ixInteractiveCombineTerminal") then
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
