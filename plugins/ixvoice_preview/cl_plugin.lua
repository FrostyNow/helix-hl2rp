local PLUGIN = PLUGIN
local animationTime = 0.5

-- Voice autocomplete entry
local PANEL = {}

AccessorFunc(PANEL, "bSelected", "Highlighted", FORCE_BOOL)

function PANEL:Init()
	self:Dock(TOP)

	self.name = self:Add("DLabel")
	self.name:Dock(TOP)
	self.name:DockMargin(4, 4, 0, 0)
	self.name:SetContentAlignment(4)
	self.name:SetFont("ixChatFont")
	self.name:SetTextColor(ix.config.Get("color"))
	self.name:SetExpensiveShadow(1, color_black)

	self.description = self:Add("DLabel")
	self.description:Dock(BOTTOM)
	self.description:DockMargin(4, 4, 0, 4)
	self.description:SetContentAlignment(4)
	self.description:SetFont("ixChatFont")
	self.description:SetTextColor(color_white)
	self.description:SetExpensiveShadow(1, color_black)

	self.highlightAlpha = 0
end

function PANEL:SetHighlighted(bValue)
	self:CreateAnimation(animationTime * 2, {
		index = 7,
		target = {highlightAlpha = bValue and 1 or 0},
		easing = "outQuint"
	})

	self.bHighlighted = true
end

function PANEL:SetVoice(key, info)
	self.name:SetText(string.upper(key))

	local text = info.text
	if (!text and info.table) then
		text = info.table[1][1] or "(Random Voice)"
	end
	
	if (text and text != "") then
		self.description:SetText(text)
	else
		self.description:SetVisible(false)
	end

	self:SizeToContents()
	self.voiceKey = key
end

function PANEL:SizeToContents()
	local bDescriptionVisible = self.description:IsVisible()
	local _, height = self.name:GetContentSize()

	self.name:SetTall(height)

	if (bDescriptionVisible) then
		_, height = self.description:GetContentSize()
		self.description:SetTall(height)
	else
		self.description:SetTall(0)
	end

	self:SetTall(self.name:GetTall() + self.description:GetTall() + (bDescriptionVisible and 12 or 8))
end

function PANEL:Paint(width, height)
	derma.SkinFunc("PaintChatboxAutocompleteEntry", self, width, height)
end

vgui.Register("ixVoiceAutocompleteEntry", PANEL, "Panel")

-- Voice autocomplete
PANEL = {}
DEFINE_BASECLASS("Panel")

AccessorFunc(PANEL, "maxEntries", "MaxEntries", FORCE_NUMBER)

function PANEL:Init()
	self:SetVisible(false, true)
	self:SetMouseInputEnabled(true)

	self.maxEntries = 20
	self.currentAlpha = 0

	self.voiceIndex = 0 
	self.voices = {}
	self.voicePanels = {}
end

function PANEL:GetVoices()
	return self.voices
end

function PANEL:IsOpen()
	return self.bOpen
end

function PANEL:SetVisible(bValue, bForce)
	if (bForce) then
		BaseClass.SetVisible(self, bValue)
		return
	end

	BaseClass.SetVisible(self, true) 
	self.bOpen = bValue

	self:CreateAnimation(animationTime, {
		index = 6,
		target = {
			currentAlpha = bValue and 255 or 0
		},
		easing = "outQuint",

		Think = function(animation, panel)
			panel:SetAlpha(math.ceil(panel.currentAlpha))
		end,

		OnComplete = function(animation, panel)
			BaseClass.SetVisible(panel, bValue)

			if (!bValue) then
				self.voices = {}
			end
		end
	})
end

function PANEL:Update(text)
	local originalText = text

	-- Ensure case-insensitivity depending on voice keys, usually they are lower in storage
	text = string.lower(text)
	
	local classes = Schema.voices.GetClass(LocalPlayer())
	
	self.voiceIndex = 0 
	self.voices = {}

	for _, v in ipairs(self.voicePanels) do
		v:Remove()
	end

	self.voicePanels = {}

	local i = 1
	local bSelected 

	-- Collect matches finding voices that start with the text
	local matches = {}
	for _, class in ipairs(classes) do
		local stored = Schema.voices.stored[string.lower(class)]
		if (stored) then
			for key, info in pairs(stored) do
				if (string.StartsWith(string.lower(key), text)) then
					table.insert(matches, {key = key, info = info})
				end
			end
		end
	end
	
	-- Sort matches alphabetically
	table.sort(matches, function(a, b)
		return a.key < b.key
	end)

	for _, v in ipairs(matches) do
		local panel = self:Add("ixVoiceAutocompleteEntry")
		panel:SetVoice(v.key, v.info)

		if (!bSelected and string.lower(v.key) == text) then
			panel:SetHighlighted(true)
			self.voiceIndex = i
			bSelected = true
		end

		self.voicePanels[i] = panel
		self.voices[i] = v

		if (i == self.maxEntries) then
			break
		end

		i = i + 1
	end
