
local function HasEquippedCPMask(character)
	local inventory = character and character:GetInventory()

	if (!inventory or !inventory.GetItems) then
		return false
	end

	for _, item in pairs(inventory:GetItems()) do
		if (!item:GetData("equip")) then
			continue
		end

		local uniqueID = isstring(item.uniqueID) and item.uniqueID:lower() or ""

		if (uniqueID:find("cp_mask", 1, true) or item.combineMaskProtection == true) then
			return true
		end
	end

	return false
end

local function ShouldRenderMasklessMetrocopAsAnonymous(viewer, client)
	if (!IsValid(viewer) or !IsValid(client) or viewer == client or viewer:IsCombine() or client:Team() != FACTION_MPF) then
		return false
	end

	local character = client:GetCharacter()
	local faction = character and ix.faction.indices[character:GetFaction()]

	if (!character or !faction or !faction.IsUniformCitizenDuty or !faction:IsUniformCitizenDuty(character)) then
		return false
	end

	return !HasEquippedCPMask(character)
end

function Schema:PopulateCharacterInfo(client, character, tooltip)
	local panel = tooltip:AddRowAfter("name", "ziptie")
	panel:SetBackgroundColor(derma.GetColor("Warning", tooltip))
	panel:SizeToContents()

	function panel:Think()
		local text = ""
		local bVisible = true

		if (client:IsRestricted()) then
			text = L("tiedUp")
		elseif (client:GetNetVar("tying")) then
			text = L("beingTied")
		elseif (client:GetNetVar("untying")) then
			text = L("beingUntied")
		else
			bVisible = false
		end

		if (self:GetText() != text) then
			self:SetText(text)
			self:SizeToContents()
		end

		if (self:IsVisible() != bVisible) then
			self:SetVisible(bVisible)
		end
	end
end

do
	local function ShouldUseDynamicScoreboardIcon(client)
		if (!IsValid(client)) then
			return false
		end

		if (client:GetNetVar("gasmask", false)) then
			return true
		end

		if (Schema:IsConceptCombine(client)) then
			local maskIndex = client:FindBodygroupByName("mask")

			return maskIndex != -1 and client:GetBodygroup(maskIndex) >= 1
		end

		return false
	end

	local function ParseScoreboardBodygroups(bodygroups)
		if (!isstring(bodygroups) or bodygroups == "") then
			return bodygroups
		end

		local indexed = {}

		for i = 1, bodygroups:len() do
			local value = tonumber(bodygroups[i]) or 0

			if (value > 0) then
				indexed[i - 1] = value
			end
		end

		return indexed
	end

	local function PatchScoreboardDynamicRenderer(icon)
		if (!IsValid(icon) or !IsValid(icon.ixDynamicRenderer) or icon.ixDynamicRenderer.ixSchemaMaskScalePatch) then
			return
		end

		local renderer = icon.ixDynamicRenderer
		local originalLayout = renderer.LayoutEntity
		local originalSetHidden = renderer.SetHidden

		renderer.ixSchemaMaskScalePatch = true

		local function ApplyAnonymousRenderState(panel, hidden)
			if (!IsValid(panel)) then
				return
			end

			if (hidden) then
				panel:SetAmbientLight(color_black)
				panel:SetColor(Color(0, 0, 0))

				for i = 0, 5 do
					panel:SetDirectionalLight(i, color_black)
				end

				return
			end

			if (panel.ixAdminAnonymousView) then
				panel:SetAmbientLight(Color(18, 18, 18))
				panel:SetColor(Color(95, 95, 95))

				for i = 0, 5 do
					if (i == 1 or i == 5) then
						panel:SetDirectionalLight(i, Color(85, 85, 85))
					else
						panel:SetDirectionalLight(i, Color(60, 60, 60))
					end
				end

				return
			end

			panel:SetAmbientLight(Color(20, 20, 20))
			panel:SetColor(color_white)
			panel:SetAlpha(255)

			for i = 0, 5 do
				if (i == 1 or i == 5) then
					panel:SetDirectionalLight(i, Color(155, 155, 155))
				else
					panel:SetDirectionalLight(i, Color(255, 255, 255))
				end
			end
		end

		renderer.LayoutEntity = function(panel, entity)
			if (originalLayout) then
				originalLayout(panel, entity)
			end

			Schema:ApplyMaskScale(entity, icon.ixClient)
			ApplyAnonymousRenderState(panel, panel.ixAnonymousHidden == true)
		end

		renderer.SetHidden = function(panel, hidden)
			hidden = tobool(hidden)
			panel.ixAnonymousHidden = hidden
			panel.ixAdminAnonymousView = !hidden and IsValid(icon) and icon.bHidden and IsValid(LocalPlayer()) and LocalPlayer():IsAdmin()

			if (originalSetHidden) then
				originalSetHidden(panel, hidden)
			end

			ApplyAnonymousRenderState(panel, hidden)
		end
	end

	local function ShouldHideScoreboardIcon(client)
		return ShouldRenderMasklessMetrocopAsAnonymous(LocalPlayer(), client)
	end

	local scoreboardRow = vgui.GetControlTable("ixScoreboardRow")
	local scoreboardIcon = vgui.GetControlTable("ixScoreboardIcon")
	local panelMeta = FindMetaTable("Panel")

	if (scoreboardIcon and panelMeta and panelMeta.GetSkin and !scoreboardIcon.ixSchemaModelSkinPatch) then
		scoreboardIcon.ixSchemaModelSkinPatch = true

		function scoreboardIcon:GetModelSkin()
			return self.ixModelSkin or 0
		end

		local originalSetModel = scoreboardIcon.SetModel
		local originalSetDynamicRenderer = scoreboardIcon.SetDynamicRenderer

		function scoreboardIcon:SetModel(model, skin, bodygroups)
			self.ixModelSkin = tonumber(skin) or 0

			if (ShouldUseDynamicScoreboardIcon(self.ixClient)) then
				return self:SetDynamicRenderer(model, self.ixModelSkin, ParseScoreboardBodygroups(bodygroups), self:GetBodygroupSignature())
			end

			return originalSetModel(self, model, self.ixModelSkin, bodygroups)
		end

		function scoreboardIcon:SetDynamicRenderer(model, skin, bodygroups, signature)
			self.ixModelSkin = tonumber(skin) or 0
			local originalGetSkin = self.GetSkin
			self.GetSkin = panelMeta.GetSkin

			local ok, result = pcall(originalSetDynamicRenderer, self, model, self.ixModelSkin, bodygroups, signature)

			self.GetSkin = originalGetSkin

			if (!ok) then
				error(result)
			end

			PatchScoreboardDynamicRenderer(self)

			return result
		end
	end

	if (scoreboardRow and !scoreboardRow.ixSchemaMaskedIconPatch) then
		scoreboardRow.ixSchemaMaskedIconPatch = true

		local originalUpdate = scoreboardRow.Update

		function scoreboardRow:Update(...)
			if (IsValid(self.icon)) then
				self.icon.ixClient = self.player
			end

			originalUpdate(self, ...)

			if (IsValid(self.icon) and ShouldHideScoreboardIcon(self.player)) then
				self.icon:SetHidden(true)
			end

			if (ShouldRenderMasklessMetrocopAsAnonymous(LocalPlayer(), self.player)) then
				self:SetZPos(2)

				if (IsValid(self.description) and self.description:GetText() != L"noRecog") then
					self.description:SetText(L"noRecog")
					self.description:SizeToContents()
				end

				if (IsValid(self.realNameHint)) then
					self.realNameHint:SetVisible(false)
				end

				if (IsValid(self.realDescriptionHint)) then
					self.realDescriptionHint:SetVisible(false)
				end
			end

			if (IsValid(self.icon)) then
				PatchScoreboardDynamicRenderer(self.icon)

				if (self.icon.ixUseDynamicRenderer and IsValid(self.icon.ixDynamicRenderer) and IsValid(self.icon.ixDynamicRenderer.Entity)) then
					Schema:ApplyMaskScale(self.icon.ixDynamicRenderer.Entity, self.player)
				end
			end
		end
	end
