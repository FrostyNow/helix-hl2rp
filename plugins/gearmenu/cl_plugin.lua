local PLUGIN = PLUGIN

-- Gear inventory ID synced from server.
PLUGIN.gearInvID = PLUGIN.gearInvID or 0

net.Receive("ixGearSync", function()
	PLUGIN.gearInvID = net.ReadUInt(32)

	if (IsValid(ix.gui.gearMenu)) then
		ix.gui.gearMenu:RefreshGearInv()
	end
end)

local function RequestEquip(itemID)
	net.Start("ixGearEquipReq")
		net.WriteUInt(itemID, 32)
	net.SendToServer()
end

local function RequestUnequip(itemID, targetInvID, x, y, bDropToGround)
	net.Start("ixGearUnequipReq")
		net.WriteUInt(itemID, 32)
		net.WriteUInt(targetInvID or 0, 32)
		net.WriteInt(x or -1, 16)
		net.WriteInt(y or -1, 16)
		net.WriteBool(bDropToGround or false)
	net.SendToServer()
end

local function RequestGearReorder(itemID, direction)
	net.Start("ixGearReorderReq")
		net.WriteUInt(itemID, 32)
		net.WriteInt(direction or 0, 4)
	net.SendToServer()
end

local WEAPON_ORDER_BADGE = Color(196, 160, 74, 245)
local WEAPON_ORDER_TEXT = Color(20, 16, 8)
local function SetupGearIcon(panel, item)
	if (item.exRender) then
		panel.Icon:SetVisible(false)
		panel.ExtraPaint = function(this, panelX, panelY)
			local bg = item:GetData("bodygroups", item.bodyGroups)
			local renderKey = item.uniqueID .. (istable(bg) and util.CRC(util.TableToJSON(bg)) or "")
			local exIcon = ikon:GetIcon(renderKey)

			if (exIcon) then
				surface.SetMaterial(exIcon)
				surface.SetDrawColor(color_white)
				surface.DrawTexturedRect(0, 0, panelX, panelY)
			else
				ikon:renderIcon(
					renderKey,
					item.width or 1,
					item.height or 1,
					item:GetModel(),
					item.iconCam,
					nil,
					bg
				)
			end
		end
	else
		ix.gui.RenderNewIcon(panel, item)
	end
end

-- ============================================================
-- ixGearMenu Panel
-- ============================================================
local PANEL = {}

