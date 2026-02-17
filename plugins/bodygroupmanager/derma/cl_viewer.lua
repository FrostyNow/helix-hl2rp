
local PLUGIN = PLUGIN

local PANEL = {}

function PANEL:Init()
	local pWidth, pHeight = ScrW() * 0.75, ScrH() * 0.75
	self:SetSize(pWidth, pHeight)
	self:Center()
	self:SetBackgroundBlur(true)
	self:SetDeleteOnClose(true)

	self:MakePopup()
	self:SetTitle(L("bodygroupManager"))
	
	-- Premium fade-in
	self:SetAlpha(0)
	self:AlphaTo(255, 0.3, 0)

	self.bodygroups = self:Add("DScrollPanel")
	self.bodygroups:Dock(RIGHT)
	self.bodygroups:SetWide(pWidth * 0.4)
	self.bodygroups:DockPadding(16, 16, 48, 16)
	self.bodygroups:DockMargin(0, 32, 0, 32)
	
	local vBar = self.bodygroups:GetVBar()
	vBar:SetWide(4)
	vBar:SetHideButtons(true)
	vBar.Paint = nil
	vBar.btnGrip.Paint = function(this, w, h)
		surface.SetDrawColor(255, 255, 255, 50)
		surface.DrawRect(0, 0, w, h)
	end
end

function PANEL:Paint(w, h)
	surface.SetDrawColor(0, 0, 0, 200)
	surface.DrawRect(0, 0, w, h)
	
	surface.SetDrawColor(255, 255, 255, 10)
	surface.DrawOutlinedRect(0, 0, w, h)
	
	ix.util.DrawBlur(self, 5)
end

function PANEL:OnKeyCodePressed(keyCode)
	if (keyCode == KEY_TAB or keyCode == KEY_ESCAPE) then
		self:Close()
		return true
	end
end

function PANEL:Display(target)
	local pWidth, pHeight = self:GetSize()

	self.saveButton = self:Add("ixMenuButton")
	self.saveButton:Dock(BOTTOM)
	self.saveButton:SetTall(64)
	self.saveButton:SetText(L("saveChanges"):upper())
	self.saveButton:SetTextColor(color_white)
	self.saveButton:SetBackgroundColor(Color(0, 0, 0, 150))
	self.saveButton:SetFont("ixMediumFont")
	self.saveButton.DoClick = function(this)
		local bodygroups = {}
		for _, v in pairs(self.bodygroupIndex) do
			bodygroups[v.index] = v.value
		end

		net.Start("ixBodygroupTableSet")
			net.WriteEntity(self.target)
			net.WriteTable(bodygroups)
			net.WriteUInt(self.skinIndex and self.skinIndex.value or self.target:GetSkin(), 8)
		net.SendToServer()
		
		surface.PlaySound("buttons/button14.wav")
		self:Close()
	end

	self.model = self:Add("DAdjustableModelPanel")
	self.model:SetSize(pWidth * 0.6, pHeight - 64)
	self.model:Dock(LEFT)
	self.model:SetModel(target:GetModel())
	self.model.Entity:SetSkin(target:GetSkin())
	self.model:SetLookAng(Angle(2, 225, 0))
	self.model:SetCamPos(Vector(50, 50, 45))
	self.model:SetMouseInputEnabled(true)
	self.model.ixRotationYaw = 45
	self.model.ixDragging = false
	self.model.ixLastMouseX = 0

	function self.model:FirstPersonControls() end

	function self.model:DragMousePress()
		self.ixDragging = true
		self.ixLastMouseX = gui.MouseX()
		self:MouseCapture(true)
	end

	function self.model:DragMouseRelease()
		self.ixDragging = false
		self:MouseCapture(false)
	end

	function self.model:OnMousePressed(mouseCode)
		if (mouseCode == MOUSE_LEFT) then
			self:DragMousePress()
		end
	end

	function self.model:OnMouseReleased(mouseCode)
		if (mouseCode == MOUSE_LEFT) then
			self:DragMouseRelease()
		end
	end

	self.target = target
	self:PopulateBodygroupOptions()
	self:SetTitle(target:GetName())

	function self.model:LayoutEntity(Entity)
		if (self.ixDragging) then
			local mouseX = gui.MouseX()
			local deltaX = mouseX - (self.ixLastMouseX or mouseX)

			self.ixRotationYaw = (self.ixRotationYaw or 45) - deltaX * 0.5
			self.ixLastMouseX = mouseX
		end

		Entity:SetAngles(Angle(0, self.ixRotationYaw or 45, 0))
		Entity:SetIK(false)

		-- Eye fix
		local eyeTarget = Entity:GetPos() + Entity:GetForward() * 10000 + Vector(0, 0, 64)
		Entity:SetEyeTarget(eyeTarget)

		-- Neutral pose
		Entity:SetPoseParameter("head_pitch", 0)
		Entity:SetPoseParameter("head_yaw", 0)
		Entity:SetPoseParameter("aim_pitch", 0)
		Entity:SetPoseParameter("aim_yaw", 0)
		Entity:SetPoseParameter("eyes_pitch", 0)
		Entity:SetPoseParameter("eyes_yaw", 0)
		
		local sequence = Entity:SelectWeightedSequence(ACT_IDLE)
		if (sequence <= 0) then
			sequence = Entity:LookupSequence("idle_unarmed")
		end

		if (sequence > 0) then
			Entity:ResetSequence(sequence)
		else
			local found = false
			for _, v in ipairs(Entity:GetSequenceList()) do
				if ((v:lower():find("idle") or v:lower():find("fly")) and v != "idlenoise") then
					Entity:ResetSequence(v)
					found = true
					break
				end
			end
			if (!found) then Entity:ResetSequence(4) end
		end
	end
		
	-- Face Closeup Panel
	self.facePanel = self:Add("DModelPanel")
	self.facePanel:SetSize(ScreenScale(64), ScreenScale(64))
	self.facePanel:SetPos(4, pHeight * 0.5 - 64 - ScreenScale(64) - 4)
	self.facePanel:SetModel(target:GetModel())
	self.facePanel.Entity:SetSkin(target:GetSkin())
	for k, v in pairs(target:GetBodyGroups()) do
		self.facePanel.Entity:SetBodygroup(v.id, target:GetBodygroup(v.id))
	end
	self.facePanel:SetMouseInputEnabled(false)
	self.facePanel.LayoutEntity = function(this, entity)
		entity:SetAngles(Angle(0, 45, 0))
		entity:SetIK(false)
		
		-- Neutral pose
		entity:SetPoseParameter("head_pitch", 0)
		entity:SetPoseParameter("head_yaw", 0)
		entity:SetPoseParameter("aim_pitch", 0)
		entity:SetPoseParameter("aim_yaw", 0)
		entity:SetPoseParameter("eyes_pitch", 0)
		entity:SetPoseParameter("eyes_yaw", 0)
		
		-- Default sequence logic
		entity:SetSequence(self.model.Entity:GetSequence())
		entity:SetCycle(self.model.Entity:GetCycle())
		
		-- Eye fix for closeup
		local eyeTarget = entity:GetPos() + entity:GetForward() * 10000 + Vector(0, 0, 64)
		entity:SetEyeTarget(eyeTarget)
		local headBone = entity:LookupBone("ValveBiped.Bip01_Head1")
		if (headBone) then
			local headPos = entity:GetBonePosition(headBone)
			this:SetLookAt(headPos)
			this:SetCamPos(headPos + entity:GetForward() * 45 + entity:GetUp() * -2)
			this:SetFOV(20)
		else
			this:SetCamPos(Vector(20, 0, 60))
			this:SetLookAt(Vector(0, 0, 60))
		end
	end
