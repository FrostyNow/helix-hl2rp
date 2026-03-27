AddCSLuaFile()

ENT.Type = "anim"
ENT.PrintName = "Combine Dispenser"
ENT.Category = "HL2 RP"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.PhysgunDisable = true
ENT.bNoPersist = true

ix.lang.AddTable("english", {
	businessDispenserDesc = "This device allows to get various items.",
	businessAreaUpdated = "Business Area settings updated.",	
})
ix.lang.AddTable("korean", {
	["Combine Dispenser"] = "콤바인 보급 장치",
	businessDispenserDesc = "여러가지 물품을 지급받을 수 있는 장치입니다.",
	businessAreaUpdated = "사업 구역 설정이 업데이트되었습니다.",
})

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "Factions")
	self:NetworkVar("String", 1, "Classes")
	self:NetworkVar("String", 2, "DisplayName")
end

if (SERVER) then
	util.AddNetworkString("ixBusinessAreaConfig")
	util.AddNetworkString("ixBusinessAreaUpdate")

	function ENT:SpawnFunction(client, trace)
		local entity = ents.Create("ix_businessarea")
		entity:SetPos(trace.HitPos)
		entity:SetAngles(trace.HitNormal:Angle())
		entity:Spawn()
		entity:Activate()

		Schema:SaveBusinessAreas()
		return entity
	end

	function ENT:Initialize()
		self:SetModel("models/props_junk/watermelon01.mdl")
		self:SetSolid(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:DrawShadow(false)
		self:SetUseType(SIMPLE_USE)
		self:SetFactions("[]")
		self:SetClasses("[]")
		self:SetDisplayName(self.PrintName)

		self.dispenser = ents.Create("prop_dynamic")
		self.dispenser:SetModel("models/props_combine/combine_dispenser.mdl")
		self.dispenser:SetPos(self:GetPos())
		self.dispenser:SetAngles(self:GetAngles())
		self.dispenser:SetParent(self)
		self.dispenser:Spawn()
		self.dispenser:Activate()
		self:DeleteOnRemove(self.dispenser)

		local physics = self:GetPhysicsObject()
		if (IsValid(physics)) then
			physics:EnableMotion(false)
			physics:Sleep()
		end
	end

	function ENT:Use(client)
		if (client:IsAdmin()) then
			net.Start("ixBusinessAreaConfig")
				net.WriteEntity(self)
				net.WriteString(self:GetFactions())
				net.WriteString(self:GetClasses())
			net.Send(client)
		end
	end

	net.Receive("ixBusinessAreaUpdate", function(len, client)
		if (!client:IsAdmin()) then return end

		local entity = net.ReadEntity()
		if (IsValid(entity) and entity:GetClass() == "ix_businessarea") then
			entity:SetFactions(net.ReadString())
			entity:SetClasses(net.ReadString())
			
			client:NotifyLocalized("businessAreaUpdated")
			Schema:SaveBusinessAreas()
		end
	end)

	function ENT:OnRemove()
		if (!ix.shuttingDown) then
			Schema:SaveBusinessAreas()
		end
	end
else
	function ENT:PopulateEntityInfo(tooltip)
		local title = tooltip:AddRow("name")
		title:SetImportant()
		title:SetText(self:GetDisplayName())
		title:SizeToContents()

		local description = tooltip:AddRow("description")
		description:SetText(L("businessDispenserDesc"))
		description:SizeToContents()

		local allowedNames = {}
		local factions = util.JSONToTable(self:GetFactions() or "[]")
		local classes = util.JSONToTable(self:GetClasses() or "[]")

		for _, v in ipairs(factions) do
			local faction = ix.faction.indices[v]
			if (faction) then
				allowedNames[#allowedNames + 1] = L(faction.name)
			end
		end

		for _, v in ipairs(classes) do
			local class = ix.class.indices[v]
			if (class) then
				allowedNames[#allowedNames + 1] = L(class.name)
			end
		end

		if (#allowedNames > 0) then
			local hint = tooltip:AddRow("hint")
			hint:SetText(table.concat(allowedNames, ", "))
			hint:SetBackgroundColor(ix.config.Get("color"))	
			hint:SizeToContents()
		end
	end

	function ENT:Draw()
		local position, angles = self:GetPos(), self:GetAngles()

		angles:RotateAroundAxis(angles:Forward(), 90)
		angles:RotateAroundAxis(angles:Right(), 270)

		cam.Start3D2D(position + self:GetForward() * 7.6 + self:GetRight() * 8.5 + self:GetUp() * 3, angles, 0.1)
			surface.SetDrawColor(color_black)
			surface.DrawRect(10, 16, 153, 40)

			surface.SetDrawColor(60, 60, 60)
			surface.DrawOutlinedRect(9, 16, 155, 40)

			draw.SimpleText("BUSINESS", "ixRationDispenser", 86, 36, Color(0, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		cam.End3D2D()
	end

	net.Receive("ixBusinessAreaConfig", function()
		local entity = net.ReadEntity()
		local factionsRaw = net.ReadString()
		local classesRaw = net.ReadString()

		local factions = util.JSONToTable(factionsRaw)
		local classes = util.JSONToTable(classesRaw)

		local frame = vgui.Create("DFrame")
		frame:SetSize(400, 500)
		frame:Center()
		frame:MakePopup()
		frame:SetTitle("Business Area Config")

		local scroll = vgui.Create("DScrollPanel", frame)
		scroll:Dock(FILL)
		scroll:DockMargin(10, 10, 10, 10)

		local function AddSection(name)
			local label = vgui.Create("DLabel", scroll)
			label:SetText(name)
			label:SetFont("ixMediumFont")
			label:Dock(TOP)
			label:DockMargin(0, 10, 0, 5)
			label:SetTextColor(color_white)
		end

		AddSection("Allowed Factions")
		local factionChecks = {}
		for k, v in pairs(ix.faction.indices) do
			local check = vgui.Create("DCheckBoxLabel", scroll)
			check:SetText(v.name)
			check:SetValue(table.HasValue(factions, k))
			check:Dock(TOP)
			check:DockMargin(5, 2, 5, 2)
			factionChecks[k] = check
		end

		AddSection("Allowed Classes")
		local classChecks = {}
		for k, v in pairs(ix.class.indices) do
			local check = vgui.Create("DCheckBoxLabel", scroll)
			check:SetText(v.name)
			check:SetValue(table.HasValue(classes, k))
			check:Dock(TOP)
			check:DockMargin(5, 2, 5, 2)
			classChecks[k] = check
		end

		local save = vgui.Create("DButton", frame)
		save:SetText("Save Settings")
		save:Dock(BOTTOM)
		save:DockMargin(10, 0, 10, 10)
		save:SetTall(30)
		save.DoClick = function()
			local newFactions = {}
			for k, v in pairs(factionChecks) do
				if (v:GetChecked()) then
					table.insert(newFactions, k)
				end
			end

			local newClasses = {}
			for k, v in pairs(classChecks) do
				if (v:GetChecked()) then
					table.insert(newClasses, k)
				end
			end

			net.Start("ixBusinessAreaUpdate")
				net.WriteEntity(entity)
				net.WriteString(util.TableToJSON(newFactions))
				net.WriteString(util.TableToJSON(newClasses))
			net.SendToServer()

			frame:Remove()
		end
	end)
end

properties.Add("businessarea_setname", {
	MenuLabel = "Set Name",
	Order = 400,
	MenuIcon = "icon16/tag_blue_edit.png",

	Filter = function(self, entity, client)
		if (entity:GetClass() != "ix_businessarea") then return false end
		if (!client:IsAdmin()) then return false end

		return true
	end,

	Action = function(self, entity)
		Derma_StringRequest("Set Name", "Enter the new name for the device.", entity:GetDisplayName(), function(text)
			self:MsgStart()
				net.WriteEntity(entity)
				net.WriteString(text)
			self:MsgEnd()
		end)
	end,

	Receive = function(self, length, client)
		local entity = net.ReadEntity()

		if (!IsValid(entity) or !client:IsAdmin()) then return end
		if (!self:Filter(entity, client)) then return end

		local name = net.ReadString()

		if (name:len() != 0) then
			entity:SetDisplayName(name)
		else
			entity:SetDisplayName(self.PrintName)
		end
		
		Schema:SaveBusinessAreas()
	end
})