function PANEL:Init()
	if (IsValid(ix.gui.gearMenu)) then ix.gui.gearMenu:Remove() end
	ix.gui.gearMenu = self

	self:SetTitle("")
	self:ShowCloseButton(false)
	self:SetDraggable(false)
	self:SetSizable(false)

	local scrW, scrH = ScrW(), ScrH()
	local modelPanelWidth = scrW * 0.2
	local panelW = math.min(scrW * 0.8, 900) + modelPanelWidth
	local panelH = math.min(scrH * 0.75, 650)

	self:SetSize(panelW, panelH)
	self:Center()

	self.bNoBackgroundBlur = false

	local equipWidth = (panelW - modelPanelWidth) * 0.4

	-- Left: Equipment
	self.equipPanel = self:Add("DPanel")
	self.equipPanel:SetWide(equipWidth)
	self.equipPanel:Dock(LEFT)
	self.equipPanel:DockMargin(4, 4, 2, 4)
	self.equipPanel.Paint = function(_, w, h)
		draw.RoundedBox(4, 0, 0, w, h, Color(20, 20, 20, 220))
	end
	
	-- Correctly positioned highlight for equipment zone
	self.equipPanel.PaintOver = function(this, w, h)
		local panels = dragndrop.GetDroppable("ixInventoryItem")
		if (panels and IsValid(panels[1])) then
			local panel = panels[1]
			local item = panel:GetItemTable()
			if (item and item.functions and item.functions.Equip) then
				local mx, my = this:CursorPos()
				if (mx > 0 and my > 32 and mx < w and my < h) then
					surface.SetDrawColor(100, 255, 100, 20)
					surface.DrawRect(0, 32, w, h - 32)
				end
			end
		end

		if (self.bShowEmptyMessage) then
			draw.DrawText(L"gearTooltip", "ixMediumFont", w / 2, h / 2, Color(150, 150, 150, 150), TEXT_ALIGN_CENTER)
		end
	end

	local equipHeader = self.equipPanel:Add("DLabel")
	equipHeader:SetFont("ixMediumFont")
	equipHeader:SetText(L"Equipment")
	equipHeader:SetTextColor(Color(220, 220, 220))
	equipHeader:Dock(TOP)
	equipHeader:DockMargin(8, 8, 8, 4)
	equipHeader:SizeToContents()

	local sep = self.equipPanel:Add("DPanel")
	sep:SetTall(1)
	sep:Dock(TOP)
	sep:DockMargin(8, 0, 8, 4)
	sep.Paint = function(_, w, h) surface.SetDrawColor(80, 80, 80) surface.DrawRect(0, 0, w, h) end

	self.gearScroll = self.equipPanel:Add("DScrollPanel")
	self.gearScroll:Dock(FILL)
	self.gearScroll:DockMargin(4, 4, 4, 4)

	self.gearCanvas = self.gearScroll:Add("DTileLayout")
	self.gearCanvas:Dock(TOP)
	self.gearCanvas:SetBorder(0)
	self.gearCanvas:SetSpaceX(0)
	self.gearCanvas:SetSpaceY(0)
	self.gearCanvas:SetBaseSize(80)

	-- Drop handler for drag and drop equipping
	local function DropHandler(receiver, panels, bDropped, menuIndex, x, y)
		if (!bDropped) then return end
		local panel = panels[1]
		if (!IsValid(panel)) then return end
		local itemTable = panel:GetItemTable()
		if (!itemTable) then return end
		-- Only allow items that have an Equip function
		if (!itemTable.functions or !itemTable.functions.Equip) then return end
		RequestEquip(itemTable.id)
	end

	self.equipPanel:Receiver("ixInventoryItem", DropHandler)
	self.gearScroll:Receiver("ixInventoryItem", DropHandler)
	self.gearCanvas:Receiver("ixInventoryItem", DropHandler)

	-- Middle: Inventory
	self.invContainer = self:Add("DPanel")
	self.invContainer:Dock(FILL)
	self.invContainer:DockMargin(2, 4, 2, 4)
	self.invContainer.Paint = function(_, w, h)
		draw.RoundedBox(4, 0, 0, w, h, Color(20, 20, 20, 220))
	end

	local invHeader = self.invContainer:Add("DLabel")
	invHeader:SetFont("ixMediumFont")
	invHeader:SetText(L("Inventory"))
	invHeader:SetTextColor(Color(220, 220, 220))
	invHeader:Dock(TOP)
	invHeader:DockMargin(8, 8, 8, 4)
	invHeader:SizeToContents()

	local sep2 = self.invContainer:Add("DPanel")
	sep2:SetTall(1)
	sep2:Dock(TOP)
	sep2:DockMargin(8, 0, 8, 4)
	sep2.Paint = function(_, w, h) surface.SetDrawColor(80, 80, 80) surface.DrawRect(0, 0, w, h) end

	self.invScroll = self.invContainer:Add("DScrollPanel")
	self.invScroll:Dock(FILL)
	self.invScroll:DockMargin(4, 4, 4, 4)

	self.invCanvas = self.invScroll:Add("DTileLayout")
	self.invCanvas:Dock(TOP)
	self.invCanvas:SetBorder(0)
	self.invCanvas:SetBaseSize(1)
	self.invCanvas:SetSpaceX(4)
	self.invCanvas:SetSpaceY(4)

	-- Right: Character Model Preview
	self.modelContainer = self:Add("DPanel")
	self.modelContainer:SetWide(modelPanelWidth)
	self.modelContainer:Dock(RIGHT)
	self.modelContainer:DockMargin(2, 4, 4, 4)
	self.modelContainer.Paint = function(_, w, h)
		draw.RoundedBox(4, 0, 0, w, h, Color(20, 20, 20, 220))
	end

	self.model = self.modelContainer:Add("ixModelPanel")
	self.model:Dock(FILL)
	self.model:DockMargin(4, 4, 4, 4)
	self.model:SetFOV(30)
	self.model:SetCamPos(Vector(85, 7, 50))
	self.model:SetLookAt(Vector(0, 0, 38))

	-- Initial setup
	self.model.currentAngles = Angle(0, -15, 0)
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

		Schema:ApplyMaskScale(entity)
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

	self:UpdateModel()

	self:LoadInventory()
	self:RefreshGearInv()

	self.nextRefresh = 0
