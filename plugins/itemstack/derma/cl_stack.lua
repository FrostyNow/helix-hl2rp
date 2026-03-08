
local PLUGIN = PLUGIN

-- ============================================
-- Stack Management Panel
-- ============================================
local PANEL = {}

function PANEL:Init()
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
	self.stackItems = stackItems

	self:Populate()
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
				upBtn:SetText("▲")
				upBtn.DoClick = function()
					self:MoveItem(i, i - 1)
				end
			end

			if (i < #self.stackItems) then
				local downBtn = btnPanel:Add("DButton")
				downBtn:Dock(TOP)
				downBtn:DockMargin(0, 2, 0, 0)
				downBtn:SetTall(14)
				downBtn:SetText("▼")
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
		if (!inventory or !inventory.stacks) then return end

		-- Use the PANEL's grid position (set by AddIcon), not the item instance's
		local gx = self.gridX
		local gy = self.gridY
		if (!gx or !gy) then return end

		local key = gx .. ":" .. gy
		local stack = inventory.stacks[key]

		if (stack and #stack > 1) then
			local count = tostring(#stack)

			surface.SetFont("ixMenuButtonFont")
			local tw, th = surface.GetTextSize(count)

			local badgeX = width - tw - 6
			local badgeY = height - th - 2

			surface.SetDrawColor(0, 0, 0, 180)
			surface.DrawRect(badgeX - 2, badgeY, tw + 4, th)

			surface.SetTextColor(255, 255, 255, 255)
			surface.SetTextPos(badgeX, badgeY)
			surface.DrawText(count)
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
	if (!inventory or !inventory.stacks) then return end

	local key = gx .. ":" .. gy
	local stack = inventory.stacks[key]

	if (stack and #stack > 1) then
		menu:AddOption(L("StackManage"), function()
			local panel = vgui.Create("ixStackManager")
			panel:SetStack(inventory, stack, gx, gy)
		end):SetImage("icon16/layers.png")
	end
end)
