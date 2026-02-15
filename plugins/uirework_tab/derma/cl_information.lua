
local PANEL = {}

function PANEL:Init()
	self:Dock(FILL)
	self:DockPadding(32, 0, 32, 0) -- Removed vertical padding to maximize height

	-- Create the Model Panel (Left Side)
	self.model = self:Add("ixModelPanel")
	self.model:Dock(LEFT)
	self.model:SetWide(ScrW() * 0.35)
	self.model:DockMargin(64, 0, 0, 0)
	self.model:SetFOV(42)
	self.model:SetCamPos(Vector(85, 7, 50))
	self.model:SetLookAt(Vector(0, 0, 38))
	
	-- Initial setup
	self.model.currentAngles = Angle(0, 45, 0)
	self.model.isDragging = false
	self.model.lastMouseX = 0

	self.model.LayoutEntity = function(this, entity)
		this:RunAnimation()
		
		-- Hide early if menu is closing to avoid "delay" feeling
		if (IsValid(ix.gui.menu) and ix.gui.menu.bClosing) then
			this:SetAlpha(0)
			return
		end

		-- Fix eyes looking weird (set target in front of head)
		local head = entity:LookupBone("ValveBiped.Bip01_Head1")
		if (head) then
			local pos = entity:GetBonePosition(head)
			entity:SetEyeTarget(pos + entity:GetForward() * 32)
		end

		-- Apply rotation
		entity:SetAngles(this.currentAngles)
	end

	-- Overwrite Paint to support alpha modulation during menu fade
	self.model.Paint = function(this, w, h)
		if (!IsValid(this.Entity)) then return end

		local alpha = this:GetAlpha() / 255
		if (IsValid(ix.gui.menu)) then
			alpha = alpha * (ix.gui.menu:GetAlpha() / 255)
		end

		if (alpha <= 0) then return end

		local x, y = this:LocalToScreen(0, 0)
		
		-- Use the original DrawModel but with modulation
		this:LayoutEntity(this.Entity)

		cam.Start3D(this.vCamPos, (this.vLookatPos - this.vCamPos):Angle(), this.fFOV, x, y, w, h)
			render.SuppressEngineLighting(true)
			render.SetLightingOrigin(this.Entity:GetPos())
			
			-- Modulate lighting by alpha
			local br = 1.5 * alpha
			local br2 = 0.4 * alpha
			local br3 = 0.04 * alpha

			render.SetModelLighting(0, br, br, br)
			for i = 1, 4 do
				render.SetModelLighting(i, br2, br2, br2)
			end
			render.SetModelLighting(5, br3, br3, br3)

			render.SetColorModulation(alpha, alpha, alpha)
			this.Entity:DrawModel()
			render.SetColorModulation(1, 1, 1)

			render.SuppressEngineLighting(false)
		cam.End3D()

		this.LastPaint = RealTime()
	end

	self.model.OnMousePressed = function(this, code)
		if (code == MOUSE_LEFT) then
			this.isDragging = true
			this.lastMouseX = gui.MouseX()
			this:SetCursor("sizewe")
		end
	end

	self.model.OnMouseReleased = function(this, code)
		if (code == MOUSE_LEFT) then
			this.isDragging = false
			this:SetCursor("none")
		end
	end

	self.model.OnCursorMoved = function(this, x, y)
		if (this.isDragging) then
			local mouseX = gui.MouseX()
			local delta = mouseX - this.lastMouseX
			this.lastMouseX = mouseX
			
			this.currentAngles.y = (this.currentAngles.y + delta * 0.5) % 360
		end
	end

	self.model.OnCursorExited = function(this)
		this.isDragging = false
		this:SetCursor("none")
	end

	-- Create the Scroll Panel for Info (Right Side)
	self.infoScroll = self:Add("DScrollPanel")
	self.infoScroll:Dock(FILL)
	self.infoScroll:DockMargin(16, 0, 0, 0) -- Add some spacing

	-- The original Init logic, adapted to parent to self.infoScroll
	self.VBar = self.infoScroll:GetVBar() -- Use the scroll panel's VBar

	-- entry setup
	local suppress = {}
	hook.Run("CanCreateCharacterInfo", suppress)

	if (!suppress.time) then
		local format = ix.option.Get("24hourTime", false) and "%A, %B %d, %Y. %H:%M" or "%A, %B %d, %Y. %I:%M %p"

		self.time = self.infoScroll:Add("DLabel")
		self.time:SetFont("ixMediumFont")
		self.time:SetTall(28)
		self.time:SetContentAlignment(5)
		self.time:Dock(TOP)
		self.time:SetTextColor(color_white)
		self.time:SetExpensiveShadow(1, Color(0, 0, 0, 150))
		self.time:DockMargin(0, 0, 0, 32)
		self.time:SetText(ix.date.GetFormatted(format))
		self.time.Think = function(this)
			if ((this.nextTime or 0) < CurTime()) then
				this:SetText(ix.date.GetFormatted(format))
				this.nextTime = CurTime() + 0.5
			end
		end
	end

	if (!suppress.name) then
		self.name = self.infoScroll:Add("ixLabel")
		self.name:Dock(TOP)
		self.name:DockMargin(0, 0, 0, 8)
		self.name:SetFont("ixMenuButtonHugeFont")
		self.name:SetContentAlignment(5)
		self.name:SetTextColor(color_white)
		self.name:SetPadding(8)
		self.name:SetScaleWidth(true)
	end

	if (!suppress.description) then
		self.description = self.infoScroll:Add("DLabel")
		self.description:Dock(TOP)
		self.description:DockMargin(0, 0, 0, 8)
		self.description:SetFont("ixMenuButtonFont")
		self.description:SetTextColor(color_white)
		self.description:SetContentAlignment(5)
		self.description:SetMouseInputEnabled(true)
		self.description:SetCursor("hand")

		self.description.Paint = function(this, width, height)
			surface.SetDrawColor(0, 0, 0, 150)
			surface.DrawRect(0, 0, width, height)
		end

		self.description.OnMousePressed = function(this, code)
			if (code == MOUSE_LEFT) then
				ix.command.Send("CharDesc")

				if (IsValid(ix.gui.menu)) then
					ix.gui.menu:Remove()
				end
			end
		end

		self.description.SizeToContents = function(this)
			local limit = self.infoScroll:GetWide()
			if (limit <= 0) then
				limit = self:GetWide() - (self.model:GetWide() + 64)
			end

			this:SetWide(limit)
			this:SetTextInset(16, 8)
			this:SetWrap(true)
			this:SetAutoStretchVertical(true)
			
			-- Force a layout update to calculate height
			this:InvalidateLayout(true)
			
			-- Add some padding to the calculated height
			timer.Simple(0, function()
				if (IsValid(this)) then
					this:SetTall(this:GetTall() + 16)
				end
			end)

			this:SetContentAlignment(8)
		end
	end

	if (!suppress.characterInfo) then
		self.characterInfo = self.infoScroll:Add("Panel")
		self.characterInfo.list = {}
		self.characterInfo:Dock(TOP)
		self.characterInfo.SizeToContents = function(this)
			local height = 0

			for _, v in ipairs(this:GetChildren()) do
				if (IsValid(v) and v:IsVisible()) then
					local _, top, _, bottom = v:GetDockMargin()
					height = height + v:GetTall() + top + bottom
				end
			end

			this:SetTall(height)
		end

		if (!suppress.faction) then
			self.faction = self.characterInfo:Add("ixListRow")
			self.faction:SetList(self.characterInfo.list)
			self.faction:Dock(TOP)
		end

		if (!suppress.class) then
			self.class = self.characterInfo:Add("ixListRow")
			self.class:SetList(self.characterInfo.list)
			self.class:Dock(TOP)
		end

		if (!suppress.money) then
			self.money = self.characterInfo:Add("ixListRow")
			self.money:SetList(self.characterInfo.list)
			self.money:Dock(TOP)
			self.money:SizeToContents()
		end

		hook.Run("CreateCharacterInfo", self.characterInfo)
		self.characterInfo:SizeToContents()
	end

	if (!suppress.attributes) then
		local character = LocalPlayer().GetCharacter and LocalPlayer():GetCharacter()

		if (character) then
			self.attributes = self.infoScroll:Add("ixCategoryPanel")
			self.attributes:SetText(L("attributes"))
			self.attributes:Dock(TOP)
			self.attributes:DockMargin(0, 0, 0, 8)

			local boost = character:GetBoosts()
			local bFirst = true

			for k, v in SortedPairsByMemberValue(ix.attributes.list, "name") do
				local attributeBoost = 0

				if (boost[k]) then
					for _, bValue in pairs(boost[k]) do
						attributeBoost = attributeBoost + bValue
					end
				end

				local bar = self.attributes:Add("ixAttributeBar")
				bar:Dock(TOP)

				if (!bFirst) then
					bar:DockMargin(0, 3, 0, 0)
				else
					bFirst = false
				end

				local value = character:GetAttribute(k, 0)

				if (attributeBoost) then
					bar:SetValue(value - attributeBoost or 0)
				else
					bar:SetValue(value)
				end

				local maximum = v.maxValue or ix.config.Get("maxAttributes", 100)
				bar:SetMax(maximum)
				bar:SetReadOnly()
				bar:SetText(Format("%s [%.1f/%.1f] (%.1f%%)", L(v.name), value, maximum, value / maximum * 100))

				if (attributeBoost) then
					bar:SetBoost(attributeBoost)
				end
			end

			self.attributes:SizeToContents()
		end
	end

	hook.Run("CreateCharacterInfoCategory", self.infoScroll)
