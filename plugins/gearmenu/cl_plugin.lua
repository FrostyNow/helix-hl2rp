local PLUGIN = PLUGIN

-- Gear inventory ID synced from server.
PLUGIN.gearInvID = PLUGIN.gearInvID or 0

-- ============================================================
-- Net Messages
-- ============================================================

net.Receive("ixGearSync", function()
	PLUGIN.gearInvID = net.ReadUInt(32)

	if (IsValid(ix.gui.gearMenu)) then
		ix.gui.gearMenu:RefreshSlots()
	end
end)

-- Equip: use native ixInventoryMove (we know exact source and target grid coords).
local function MoveToGearSlot(panelGridX, panelGridY, sourceInvID, slotIndex)
	local gearInvID = PLUGIN.gearInvID
	if (!gearInvID or gearInvID == 0) then return end
	if (!panelGridX or !panelGridY or !sourceInvID) then return end

	net.Start("ixInventoryMove")
		net.WriteUInt(panelGridX, 6)
		net.WriteUInt(panelGridY, 6)
		net.WriteUInt(1, 6) -- gear inv X is always 1
		net.WriteUInt(slotIndex, 6) -- gear inv Y = slot index
		net.WriteUInt(sourceInvID, 32)
		net.WriteUInt(gearInvID, 32)
	net.SendToServer()
end

-- Unequip: custom net message.
-- Optional targetInvID / targetX / targetY for specific slot placement.
local function UnequipFromGearSlot(slotIndex, targetInvID, targetX, targetY)
	if (!slotIndex) then return end

	net.Start("ixGearUnequip")
		net.WriteUInt(slotIndex, 6)

		local bHasTarget = (targetInvID != nil)
		net.WriteBool(bHasTarget)

		if (bHasTarget) then
			net.WriteUInt(targetInvID, 32)
			net.WriteUInt(targetX or 0, 6)
			net.WriteUInt(targetY or 0, 6)
		end
	net.SendToServer()
end

-- ============================================================
-- Helper: get the standard icon cell size from the main inventory panel
-- ============================================================
local function GetInventoryIconSize()
	if (IsValid(ix.gui.inv1) and ix.gui.inv1.iconSize) then
		return ix.gui.inv1.iconSize
	end

	return 64
end

-- ============================================================
-- ixGearSlot: Individual equipment slot panel
-- ============================================================
local SLOT_PANEL = {}

function SLOT_PANEL:Init()
	self:SetTall(72)
	self:Dock(TOP)
	self:DockMargin(4, 4, 4, 0)

	-- Accept item drops from the inventory.
	self:Receiver("ixInventoryItem", self.OnItemDropped)

	-- Slot label
	self.label = self:Add("DLabel")
	self.label:SetFont("ixSmallFont")
	self.label:SetText("")
	self.label:SetTextColor(Color(200, 200, 200))
	self.label:Dock(FILL)
	self.label:SetContentAlignment(5)
	self.label:SetTall(18)

	self.slotID = ""
	self.slotIndex = 1
	self.equippedItem = nil
end

function SLOT_PANEL:SetSlotInfo(slotData, slotIndex)
	self.slotID = slotData.id
	self.slotName = slotData.name
	self.slotIcon = slotData.icon
	self.slotIndex = slotIndex
	self.label:SetText(slotData.name)
end