end

function Schema:GetCharacterDescription(client)
	if (ShouldRenderMasklessMetrocopAsAnonymous(LocalPlayer(), client)) then
		return L"noRecog"
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

-- function Schema:CharacterLoaded(character)
-- end

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

function Schema:ApplyMaskScale(v, client)
	if (!IsValid(v)) then return end

	local headBone = v:LookupBone("ValveBiped.Bip01_Head1")

	if (!headBone) then
		return
	end

	local sourceClient = IsValid(client) and client or (v:IsPlayer() and v or nil)

	if (Schema:IsConceptCombine(v)) then
		local maskIndex = v:FindBodygroupByName("mask")

		if (maskIndex != -1) then
			local scale = (v:GetBodygroup(maskIndex) >= 1) and 0.9 or 1
			v:ManipulateBoneScale(headBone, Vector(scale, scale, scale))
			return
		end
	end

	if (IsValid(sourceClient) and sourceClient:GetNetVar("gasmask", false)) then
		v:ManipulateBoneScale(headBone, Vector(0.93, 0.93, 0.93))
		return
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
	return self:CanPlayerUseBusiness(LocalPlayer())
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
		local headBone = Entity:LookupBone("ValveBiped.Bip01_Head1") or Entity:LookupBone("Vortigaunt_Head")
		if (headBone) then
			local headPos = Entity:GetBonePosition(headBone)
			local eyeTarget = headPos + Entity:GetForward() * 50
			Entity:SetEyeTarget(eyeTarget)
		else
			local arrow = Entity:GetForward() * 100
			local eyeTarget = Entity:GetPos() + arrow + Vector(0, 0, 64)
			Entity:SetEyeTarget(eyeTarget)
		end

		-- Neutral pose parameters (Safe for most standard and HL2 models)
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

			createPanel.descriptionFace.Think = function(this)
				local faction = createPanel.faction
				local factionTable = ix.faction.indices[faction]
				local uniqueID = (factionTable and factionTable.uniqueID) or ""
				local model = (this:GetModel() or ""):lower()
				
				local bIsVortigaunt = (uniqueID == "vortigaunt" or uniqueID == "vortigaunt_slave")
					or (FACTION_VORT ~= nil and faction == FACTION_VORT)
					or (model:find("vortigaunt", 1, true) ~= nil)
				
				if (bIsVortigaunt) then
					if (this:IsVisible()) then
						this:SetVisible(false)
					end
				elseif (!this:IsVisible()) then
					this:SetVisible(true)
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