end

function PANEL:Think()
	local character = LocalPlayer().GetCharacter and LocalPlayer():GetCharacter()
	if (!character) then return end

	local client = LocalPlayer()
	local bChanged = false

	-- Check for model/skin/bodygroup changes on the player entity
	if (IsValid(self.model) and IsValid(self.model.Entity)) then
		local curModel = self.model.Entity:GetModel():lower():gsub("\\", "/")
		local clientModel = client:GetModel():lower():gsub("\\", "/")

		if (curModel != clientModel) then
			bChanged = true
		elseif (self.model.Entity:GetSkin() != client:GetSkin()) then
			bChanged = true
		else
			-- Check bodygroups
			for i = 0, client:GetNumBodyGroups() - 1 do
				if (self.model.Entity:GetBodygroup(i) != client:GetBodygroup(i)) then
					bChanged = true
					break
				end
			end
		end
	else
		-- If model info exists but entity doesn't, we need to update
		bChanged = true
	end

	-- Check for name/description changes
	if (!bChanged) then
		if (self.name and self.name:GetText() != character:GetName()) then
			bChanged = true
		elseif (self.description and self.description:GetText() != character:GetDescription()) then
			bChanged = true
		end
	end

	if (bChanged) then
		self:Update(character)
	end
end

function PANEL:Update(character)
	if (!character) then
		return
	end

	local client = LocalPlayer()
	local bIsLocal = (character:GetPlayer() == client)

	if (IsValid(self.model)) then
		local model = (bIsLocal and client:GetModel()) or character:GetModel()
		local skin = (bIsLocal and client:GetSkin()) or character:GetData("skin", 0)
		local bModelChanged = false

		if (!IsValid(self.model.Entity) or self.model.Entity:GetModel():lower():gsub("\\", "/") != model:lower():gsub("\\", "/")) then
			self.model:SetModel(model, skin)
			bModelChanged = true
		end

		if (IsValid(self.model.Entity)) then
			if (self.model.Entity:GetSkin() != skin) then
				self.model.Entity:SetSkin(skin)
			end

			local groups = (bIsLocal and {}) or character:GetData("groups", {})
			if (bIsLocal) then
				for i = 0, client:GetNumBodyGroups() - 1 do
					groups[i] = client:GetBodygroup(i)
				end
			end

			for k, v in pairs(groups) do
				self.model.Entity:SetBodygroup(k, v)
			end

			if (bModelChanged) then
				local min, max = self.model.Entity:GetRenderBounds()
				local height = max.z - min.z
				local width = max.x - min.x
				local depth = max.y - min.y
				local size = math.max(height, width, depth)

				local fov = self.model:GetFOV()
				local distance = (size * 0.43) / math.tan(math.rad(fov * 0.55))
				
				local center = (min + max) * 0.65

				local verticalAngleOffset = distance * math.tan(math.rad(10))
				
				self.model:SetCamPos(Vector(distance, 0, center.z + (height * 0.1)))
				self.model:SetLookAt(Vector(center.x, center.y, self.model.vCamPos.z - verticalAngleOffset))
			end
		end
	end

	local faction = ix.faction.indices[character:GetFaction()]
	local class = ix.class.list[character:GetClass()]

	if (self.name) then
		self.name:SetText(character:GetName())

		if (faction) then
			self.name.backgroundColor = ColorAlpha(faction.color, 150) or Color(0, 0, 0, 150)
		end

		self.name:SizeToContents()
	end

	if (self.description) then
		self.description:SetText(character:GetDescription())
		self.description:SizeToContents()
		
		-- Ensure the parent list redraws if needed
		if (IsValid(self.characterInfo)) then
			self.characterInfo:SizeToContents()
		end
	end

	if (self.faction) then
		self.faction:SetLabelText(L("faction"))
		self.faction:SetText(L(faction.name))
		self.faction:SizeToContents()
	end

	if (self.class) then
		if (class and class.name != faction.name) then
			self.class:SetLabelText(L("class"))
			self.class:SetText(L(class.name))
			self.class:SizeToContents()
		else
			self.class:SetVisible(false)
		end
	end

	if (self.money) then
		self.money:SetLabelText(L("money"))
		self.money:SetText(ix.currency.Get(character:GetMoney()))
		self.money:SizeToContents()
	end

	hook.Run("UpdateCharacterInfo", self.characterInfo, character)

	self.characterInfo:SizeToContents()

	hook.Run("UpdateCharacterInfoCategory", self, character)
end

function PANEL:OnSubpanelRightClick()
	properties.OpenEntityMenu(LocalPlayer())
end

vgui.Register("ixCharacterInfo", PANEL, "EditablePanel")

-- Overwrite the tab definition to stop using SetCharacterOverview (World View)
hook.Add("CreateMenuButtons", "ixCharInfo", function(tabs)
	tabs["you"] = {
		bHideBackground = true,
		buttonColor = team.GetColor(LocalPlayer():Team()),
		Create = function(info, container)
			container.infoPanel = container:Add("ixCharacterInfo")

			container.OnMouseReleased = function(this, key)
				if (key == MOUSE_RIGHT) then
					this.infoPanel:OnSubpanelRightClick()
				end
			end
		end,
		OnSelected = function(info, container)
			container.infoPanel:Update(LocalPlayer():GetCharacter())
			-- ix.gui.menu:SetCharacterOverview(true) -- DISABLED
		end,
		OnDeselected = function(info, container)
			-- ix.gui.menu:SetCharacterOverview(false) -- DISABLED
		end
	}
end)
