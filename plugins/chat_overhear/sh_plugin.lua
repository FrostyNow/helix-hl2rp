local PLUGIN = PLUGIN or {}
PLUGIN.name = "Chat Overhear"
PLUGIN.author = "Frosty"
PLUGIN.description = "Displays overheard chat messages with transparency based on the distance between players."

PLUGIN.license = [[
Copyright © 2026 Frosty

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/
]]

ix.config.Add("overhearScale", 1.2, "Maximum distance multiplier for overhearing.", nil, {
	data = {min = 1.0, max = 5.0, decimals = 1},
	category = "chat"
})

ix.config.Add("overhearFadeStart", 0.3, "Distance multiplier where transparency starts (relative to original range).", nil, {
	data = {min = 0.0, max = 1.0, decimals = 2},
	category = "chat"
})

ix.config.Add("overhearMinAlpha", 1, "Minimum alpha percentage for overheard messages (0-100%).", nil, {
	data = {min = 0, max = 100},
	category = "chat"
})

-- Function to register overheard chat classes
local function RegisterOverhear(baseType)
	local base = ix.chat.classes[baseType]
	if (!base) then return end

	local data = table.Copy(base)
	data.uniqueID = baseType .. "_overhear"
	data.prefix = nil -- Cannot be used as a chat command
	data.description = nil
	
	-- Override OnChatAdd to apply the received transparency
	local oldOnChatAdd = data.OnChatAdd
	data.OnChatAdd = function(self, speaker, text, anonymous, info)
		local alpha = (info and info.overhearAlpha) or 255
		self.overhearAlpha = alpha
		local oldChatAddText = chat.AddText
		
		-- Temporarily intercept chat.AddText to apply alpha to all color arguments
		chat.AddText = function(...)
			local args = {...}
			for k, v in ipairs(args) do
				if (istable(v) and v.r and v.g and v.b) then
					args[k] = Color(v.r, v.g, v.b, alpha)
				end
			end
			oldChatAddText(unpack(args))
		end
		
		oldOnChatAdd(self, speaker, text, anonymous, info)
		chat.AddText = oldChatAddText
		self.overhearAlpha = nil
	end

	ix.chat.Register(data.uniqueID, data)
end

function PLUGIN:InitializedChatClasses()
	-- Default targets: IC, Y, W
	local targets = {"ic", "y", "w"}

	-- Compatibility with Extended Radio plugin
	if (ix.plugin.Get("radio_extended") or ix.plugin.Get("extended_radio")) then
		-- Exclude purely frequency-based radio chats; only add eavesdrop (local overheard) variants.
		table.Add(targets, {"radio_eavesdrop", "radio_eavesdrop_yell", "radio_eavesdrop_whisper"})
	end

	-- Compatibility with Vortigaunt Stuff plugin (Vortigese)
	if (ix.plugin.Get("vortigaunt_stuff")) then
		table.insert(targets, "Vortigese")
	end

	local overhearScale = ix.config.Get("overhearScale", 1.2)
	for _, v in ipairs(targets) do
		local class = ix.chat.classes[v]
		if (class) then
			-- Fix for inflation bug: store the original range to prevent it from growing on every reload
			if (!class.baseRangeSqr) then
				-- Handle if GetRange function exists (common in Extended Radio)
				if (class.GetRange) then
					local r = class:GetRange()
					class.baseRangeSqr = r * r
				elseif (class.range) then
					class.baseRangeSqr = class.range
				end
			end

			if (class.baseRangeSqr) then
				class.range = class.baseRangeSqr * (overhearScale * overhearScale)
			end

			-- Register the overhear-specific class
			RegisterOverhear(v)
		end
	end
end

-- Hook to ensure overhear chat types are treated as 'recognizable' by the recognition system.
-- This prevents the GetCharacterName hook from returning the real name for unrecognized characters.
function PLUGIN:IsRecognizedChatType(chatType)
	if (chatType:find("_overhear$")) then
		return true
	end
end

-- Hook to ensure correct name color (chat color vs faction color) for unrecognized characters.
function PLUGIN:GetPlayerChatColor(client, chatClass)
	if (chatClass and chatClass.uniqueID:find("_overhear$")) then
		local character = client:GetCharacter()
		local ourCharacter = LocalPlayer():GetCharacter()
		local bRecognized = (ourCharacter and character and (ourCharacter:DoesRecognize(character) or hook.Run("IsPlayerRecognized", client)))

		-- MODIFIED: Only apply chatListenColor highlight to UNRECOGNIZED targets
		if (LocalPlayer():GetEyeTrace().Entity == client) then
			if (!bRecognized) then
				return ix.config.Get("chatListenColor")
			end
			-- If recognized, return nil so it uses the faction/unique color as requested
			return nil
		end

		-- If the speaker is not recognized, force the chat color (no faction coloring)
		if (!bRecognized) then
			return chatClass.color or ix.config.Get("chatColor")
		end
	end
end

