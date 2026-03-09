
local PLUGIN = PLUGIN

PLUGIN.stack = PLUGIN.stack or {}
PLUGIN.stack.clientStacks = PLUGIN.stack.clientStacks or {}

local function GetClientStackCache(inventoryOrID)
	local invID = isnumber(inventoryOrID) and inventoryOrID or (inventoryOrID and inventoryOrID.GetID and inventoryOrID:GetID())

	if (!invID) then
		return nil
	end

	PLUGIN.stack.clientStacks[invID] = PLUGIN.stack.clientStacks[invID] or {}
	return PLUGIN.stack.clientStacks[invID]
end

local function GetClientStack(inventory, x, y)
	if (!inventory or x == nil or y == nil) then
		return nil
	end

	local cache = GetClientStackCache(inventory)
	return cache and cache[x .. ":" .. y] or nil
end

local function IsStackRepresentative(inventory, item, x, y)
	local stack = GetClientStack(inventory, x, y)
	return stack and #stack > 1 and stack[1] and item and stack[1].id == item.id
end

-- ============================================
-- Stack Management Panel
-- ============================================
local PANEL = {}

function PANEL:Init()
	ix.gui.stackManager = self
	self:SetSize(300, 400)
	self:SetTitle(L("StackManage"))
	self:MakePopup()
	self:Center()

	self.list = self:Add("DScrollPanel")
	self.list:Dock(FILL)
	self.list:DockMargin(4, 4, 4, 4)
end

function PANEL:SetStack(inventory, stackItems, x, y)
	self.inventory = inventory
	self.stackX = x
	self.stackY = y
	self.stackItems = table.Copy(stackItems)

	self:Populate()
end

function PANEL:OnRemove()
	if (ix.gui and ix.gui.stackManager == self) then
		ix.gui.stackManager = nil
	end
end

