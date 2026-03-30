local PLUGIN = PLUGIN or {}
PLUGIN.name = "Chat Overhear"
PLUGIN.author = "Frosty"
PLUGIN.description = "Displays overheard chat messages with transparency based on the distance between players."

ix.config.Add("overhearScale", 1.3, "Maximum distance multiplier for overhearing.", nil, {
	data = {min = 1.0, max = 5.0, decimals = 1},
	category = "chat"
})

ix.config.Add("overhearFadeStart", 0.5, "Distance multiplier where transparency starts (relative to original range).", nil, {
	data = {min = 0.0, max = 1.0, decimals = 2},
	category = "chat"
})

ix.config.Add("overhearMinAlpha", 5, "Minimum alpha percentage for overheard messages (0-100%).", nil, {
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

	local overhearScale = ix.config.Get("overhearScale", 1.3)
	for _, v in ipairs(targets) do
		local class = ix.chat.classes[v]
		if (class) then
			-- Handle if range is a number
			if (class.range) then
				class.range = class.range * (overhearScale * overhearScale)
			-- Handle if GetRange function exists (common in Extended Radio)
			elseif (class.GetRange) then
				local r = class:GetRange()
				class.range = r * r * (overhearScale * overhearScale)
			end
			
			-- Register the overhear-specific class
			RegisterOverhear(v)
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
			local overhearScale = ix.config.Get("overhearScale", 1.3)
			-- Attempt real-time range calculation if range property is missing
			local rangeSqr = class.range
			if (!rangeSqr and class.GetRange) then
				local r = class:GetRange()
				rangeSqr = r * r * (overhearScale * overhearScale)
			end

			if (rangeSqr) then
				local dist = (speaker:GetPos() - LocalPlayer():GetPos()):Length()
				-- Calculate the original range (1.0x)
				local normalRange = math.sqrt(rangeSqr / (overhearScale * overhearScale))
				
				local fadeStartScale = ix.config.Get("overhearFadeStart", 0.5)
				local minDist = normalRange * fadeStartScale
				local maxDist = normalRange * overhearScale
				
				-- Apply processing if distance exceeds the fade start point
				if (dist > minDist) then
					-- Calculate alpha based on distance ratio
					local fraction = math.Clamp((dist - minDist) / (maxDist - minDist), 0, 1)
					-- Convert percentage config to 0-255 alpha value
					local minAlpha = (ix.config.Get("overhearMinAlpha", 5) / 100) * 255
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
		-- 1. Patch ixChatboxHistory:AddLine to preserve alpha values in Color objects
		local historyTable = vgui.GetControlTable("ixChatboxHistory")
		if (historyTable and historyTable.AddLine) then
			local oldAddLine = historyTable.AddLine
			function historyTable:AddLine(elements, bShouldScroll)
				for k, v in ipairs(elements) do
					-- Helix default only uses <color=r,g,b>; we modify it to <color=r,g,b,a>
					if (istable(v) and v.r and v.g and v.b and v.a) then
						elements[k] = string.format("<color=%d,%d,%d,%d>", v.r, v.g, v.b, v.a)
					end
				end
				return oldAddLine(self, elements, bShouldScroll)
			end
		end

		-- 2. Patch ixChatMessage:Paint to merge individual alpha with the overall fade alpha
		local messageTable = vgui.GetControlTable("ixChatMessage")
		if (messageTable) then
			-- Define the actual drawing logic for text
			local function NewPaintMarkupOverride(text, font, x, y, color, alignX, alignY, alpha)
				-- Multiply the character's unique alpha (color.a) with the line's fade alpha (alpha)
				local targetAlpha = ( (color.a or 255) * (alpha or 255) ) / 255
				
				if (ix.option.Get("chatOutline", false)) then
					draw.SimpleTextOutlined(text, font, x, y, ColorAlpha(color, targetAlpha), alignX, alignY, 1, Color(0, 0, 0, targetAlpha))
				else
					-- Shadow rendering
					surface.SetTextPos(x + 1, y + 1)
					surface.SetTextColor(0, 0, 0, targetAlpha)
					surface.SetFont(font)
					surface.DrawText(text)

					-- Main transparent text
					surface.SetTextPos(x, y)
					surface.SetTextColor(color.r, color.g, color.b, targetAlpha)
					surface.SetFont(font)
					surface.DrawText(text)
				end
			end

			local oldSetMarkup = messageTable.SetMarkup
			function messageTable:SetMarkup(text)
				oldSetMarkup(self, text)
				if (self.markup) then
					-- Inject the custom drawing function into the markup object
					self.markup.onDrawText = NewPaintMarkupOverride
				end
			end
		end
	end
end
