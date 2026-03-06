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
	local panelW = math.min(scrW * 0.8, 900)
	local panelH = math.min(scrH * 0.75, 650)

	self:SetSize(panelW, panelH)
	self:Center()

	self.bNoBackgroundBlur = false

	local equipWidth = panelW * 0.4

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

	-- Right: Inventory
	self.invContainer = self:Add("DPanel")
	self.invContainer:Dock(FILL)
	self.invContainer:DockMargin(2, 4, 4, 4)
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

	self:LoadInventory()
	self:RefreshGearInv()

	self.nextRefresh = 0
end

function PANEL:Think()
	if (CurTime() > self.nextRefresh) then
		self.nextRefresh = CurTime() + 0.5
		self:RefreshGearInv()
	end
end

local BASE_PRIO = {
	["base_weapons"] = 1,
	["base_armor"] = 2,
	["base_houtfit"] = 3
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
	for _, item in ipairs(equippedItems) do
		hash = hash .. item.id .. ","
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
		local icon = self.gearCanvas:Add("ixItemIcon")
		icon:SetSize(item.width * iconSize, item.height * iconSize)
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
			proxy:SetModel(item:GetModel() or "models/props_junk/popcan01a.mdl", item:GetSkin())
			proxy:SetItemTable(item)
			proxy:SetInventoryID(PLUGIN.gearInvID)
			proxy.gridX = 1
			proxy.gridY = 1
			proxy.gridW = item.width
			proxy.gridH = item.height

			if (item.exRender) then
				proxy.Icon:SetVisible(false)
				proxy.ExtraPaint = function(this_proxy, panelX, panelY)
					local bg = item:GetData("bodygroups", item.bodyGroups)
					local renderKey = item.uniqueID .. (istable(bg) and util.CRC(util.TableToJSON(bg)) or "") .. "Gear"

					local exIcon = ikon:GetIcon(renderKey)
					if (exIcon) then
						surface.SetMaterial(exIcon)
						surface.SetDrawColor(color_white)
						surface.DrawTexturedRect(0, 0, panelX, panelY)
					else
						ikon:renderIcon(renderKey, panelX, panelY, item:GetModel(), item.iconCam, nil, bg)
					end
				end
			else
				ix.gui.RenderNewIcon(proxy, item)
			end

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
					elseif (inventoryPanel.invID and gridX and gridY) then
						RequestUnequip(item.id, inventoryPanel.invID, gridX, gridY)
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

		if (item.exRender) then
			icon.Icon:SetVisible(false)
			icon.ExtraPaint = function(this, panelX, panelY)
				local bg = item:GetData("bodygroups", item.bodyGroups)
				local renderKey = item.uniqueID .. (istable(bg) and util.CRC(util.TableToJSON(bg)) or "") .. "Gear"

				local exIcon = ikon:GetIcon(renderKey)
				if (exIcon) then
					surface.SetMaterial(exIcon)
					surface.SetDrawColor(color_white)
					surface.DrawTexturedRect(0, 0, panelX, panelY)
				else
					ikon:renderIcon(renderKey, panelX, panelY, item:GetModel(), item.iconCam, nil, bg)
				end
			end
		else
			ix.gui.RenderNewIcon(icon, item)
		end

		icon:SetHelixTooltip(function(tooltip)
			ix.hud.PopulateItemTooltip(tooltip, item)
		end)

		icon.DoRightClick = function()
			local menu = DermaMenu()
			menu:AddOption(L("Unequip"), function()
				RequestUnequip(item.id)
			end):SetIcon("icon16/cross.png")

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
				local cursorX, cursorY = invPanel:CursorPos()
				local iconS = invPanel.iconSize or 64
				
				local dropX = math.ceil((cursorX - 4 - (this.gridW - 1) * (iconS / 2)) / iconS)
				local dropY = math.ceil((cursorY - invPanel:GetPadding(2) - (this.gridH - 1) * (iconS / 2)) / iconS)
				
				dropX = math.max(1, dropX)
				dropY = math.max(1, dropY)
				
				RequestUnequip(item.id, inv:GetID(), dropX, dropY)
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