function PANEL:Populate()
	self.list:Clear()
	self.itemPanels = {}

	for i, item in ipairs(self.stackItems) do
		local entry = self.list:Add("DPanel")
		entry:Dock(TOP)
		entry:SetTall(64)
		entry:DockMargin(0, 0, 0, 2)
		entry.Paint = function(this, w, h)
			local bgColor = (i == 1)
				and Color(50, 100, 150, 200)
				or Color(40, 40, 40, 200)

			surface.SetDrawColor(bgColor)
			surface.DrawRect(0, 0, w, h)

			surface.SetDrawColor(60, 60, 60, 255)
			surface.DrawOutlinedRect(0, 0, w, h)
		end

		entry:SetHelixTooltip(function(tooltip)
			ix.hud.PopulateItemTooltip(tooltip, item)
			tooltip:SizeToContents()
		end)

		local icon = entry:Add("SpawnIcon")
		icon:Dock(LEFT)
		icon:SetSize(64, 64)
		icon:SetModel(item:GetModel(), item:GetSkin())
		icon:SetMouseInputEnabled(false)
		icon.PaintOver = function() end

		local infoPanel = entry:Add("DPanel")
		infoPanel:Dock(FILL)
		infoPanel:DockMargin(8, 4, 0, 4)
		infoPanel.Paint = function() end

		local nameLabel = infoPanel:Add("DLabel")
		nameLabel:Dock(TOP)
		nameLabel:SetText(L(item.name))
		nameLabel:SetFont("ixMenuButtonFont")
		nameLabel:SetTextColor(color_white)
		nameLabel:SetExpensiveShadow(1, Color(0, 0, 0, 200))
		nameLabel:SizeToContents()

		local posLabel = infoPanel:Add("DLabel")
		posLabel:Dock(TOP)
		posLabel:SetText(i == 1 and L("StackRepresentative") or string.format("#%d", i))
		posLabel:SetTextColor(i == 1 and Color(100, 200, 100) or Color(180, 180, 180))
		posLabel:SizeToContents()

		local btnPanel = entry:Add("DPanel")
		btnPanel:Dock(RIGHT)
		btnPanel:SetWide(80)
		btnPanel:DockMargin(0, 4, 4, 4)
		btnPanel.Paint = function() end

		if (#self.stackItems > 1) then
			local splitBtn = btnPanel:Add("DButton")
			splitBtn:Dock(TOP)
			splitBtn:SetTall(24)
			splitBtn:SetText(L("StackSplit"))
			splitBtn.DoClick = function()
				net.Start("ixStackPop")
					net.WriteUInt(self.inventory:GetID(), 32)
					net.WriteUInt(item.id, 32)
				net.SendToServer()

				timer.Simple(0.3, function()
					if (IsValid(self)) then
						self:Close()
					end
				end)
			end

			if (i > 1) then
				local upBtn = btnPanel:Add("DButton")
				upBtn:Dock(TOP)
				upBtn:DockMargin(0, 2, 0, 0)
				upBtn:SetTall(14)
				upBtn:SetText("^")
				upBtn.DoClick = function()
					self:MoveItem(i, i - 1)
				end
			end

			if (i < #self.stackItems) then
				local downBtn = btnPanel:Add("DButton")
				downBtn:Dock(TOP)
				downBtn:DockMargin(0, 2, 0, 0)
				downBtn:SetTall(14)
				downBtn:SetText("v")
				downBtn.DoClick = function()
					self:MoveItem(i, i + 1)
				end
			end
		end

		self.itemPanels[i] = entry
	end

	self:SetTall(math.min(#self.stackItems * 68 + 32, ScrH() * 0.6))
end

function PANEL:MoveItem(fromIndex, toIndex)
	local temp = self.stackItems[fromIndex]
	self.stackItems[fromIndex] = self.stackItems[toIndex]
	self.stackItems[toIndex] = temp

	local newOrder = {}
	for i, item in ipairs(self.stackItems) do
		newOrder[i] = item.id
	end

	net.Start("ixStackReorder")
		net.WriteUInt(self.inventory:GetID(), 32)
		net.WriteUInt(self.stackX, 6)
		net.WriteUInt(self.stackY, 6)
		net.WriteUInt(#newOrder, 8)
		for _, id in ipairs(newOrder) do
			net.WriteUInt(id, 32)
		end
	net.SendToServer()

	self:Populate()
end

vgui.Register("ixStackManager", PANEL, "DFrame")

-- ============================================
-- Stack count overlay via ixItemIcon PaintOver override
-- Uses the PANEL's gridX/gridY (which ARE set by helix), not the itemTable's
-- ============================================
local ixItemIcon = vgui.GetControlTable("ixItemIcon")

if (ixItemIcon) then
	local origPaintOver = ixItemIcon.PaintOver

	ixItemIcon.PaintOver = function(self, width, height)
		if (origPaintOver) then
			origPaintOver(self, width, height)
		end

		-- Draw stack count badge
		local itemTable = self.itemTable
		if (!itemTable or !itemTable.isStackable) then return end

		local invID = self.inventoryID or (itemTable and itemTable.invID)
		if (!invID) then return end

		local inventory = ix.item.inventories[invID]
		if (!inventory) then return end

		-- Use the PANEL's grid position (set by AddIcon), not the item instance's
		local gx = self.gridX
		local gy = self.gridY
		if (!gx or !gy) then return end

		local key = gx .. ":" .. gy
		local stack = GetClientStack(inventory, gx, gy)

		if (stack and #stack > 1) then
			local count = tostring(#stack)

			draw.SimpleTextOutlined(
				count, "DermaDefault", 5, 5,
				color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, color_black
			)
		end
	end
	local origOnDrop = ixItemIcon.OnDrop

	ixItemIcon.OnDrop = function(self, bDragging, inventoryPanel, inventory, gridX, gridY)
		local item = self.itemTable

		if (bDragging and item and item.isStackable) then
			local invID = self.inventoryID or item.invID
			local sourceInventory = invID and ix.item.inventories[invID]
			local stack = sourceInventory and self.gridX and self.gridY and GetClientStack(sourceInventory, self.gridX, self.gridY)
			local isRepresentative = stack and #stack > 1 and stack[1] and stack[1].id == item.id
			local isCtrlDown = input.IsKeyDown(KEY_LCONTROL) or input.IsKeyDown(KEY_RCONTROL)

			if (isCtrlDown and isRepresentative and IsValid(inventoryPanel) and inventoryPanel.combineItem) then
				local combineItem = inventoryPanel.combineItem

				if (combineItem and combineItem.id != item.id and combineItem.isStackable and combineItem.uniqueID == item.uniqueID) then
					net.Start("ixStackMoveSingle")
						net.WriteUInt(invID, 32)
						net.WriteUInt(inventoryPanel.invID, 32)
						net.WriteUInt(item.id, 32)
						net.WriteUInt(combineItem.gridX, 6)
						net.WriteUInt(combineItem.gridY, 6)
					net.SendToServer()

					return
				end
			end

			if (isRepresentative and IsValid(inventoryPanel) and inventoryPanel.combineItem) then
				local combineItem = inventoryPanel.combineItem
				local combineInfo = combineItem and combineItem.functions and combineItem.functions.combine

				if (combineItem and combineItem.id != item.id and combineInfo and !combineItem.isStackable) then
					local data = {item.id}

					if (isCtrlDown) then
						data.ixStackSingle = true
					end

					combineItem.player = LocalPlayer()
						if (combineInfo.sound) then
							surface.PlaySound(combineInfo.sound)
						end

						net.Start("ixInventoryAction")
							net.WriteString("combine")
							net.WriteUInt(combineItem.id, 32)
							net.WriteUInt(combineItem.invID, 32)
							net.WriteTable(data)
						net.SendToServer()
					combineItem.player = nil

					return
				end
			end
		end

		if (origOnDrop) then
			return origOnDrop(self, bDragging, inventoryPanel, inventory, gridX, gridY)
		end
	end

end

-- ============================================
-- Add "Stack Manage" to item right-click menu
-- Uses the icon PANEL's gridX/gridY
-- ============================================
hook.Add("CreateItemInteractionMenu", "ixStackManage", function(icon, menu, itemTable)
	if (!itemTable or !itemTable.isStackable) then return end

	-- Use the panel's grid position
	local gx = icon.gridX
	local gy = icon.gridY
	if (!gx or !gy) then return end

	local invID = icon.inventoryID or (itemTable and itemTable.invID)
	if (!invID) then return end

	local inventory = ix.item.inventories[invID]
	if (!inventory) then return end

	local key = gx .. ":" .. gy
	local stack = GetClientStack(inventory, gx, gy)

	if (stack and #stack > 1) then
		menu:AddOption(L("StackManage"), function()
			local panel = vgui.Create("ixStackManager")
			panel:SetStack(inventory, stack, gx, gy)
		end):SetImage("icon16/layers.png")
	end
end)

local ixInventory = vgui.GetControlTable("ixInventory")

if (ixInventory) then
	local originalOnTransfer = ixInventory.OnTransfer
	local originalSetInventory = ixInventory.SetInventory

	local function ClearInventoryPanel(panel)
		if (!IsValid(panel) or !panel.panels) then
			return
		end

		for itemID, icon in pairs(panel.panels) do
			if (IsValid(icon)) then
				for _, slot in ipairs(icon.slots or {}) do
					if (slot.item == icon) then
						slot.item = nil
					end
				end

				icon:Remove()
			end

			panel.panels[itemID] = nil
		end
	end

	local function RecalculatePanelRepresentatives(panel, inventory)
		if (!IsValid(panel) or !inventory or !panel.panels) then
			return
		end

		for itemID, icon in pairs(panel.panels) do
			if (IsValid(icon)) then
				local gx, gy = icon.gridX, icon.gridY
				local representative = gx and gy and inventory:GetItemAt(gx, gy) or nil

				if (!representative or representative.id != itemID) then
					for _, slot in ipairs(icon.slots or {}) do
						if (slot.item == icon) then
							slot.item = nil
						end
					end

					icon:Remove()
					panel.panels[itemID] = nil
				end
			end
		end
	end

	local function RefreshInventoryPanel(panel, inventory)
		if (!IsValid(panel) or !inventory) then
			return
		end

		ClearInventoryPanel(panel)
		panel.ixStackSkipSyncRequest = true
		originalSetInventory(panel, inventory)
		panel.ixStackSkipSyncRequest = nil
		RecalculatePanelRepresentatives(panel, inventory)
		panel:RebuildItems()
		panel:InvalidateLayout(true)
		panel:InvalidateParent(true)
		panel:InvalidateChildren(true)
		panel:InvalidateChildren(true)
		panel:InvalidateLayout(true)
	end

	function ixInventory:SetInventory(inventory, bFitParent)
		local result = originalSetInventory(self, inventory, bFitParent)

		if (!self.ixStackSkipSyncRequest and inventory and inventory.GetID) then
			net.Start("ixStackRequestSync")
				net.WriteUInt(inventory:GetID(), 32)
			net.SendToServer()
		end

		return result
	end

	net.Receive("ixStackRefreshPanel", function()
		local invID = net.ReadUInt(32)
		local inventory = ix.item.inventories[invID]

		if (!inventory) then
			return
		end

		local localInvID = LocalPlayer():GetCharacter() and LocalPlayer():GetCharacter():GetInventory():GetID() or nil
		local panelID = (localInvID and invID == localInvID) and 1 or invID
		local panel = ix.gui["inv" .. panelID]

		if (IsValid(panel)) then
			RefreshInventoryPanel(panel, inventory)
		end
	end)


	function ixInventory:OnTransfer(oldX, oldY, x, y, oldInventory, noSend)
		local inventories = ix.item.inventories
		local sourceInventory = inventories[oldInventory.invID]
		local targetInventory = inventories[self.invID]
		local item = sourceInventory and sourceInventory:GetItemAt(oldX, oldY)

		if (!noSend and item and item.isStackable and sourceInventory) then
			local stack = item.gridX and item.gridY and GetClientStack(sourceInventory, item.gridX, item.gridY)
			local isRepresentative = stack and #stack > 1 and stack[1] and stack[1].id == item.id
			local isCtrlDown = input.IsKeyDown(KEY_LCONTROL) or input.IsKeyDown(KEY_RCONTROL)

			if (isRepresentative and isCtrlDown) then
				net.Start("ixStackMoveSingle")
					net.WriteUInt(oldInventory.invID, 32)
					net.WriteUInt(self != oldInventory and self.invID or oldInventory.invID, 32)
					net.WriteUInt(item.id, 32)
					net.WriteUInt(x, 6)
					net.WriteUInt(y, 6)
				net.SendToServer()

				return false
			end

			if (isRepresentative and self != oldInventory) then
				net.Start("ixInventoryMove")
					net.WriteUInt(oldX, 6)
					net.WriteUInt(oldY, 6)
					net.WriteUInt(x, 6)
					net.WriteUInt(y, 6)
					net.WriteUInt(oldInventory.invID, 32)
					net.WriteUInt(self.invID, 32)
				net.SendToServer()

				return false
			end
		end

		return originalOnTransfer(self, oldX, oldY, x, y, oldInventory, noSend)
	end
end