end

function PANEL:SelectNext()
	if (self.voiceIndex == #self.voices) then
		self.voiceIndex = 1
	else
		self.voiceIndex = self.voiceIndex + 1
	end

	for k, v in ipairs(self.voicePanels) do
		if (k == self.voiceIndex) then
			v:SetHighlighted(true)
			self:ScrollToChild(v)
		else
			v:SetHighlighted(false)
		end
	end

	return self.voices[self.voiceIndex].key .. " "
end

function PANEL:Paint(width, height)
	ix.util.DrawBlur(self)
	surface.SetDrawColor(0, 0, 0, 200)
	surface.DrawRect(0, 0, width, height)
end

vgui.Register("ixVoiceAutocomplete", PANEL, "DScrollPanel")

local function PatchChatboxEntry(chatbox)
	if (!IsValid(chatbox.entry)) then return end
	if (chatbox.entry.bVoicePatch) then return end
	
	local oldOnKeyCodeTyped = chatbox.entry.OnKeyCodeTyped
	chatbox.entry.OnKeyCodeTyped = function(self, key)
		if (key == KEY_TAB) then
			if (IsValid(chatbox.voiceAutocomplete) and chatbox.voiceAutocomplete:IsOpen() and #chatbox.voiceAutocomplete:GetVoices() > 0) then
				local newText = chatbox.voiceAutocomplete:SelectNext()
				
				-- If they had a chat class prefix at the start, append it back
				local oldText = self:GetText()
				local start, _, command = oldText:find("^(/(%S+)%s+)")
                
                -- Support OOC too if needed but OOC is //
                if (!start) then
                    start, _, command = oldText:find("^((//|/w|/y|/me|/it)%s+)")
                end

				if (start == 1) then
					newText = command .. newText
				end

				self:SetText(newText)
				-- Ensure caret is correctly placed
				if utf8 and utf8.len then
					self:SetCaretPos(utf8.len(newText) or string.len(newText))
				else
					self:SetCaretPos(string.len(newText))
				end
				return true
			end
		end
		
		return oldOnKeyCodeTyped(self, key)
	end
	
	chatbox.entry.bVoicePatch = true
end

function PLUGIN:ChatTextChanged(text)
	if (!IsValid(ix.gui.chat)) then return end
	
	PatchChatboxEntry(ix.gui.chat)

	if (!IsValid(ix.gui.chat.voiceAutocomplete)) then
		ix.gui.chat.voiceAutocomplete = ix.gui.chat.tabs:Add("ixVoiceAutocomplete")
		ix.gui.chat.voiceAutocomplete:Dock(FILL)
		ix.gui.chat.voiceAutocomplete:DockMargin(4, 3, 4, 4)
		ix.gui.chat.voiceAutocomplete:SetZPos(3)
		ix.gui.chat.voiceAutocomplete:SetVisible(false, true)
	end
	
	local voiceAutocomplete = ix.gui.chat.voiceAutocomplete
	
	-- We only show it if the player is typing an IC chat
	local chatClassCommand = ix.gui.chat:GetTextEntryChatClass(text)
	if (chatClassCommand and chatClassCommand != "ic" and chatClassCommand != "w" and chatClassCommand != "y" and chatClassCommand != "radio") then
		if (voiceAutocomplete:IsVisible()) then
			voiceAutocomplete:SetVisible(false)
		end
		return
	end

	local matchText = text

	-- If starts with "/", ignore normal autocomplete commands except class prefix
    if (text:sub(1, 1) == "/") then
        -- We only care if the first word is a valid chat class prefix for IC/w/y/radio
        local start, _, command = text:find("^(/(%w+)%s+)")
        if (start == 1) then
            matchText = text:sub(string.len(command) + 1)
        else
            -- Probably typing a command, so hide our voice autocomplete
            if (voiceAutocomplete:IsVisible()) then
                voiceAutocomplete:SetVisible(false)
            end
            return
        end
    end

    -- Support //
    if (text:sub(1, 2) == "//") then
        if (voiceAutocomplete:IsVisible()) then
            voiceAutocomplete:SetVisible(false)
        end
        return
    end

	matchText = string.TrimLeft(matchText)
	if (matchText == "") then
		if (voiceAutocomplete:IsVisible()) then
			voiceAutocomplete:SetVisible(false)
		end
		return
	end

	voiceAutocomplete:Update(matchText)
	
	if (#voiceAutocomplete:GetVoices() > 0) then
		voiceAutocomplete:SetVisible(true)
		if (IsValid(ix.gui.chat.autocomplete) and ix.gui.chat.autocomplete:IsVisible()) then
			ix.gui.chat.autocomplete:SetVisible(false)
		end
	else
		if (voiceAutocomplete:IsVisible()) then
			voiceAutocomplete:SetVisible(false)
		end
	end
end
