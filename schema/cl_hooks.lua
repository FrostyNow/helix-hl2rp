
function Schema:PopulateCharacterInfo(client, character, tooltip)
	if (client:IsRestricted()) then
		local panel = tooltip:AddRowAfter("name", "ziptie")
		panel:SetBackgroundColor(derma.GetColor("Warning", tooltip))
		panel:SetText(L("tiedUp"))
		panel:SizeToContents()
	elseif (client:GetNetVar("tying")) then
		local panel = tooltip:AddRowAfter("name", "ziptie")
		panel:SetBackgroundColor(derma.GetColor("Warning", tooltip))
		panel:SetText(L("beingTied"))
		panel:SizeToContents()
	elseif (client:GetNetVar("untying")) then
		local panel = tooltip:AddRowAfter("name", "ziptie")
		panel:SetBackgroundColor(derma.GetColor("Warning", tooltip))
		panel:SetText(L("beingUntied"))
		panel:SizeToContents()
	end
end

function Schema:CalcView(client, origin, angles, fov)
	if (!client:Alive()) then
		local ragdoll
		-- Find the active corpse (if one exists with the NetVar)
		for _, v in ipairs(ents.FindByClass("prop_ragdoll")) do
			if (v:GetNetVar("player") == client) then
				ragdoll = v
				break
			end
		end

		if (IsValid(ragdoll)) then
			local center = ragdoll:WorldSpaceCenter()
			local view = {}
			
			-- Use the player's eye angles for rotation
			local angles = client:EyeAngles()
			
			view.origin = center + (angles:Forward() * -100) + Vector(0, 0, 10)
			view.angles = angles
			
			-- Collision trace
			local trace = util.TraceHull({
				start = center,
				endpos = view.origin,
				mins = Vector(-8, -8, -8),
				maxs = Vector(8, 8, 8),
				filter = ragdoll
			})
			
			if (trace.Hit) then
				view.origin = trace.HitPos + trace.HitNormal * 4
			end
			
			return view
		end
	end
end

local COMMAND_PREFIX = "/"

function Schema:ChatTextChanged(text)
	if (LocalPlayer():IsCombine()) then
		local key = nil

		if (text == COMMAND_PREFIX .. "radio") then
			key = "r"
		elseif (text == COMMAND_PREFIX .. "w ") then
			key = "w"
		elseif (text == COMMAND_PREFIX .. "y ") then
			key = "y"
		elseif (text:sub(1, 1):match("%w")) then
			key = "t"
		end

		if (key) then
			netstream.Start("PlayerChatTextChanged", key)
		end
	end
end

function Schema:FinishChat()
	netstream.Start("PlayerFinishChat")
end

function Schema:CanPlayerJoinClass(client, class, info)
	return client:IsAdmin()
end

function Schema:CharacterLoaded(character)
	if (character:IsCombine()) then
		vgui.Create("ixCombineDisplay")
	elseif (IsValid(ix.gui.combine)) then
		ix.gui.combine:Remove()
	end
end

-- function Schema:PlayerFootstep(client, position, foot, soundName, volume)
-- 	return true
-- end

local COLOR_BLACK_WHITE = {
	["$pp_colour_addr"] = 0,
	["$pp_colour_addg"] = 0,
	["$pp_colour_addb"] = 0,
	["$pp_colour_brightness"] = 0,
	["$pp_colour_contrast"] = 1.5,
	["$pp_colour_colour"] = 0,
	["$pp_colour_mulr"] = 0,
	["$pp_colour_mulg"] = 0,
	["$pp_colour_mulb"] = 0
}

local combineOverlay = ix.util.GetMaterial("effects/combine_binocoverlay")
local cinematicOverlay = ix.util.GetMaterial("nco/cinover")
-- local scannerFirstPerson = false

