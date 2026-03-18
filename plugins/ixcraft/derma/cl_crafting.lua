
local PLUGIN = PLUGIN

local color_green = Color(50,150,100)
local color_red = Color(150, 50, 50)
local ALL_CATEGORY = "__all"

local PANEL = {}

local function IsEnvironmentBlocked(recipeTable)
	if (recipeTable.station and !recipeTable:HasStationAccess(LocalPlayer())) then
		return true
	end

	if (recipeTable.category == "Food") then
		local cookingStation = recipeTable:GetNearbyCookingStation(LocalPlayer())

		if (!IsValid(cookingStation) or !cookingStation:GetNetVar("active", false)) then
			return true
		end
	end

	return false
end

local function GetRecipeState(recipeTable)
	local canCraft = recipeTable:OnCanCraft(LocalPlayer()) == true
	local environmentBlocked = IsEnvironmentBlocked(recipeTable)

	return {
		canCraft = canCraft,
		environmentBlocked = environmentBlocked
	}
end

function PANEL:Init()
	self:Dock(TOP)
	self:SetTall(64)

	self:SetText("")
end

function PANEL:UpdateCraftState()
	if (!self.recipeTable) then
		return
	end

	local craftState = GetRecipeState(self.recipeTable)

	self.canCraft = craftState.canCraft
	self.environmentBlocked = craftState.environmentBlocked
	self:SetBackgroundColor(self.canCraft and color_green or color_red)
end

function PANEL:SetRecipe(recipeTable, craftState)
	self.recipeTable = recipeTable

	self.icon = self:Add("SpawnIcon")
	self.icon:InvalidateLayout(true)
	self.icon:Dock(LEFT)
	self.icon:DockMargin(0, 0, 8, 0)
	self.icon:SetMouseInputEnabled(false)
	self.icon:SetModel(recipeTable:GetModel(), recipeTable:GetSkin())
	self.icon.PaintOver = function(this) end

	self.name = self:Add("DLabel")
	self.name:Dock(FILL)
	self.name:SetContentAlignment(4)
	self.name:SetTextColor(color_white)
	self.name:SetFont("ixMenuButtonFont")
	self.name:SetExpensiveShadow(1, Color(0, 0, 0, 200))
	self.name:SetText(L(recipeTable.GetName and recipeTable:GetName() or recipeTable.name))

	self.canCraft = craftState and craftState.canCraft
	self.environmentBlocked = craftState and craftState.environmentBlocked

	if (self.canCraft == nil or self.environmentBlocked == nil) then
		self:UpdateCraftState()
	else
		self:SetBackgroundColor(self.canCraft and color_green or color_red)
	end
end

function PANEL:DoClick()
	if (self.recipeTable) then
		net.Start("ixCraftRecipe")
			net.WriteString(self.recipeTable.uniqueID)
			-- Send current station context
			net.WriteString(LocalPlayer().ixCurrentStation or "")
			net.WriteUInt(IsValid(LocalPlayer().ixCurrentStationEnt) and LocalPlayer().ixCurrentStationEnt:EntIndex() or 0, 16)
		net.SendToServer()
	end
end

function PANEL:PaintBackground(width, height)
	self:UpdateCraftState()

	local alpha = self.currentBackgroundAlpha

	if (self.canCraft or self.environmentBlocked) then
		alpha = math.max(alpha, 100)
	end

	derma.SkinFunc("DrawImportantBackground", 0, 0, width, height, ColorAlpha(self.backgroundColor, alpha))
end

vgui.Register("ixCraftingRecipe", PANEL, "ixMenuButton")

PANEL = {}

function PANEL:IsCategoryAllowed(category)
	return !self.allowedCategories or self.allowedCategories[category] == true
end

function PANEL:GetCategoryLabel(category)
	return category == ALL_CATEGORY and L("All") or L(category)
end

