
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
	if (Schema:CanPlayerSeeCombineOverlay(LocalPlayer())) then
		local key = nil

		if (text == COMMAND_PREFIX .. "radio") then
			key = "r"
		elseif (text == COMMAND_PREFIX .. "w ") then
			key = "w"
		elseif (text == COMMAND_PREFIX .. "y ") then
			key = "y"
		elseif (text:sub(1, 1):match("[%w]") or (text:byte(1) or 0) > 127) then
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
	-- Creation is now handled by the Think hook for dynamic mask support
end

function Schema:Think()
	local client = LocalPlayer()
	if (!client:GetCharacter()) then return end

	local bCanSeeOverlay = Schema:CanPlayerSeeCombineOverlay(client)
	if (bCanSeeOverlay and !IsValid(ix.gui.combine)) then
		vgui.Create("ixCombineDisplay")
	elseif (!bCanSeeOverlay and IsValid(ix.gui.combine)) then
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

function Schema:ApplyMaskScale(v)
	if (!IsValid(v)) then return end

	local headBone = v:LookupBone("ValveBiped.Bip01_Head1")

	if (!headBone) then
		return
	end

	if (Schema:IsConceptCombine(v)) then
		local maskIndex = v:FindBodygroupByName("mask")

		if (maskIndex != -1) then
			local scale = (v:GetBodygroup(maskIndex) >= 1) and 0.9 or 1
			v:ManipulateBoneScale(headBone, Vector(scale, scale, scale))
			return
		end
	end

	v:ManipulateBoneScale(headBone, Vector(1, 1, 1))
end

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

	if (LocalPlayer():GetNetVar("antidepressant")) then
		colorModify["$pp_colour_brightness"] = (colorModify["$pp_colour_brightness"] or 0) + 0.02
		colorModify["$pp_colour_contrast"] = (colorModify["$pp_colour_contrast"] or 1) + 2.0
		colorModify["$pp_colour_colour"] = 1.2
	end

	if (LocalPlayer():GetNetVar("poisoned")) then
		colorModify["$pp_colour_brightness"] = (colorModify["$pp_colour_brightness"] or 0) - 0.1
		colorModify["$pp_colour_colour"] = 0.7
	end

	DrawColorModify(colorModify)

	if (Schema:CanPlayerSeeCombineOverlay(LocalPlayer())) then
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
		panel.cid:SetText(string.format("##%s", Schema:GetCitizenID(LocalPlayer()) or "UNKNOWN"))
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

netstream.Hook("ixHUDReset", function()
	local elements = {"msg"}
	for _, v in ipairs(elements) do
		cookie.Set("ixHUD_" .. v .. "_X", nil)
		cookie.Set("ixHUD_" .. v .. "_Y", nil)
	end
	
	hook.Run("ixHUDReset")
end)

netstream.Hook("CombineDisplayMessage", function(text, color, arguments)
	if (IsValid(ix.gui.combine)) then
		ix.gui.combine:AddLine(text, color, nil, unpack(arguments))
	end
end)


netstream.Hook("PlaySound", function(sound)
	surface.PlaySound(sound)
end)

