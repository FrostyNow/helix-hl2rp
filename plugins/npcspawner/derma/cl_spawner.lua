local PANEL = {}

function PANEL:Init()
	self:SetSize(400, 500)
	self:Center()
	self:MakePopup()
	self:SetTitle(L("spawnerTitle"))
	
	self.scroll = self:Add("DScrollPanel")
	self.scroll:Dock(FILL)
	self.scroll:DockMargin(5, 5, 5, 5)

	self.maxSpawned = self:AddRow(L("spawnerMaxSpawned"))
	self.maxNearby = self:AddRow(L("spawnerMaxNearby"))
	self.minDistance = self:AddRow(L("spawnerMinDistance"))
	self.spawnDelay = self:AddRow(L("spawnerSpawnDelay"))
	self.activeRadius = self:AddRow(L("spawnerActiveRadius"))
	self.useArea = self:AddCheckRow(L("spawnerUseArea"))
	self.visitCooldown = self:AddRow(L("spawnerVisitCooldown"))

	local classLabel = self.scroll:Add("DLabel")
	classLabel:Dock(TOP)
	classLabel:SetText(L("spawnerClassLabel"))
	classLabel:SetTextColor(color_white)

	self.classList = self.scroll:Add("DListView")
	self.classList:Dock(TOP)
	self.classList:SetTall(150)
	local col1 = self.classList:AddColumn(L("spawnerColumnClass"))
	local col2 = self.classList:AddColumn(L("spawnerColumnWeight"))
	col1.Header:SetTextColor(color_black)
	col2.Header:SetTextColor(color_black)
	self.classList:SetMultiSelect(false)
	self.classList.DoDoubleClick = function(pnl, lineID, line)
		local curClass = line:GetValue(1)
		local curWeight = line:GetValue(2)
		Derma_StringRequest(L("spawnerClassPromptTitle"), L("spawnerClassPromptDesc"), curClass, function(class)
			if class and class != "" then
				Derma_StringRequest(L("spawnerWeightPromptTitle"), L("spawnerWeightPromptDesc"), tostring(curWeight), function(weight)
					line:SetValue(1, class)
					line:SetValue(2, tonumber(weight) or 10)
				end)
			end
		end)
	end
	
	local addClassBtn = self.scroll:Add("DButton")
	addClassBtn:Dock(TOP)
	addClassBtn:SetText(L("spawnerClassAdd"))
	addClassBtn.DoClick = function()
		Derma_StringRequest(L("spawnerClassPromptTitle"), L("spawnerClassPromptDesc"), "", function(class)
			if class and class != "" then
				Derma_StringRequest(L("spawnerWeightPromptTitle"), L("spawnerWeightPromptDesc"), "10", function(weight)
					self.classList:AddLine(class, tonumber(weight) or 10)
				end)
			end
		end)
	end
	
	local removeClassBtn = self.scroll:Add("DButton")
	removeClassBtn:Dock(TOP)
	removeClassBtn:SetText(L("spawnerClassRemove"))
	removeClassBtn.DoClick = function()
		local selected = self.classList:GetSelected()[1]
		if (IsValid(selected)) then
			self.classList:RemoveLine(selected:GetID())
		end
	end

	local saveBtn = self:Add("DButton")
	saveBtn:Dock(BOTTOM)
	saveBtn:SetText(L("spawnerSave"))
	saveBtn.DoClick = function()
		self:Save()
	end
end

function PANEL:AddRow(text)
	local pnl = self.scroll:Add("Panel")
	pnl:Dock(TOP)
	pnl:SetTall(30)

	local label = pnl:Add("DLabel")
	label:Dock(LEFT)
	label:SetWide(180)
	label:SetText(text)
	label:SetTextColor(color_white)

	local entry = pnl:Add("DTextEntry")
	entry:Dock(FILL)
	entry:SetNumeric(true)

	return entry
end

function PANEL:AddCheckRow(text)
	local pnl = self.scroll:Add("Panel")
	pnl:Dock(TOP)
	pnl:SetTall(30)

	local label = pnl:Add("DLabel")
	label:Dock(LEFT)
	label:SetWide(180)
	label:SetText(text)
	label:SetTextColor(color_white)

	local cb = pnl:Add("DCheckBox")
	cb:Dock(LEFT)

	return cb
end

function PANEL:SetSpawner(id, data)
	self.spawnerId = id
	
	self.maxSpawned:SetValue(data.maxSpawned or 5)
	self.maxNearby:SetValue(data.maxNearby or 10)
	self.minDistance:SetValue(data.minDistance or 1000)
	self.spawnDelay:SetValue(data.spawnDelay or 60)
	self.activeRadius:SetValue(data.activeRadius or 4500)
	self.useArea:SetValue(data.useArea or false)
	self.visitCooldown:SetValue(data.visitCooldown or 0)
	
	for class, weight in pairs(data.classes or {}) do
		self.classList:AddLine(class, weight)
	end
end

function PANEL:Save()
	local data = {}
	data.maxSpawned = tonumber(self.maxSpawned:GetValue()) or 5
	data.maxNearby = tonumber(self.maxNearby:GetValue()) or 10
	data.minDistance = tonumber(self.minDistance:GetValue()) or 1000
	data.spawnDelay = tonumber(self.spawnDelay:GetValue()) or 60
	data.activeRadius = tonumber(self.activeRadius:GetValue()) or 4500
	data.useArea = self.useArea:GetChecked()
	data.visitCooldown = tonumber(self.visitCooldown:GetValue()) or 0
	
	data.classes = {}
	for _, line in pairs(self.classList:GetLines()) do
		local class = line:GetValue(1)
		local weight = line:GetValue(2)
		data.classes[class] = tonumber(weight) or 10
	end
	
	net.Start("ixNpcSpawnerEdit")
	net.WriteString(self.spawnerId)
	net.WriteTable(data)
	net.SendToServer()
	
	self:Remove()
end

vgui.Register("ixNpcSpawnerEdit", PANEL, "DFrame")