function SLOT_PANEL:SetEquippedItem(item)
	-- If same item, skip rebuild.
	if (self.equippedItem and item and self.equippedItem.id == item.id) then
		return
	end

	-- Clear existing display.
	if (IsValid(self.displayPanel)) then
		self.displayPanel:Remove()
		self.displayPanel = nil
	end

	-- Clean up any lingering drag proxy.
	if (IsValid(self.dragProxy)) then
		self.dragProxy:Remove()
		self.dragProxy = nil
	end

	self.equippedItem = item

	if (!item) then return end

	-- ---- Display Panel: ixItemIcon filling the slot content area ----
	local contentH = self:GetTall() - 18
	local displaySize = math.min(self:GetWide() - 8, contentH - 4)

	local display = self:Add("ixItemIcon")
	display:Dock(FILL)
	display:DockMargin(0, 0, 0, 0)
	display:SetModel(item:GetModel() or "models/props_junk/popcan01a.mdl", item:GetSkin())
	display:SetItemTable(item)
	display.gridW = 1
	display.gridH = 1
	display:SetZPos(999)
	display:SetPos((self:GetWide() - displaySize) / 2, (contentH - displaySize) / 2)

    if (item.exRender) then
        display.Icon:SetVisible(false)
        display.ExtraPaint = function(this, panelX, panelY)
            local bg = item:GetData("bodygroups", item.bodyGroups)
            local renderKey = item.uniqueID .. (istable(bg) and util.CRC(util.TableToJSON(bg)) or "") .. "Equipped"

            local exIcon = ikon:GetIcon(renderKey)
            if (exIcon) then
                surface.SetMaterial(exIcon)
                surface.SetDrawColor(color_white)
                surface.DrawTexturedRect(0, 0, panelX, panelY)
            else
                ikon:renderIcon(
                    renderKey,
                    display:GetWide(),
                    display:GetTall(),
                    item:GetModel(),
                    item.iconCam,
                    nil,
                    bg
                )
            end
        end
    else
        -- yeah..
        ix.gui.RenderNewIcon(display, item)
    end

	-- Tooltip on hover.
	display:SetHelixTooltip(function(tooltip)
		ix.hud.PopulateItemTooltip(tooltip, item)
	end)

	-- Store references for the closures.
	local mySlotIndex = self.slotIndex
	local mySlotPanel = self

	-- ---- Left Click: Create drag proxy (standard Helix size) ----
	display.OnMousePressed = function(pnl, mcode)
		if (mcode == MOUSE_RIGHT) then
			pnl:DoRightClick()
			return
		end

		if (mcode != MOUSE_LEFT) then return end

		-- Ensure previous proxy is cleaned up.
		if (IsValid(mySlotPanel.dragProxy)) then
			mySlotPanel.dragProxy:Remove()
		end

		local cellSize = GetInventoryIconSize()
		-- Parent proxy to the gear menu so it gets destroyed if the menu is closed.
		local proxy = vgui.Create("ixItemIcon", ix.gui.gearMenu)
		proxy:SetSize(cellSize * (item.width or 1), cellSize * (item.height or 1))
		proxy:SetModel(item:GetModel() or "models/props_junk/popcan01a.mdl", item:GetSkin())
		proxy:SetItemTable(item)
		proxy:SetInventoryID(PLUGIN.gearInvID)
		proxy.gridX = 1
		proxy.gridY = mySlotIndex
		proxy.gridW = item.width or 1
		proxy.gridH = item.height or 1

        
		if (item.exRender) then
			proxy.Icon:SetVisible(false)
			proxy.ExtraPaint = function(this, panelX, panelY)
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
						item.width,
						item.height,
						item:GetModel(),
						item.iconCam,
						nil,
						bg
					)
				end
			end
		else
			-- yeah..
			ix.gui.RenderNewIcon(proxy, item)
		end

		-- Set up DnD.
		proxy:Droppable("ixInventoryItem")

		-- OnDrop handler.
		proxy.OnDrop = function(proxyPnl, bDragging, inventoryPanel, inventory, gridX, gridY)
			if (!bDragging) then return end

			if (IsValid(inventoryPanel)) then
				if (inventoryPanel.combineItem) then
					-- User dropped onto another item (e.g., bag or combinable).
					local combineItem = inventoryPanel.combineItem
					if (combineItem.isBag) then
						-- Drop straight into the bag's inventory.
						UnequipFromGearSlot(mySlotIndex, combineItem:GetData("id"))
					else
						-- Standard native combine action.
						local inventoryID = combineItem.invID
						if (inventoryID) then
							net.Start("ixInventoryAction")
								net.WriteString("combine")
								net.WriteUInt(combineItem.id, 32)
								net.WriteUInt(inventoryID, 32)
								net.WriteTable({item.id})
							net.SendToServer()
						end
					end
				elseif (inventoryPanel.invID and gridX and gridY) then
					-- Native drop onto specific coordinates.
					UnequipFromGearSlot(mySlotIndex, inventoryPanel.invID, gridX, gridY)
				else
					UnequipFromGearSlot(mySlotIndex)
				end
			else
				UnequipFromGearSlot(mySlotIndex)
			end

			proxyPnl:Remove()
		end

		-- Fallback cleanup: destroy if mouse is released and we're not dragging.
		proxy.Think = function(proxyPnl)
			if (!input.IsMouseDown(MOUSE_LEFT) and !dragndrop.IsDragging()) then
				proxyPnl:Remove()
			end
		end

		-- Position proxy off-screen so ONLY the drag system's ghost is visible.
		proxy:SetPos(-9999, -9999)

		-- Trigger the drag manually.
		proxy:MouseCapture(true)
		proxy:DragMousePress(mcode)

		mySlotPanel.dragProxy = proxy
	end

	display.OnMouseReleased = function(pnl, mcode)
		if (mcode != MOUSE_LEFT) then return end

		if (IsValid(mySlotPanel.dragProxy)) then
			mySlotPanel.dragProxy:DragMouseRelease(mcode)
			mySlotPanel.dragProxy:MouseCapture(false)
		end
	end

	-- ---- Right Click: Context Menu ----
	display.DoRightClick = function()
		local menu = DermaMenu()

		menu:AddOption("Unequip", function()
			UnequipFromGearSlot(mySlotIndex)
		end):SetIcon("icon16/cross.png")

		if (item and item.functions) then
			for k, v in SortedPairs(item.functions) do
				if (k == "drop" or k == "combine" or k == "Equip" or k == "EquipUn") then
					continue
				end

				if (v.OnCanRun and v.OnCanRun(item) == false) then
					continue
				end

				menu:AddOption(L(v.name or k), function()
					item.player = LocalPlayer()

					local send = true

					if (v.OnClick) then
						send = v.OnClick(item)
					end

					if (v.sound) then
						surface.PlaySound(v.sound)
					end

					if (send != false) then
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

	self.displayPanel = display
	self:InvalidateLayout(true)
end

function SLOT_PANEL:PerformLayout(w, h)
end

function SLOT_PANEL:OnRemove()
	if (IsValid(self.dragProxy)) then
		self.dragProxy:Remove()
		self.dragProxy = nil
	end
end

function SLOT_PANEL:OnItemDropped(panels, bDropped, menuIndex, x, y)
	if (!bDropped) then return end

	local panel = panels[1]
	if (!IsValid(panel)) then return end

	local itemTable = panel:GetItemTable()
	if (!itemTable) then return end

	if (!PLUGIN:CanItemFitSlot(itemTable, self.slotID)) then
		return
	end

	if (panel:GetInventoryID() == PLUGIN.gearInvID) then
		-- Dragging from another gear slot.
		-- Use our unequip bypass so `better_armor` doesn't block the swap due to early equip flags.
		UnequipFromGearSlot(panel.gridY, PLUGIN.gearInvID, 1, self.slotIndex)
	else
		-- Moving from main/bag inventory to gear slot.
		MoveToGearSlot(panel.gridX, panel.gridY, panel:GetInventoryID(), self.slotIndex)
	end
end

function SLOT_PANEL:Paint(w, h)
	local bgColor

	if (self.equippedItem) then
		bgColor = Color(40, 70, 40, 200)
	elseif (self:IsHovered()) then
		bgColor = Color(60, 60, 60, 200)
	else
		bgColor = Color(30, 30, 30, 200)
	end

	draw.RoundedBox(4, 0, 0, w, h, bgColor)

	surface.SetDrawColor(80, 80, 80, 150)
	surface.DrawOutlinedRect(0, 0, w, h, 1)

	-- Slot icon placeholder when empty.
	if (!self.equippedItem and self.slotIcon) then
		local iconMat = Material(self.slotIcon)

		if (iconMat and !iconMat:IsError()) then
			surface.SetDrawColor(100, 100, 100, 100)
			surface.SetMaterial(iconMat)
			surface.DrawTexturedRect(w / 2 - 12, (h - 18) / 2 - 4, 24, 24)
		end
	end

	-- Highlight when dragging a compatible item over.
	if (dragndrop.IsDragging()) then
		local droppable = dragndrop.GetDroppable()

		if (droppable and droppable[1]) then
			local itemPanel = droppable[1]

			if (IsValid(itemPanel) and itemPanel.GetItemTable) then
				local itemTable = itemPanel:GetItemTable()

				if (itemTable and PLUGIN:CanItemFitSlot(itemTable, self.slotID)) then
					if (self:IsHovered()) then
						draw.RoundedBox(4, 0, 0, w, h, Color(80, 180, 80, 40))
					else
						draw.RoundedBox(4, 0, 0, w, h, Color(80, 180, 80, 15))
					end
				end
			end
		end
	end
end

vgui.Register("ixGearSlot", SLOT_PANEL, "DPanel")

-- ============================================================
-- ixGearMenu: Main gear menu panel
-- ============================================================
local PANEL = {}

function PANEL:Init()
	if (IsValid(ix.gui.gearMenu)) then
		ix.gui.gearMenu:Remove()
	end

	ix.gui.gearMenu = self

	self:SetTitle("")
	self:ShowCloseButton(false)
	self:SetDraggable(false)
	self:SetSizable(false)

	local scrW, scrH = ScrW(), ScrH()
	local panelW = math.min(scrW * 0.8, 900)
	local panelH = math.min(scrH * 0.75, 650)

	self:SetSize(panelW, panelH)
	self:Center()

	self.bNoBackgroundBlur = false

	-- ---- Left Side: Equipment Panel ----
	local equipWidth = panelW * 0.3

	self.equipPanel = self:Add("DPanel")
	self.equipPanel:SetWide(equipWidth)
	self.equipPanel:Dock(LEFT)
	self.equipPanel:DockMargin(4, 4, 2, 4)
	self.equipPanel.Paint = function(_, w, h)
		draw.RoundedBox(4, 0, 0, w, h, Color(20, 20, 20, 220))
	end

	local equipHeader = self.equipPanel:Add("DLabel")
	equipHeader:SetFont("ixMediumFont")
	equipHeader:SetText("Equipment")
	equipHeader:SetTextColor(Color(220, 220, 220))
	equipHeader:Dock(TOP)
	equipHeader:DockMargin(8, 8, 8, 4)
	equipHeader:SizeToContents()

	local sep = self.equipPanel:Add("DPanel")
	sep:SetTall(1)
	sep:Dock(TOP)
	sep:DockMargin(8, 0, 8, 4)
	sep.Paint = function(_, w, h)
		surface.SetDrawColor(80, 80, 80)
		surface.DrawRect(0, 0, w, h)
	end

	self.slotScroll = self.equipPanel:Add("DScrollPanel")
	self.slotScroll:Dock(FILL)
	self.slotScroll:DockMargin(4, 4, 4, 4)

	local sbar = self.slotScroll:GetVBar()
	sbar:SetWide(4)
	sbar.Paint = function(_, w, h) draw.RoundedBox(2, 0, 0, w, h, Color(30, 30, 30, 100)) end
	sbar.btnUp.Paint = function() end
	sbar.btnDown.Paint = function() end
	sbar.btnGrip.Paint = function(_, w, h) draw.RoundedBox(2, 0, 0, w, h, Color(100, 100, 100, 150)) end

	self.slotPanels = {}

	for i, slotData in ipairs(PLUGIN.GearSlots) do
		local slot = self.slotScroll:Add("ixGearSlot")
		slot:SetSlotInfo(slotData, i)
		slot:Dock(TOP)
		slot:DockMargin(0, 0, 0, 2)

		self.slotPanels[i] = slot
	end

	-- ---- Right Side: Inventory Panel ----
	self.invContainer = self:Add("DPanel")
	self.invContainer:Dock(FILL)
	self.invContainer:DockMargin(2, 4, 4, 4)
	self.invContainer.Paint = function(_, w, h)
		draw.RoundedBox(4, 0, 0, w, h, Color(20, 20, 20, 220))
	end

	local invHeader = self.invContainer:Add("DLabel")
	invHeader:SetFont("ixMediumFont")
	invHeader:SetText("Inventory")
	invHeader:SetTextColor(Color(220, 220, 220))
	invHeader:Dock(TOP)
	invHeader:DockMargin(8, 8, 8, 4)
	invHeader:SizeToContents()

	local sep2 = self.invContainer:Add("DPanel")
	sep2:SetTall(1)
	sep2:Dock(TOP)
	sep2:DockMargin(8, 0, 8, 4)
	sep2.Paint = function(_, w, h)
		surface.SetDrawColor(80, 80, 80)
		surface.DrawRect(0, 0, w, h)
	end

	self.invScroll = self.invContainer:Add("DScrollPanel")
	self.invScroll:Dock(FILL)
	self.invScroll:DockMargin(4, 4, 4, 4)

	local sbar2 = self.invScroll:GetVBar()
	sbar2:SetWide(4)
	sbar2.Paint = function(_, w, h) draw.RoundedBox(2, 0, 0, w, h, Color(30, 30, 30, 100)) end
	sbar2.btnUp.Paint = function() end
	sbar2.btnDown.Paint = function() end
	sbar2.btnGrip.Paint = function(_, w, h) draw.RoundedBox(2, 0, 0, w, h, Color(100, 100, 100, 150)) end

	self.invCanvas = self.invScroll:Add("DTileLayout")
	self.invCanvas:Dock(TOP)
	self.invCanvas:SetBorder(0)
	self.invCanvas:SetSpaceX(2)
	self.invCanvas:SetSpaceY(2)

	self:LoadInventory()
	self:RefreshSlots()

	self.nextRefresh = 0
end

function PANEL:Think()
	if (CurTime() > self.nextRefresh) then
		self.nextRefresh = CurTime() + 0.3
		self:RefreshSlots()
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

	if (ix.option.Get("openBags", true)) then
		for k, _ in inventory:Iter() do
			if (!k.isBag) then continue end

			local viewFunc = k.functions.View
			if (viewFunc and viewFunc.OnClick) then
				viewFunc.OnClick(k)
			end
		end
	end

	self.invCanvas:Layout()
end

function PANEL:RefreshSlots()
	local gearInvID = PLUGIN.gearInvID
	local gearInv = gearInvID and gearInvID > 0 and ix.item.inventories[gearInvID]

	for i, slotPanel in ipairs(self.slotPanels) do
		local item = nil

		if (gearInv and gearInv.slots and gearInv.slots[1]) then
			local slotData = gearInv.slots[1][i]

			if (slotData and istable(slotData) and slotData.id) then
				item = slotData
			end
		end

		slotPanel:SetEquippedItem(item)
	end
end

function PANEL:Paint(w, h)
	ix.util.DrawBlurAt(0, 0, w, h)
	draw.RoundedBox(0, 0, 0, w, h, Color(10, 10, 10, 240))
end

function PANEL:OnRemove()
	if (IsValid(ix.gui.inv1) and ix.gui.inv1:GetParent() == self.invCanvas) then
		ix.gui.inv1:Remove()
	end
end

vgui.Register("ixGearMenu", PANEL, "DFrame")

-- ============================================================
-- Tab Menu Integration
-- ============================================================
hook.Add("CreateMenuButtons", "ixGearMenu", function(tabs)
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