function Schema:RenderScreenspaceEffects()
	local colorModify = {}
	colorModify["$pp_colour_colour"] = 0.77

	if (system.IsWindows()) then
		colorModify["$pp_colour_brightness"] = -0.02
		colorModify["$pp_colour_contrast"] = 1.2
	else
		colorModify["$pp_colour_brightness"] = 0
		colorModify["$pp_colour_contrast"] = 1
	end

	-- if (scannerFirstPerson) then
	-- 	COLOR_BLACK_WHITE["$pp_colour_brightness"] = 0.05 + math.sin(RealTime() * 10) * 0.01
	-- 	colorModify = COLOR_BLACK_WHITE
	-- end

	DrawColorModify(colorModify)

	if (LocalPlayer():IsCombine()) then
		render.UpdateScreenEffectTexture()

		combineOverlay:SetFloat("$alpha", 0.1)
		combineOverlay:SetInt("$ignorez", 1)

		render.SetMaterial(combineOverlay)
		render.DrawScreenQuad()
	else
		render.UpdateScreenEffectTexture()
		render.SetMaterial(cinematicOverlay)
		render.DrawScreenQuad()
	end
end

-- function Schema:PreDrawOpaqueRenderables()
-- 	local viewEntity = LocalPlayer():GetViewEntity()

-- 	if (IsValid(viewEntity) and viewEntity:GetClass():find("scanner")) then
-- 		self.LastViewEntity = viewEntity
-- 		self.LastViewEntity:SetNoDraw(true)

-- 		scannerFirstPerson = true
-- 		return
-- 	end

-- 	if (self.LastViewEntity != viewEntity) then
-- 		if (IsValid(self.LastViewEntity)) then
-- 			self.LastViewEntity:SetNoDraw(false)
-- 		end

-- 		self.LastViewEntity = nil
-- 		scannerFirstPerson = false
-- 	end
-- end

function Schema:ShouldDrawCrosshair()
	local client = LocalPlayer()
	local weapon = client:GetActiveWeapon()
	
	if (weapon and weapon:IsValid()) then
		local class = weapon:GetClass()
		
		if (class:find("ix_") or class:find("weapon_physgun") or class:find("gmod_tool")) then
			return true
		elseif (!client:IsWepRaised()) then
			return true
		else
			return false
		end
	end
end

-- function Schema:AdjustMouseSensitivity()
-- 	if (scannerFirstPerson) then
-- 		return 0.3
-- 	end
-- end

-- creates labels in the status screen
function Schema:CreateCharacterInfo(panel)
	if (LocalPlayer():Team() == FACTION_CITIZEN) then
		panel.cid = panel:Add("ixListRow")
		panel.cid:SetList(panel.list)
		panel.cid:Dock(TOP)
		panel.cid:DockMargin(0, 0, 0, 8)
	end
end

-- populates labels in the status screen
function Schema:UpdateCharacterInfo(panel)
	if (LocalPlayer():Team() == FACTION_CITIZEN) then
		panel.cid:SetLabelText(L("citizenid"))
		panel.cid:SetText(string.format("##%s", LocalPlayer():GetCharacter():GetData("cid") or "UNKNOWN"))
		panel.cid:SizeToContents()
	end
end

function Schema:BuildBusinessMenu(panel)
	return LocalPlayer():IsAdmin()
end