if (CLIENT) then
	-- Calculate transparency and switch class based on distance when a message is received
	function PLUGIN:MessageReceived(speaker, info)
		local chatType = info.chatType
		-- Ignore types already processed with _overhear
		if (chatType:find("_overhear$")) then return end

		local class = ix.chat.classes[chatType]
		if (class and IsValid(speaker) and speaker:IsPlayer()) then
			local overhearScale = ix.config.Get("overhearScale", 1.2)
			-- Use baseRangeSqr if available, otherwise fallback to class.range
			local rangeSqr = class.baseRangeSqr or class.range
			
			-- Attempt real-time range calculation if range property is missing
			if (!rangeSqr and class.GetRange) then
				local r = class:GetRange()
				rangeSqr = r * r
			end

			if (rangeSqr) then
				local dist = (speaker:GetPos() - LocalPlayer():GetPos()):Length()
				-- Calculate the original range (1.0x)
				local normalRange = math.sqrt(rangeSqr)
				
				local fadeStartScale = ix.config.Get("overhearFadeStart", 0.3)
				local minDist = normalRange * fadeStartScale
				local maxDist = normalRange * overhearScale
				
				-- Apply processing if distance exceeds the fade start point
				if (dist > minDist) then
					-- Calculate alpha based on distance ratio
					local fraction = math.Clamp((dist - minDist) / (maxDist - minDist), 0, 1)
					-- Convert percentage config to 0-255 alpha value
					local minAlpha = (ix.config.Get("overhearMinAlpha", 1) / 100) * 255
					local alpha = Lerp(fraction, 255, minAlpha)
					
					info.data = info.data or {}
					info.data.overhearAlpha = alpha
					info.chatType = chatType .. "_overhear"
				end
			end
		end
	end

	-- [UI Patch] Runtime fixes to handle Alpha in Helix Chatbox UI
	function PLUGIN:InitPostEntity()
		-- Function to patch a chat history table to support alpha in markup
		local function PatchHistoryTable(name)
			local historyTable = vgui.GetControlTable(name)
			if (historyTable and historyTable.AddLine) then
				-- We don't call oldAddLine because we need to change how the buffer is constructed.
				function historyTable:AddLine(elements, bShouldScroll)
					local maxChatEntries = 100 -- Default Helix limit

					local buffer = {
						"<font=ixChatFont>"
					}

					-- Robustly extract overhearAlpha FIRST so it can be used for timestamps and special elements
					local overhearAlpha = 255
					if (CHAT_CLASS and CHAT_CLASS.uniqueID:find("_overhear$") and CHAT_CLASS.overhearAlpha) then
						overhearAlpha = CHAT_CLASS.overhearAlpha
					else
						-- Fallback: Scan elements for colors with alpha < 255
						for _, v in ipairs(elements) do
							if (istable(v) and v.r and v.g and v.b and v.a and v.a < 255) then
								overhearAlpha = v.a
								break
							end
						end
					end

					if (ix.option.Get("chatTimestamps", false)) then
						local tsColor = Color(150, 150, 150, overhearAlpha)
						buffer[#buffer + 1] = string.format("<color=%d,%d,%d,%d>(", tsColor.r, tsColor.g, tsColor.b, tsColor.a)
						buffer[#buffer + 1] = (ix.option.Get("24hourTime", false) and os.date("%H:%M") or os.date("%I:%M %p"))
						buffer[#buffer + 1] = ")</color> " -- Added closing tag and trailing space
					end

					if (CHAT_CLASS) then
						buffer[#buffer + 1] = string.format("<font=%s>", CHAT_CLASS.font or "ixChatFont")
					end

					for _, v in ipairs(elements) do
						if (type(v) == "IMaterial") then
							local texture = v:GetName()
							if (texture) then
								buffer[#buffer + 1] = string.format("<img=%s,%dx%d> ", texture, v:Width(), v:Height())
							end
						elseif (istable(v) and v.r and v.g and v.b) then
							buffer[#buffer + 1] = string.format("<color=%d,%d,%d,%d>", v.r, v.g, v.b, v.a or 255)
						elseif (type(v) == "Player" or (istable(v) and v.IsPlayer and v:IsPlayer())) then
							local color = hook.Run("GetPlayerChatColor", v, CHAT_CLASS) or team.GetColor(v:Team())
							local name = hook.Run("GetCharacterName", v, CHAT_CLASS and CHAT_CLASS.uniqueID) or v:GetName()
							
							-- Apply overhear alpha to the player's name color
							local r, g, b, a = color.r, color.g, color.b, (color.a or 255)
							if (overhearAlpha < 255) then
								a = (a * overhearAlpha) / 255
							end

							buffer[#buffer + 1] = string.format("<color=%d,%d,%d,%d>%s", r, g, b, a,
								name:gsub("<", "&lt;"):gsub(">", "&gt;"))
						else
							-- Standard Helix processing for strings and other types
							buffer[#buffer + 1] = tostring(v):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub("%%", "%%%%"):gsub("%b**", function(value)
								local inner = value:utf8sub(2, -2)
								if (inner:find("%S")) then
									return "<font=ixChatFontItalics>" .. inner .. "</font>"
								end
							end)
						end
					end

					local panel = self:Add("ixChatMessage")
					panel:Dock(TOP)
					panel:InvalidateParent(true)
					panel:SetMarkup(table.concat(buffer))
					
					-- MODIFIED: Attach the calculated transparency to the panel
					panel.overhearAlpha = overhearAlpha

					-- FINAL FIX: Manually inject alpha into the parsed markup blocks
					-- This is the only way to reliably override the internal drawing alpha
					-- HELIX NOTE: The property is 'colour', not 'color'
					if (panel.markup and panel.markup.blocks and overhearAlpha < 255) then
						for _, block in ipairs(panel.markup.blocks) do
							if (block.colour) then
								block.colour.a = overhearAlpha
							end
						end
					end

					if (#self.entries >= maxChatEntries) then
						local oldPanel = table.remove(self.entries, 1)
						if (IsValid(oldPanel)) then
							oldPanel:Remove()
						end
					end

					self.entries[#self.entries + 1] = panel
					return panel
				end
			end
		end

		-- Patch BOTH standard and radio chat history
		PatchHistoryTable("ixChatboxHistory")
		PatchHistoryTable("radioChatboxHistory")
	end




end