function PANEL:GetVisibleRecipes(category, search)
	local recipes = {}
	local searchText = search and search:lower() or nil

	for uniqueID, recipeTable in pairs(PLUGIN.craft.recipes) do
		if (recipeTable:CanList(LocalPlayer()) == false) then
			continue
		end

		if (!self:IsCategoryAllowed(recipeTable.category)) then
			continue
		end

		if (category != ALL_CATEGORY and recipeTable.category != category) then
			continue
		end

		if (searchText and searchText != "" and !L(recipeTable.name):lower():find(searchText, 1, true)) then
			continue
		end

		local craftState = GetRecipeState(recipeTable)

		recipes[#recipes + 1] = {
			uniqueID = uniqueID,
			recipeTable = recipeTable,
			displayName = L(recipeTable.GetName and recipeTable:GetName() or recipeTable.name),
			canCraft = craftState.canCraft,
			environmentBlocked = craftState.environmentBlocked
		}
	end

	table.sort(recipes, function(a, b)
		if (a.canCraft != b.canCraft) then
			return a.canCraft
		end

		if (a.environmentBlocked != b.environmentBlocked) then
			return a.environmentBlocked == false
		end

		return a.displayName:lower() < b.displayName:lower()
	end)

	return recipes
end

function PANEL:BuildCategoryList()
	if (!IsValid(self.categories)) then
		return
	end

	self.categories:Clear()
	self.categoryPanels = {}
	self.selected = nil

	local categoryEntries = {}

	for _, recipeTable in pairs(PLUGIN.craft.recipes) do
		if (recipeTable:CanList(LocalPlayer()) == false) then
			continue
		end

		if (!self:IsCategoryAllowed(recipeTable.category)) then
			continue
		end

		if (!categoryEntries[recipeTable.category]) then
			categoryEntries[recipeTable.category] = true
		end
	end

	local categories = {}

	if (!table.IsEmpty(categoryEntries)) then
		categories[#categories + 1] = ALL_CATEGORY
	end

	for category in pairs(categoryEntries) do
		categories[#categories + 1] = category
	end

	table.sort(categories, function(a, b)
		if (a == ALL_CATEGORY or b == ALL_CATEGORY) then
			return a == ALL_CATEGORY
		end

		return self:GetCategoryLabel(a):lower() < self:GetCategoryLabel(b):lower()
	end)

	for _, category in ipairs(categories) do
		local realName = category
		local button = self.categories:Add("ixMenuButton")
		button:Dock(TOP)
		button:SetText(self:GetCategoryLabel(category))
		button:SizeToContents()
		button.Paint = function(this, w, h)
			surface.SetDrawColor(self.selected == this and ix.config.Get("color") or color_transparent)
			surface.DrawRect(0, 0, w, h)
		end
		button.DoClick = function(this)
			if (self.selected != this) then
				self.selected = this
				self:LoadRecipes(realName)
				timer.Simple(0.01, function()
					if (IsValid(self.scroll)) then
						self.scroll:InvalidateLayout()
					end
				end)
			end
		end
		button.category = realName

		if (!self.selected or realName == self.defaultCategory) then
			self.selected = button
		end

		self.categoryPanels[realName] = button
	end

	if (self.selected) then
		self:LoadRecipes(self.selected.category)
	else
		self.scroll:Clear()
	end
end

function PANEL:Init()
	ix.gui.crafting = self

	self:SetSize(self:GetParent():GetSize())

	self.categories = self:Add("DScrollPanel")
	self.categories:Dock(LEFT)
	self.categories:SetWide(260)
	self.categories.Paint = function(this, w, h)
		surface.SetDrawColor(0, 0, 0, 66)
		surface.DrawRect(0, 0, w, h)
	end
	self.categoryPanels = {}

	self.scroll = self:Add("DScrollPanel")
	self.scroll:Dock(FILL)

	self.search = self:Add("ixIconTextEntry")
	self.search:SetEnterAllowed(false)
	self.search:Dock(TOP)

	local leftMargin = self.search:GetDockMargin()
	self.search:DockMargin(leftMargin, 0, 0, 0)

	self.search.OnChange = function(this)
		local text = self.search:GetText():lower()

		if (self.selected) then
			self:LoadRecipes(self.selected.category, text:find("%S") and text or nil)
			self.scroll:InvalidateLayout()
		end
	end

	-- Station mode header
	if (self.stationID) then
		local stationTable = PLUGIN.craft.stations[self.stationID]
		if (stationTable) then
			local header = self:Add("DLabel")
			header:Dock(TOP)
			header:SetTall(24)
			header:SetText("  " .. L("CraftingAtStation") .. ": " .. L(stationTable.name or self.stationID))
			header:SetFont("ixMenuButtonFont")
			header:SetTextColor(Color(100, 200, 100))
		end
	end

	self:BuildCategoryList()
end

function PANEL:SetStation(stationID)
	self.stationID = stationID
	LocalPlayer().ixCurrentStation = stationID
end

function PANEL:SetCategoryFilter(allowedCategories, defaultCategory)
	self.allowedCategories = allowedCategories
	self.defaultCategory = defaultCategory
	self:BuildCategoryList()
end

function PANEL:RefreshRecipes()
	local category = self.currentCategory
	local search = self.currentSearch

	if (!category and self.selected) then
		category = self.selected.category
	end

	self:LoadRecipes(category, search)
	self.scroll:InvalidateLayout()
end

function PANEL:LoadRecipes(category, search)
	category = category or self.defaultCategory or ALL_CATEGORY
	self.currentCategory = category
	self.currentSearch = search

	self.scroll:Clear()
	self.scroll:InvalidateLayout(true)

	for _, entry in ipairs(self:GetVisibleRecipes(category, search)) do
		local recipeButton = self.scroll:Add("ixCraftingRecipe")
		recipeButton:SetRecipe(entry.recipeTable, entry)
		recipeButton:SetHelixTooltip(function(tooltip)
			PLUGIN:PopulateRecipeTooltip(tooltip, entry.recipeTable)
		end)
	end
end

function PANEL:OnAppear()
	self:RefreshRecipes()
end

function PANEL:OnRemove()
	-- Clear station context when closing crafting panel
	LocalPlayer().ixCurrentStation = nil
end

vgui.Register("ixCrafting", PANEL, "EditablePanel")

-- ============================================
-- Menu button (non-station mode)
-- ============================================
hook.Add("CreateMenuButtons", "ixCrafting", function(tabs)
	if (hook.Run("BuildCraftingMenu") != false) then
		tabs["crafting"] = function(container)
			container:Add("ixCrafting")
		end
	end
end)

-- ============================================
-- Station mode: receive ixStationOpen
-- ============================================
net.Receive("ixStationOpen", function()
	local stationID = net.ReadString()
	local entIndex = net.ReadUInt(16)

	LocalPlayer().ixCurrentStation = stationID
	LocalPlayer().ixCurrentStationEnt = Entity(entIndex)

	-- Open a standalone crafting frame
	if (IsValid(ix.gui.stationCrafting)) then
		ix.gui.stationCrafting:Remove()
	end

	local frame = vgui.Create("DFrame")
	frame:SetSize(ScrW() * 0.78, ScrH() * 0.78)
	frame:Center()
	frame:MakePopup()

	local stationTable = PLUGIN.craft.stations[stationID]
	frame:SetTitle(L("crafting") .. " - " .. L(stationTable and stationTable.name or stationID))

	local craftPanel = frame:Add("ixCrafting")
	craftPanel:SetStation(stationID)
	craftPanel:Dock(FILL)

	frame.OnRemove = function()
		LocalPlayer().ixCurrentStation = nil
		LocalPlayer().ixCurrentStationEnt = nil
	end

	ix.gui.stationCrafting = frame
end)

net.Receive("ixCraftRefresh", function()
	local craftPanel = ix.gui.crafting

	if (IsValid(craftPanel)) then
		craftPanel:RefreshRecipes()
	end

	-- Also refresh station crafting panel
	if (IsValid(ix.gui.stationCrafting)) then
		for _, child in ipairs(ix.gui.stationCrafting:GetChildren()) do
			if (child.RefreshRecipes) then
				child:RefreshRecipes()
				break
			end
		end
	end
end)

hook.Add("PostMenuOpened", "ixCraftingRefresh", function()
	if (IsValid(ix.gui.crafting)) then
		ix.gui.crafting:RefreshRecipes()
	end
end)