function Schema:PopulateHelpMenu(tabs)
	tabs["voices"] = function(container)
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
					return variant[1]
				end
			end

			return command
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

		local classes = {}
		local classLookup = {}

		for k, v in pairs(Schema.voices.classes) do
			classes[#classes + 1] = k
			classLookup[k] = v
		end

		if (#classes < 1) then
			local info = container:Add("DLabel")
			info:SetFont("ixSmallFont")
			info:SetText("No voice lines are available.")
			info:SetContentAlignment(5)
			info:SetTextColor(color_white)
			info:SetExpensiveShadow(1, color_black)
			info:Dock(TOP)
			info:DockMargin(0, 0, 0, 8)
			info:SizeToContents()
			info:SetTall(info:GetTall() + 16)

			info.Paint = function(_, width, height)
				surface.SetDrawColor(ColorAlpha(derma.GetColor("Error", info), 160))
				surface.DrawRect(0, 0, width, height)
			end

			return
		end

		table.sort(classes, function(a, b)
			return a < b
		end)

		for _, class in ipairs(classes) do
			local available = classLookup[class] and classLookup[class].condition(LocalPlayer()) or false
			local accent = getClassColor(class)
			local category = container:Add("DCollapsibleCategory")

			category:Dock(TOP)
			category:DockMargin(0, 0, 0, 8)
			category:SetExpanded(false)
			category:SetLabel(string.upper(class))
			category.Paint = function(_, width, height)
				surface.SetDrawColor(ColorAlpha(accent, 22))
				surface.DrawRect(0, 0, width, height)
			end

			if (IsValid(category.Header)) then
				category.Header:SetTextColor(available and color_white or Color(170, 170, 170))
			end

			local content = vgui.Create("DPanel", category)
			content:DockPadding(8, 8, 8, 8)
			content.Paint = nil
			category:SetContents(content)

			local commands = {}

			for command, info in pairs(self.voices.stored[class] or {}) do
				commands[#commands + 1] = {
					command = command,
					info = info
				}
			end

			table.sort(commands, function(a, b)
				return naturalCommandLess(a.command, b.command)
			end)

			for _, entry in ipairs(commands) do
				local title = content:Add("DLabel")
				title:SetFont("ixMediumLightFont")
				title:SetText(entry.command:upper())
				title:Dock(TOP)
				title:SetTextColor(accent)
				title:SetExpensiveShadow(1, color_black)
				title:SizeToContents()

				local description = content:Add("DLabel")
				description:SetFont("ixSmallFont")
				description:SetText(getVoicePreviewText(entry.command, entry.info))
				description:Dock(TOP)
				description:SetTextColor(available and color_white or Color(180, 180, 180))
				description:SetExpensiveShadow(1, color_black)
				description:SetWrap(true)
				description:SetAutoStretchVertical(true)
				description:SizeToContents()
				description:DockMargin(0, 0, 0, 8)
			end
		end
	end
end

netstream.Hook("CombineDisplayMessage", function(text, color, arguments)
	if (IsValid(ix.gui.combine)) then
		ix.gui.combine:AddLine(text, color, nil, unpack(arguments))
	end
end)

netstream.Hook("PlaySound", function(sound)
	surface.PlaySound(sound)
end)

netstream.Hook("Frequency", function(oldFrequency)
	Derma_StringRequest("Frequency", "What would you like to set the frequency to?", oldFrequency, function(text)
		ix.command.Send("SetFreq", text)
	end)
end)

netstream.Hook("ViewData", function(target, cid, data)
	Schema:AddCombineDisplayMessage("@cViewData")
	vgui.Create("ixViewData"):Populate(target, cid, data)
end)

netstream.Hook("ViewObjectives", function(data)
	Schema:AddCombineDisplayMessage("@cViewObjectives")
	vgui.Create("ixViewObjectives"):Populate(data)
end)

local sndOn = Sound( "items/nvg_on.wav" )
local sndOff = Sound( "items/nvg_off.wav" )

netstream.Hook("ixNVToggle", function(bool)
	if not LocalPlayer():Alive() then
		return
	end

    NV_Status = bool
	NV_NIGHTTYPE = 1
    
    if bool then        
        CurScale = 0.2
        surface.PlaySound( sndOn )
        hook.Add("RenderScreenspaceEffects", "NV_FX", NV_FX)
        hook.Add("PostDrawViewModel", "NV_PostDrawViewModel", NV_PostDrawViewModel)    
    else
        surface.PlaySound( sndOff )
        hook.Remove("RenderScreenspaceEffects", "NV_FX")
        hook.Remove("PostDrawViewModel", "NV_PostDrawViewModel")
    end
end)

netstream.Hook("ixFLIRToggle", function(bool)
	if not LocalPlayer():Alive() then
		return
	end
    
    NV_Status = bool
	NV_NIGHTTYPE = 2
    
    if bool then        
        CurScale = 0.2
        surface.PlaySound( sndOn )
        hook.Add("RenderScreenspaceEffects", "NV_FX", NV_FX)
        hook.Add("PostDrawViewModel", "NV_PostDrawViewModel", NV_PostDrawViewModel)
    else
        surface.PlaySound( sndOff )
        hook.Remove("RenderScreenspaceEffects", "NV_FX")
        hook.Remove("PostDrawViewModel", "NV_PostDrawViewModel")
    end
end)

local adminAnonHintColor = Color(170, 170, 170)

local function IsAdminViewingAnonymous(target)
	local localClient = LocalPlayer()

	if (!IsValid(localClient) or !localClient:IsAdmin()) then
		return false
	end

	local ourCharacter = localClient:GetCharacter()
	local targetCharacter = IsValid(target) and target:GetCharacter()

	if (!ourCharacter or !targetCharacter) then
		return false
	end

	local recognized = hook.Run("IsCharacterRecognized", ourCharacter, targetCharacter:GetID())
		or hook.Run("IsPlayerRecognized", target)

	return !recognized
end

local function CompactText(text, maxLength)
	text = tostring(text or ""):gsub("%s+", " ")

	if (text:utf8len() > maxLength) then
		return text:utf8sub(1, maxLength - 3) .. "..."
	end

	return text
end

hook.Add("LoadFonts", "ixAdminAnonHintFont", function(font, genericFont)
	surface.CreateFont("ixAdminAnonHintFont", {
		font = genericFont,
		size = math.max(ScreenScale(6), 16),
		weight = 450,
		italic = true
	})
end)

-- remove legacy hook IDs so autoreload does not stack duplicate rows
hook.Remove("PopulateImportantCharacterInfo", "ixHL2RPAdminAnonImportantInfo")
hook.Remove("PopulateImportantCharacterInfo", "ixAdminAnonImportantInfo")
hook.Remove("PopulateCharacterInfo", "ixHL2RPAdminAnonDescriptionInfo")

hook.Add("PopulateImportantCharacterInfo", "ixAdminAnonImportantInfo", function(client, character, container)
	if (!IsAdminViewingAnonymous(client)) then
		return
	end

	local displayedName = hook.Run("GetCharacterName", client) or character:GetName()
	local realName = character:GetName()
	local unknownName = L("unknown")

	if (displayedName == realName or displayedName != unknownName or IsValid(container:GetRow("adminRealName"))) then
		return
	end

	local realNameRow = container:AddRowAfter("name", "adminRealName")
	realNameRow:SetFont("ixAdminAnonHintFont")
	realNameRow:SetTextColor(adminAnonHintColor)
	realNameRow:SetText("(" .. CompactText(realName, 64) .. ")")
	realNameRow:SizeToContents()
end)

local function PatchScoreboardPanels()
	local iconTable = vgui.GetControlTable("ixScoreboardIcon")

	if (iconTable and !iconTable.ixAdminAnonPatchApplied) then
		iconTable.ixAdminAnonPatchApplied = true

		function iconTable:Paint(width, height)
			if (!self.material) then
				return
			end

			surface.SetMaterial(self.material)

			if (self.bHidden) then
				local row = self:GetParent()
				local target = IsValid(row) and row.player

				if (IsAdminViewingAnonymous(target)) then
					surface.SetDrawColor(128, 128, 128, 255)
				else
					surface.SetDrawColor(0, 0, 0, 255)
				end
			else
				surface.SetDrawColor(255, 255, 255, 255)
			end

			surface.DrawTexturedRect(0, 0, width, height)
		end
	end

	local rowTable = vgui.GetControlTable("ixScoreboardRow")

	if (rowTable and !rowTable.ixAdminAnonPatchApplied) then
		rowTable.ixAdminAnonPatchApplied = true

		local oldInit = rowTable.Init
		local oldUpdate = rowTable.Update

		function rowTable:Init(...)
			oldInit(self, ...)

			self.realNameHint = self.name:Add("DLabel")
			self.realNameHint:SetFont("ixAdminAnonHintFont")
			self.realNameHint:SetTextColor(adminAnonHintColor)
			self.realNameHint:SetMouseInputEnabled(false)
			self.realNameHint:SetVisible(false)

			self.realDescriptionHint = self.description:Add("DLabel")
			self.realDescriptionHint:SetFont("ixAdminAnonHintFont")
			self.realDescriptionHint:SetTextColor(adminAnonHintColor)
			self.realDescriptionHint:SetMouseInputEnabled(false)
			self.realDescriptionHint:SetVisible(false)
		end

		function rowTable:Update(...)
			oldUpdate(self, ...)

			local target = self.player
			local character = IsValid(target) and target:GetCharacter()
			local showHints = IsAdminViewingAnonymous(target) and character

			if (!showHints) then
				if (IsValid(self.realNameHint)) then
					self.realNameHint:SetVisible(false)
				end

				if (IsValid(self.realDescriptionHint)) then
					self.realDescriptionHint:SetVisible(false)
				end

				return
			end

			local displayedName = self.name:GetText()
			local realName = character:GetName()

			if (displayedName != realName and IsValid(self.realNameHint)) then
				self.realNameHint:SetText(" (" .. CompactText(realName, 48) .. ")")
				self.realNameHint:SizeToContents()

				surface.SetFont(self.name:GetFont())
				local nameWidth = select(1, surface.GetTextSize(displayedName))
				self.realNameHint:SetPos(nameWidth + 4, 0)
				self.realNameHint:SetVisible(true)
			elseif (IsValid(self.realNameHint)) then
				self.realNameHint:SetVisible(false)
			end

			local displayedDescription = self.description:GetText()
			local realDescription = character:GetDescription() or ""

			if (realDescription != "" and displayedDescription != realDescription and IsValid(self.realDescriptionHint)) then
				self.realDescriptionHint:SetText(" (" .. CompactText(realDescription, 80) .. ")")
				self.realDescriptionHint:SizeToContents()

				surface.SetFont(self.description:GetFont())
				local descriptionWidth = select(1, surface.GetTextSize(displayedDescription))
				self.realDescriptionHint:SetPos(descriptionWidth + 4, 0)
				self.realDescriptionHint:SetVisible(true)
			elseif (IsValid(self.realDescriptionHint)) then
				self.realDescriptionHint:SetVisible(false)
			end
		end
	end
end


function Schema:PrePlayerDraw(v)
	if (v:GetCharacter() and !v:GetNoDraw() and v:Alive()) then
		local attachment = v:GetAttachment(v:LookupAttachment("eyes"))
		
		if (attachment) then
			local eyePos = attachment.Pos
			local headForward = attachment.Ang:Forward()
			local headRight = attachment.Ang:Right()
			local headUp = attachment.Ang:Up()
			
			local aimDir = v:GetAimVector()
			
			-- Project aim direction onto head-local axes
			local dotF = aimDir:Dot(headForward)
			local dotR = aimDir:Dot(headRight)
			local dotU = aimDir:Dot(headUp)
			
			-- Tight clamping to keep eye movement natural and within model limits
			dotF = math.max(dotF, 0.7) -- Only look forward (about 45 deg cone)
			dotR = math.Clamp(dotR, -0.4, 0.4)
			dotU = math.Clamp(dotU, -0.3, 0.3)
			
			local finalDir = (headForward * dotF + headRight * dotR + headUp * dotU):GetNormalized()
			v:SetEyeTarget(eyePos + finalDir * 1000)
		else
			v:SetEyeTarget(v:EyePos() + v:GetAimVector() * 1000)
		end
	end
end

hook.Add("InitializedSchema", "ixHL2RPPatchScoreboardPanels", PatchScoreboardPanels)
hook.Add("InitPostEntity", "ixHL2RPPatchScoreboardPanels", PatchScoreboardPanels)