end

local function CreateEditorRow(parent, labelText, currentValue, onPrev, onNext, onValueSet)
	local row = parent:Add("DPanel")
	row:Dock(TOP)
	row:DockMargin(0, 0, 0, 8)
	row:SetTall(50)
	
	local themeColor = ix.config.Get("color")
	row.Paint = function(this, w, h)
		surface.SetDrawColor(themeColor.r, themeColor.g, themeColor.b, 10)
		surface.DrawRect(0, 0, w, h)
		
		surface.SetDrawColor(themeColor.r, themeColor.g, themeColor.b, 30)
		surface.DrawOutlinedRect(0, 0, w, h)
	end

	local label = row:Add("DLabel")
	label:SetText(labelText:upper())
	label:SetFont("ixSmallFont")
	label:Dock(LEFT)
	label:DockMargin(16, 0, 0, 0)
	label:SetWide(150)
	label:SetTextColor(color_white)

	local rightPanel = row:Add("Panel")
	rightPanel:Dock(RIGHT)
	rightPanel:SetWide(150)

	local nextBtn = rightPanel:Add("DButton")
	nextBtn:SetText(">")
	nextBtn:SetFont("ixMediumFont")
	nextBtn:Dock(RIGHT)
	nextBtn:SetWide(40)
	nextBtn.Paint = function(this, w, h)
		surface.SetDrawColor(255, 255, 255, this:IsHovered() and 20 or 10)
		surface.DrawRect(0, 0, w, h)
	end
		
	-- Hold to change logic
	nextBtn.DoClick = onNext
	nextBtn.nextRun = 0
	nextBtn.Think = function(this)
		if (this:IsDown()) then
			if (this.nextRun == 0) then
				this.nextRun = RealTime() + 0.3
			elseif (RealTime() >= this.nextRun) then
				onNext()
				this.nextRun = RealTime() + 0.1
			end
		else
			this.nextRun = 0
		end
	end
	
	local valueEntry = rightPanel:Add("DTextEntry")
	valueEntry:SetText(currentValue)
	valueEntry:SetFont("ixMediumFont")
	valueEntry:SetNumeric(true)
	valueEntry:Dock(FILL)
	valueEntry:SetPaintBackground(false)
	valueEntry:SetTextColor(color_white)
	valueEntry:SetContentAlignment(5) -- Center alignment support depends on skin/font
	valueEntry.value = currentValue
		
	valueEntry.OnEnter = function(this)
		if (onValueSet) then
			onValueSet(tonumber(this:GetValue()) or 0)
		end
	end
	
	local prevBtn = rightPanel:Add("DButton")
	prevBtn:SetText("<")
	prevBtn:SetFont("ixMediumFont")
	prevBtn:Dock(LEFT)
	prevBtn:SetWide(40)
	prevBtn.Paint = function(this, w, h)
		surface.SetDrawColor(255, 255, 255, this:IsHovered() and 20 or 10)
		surface.DrawRect(0, 0, w, h)
	end
		
	-- Hold to change logic
	prevBtn.DoClick = onPrev
	prevBtn.nextRun = 0
	prevBtn.Think = function(this)
		if (this:IsDown()) then
			if (this.nextRun == 0) then
				this.nextRun = RealTime() + 0.3
			elseif (RealTime() >= this.nextRun) then
				onPrev()
				this.nextRun = RealTime() + 0.1
			end
		else
			this.nextRun = 0
		end
	end

	return valueEntry