netstream.Hook("PlayPrivateSound", function(sound, soundLevel, pitch, volume)
	LocalPlayer():EmitSound(sound, soundLevel or 75, pitch or 100, volume or 1)
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

		self:ApplyMaskScale(v)
	end
end



-- GLOBAL FIX: Detour character:GetData to sanitize groups on the fly
-- This ensures cl_charload.lua receives clean data regardless of when it asks
hook.Add("InitPostEntity", "ixHL2RPfixBodygroups", function()
	if (ix and ix.meta and ix.meta.character) then
		local oldGetData = ix.meta.character.GetData
		
		ix.meta.character.GetData = function(self, key, default)
			local data = oldGetData(self, key, default)
			
			if (key == "groups" and istable(data)) then
				local clean = {}
				for k, v in pairs(data) do
					if (isnumber(k) or isstring(k)) then
						clean[k] = v
					end
				end
				return clean
			end
			
			return data
		end
	end
end)

hook.Add("InitPostEntity", "ixHL2RPModelHeadScale", function()
	local modelPanel = vgui.GetControlTable("ixModelPanel")

	if (modelPanel) then
		local oldLayout = modelPanel.LayoutEntity

		modelPanel.LayoutEntity = function(self, entity)
			if (oldLayout) then
				oldLayout(self, entity)
			end

			Schema:ApplyMaskScale(entity)
		end
	end
end)

local function SelectScoreboardIconSequence(entity)
	if (!IsValid(entity)) then
		return
	end

	local sequence = entity:SelectWeightedSequence(ACT_IDLE)

	if (sequence <= 0) then
		sequence = entity:LookupSequence("idle_unarmed")
	end

	if (sequence > 0) then
		entity:ResetSequence(sequence)
		return
	end

	for _, sequenceName in ipairs(entity:GetSequenceList()) do
		if ((sequenceName:lower():find("idle") or sequenceName:lower():find("fly")) and sequenceName != "idlenoise") then
			entity:ResetSequence(sequenceName)
			return
		end
	end

	entity:ResetSequence(4)
end

local function BuildScoreboardIconState(entity)
	local state = {
		bodygroups = "",
		signature = "",
		indexed = {},
		named = {},
		requiresIkon = false
	}

	if (!IsValid(entity)) then
		return state
	end

	local groups = entity:GetBodyGroups()

	if (!istable(groups) or #groups == 0) then
		return state
	end

	local entries = {}

	for _, group in ipairs(groups) do
		local index = tonumber(group.id)

		if (index and index >= 0) then
			local value = math.max(tonumber(entity:GetBodygroup(index)) or 0, 0)

			entries[#entries + 1] = {
				index = index,
				value = value
			}

			if (isstring(group.name) and group.name != "") then
				state.named[group.name] = value
			end
		end
	end

	if (#entries == 0) then
		return state
	end

	table.sort(entries, function(a, b)
		return a.index < b.index
	end)

	local digits = {}
	local digitIndex = 1
	local lastIndex = entries[#entries].index
	local signatureParts = {}

	for bodygroupIndex = 0, lastIndex do
		digits[digitIndex] = "0"
		digitIndex = digitIndex + 1
	end

	for _, entry in ipairs(entries) do
		state.indexed[entry.index] = entry.value
		signatureParts[#signatureParts + 1] = entry.index .. "=" .. entry.value
		digits[entry.index + 1] = tostring(math.min(entry.value, 9))

		if (entry.index > 8 or entry.value > 9) then
			state.requiresIkon = true
		end
	end

	state.signature = table.concat(signatureParts, ";")
	state.bodygroups = table.concat(digits, "", 1, #digits)

	if (state.bodygroups:match("^0+$")) then
		state.bodygroups = ""
	end

	return state
end

local function CleanupScoreboardIcon(icon)
	if (icon.id) then
		hook.Remove("SpawniconGenerated", icon.id)
		icon.id = nil
	end

	if (IsValid(icon.renderer)) then
		icon.renderer:Remove()
		icon.renderer = nil
	end
end

local function ShouldShowScoreboardDynamicRenderer(panel)
	if (!IsValid(panel) or !panel:IsVisible()) then
		return false
	end

	local parent = panel:GetParent()
	local rootMenu = nil

	while (IsValid(parent)) do
		if (!parent:IsVisible() or parent.bClosing) then
			return false
		end

		if (parent:GetName() == "ixMenu") then
			rootMenu = parent
		end

		parent = parent:GetParent()
	end

	if (IsValid(ix.gui.menu)) then
		if (ix.gui.menu.bClosing) then
			return false
		end

		rootMenu = rootMenu or ix.gui.menu
	end

	if (IsValid(rootMenu)) then
		if (rootMenu.ixScoreboardDynamicReady == false) then
			return false
		end
	end

	return true
end

local function SetScoreboardDynamicRenderersVisible(panel, visible)
	if (!IsValid(panel)) then
		return
	end

	if (panel.ixUseDynamicRenderer and IsValid(panel.ixDynamicRenderer)) then
		panel.ixDynamicRenderer:SetVisible(visible)
	end

	for _, child in ipairs(panel:GetChildren()) do
		SetScoreboardDynamicRenderersVisible(child, visible)
	end
end

local function PatchScoreboardBodygroups()
	local scoreboardIcon = vgui.GetControlTable("ixScoreboardIcon")
	local menuPanel = vgui.GetControlTable("ixMenu")

	if (scoreboardIcon and !scoreboardIcon.ixBodygroupPatch) then
		scoreboardIcon.ixBodygroupPatch = true
		scoreboardIcon.ixOriginalPaint = scoreboardIcon.Paint

		function scoreboardIcon:GetBodygroupString()
			return self.bodygroups or ""
		end

		function scoreboardIcon:GetBodygroupSignature()
			return self.ixBodygroupSignature or ""
		end

		function scoreboardIcon:SetBodygroupSignature(signature)
			self.ixBodygroupSignature = signature or ""
		end

		function scoreboardIcon:ClearDynamicRenderer()
			self.ixUseDynamicRenderer = false
			self.ixPreferDynamicRenderer = false

			if (IsValid(self.ixDynamicRenderer)) then
				self.ixDynamicRenderer:Remove()
				self.ixDynamicRenderer = nil
			end
		end

		function scoreboardIcon:SetHidden(hidden)
			self.bHidden = tobool(hidden)

			if (IsValid(self.ixDynamicRenderer)) then
				self.ixDynamicRenderer:SetHidden(self.bHidden)
				self.ixDynamicRenderer:SetVisible(ShouldShowScoreboardDynamicRenderer(self))
			end
		end

		function scoreboardIcon:SetBodygroup(k, v)
			k = tonumber(k)
			v = tonumber(v)

			if (!k or k < 0 or !v or v < 0) then
				return
			end

			local current = self.bodygroups or ""
			local highestIndex = math.max(#current, k + 1)
			local digits = {}

			for i = 1, highestIndex do
				local digit = current:sub(i, i)
				digits[i] = digit != "" and digit or "0"
			end

			digits[k + 1] = tostring(math.min(v, 9))

			local signature = table.concat(digits, "", 1, highestIndex)
			self.bodygroups = signature:match("^0+$") and "" or signature
		end

		function scoreboardIcon:SetModel(model, skin, bodygroups)
			if (!isstring(model) or model == "") then
				return
			end

			model = model:gsub("\\", "/")

			if (isstring(bodygroups)) then
				self.bodygroups = bodygroups:match("^%d+$") or ""
			elseif (!isstring(self.bodygroups)) then
				self.bodygroups = ""
			end

			self.model = model
			self.skin = skin

			if (self.ixPreferDynamicRenderer) then
				CleanupScoreboardIcon(self)
				self.material = nil
				return
			end

			self:ClearDynamicRenderer()
			self.path = "materials/spawnicons/" ..
				model:sub(1, #model - 4) ..
				((isnumber(skin) and skin > 0) and ("_skin" .. tostring(skin)) or "") ..
				(self.bodygroups != "" and ("_" .. self.bodygroups) or "") ..
				".png"

			CleanupScoreboardIcon(self)
			self.material = nil

			local material = Material(self.path, "smooth")

			if (material:IsError()) then
				self.id = "ixScoreboardIcon" .. self.path
				local hookID = self.id
				local expectedPath = self.path:lower()
				self.renderer = self:Add("ModelImage")
				self.renderer:SetVisible(false)
				self.renderer:SetModel(model, skin, self.bodygroups != "" and self.bodygroups or nil)
				self.renderer:RebuildSpawnIcon()

				hook.Add("SpawniconGenerated", hookID, function(_, filePath)
					if (!IsValid(self)) then
						hook.Remove("SpawniconGenerated", hookID)
						return
					end

					filePath = filePath:gsub("\\", "/"):lower()

					if (filePath == expectedPath) then
						hook.Remove("SpawniconGenerated", hookID)
						self.id = nil
						self.material = Material(filePath, "smooth")

						if (IsValid(self.renderer)) then
							self.renderer:Remove()
							self.renderer = nil
						end
					end
				end)
			else
				self.material = material
			end
		end

		function scoreboardIcon:SetDynamicRenderer(model, skin, state)
			if (!isstring(model) or model == "" or !istable(state)) then
				return
			end

			self.model = model:gsub("\\", "/")
			self.skin = skin
			self.ixPreferDynamicRenderer = true
			self.ixUseDynamicRenderer = true
			self:SetBodygroupSignature(state.signature)
			CleanupScoreboardIcon(self)
			self.material = nil

			if (!IsValid(self.ixDynamicRenderer)) then
				local originalGetSkin = self.GetSkin
				self.GetSkin = function()
					return derma.GetNamedSkin("Default") or derma.GetDefaultSkin()
				end

				self.ixDynamicRenderer = self:Add("ixSpawnIcon")
				self.GetSkin = originalGetSkin

				self.ixDynamicRenderer:Dock(FILL)
				self.ixDynamicRenderer:SetMouseInputEnabled(false)
				self.ixDynamicRenderer.LayoutEntity = function(_, entity)
					entity:SetIK(false)
					entity:SetPlaybackRate(0)
					entity:SetCycle(0)
					entity:SetPoseParameter("head_pitch", 0)
					entity:SetPoseParameter("head_yaw", 0)
					entity:SetPoseParameter("aim_pitch", 0)
					entity:SetPoseParameter("aim_yaw", 0)
					entity:SetPoseParameter("eyes_pitch", 0)
					entity:SetPoseParameter("eyes_yaw", 0)

					local headBone = entity:LookupBone("ValveBiped.Bip01_Head1")

					if (headBone) then
						local headPos = entity:GetBonePosition(headBone)

						if (headPos and headPos != vector_origin) then
							entity:SetEyeTarget(headPos + entity:GetForward() * 32)
						end
					end
				end
			end

			local renderer = self.ixDynamicRenderer
			renderer:SetVisible(ShouldShowScoreboardDynamicRenderer(self))
			renderer:SetModel(self.model, skin, self.bHidden, state.named)
			renderer:SetHidden(self.bHidden)

			local indexedBodygroups = table.Copy(state.indexed)
			local entity = renderer.Entity

			if (!IsValid(entity)) then
				return
			end

			entity:SetSkin(tonumber(skin) or 0)

			for i = 0, entity:GetNumBodyGroups() - 1 do
				entity:SetBodygroup(i, 0)
			end

			for index, value in pairs(indexedBodygroups) do
				if (isnumber(index) and value >= 0) then
					entity:SetBodygroup(index, value)
				end
			end

			SelectScoreboardIconSequence(entity)
			entity:SetIK(false)

			local headBone = entity:LookupBone("ValveBiped.Bip01_Head1")

			if (headBone) then
				local headPos = entity:GetBonePosition(headBone)

				if (headPos and headPos != vector_origin) then
					entity:SetEyeTarget(headPos + entity:GetForward() * 32)
				end
			end

			Schema:ApplyMaskScale(entity)
		end

		function scoreboardIcon:Paint(width, height)
			if (self.ixUseDynamicRenderer and IsValid(self.ixDynamicRenderer)) then
				self.ixDynamicRenderer:SetVisible(ShouldShowScoreboardDynamicRenderer(self))

				if (self.bHidden and LocalPlayer():IsAdmin()) then
					surface.SetDrawColor(128, 128, 128, 64)
					surface.DrawRect(0, 0, width, height)
				end

				return
			end

			return self.ixOriginalPaint(self, width, height)
		end

		function scoreboardIcon:Think()
			if (self.ixUseDynamicRenderer and IsValid(self.ixDynamicRenderer)) then
				self.ixDynamicRenderer:SetVisible(ShouldShowScoreboardDynamicRenderer(self))
			end
		end

		function scoreboardIcon:OnRemove()
			self:ClearDynamicRenderer()
			CleanupScoreboardIcon(self)
		end
	end

	local scoreboardRow = vgui.GetControlTable("ixScoreboardRow")

	if (scoreboardRow and !scoreboardRow.ixBodygroupPatch) then
		scoreboardRow.ixBodygroupPatch = true

		local oldUpdate = scoreboardRow.Update

		scoreboardRow.Update = function(self)
			local client = self.player
			local icon = self.icon
			local state = IsValid(client) and BuildScoreboardIconState(client) or nil

			if (IsValid(icon)) then
				icon.ixPreferDynamicRenderer = state and state.requiresIkon or false
			end

			local previousModel = IsValid(self.icon) and self.icon:GetModel() or nil
			local previousSkin = IsValid(self.icon) and self.icon:GetSkin() or nil
			local previousBodygroups = IsValid(self.icon) and self.icon.GetBodygroupSignature and self.icon:GetBodygroupSignature() or ""
			local previousDynamic = IsValid(self.icon) and self.icon.ixUseDynamicRenderer or false

			oldUpdate(self)

			client = self.player
			icon = self.icon

			if (!IsValid(client) or !IsValid(icon)) then
				return
			end

			state = BuildScoreboardIconState(client)

			local model = client:GetModel()
			local skin = client:GetSkin()

			icon:SetBodygroupSignature(state.signature)

			if (state.requiresIkon) then
				icon:SetDynamicRenderer(model, skin, state)
				icon:SetTooltip(nil)

				return
			end

			icon.ixPreferDynamicRenderer = false

			if (previousDynamic) then
				icon:ClearDynamicRenderer()
			end

			local currentBodygroups = icon.GetBodygroupString and icon:GetBodygroupString() or ""
			local modelChanged = previousModel != model or previousSkin != skin

			if (previousDynamic or (!modelChanged and previousBodygroups != state.signature) or currentBodygroups != state.bodygroups) then
				icon:SetModel(model, skin, state.bodygroups)
				icon:SetTooltip(nil)
			end
		end
	end

	if (menuPanel and !menuPanel.ixScoreboardBodygroupPatch) then
		menuPanel.ixScoreboardBodygroupPatch = true

		local oldOnOpened = menuPanel.OnOpened
		local oldRemove = menuPanel.Remove

		menuPanel.OnOpened = function(self, ...)
			self.ixScoreboardDynamicReady = false

			timer.Create("ixHL2RPScoreboardDynamicReady" .. tostring(self), 0.12, 1, function()
				if (IsValid(self) and !self.bClosing) then
					self.ixScoreboardDynamicReady = true
				end
			end)

			if (oldOnOpened) then
				return oldOnOpened(self, ...)
			end
		end

		menuPanel.Remove = function(self, ...)
			self.ixScoreboardDynamicReady = false
			timer.Remove("ixHL2RPScoreboardDynamicReady" .. tostring(self))

			if (IsValid(ix.gui.scoreboard)) then
				SetScoreboardDynamicRenderersVisible(ix.gui.scoreboard, false)
			end

			return oldRemove(self, ...)
		end
	end
end

hook.Add("InitPostEntity", "ixHL2RPScoreboardBodygroups", function()
	PatchScoreboardBodygroups()
end)

hook.Add("OnReloaded", "ixHL2RPScoreboardBodygroups", function()
	timer.Simple(0, function()
		if (vgui and vgui.GetControlTable) then
			PatchScoreboardBodygroups()
		end
	end)
end)

timer.Simple(0, function()
	if (vgui and vgui.GetControlTable) then
		PatchScoreboardBodygroups()
	end
end)

-- Safe wrapper for SetBodygroup to prevent crashes
local function SafeSetBodygroup(entity, bodygroups)
	if (!IsValid(entity) or !istable(bodygroups)) then return end
		
	for k, v in pairs(bodygroups) do
		if (isnumber(k)) then
			entity:SetBodygroup(k, v)
		end
	end
end

function Schema:OnCharacterMenuCreated(panel)
	-- Sanitize character data (Fix for corrupted characters preventing deletion)
	if (ix.char and ix.char.loaded) then
		for id, char in pairs(ix.char.loaded) do
			local data = char:GetVar("data")
			if (data and data.groups) then
				local clean = {}
				local dirty = false
				
				for k, v in pairs(data.groups) do
					if (isnumber(k)) then
						clean[k] = v
					elseif (isstring(k)) then
						dirty = true
					end
				end
				
				if (dirty) then
					data.groups = clean
				end
			end
		end
	end

	-- Detour SetCharacter on the load panel models if they exist
	if (IsValid(panel.loadCharacterPanel)) then
		local loadPanel = panel.loadCharacterPanel
		
		-- Helper to patch a model entity
		local function PatchModelEntity(ent)
			if (!IsValid(ent)) then return end
			
			-- We can't easily detour the local function SetCharacter in cl_charload.lua
			-- But we can overwrite the method on the entity instance!
			local oldSetCharacter = ent.SetCharacter
			
			ent.SetCharacter = function(self, character)
				-- 1. Sanitize data before calling original (if original uses it)
				-- Original calls: local bodygroups = character:GetData("groups", nil)
				-- and iterates it.
				-- We already sanitized ix.char.loaded above, so hopefully that's enough.
				
				-- BUT, if the error persists, it means cl_charload is using unsanitized data?
				-- Or maybe our sanitization didn't propagate?
				
				-- Let's try to wrap the SetBodygroup call itself?
				-- No, SetBodygroup is a C function on the entity.
				
				-- The issue is cl_charload.lua:22 calls self:SetBodygroup(k, v)
				-- We can override SetBodygroup on this entity!
				
				local oldSetBodygroup = self.SetBodygroup
				self.SetBodygroup = function(miniself, index, value)
					if (isnumber(index)) then
						oldSetBodygroup(miniself, index, value)
					end
				end
				
				if (oldSetCharacter) then
					oldSetCharacter(self, character)
				end
				
				-- Restore SetBodygroup? Maybe keep it safe.
			end
		end
		
		PatchModelEntity(loadPanel.activeCharacter)
		PatchModelEntity(loadPanel.lastCharacter)
		
		-- Also patch the carousel models if they are created later?
		-- The carousel creates ixModelPanels.
	end
	-- Helper function to layout the entity (Straight ahead, neutral pose)
	-- Based on bodygroup manager viewer
	local function LayoutEntity(this, Entity)
		if (this.bScripted) then
			this:ScriptedLayoutEntity(Entity)
			return
		end
		
		local yaw = this.ixRotationYaw or 45
		if (this.ixDragging) then
			local mouseX = gui.MouseX()
			local deltaX = mouseX - (this.ixLastMouseX or mouseX)
			yaw = yaw - deltaX * 0.5
			this.ixRotationYaw = yaw
			this.ixLastMouseX = mouseX
		end
		
		Entity:SetAngles(Angle(0, yaw, 0))
		Entity:SetIK(false)

		Schema:ApplyMaskScale(Entity)

		-- Eye fix (Look forward)
		local arrow = Entity:GetForward() * 100
		local eyeTarget = Entity:GetPos() + arrow + Vector(0, 0, 64)
		Entity:SetEyeTarget(eyeTarget)

		-- Neutral pose parameters
		Entity:SetPoseParameter("head_pitch", 0)
		Entity:SetPoseParameter("head_yaw", 0)
		Entity:SetPoseParameter("aim_pitch", 0)
		Entity:SetPoseParameter("aim_yaw", 0)
		Entity:SetPoseParameter("eyes_pitch", 0)
		Entity:SetPoseParameter("eyes_yaw", 0)
		
		-- Default sequence logic
		if (this.RunAnimation) then
			this:RunAnimation(Entity)
		else
			-- Fallback if no RunAnimation (e.g. ixModelPanel default)
			Entity:FrameAdvance((RealTime() - (this.lastPaint or 0)) * 0.5)
			this.lastPaint = RealTime()
		end
	end

	-- 1. Character Creation Panels
	if (IsValid(panel.newCharacterPanel)) then
		local createPanel = panel.newCharacterPanel
		
		-- Override LayoutEntity for all model panels in creation
		if (IsValid(createPanel.factionModel)) then
			createPanel.factionModel.LayoutEntity = LayoutEntity
		end
		
		if (IsValid(createPanel.descriptionModel)) then
			-- Enable drag-to-rotate
			local modelPanel = createPanel.descriptionModel
			modelPanel:SetMouseInputEnabled(true)
			modelPanel.ixRotationYaw = 45
			
			modelPanel.OnMousePressed = function(this, code)
				if (code == MOUSE_LEFT) then
					this.ixDragging = true
					this.ixLastMouseX = gui.MouseX()
					this:MouseCapture(true)
				end
			end
			
			modelPanel.OnMouseReleased = function(this, code)
				if (code == MOUSE_LEFT) then
					this.ixDragging = false
					this:MouseCapture(false)
				end
			end

			modelPanel.LayoutEntity = LayoutEntity
		end
		
		if (IsValid(createPanel.attributesModel)) then
			createPanel.attributesModel.LayoutEntity = LayoutEntity
		end
		
		 -- Face closeup (keep custom camera, just fix eyes/pose)
		if (IsValid(createPanel.descriptionFace)) then
			local OldLayout = createPanel.descriptionFace.LayoutEntity
			createPanel.descriptionFace.LayoutEntity = function(this, entity)
				-- Call original to setup camera/head focus
				if (OldLayout) then OldLayout(this, entity) end
				
				-- Force neutral expression after
				entity:SetPoseParameter("head_pitch", 0)
				entity:SetPoseParameter("head_yaw", 0)
				entity:SetPoseParameter("aim_pitch", 0)
				entity:SetPoseParameter("aim_yaw", 0)
				entity:SetPoseParameter("eyes_pitch", 0)
				entity:SetPoseParameter("eyes_yaw", 0)
				
				-- Eye fix for closeup (Look at camera or slightly forward from head)
				local headBone = entity:LookupBone("ValveBiped.Bip01_Head1")
				if (headBone) then
					local headPos = entity:GetBonePosition(headBone)
					-- Camera is at headPos + forward*45 + up*-2 (approx)
					-- Let's just project forward from head
					local eyeTarget = headPos + entity:GetForward() * 50
					entity:SetEyeTarget(eyeTarget)
				end
			end
		end
	end

	-- 2. Character Load Panel (Carousel)
	if (IsValid(panel.loadCharacterPanel)) then
		local loadPanel = panel.loadCharacterPanel
		if (IsValid(loadPanel.carousel)) then
			-- Override the carousel's LayoutEntity which handles active/last character
			loadPanel.carousel.LayoutEntity = function(this, model)
				model:SetIK(false)
				
				-- Eye fix (Look forward)
				-- Note: Carousel rotates the camera, not the model usually, but let's ensure model looks "forward" relative to itself
				local arrow = model:GetForward() * 100
				local eyeTarget = model:GetPos() + arrow + Vector(0, 0, 64)
				model:SetEyeTarget(eyeTarget)

				-- Neutral pose
				model:SetPoseParameter("head_pitch", 0)
				model:SetPoseParameter("head_yaw", 0)
				model:SetPoseParameter("aim_pitch", 0)
				model:SetPoseParameter("aim_yaw", 0)
				model:SetPoseParameter("eyes_pitch", 0)
				model:SetPoseParameter("eyes_yaw", 0)
				
				Schema:ApplyMaskScale(model)
				this:RunAnimation(model)
			end
		end
	end
end