end

function PANEL:Think()
	if (CurTime() > self.nextRefresh) then
		self.nextRefresh = CurTime() + 0.5
		self:RefreshGearInv()
		self:CheckModelUpdate()
	end
end

function PANEL:CheckModelUpdate()
	if (!IsValid(self.model) or !IsValid(self.model.Entity)) then
		self:UpdateModel()
		return
	end

	local client = LocalPlayer()
	local curModel = self.model.Entity:GetModel():lower():gsub("\\", "/")
	local clientModel = client:GetModel():lower():gsub("\\", "/")

	if (curModel != clientModel) then
		self:UpdateModel()
		return
	end

	if (self.model.Entity:GetSkin() != client:GetSkin()) then
		self:UpdateModel()
		return
	end

	-- Check bodygroups
	for i = 0, client:GetNumBodyGroups() - 1 do
		if (self.model.Entity:GetBodygroup(i) != client:GetBodygroup(i)) then
			self:UpdateModel()
			return
		end
	end
end

function PANEL:UpdateModel()
	if (!IsValid(self.model)) then return end

	local client = LocalPlayer()
	local character = client.GetCharacter and client:GetCharacter()
	if (!character) then return end

	local bIsLocal = (character:GetPlayer() == client)
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
			local distance = (size * 0.3) / math.tan(math.rad(fov * 0.55))

			local center = (min + max) * 0.65

			local verticalAngleOffset = distance * math.tan(math.rad(10))

			self.model:SetCamPos(Vector(distance, 0, center.z + (height * 0.1)))
			self.model:SetLookAt(Vector(center.x, center.y, self.model.vCamPos.z - verticalAngleOffset))
		end
	end
end

local BASE_PRIO = {
	["base_weapons"] = 1,
	["base_armor"] = 2,
	["base_houtfit"] = 3,
	["base_filter"] = 4
}

local CAT_PRIO = {
	["head"] = 1,
	["body"] = 2,
}