end

function PANEL:PopulateBodygroupOptions()
	self.bodygroupIndex = {}
	
	local client = LocalPlayer()
	local character = client:GetCharacter()
	local target = self.target
	local isSelf = (target == client)
	local canAdmin = ix.command.HasAccess(client, "CharEditBodygroup")

	local canBodygroup = canAdmin or (isSelf and character:HasFlags("b"))
	local canSkin = canAdmin or (isSelf and character:HasFlags("s"))

	if (canSkin) then
		local skinCount = target:SkinCount()
		if (skinCount > 1) then
			self.skinIndex = CreateEditorRow(self.bodygroups, L("skin"), target:GetSkin(), function()
				if (self.skinIndex.value <= 0) then return end
				self.skinIndex.value = self.skinIndex.value - 1
				self.skinIndex:SetText(self.skinIndex.value)
				self.model.Entity:SetSkin(self.skinIndex.value)
				if (IsValid(self.facePanel)) then self.facePanel.Entity:SetSkin(self.skinIndex.value) end
				surface.PlaySound("buttons/lightswitch2.wav")
			end, function()
				if (self.skinIndex.value >= target:SkinCount() - 1) then return end
				self.skinIndex.value = self.skinIndex.value + 1
				self.skinIndex:SetText(self.skinIndex.value)
				self.model.Entity:SetSkin(self.skinIndex.value)
				if (IsValid(self.facePanel)) then self.facePanel.Entity:SetSkin(self.skinIndex.value) end
				surface.PlaySound("buttons/lightswitch2.wav")
			end, function(val)
				val = math.Clamp(math.Round(val), 0, target:SkinCount() - 1)
				self.skinIndex.value = val
				self.skinIndex:SetText(val)
				self.model.Entity:SetSkin(val)
				if (IsValid(self.facePanel)) then self.facePanel.Entity:SetSkin(val) end
				surface.PlaySound("buttons/lightswitch2.wav")
			end)
		end
	end

	if (canBodygroup) then
		for k, v in pairs(target:GetBodyGroups()) do
			if (v.id == 0) then continue end
			
			local index = v.id
			self.bodygroupIndex[index] = CreateEditorRow(self.bodygroups, v.name:gsub("^%l", string.upper), target:GetBodygroup(index), function()
				if (self.bodygroupIndex[index].value <= 0) then return end
				self.bodygroupIndex[index].value = self.bodygroupIndex[index].value - 1
				self.bodygroupIndex[index]:SetText(self.bodygroupIndex[index].value)
				self.model.Entity:SetBodygroup(index, self.bodygroupIndex[index].value)
				if (IsValid(self.facePanel)) then self.facePanel.Entity:SetBodygroup(index, self.bodygroupIndex[index].value) end
				surface.PlaySound("buttons/lightswitch2.wav")
			end, function()
				if (self.bodygroupIndex[index].value >= self.model.Entity:GetBodygroupCount(index) - 1) then return end
				self.bodygroupIndex[index].value = self.bodygroupIndex[index].value + 1
				self.bodygroupIndex[index]:SetText(self.bodygroupIndex[index].value)
				self.model.Entity:SetBodygroup(index, self.bodygroupIndex[index].value)
				if (IsValid(self.facePanel)) then self.facePanel.Entity:SetBodygroup(index, self.bodygroupIndex[index].value) end
				surface.PlaySound("buttons/lightswitch2.wav")
			end, function(val)
				val = math.Clamp(math.Round(val), 0, self.model.Entity:GetBodygroupCount(index) - 1)
				self.bodygroupIndex[index].value = val
				self.bodygroupIndex[index]:SetText(val)
				self.model.Entity:SetBodygroup(index, val)
				if (IsValid(self.facePanel)) then self.facePanel.Entity:SetBodygroup(index, val) end
				surface.PlaySound("buttons/lightswitch2.wav")
			end)
			
			self.bodygroupIndex[index].index = index
			self.model.Entity:SetBodygroup(index, target:GetBodygroup(index))
		end
	end
end

vgui.Register("ixBodygroupView", PANEL, "DFrame")