function PANEL:RefreshGearInv()
	if (!IsValid(self.gearCanvas)) then return end

	local character = LocalPlayer():GetCharacter()
	if (!character) then return end

	local gearInvID = PLUGIN.gearInvID
	local gearInv = gearInvID and gearInvID > 0 and ix.item.inventories[gearInvID]

	local equippedItems = {}
	if (gearInv) then
		for id, item in pairs(gearInv:GetItems()) do
			if (item:GetData("equip") == true) then
				equippedItems[#equippedItems + 1] = item
			end
		end
	end

	-- Sophisticated sorting
	table.sort(equippedItems, function(a, b)
		if (a.isWeapon != b.isWeapon) then
			return a.isWeapon == false
		end

		if (a.isWeapon and b.isWeapon) then
			local aTime = tonumber(a:GetData("equipTime", 0)) or 0
			local bTime = tonumber(b:GetData("equipTime", 0)) or 0

			if (aTime != bTime) then
				return aTime < bTime
			end

			return a:GetName() < b:GetName()
		end

		local aBase = a.base or ""
		local bBase = b.base or ""
		local aPrio = BASE_PRIO[aBase] or 99
		local bPrio = BASE_PRIO[bBase] or 99

		if (aPrio != bPrio) then
			return aPrio < bPrio
		end

		local aCat = a.weaponCategory or a.outfitCategory or a.category or ""
		local bCat = b.weaponCategory or b.outfitCategory or b.category or ""
		local aCatPrio = CAT_PRIO[aCat] or 99
		local bCatPrio = CAT_PRIO[bCat] or 99

		if (aCatPrio != bCatPrio) then
			return aCatPrio < bCatPrio
		end

		local aTime = a:GetData("equipTime", 0)
		local bTime = b:GetData("equipTime", 0)

		if (aTime != bTime) then
			return aTime < bTime
		end

		return a:GetName() < b:GetName()
	end)

	-- Build a hash to avoid needless redraws
	local hash = ""
	local weaponDisplayIndex = 0
	for _, item in ipairs(equippedItems) do
		local filterHash = "0"
		if (item.GetData) then
			filterHash = item:GetData("filterInstalled") and "1" or "0"
		end
		hash = hash .. (item.id or "0") .. filterHash .. ","
	end

	self.bShowEmptyMessage = (#equippedItems == 0)

	if (self.lastHash == hash) then
		self:RefreshBags()
		return
	end
	self.lastHash = hash

	self.gearCanvas:Clear()

	local iconSize = 80

	for _, item in ipairs(equippedItems) do
		local weaponOrder

		if (item.isWeapon) then
			weaponDisplayIndex = weaponDisplayIndex + 1
			weaponOrder = weaponDisplayIndex
		end

		local icon = self.gearCanvas:Add("ixItemIcon")
		icon:SetSize(item.width * iconSize, item.height * iconSize)
		icon:SetZPos(999)
		icon:InvalidateLayout(true)
		icon:SetModel(item:GetModel() or "models/props_junk/popcan01a.mdl", item:GetSkin())
		icon:SetItemTable(item)
		icon:SetInventoryID(item.invID or 0)
		icon.gridW = item.width
		icon.gridH = item.height
		icon.gridX = 1
		icon.gridY = 1

		icon:Droppable("ixInventoryItem")

		icon.OnMousePressed = function(this, mcode)
			if (mcode == MOUSE_RIGHT) then
				this:DoRightClick()
				return
			end

			if (mcode != MOUSE_LEFT) then return end

			if (IsValid(this.dragProxy)) then
				this.dragProxy:Remove()
			end

			local cellSize = (IsValid(ix.gui.inv1) and ix.gui.inv1.iconSize) or 64

			local proxy = vgui.Create("ixItemIcon", ix.gui.gearMenu)
			proxy:SetSize(cellSize * item.width, cellSize * item.height)
			proxy:SetZPos(999)
			proxy:InvalidateLayout(true)
			proxy:SetModel(item:GetModel() or "models/props_junk/popcan01a.mdl", item:GetSkin())
			proxy:SetItemTable(item)
			proxy:SetInventoryID(PLUGIN.gearInvID)
			proxy.gridX = 1
			proxy.gridY = 1
			proxy.gridW = item.width
			proxy.gridH = item.height

			SetupGearIcon(proxy, item)

			proxy:Droppable("ixInventoryItem")
			
			proxy.OnDrop = function(proxyPnl, bDragging, inventoryPanel, inventory, gridX, gridY)
				if (!bDragging) then return end

				if (IsValid(inventoryPanel)) then
					if (inventoryPanel.combineItem) then
						local combineItem = inventoryPanel.combineItem
						if (combineItem.isBag) then
							RequestUnequip(item.id, combineItem:GetData("id"))
						else
							local invID = combineItem.invID
							if (invID) then
								net.Start("ixInventoryAction")
									net.WriteString("combine")
									net.WriteUInt(combineItem.id, 32)
									net.WriteUInt(invID, 32)
									net.WriteTable({item.id})
								net.SendToServer()
							end
						end
						elseif (inventoryPanel.invID) then
							local inv = inventory or (inventoryPanel.GetInventory and inventoryPanel:GetInventory())
							local dropX, dropY = gridX, gridY

							if (inventoryPanel.GetSlotPos and (!dropX or !dropY)) then
								dropX, dropY = inventoryPanel:GetSlotPos(gui.MouseX(), gui.MouseY())
							end

							if (inv and dropX and dropY and inv:CanItemFit(dropX, dropY, item.width, item.height, item)) then
								RequestUnequip(item.id, inventoryPanel.invID, dropX, dropY)
							else
								RequestUnequip(item.id)
							end
						else
							RequestUnequip(item.id)
						end
				else
					RequestUnequip(item.id, nil, nil, nil, true)
				end

				proxyPnl:Remove()
			end

			proxy.Think = function(proxyPnl)
				if (!input.IsMouseDown(MOUSE_LEFT) and !dragndrop.IsDragging()) then
					proxyPnl:Remove()
				end
			end

			proxy:SetPos(-9999, -9999)
			proxy:MouseCapture(true)
			proxy:DragMousePress(mcode)
			this.dragProxy = proxy
		end

		icon.OnMouseReleased = function(this, mcode)
			if (mcode != MOUSE_LEFT) then return end
			if (IsValid(this.dragProxy)) then
				this.dragProxy:DragMouseRelease(mcode)
				this.dragProxy:MouseCapture(false)
			end
		end

		icon.OnRemove = function(this)
			if (IsValid(this.dragProxy)) then
				this.dragProxy:Remove()
				this.dragProxy = nil
			end
		end

		SetupGearIcon(icon, item)

		if (weaponOrder) then
			local oldPaintOver = icon.PaintOver

			icon.PaintOver = function(this, w, h)
				if (oldPaintOver) then
					oldPaintOver(this, w, h)
				end

				draw.RoundedBox(4, 6, 6, 24, 20, WEAPON_ORDER_BADGE)
				draw.SimpleText(tostring(weaponOrder), "ixSmallFont", 18, 8, WEAPON_ORDER_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			end
		end

		icon:SetHelixTooltip(function(tooltip)
			ix.hud.PopulateItemTooltip(tooltip, item)
		end)

		icon.DoRightClick = function()
			local menu = DermaMenu()
			menu:AddOption(L("Unequip"), function()
				RequestUnequip(item.id)
			end):SetIcon("icon16/cross.png")
			if (item.isWeapon and (tonumber(item:GetData("equipTime", 0)) or 0) > 0 and item.class != "weapon_physgun" and item.class != "gmod_tool") then
				menu:AddOption(L("moveUp"), function()
					RequestGearReorder(item.id, -1)
				end):SetIcon("icon16/arrow_up.png")

				menu:AddOption(L("moveDown"), function()
					RequestGearReorder(item.id, 1)
				end):SetIcon("icon16/arrow_down.png")
			end

			if (item.functions) then
				for k, v in SortedPairs(item.functions) do
					if (k == "drop" or k == "combine" or k == "Equip" or k == "EquipUn") then continue end
					if (v.OnCanRun and v.OnCanRun(item) == false) then continue end

					menu:AddOption(L(v.name or k), function()
						item.player = LocalPlayer()
						local bSend = true

						if (v.OnClick) then
							bSend = v.OnClick(item)
						end

						if (v.sound) then
							surface.PlaySound(v.sound)
						end

						if (bSend != false) then
							net.Start("ixInventoryAction")
								net.WriteString(k)
								net.WriteUInt(item.id, 32)
								net.WriteUInt(item.invID, 32)
								net.WriteTable({})
							net.SendToServer()
						end

						item.player = nil
					end):SetImage(v.icon or "icon16/brick.png")
				end
			end

			menu:Open()
		end

		icon.OnDrop = function(this, bDragging)
			if (!bDragging) then return end
			
			local hovered = vgui.GetHoveredPanel()
			local invPanel
			
			while (IsValid(hovered)) do
				if (hovered.GetClassName and hovered:GetClassName() == "ixInventory") then
					invPanel = hovered
					break
				end
				hovered = hovered:GetParent()
			end

			if (invPanel and invPanel.GetInventory) then
				local inv = invPanel:GetInventory()
				local dropX, dropY = invPanel:GetSlotPos(gui.MouseX(), gui.MouseY())

				if (inv and dropX and dropY and inv:CanItemFit(dropX, dropY, this.gridW, this.gridH, item)) then
					RequestUnequip(item.id, inv:GetID(), dropX, dropY)
				else
					RequestUnequip(item.id)
				end
			else
				RequestUnequip(item.id, nil, nil, nil, true)
			end
		end
	end

	self:RefreshBags()
end

function PANEL:RefreshBags()
	if (!ix.option.Get("openBags", true)) then return end

	local character = LocalPlayer():GetCharacter()
	if (!character) then return end

	local inventory = character:GetInventory()
	if (!inventory) then return end

	local gearInvID = PLUGIN.gearInvID
	local gearInv = gearInvID and gearInvID > 0 and ix.item.inventories[gearInvID]

	-- Collect all bag items currently in possession (equipped in gear or in main inventory)
	local validBags = {}
	local mainInvID = inventory:GetID()

	if (gearInv) then
		for _, itm in pairs(gearInv:GetItems()) do
			if (itm.isBag and itm:GetData("equip") == true) then
				local bagInvID = itm:GetData("id")
				-- Verify the item actually thinks it's in the gear inventory
				if (bagInvID and itm.invID == gearInvID) then 
					validBags[bagInvID] = itm 
				end
			end
		end
	end

	for _, itm in pairs(inventory:GetItems()) do
		if (itm.isBag) then
			local bagInvID = itm:GetData("id")
			-- Verify the item actually thinks it's in the main inventory
			if (bagInvID and itm.invID == mainInvID) then 
				validBags[bagInvID] = itm 
			end
		end
	end

	-- Build hash to detect changes
	local bagHash = ""
	for id, _ in SortedPairs(validBags) do
		bagHash = bagHash .. id .. ","
	end

	-- Clean up panels for bags no longer in possession
	for _, child in ipairs(self.invCanvas:GetChildren()) do
		if (child == ix.gui.inv1) then continue end
		if (child.invID) then
			local id = child.invID
			if (!validBags[id]) then
				child:Remove()
				ix.gui["inv" .. id] = nil
			end
		end
	end

	-- Open missing panels for valid bags (always check, regardless of hash)
	local bOpened = false
	for bagInvID, itm in pairs(validBags) do
		if (!IsValid(ix.gui["inv" .. bagInvID])) then
			local viewFunc = itm.functions and itm.functions.View
			if (viewFunc and viewFunc.OnClick) then
				viewFunc.OnClick(itm)
				bOpened = true
			end
		end
	end

	if (bOpened or self.lastBagHash != bagHash) then
		self.lastBagHash = bagHash

		if (IsValid(self.invCanvas)) then
			self.invCanvas:Layout()
		end
	end
end

function PANEL:LoadInventory()
	local character = LocalPlayer():GetCharacter()
	if (!character) then return end

	local inventory = character:GetInventory()
	if (!inventory) then return end

	local invPanel = vgui.Create("ixInventory", self.invCanvas)
	invPanel:SetPos(0, 0)
	invPanel:SetDraggable(false)
	invPanel:SetSizable(false)
	invPanel:SetTitle(nil)
	invPanel.bNoBackgroundBlur = true
	invPanel.childPanels = {}

	invPanel:SetInventory(inventory)

	ix.gui.inv1 = invPanel
	-- Ensure Helix knows where to open bag panels.
	ix.gui.menuInventoryContainer = self.invCanvas

	-- Open main inventory bags natively
	if (ix.option.Get("openBags", true)) then
		for k, _ in inventory:Iter() do
			if (!k.isBag) then continue end

			local viewFunc = k.functions.View
			if (viewFunc and viewFunc.OnClick) then
				viewFunc.OnClick(k)
			end
		end
	end

	-- Equipped bags are handled by RefreshBags via RefreshGearInv
	self.invCanvas:Layout()
end

function PANEL:Paint(w, h)
	ix.util.DrawBlurAt(0, 0, w, h)
	draw.RoundedBox(0, 0, 0, w, h, Color(10, 10, 10, 240))
end

function PANEL:OnRemove()
	if (IsValid(ix.gui.inv1) and ix.gui.inv1:GetParent() == self.invCanvas) then
		ix.gui.inv1:Remove()
	end

	if (IsValid(self.invCanvas)) then
		for _, child in ipairs(self.invCanvas:GetChildren()) do
			if (IsValid(child)) then
				child:Remove()
			end
		end
	end
end

vgui.Register("ixGearMenu", PANEL, "DFrame")

-- ============================================================
-- Tab Menu Integration
-- ============================================================
hook.Add("CreateMenuButtons", "ixGearMenu", function(tabs)
	tabs["inv"] = nil -- hide default inventory tab

	tabs["gear"] = {
		Create = function(info, container)
			local gearMenu = container:Add("ixGearMenu")
			gearMenu:SetPos(0, 0)
			gearMenu:SetSize(container:GetSize())
			gearMenu:SetDraggable(false)
			gearMenu:SetSizable(false)
			gearMenu:ShowCloseButton(false)
			gearMenu:SetTitle("")
			gearMenu.bNoBackgroundBlur = true
			gearMenu.Paint = function() end
			gearMenu.btnMinim:SetVisible(false)
			gearMenu.btnMaxim:SetVisible(false)
			gearMenu.btnClose:SetVisible(false)
		end
	}
end)
