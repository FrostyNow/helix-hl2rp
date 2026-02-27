local PLUGIN = PLUGIN

function PLUGIN:OpenActMenu()
	if (IsValid(ix.gui.actMenu)) then
		ix.gui.actMenu:Remove()
	end

	local client = LocalPlayer()
	local modelClass = ix.anim.GetModelClass(client:GetModel())
	local availableActs = {}

	-- Get all acts available for the current model class
	for name, classes in pairs(ix.act.stored) do
		if (classes[modelClass]) then
			local data = classes[modelClass]
			local variants = #data.sequence
			
			table.insert(availableActs, {
				name = name,
				variants = variants,
				data = data
			})
		end
	end

	if (#availableActs == 0) then
		client:NotifyLocalized("modelNoSeq")
		return
	end

	table.SortByMember(availableActs, "name", true)

	local width, height = 640, 520
	ix.gui.actMenu = vgui.Create("EditablePanel")
	ix.gui.actMenu:SetSize(width, height)
	ix.gui.actMenu:Center()
	ix.gui.actMenu:MakePopup()
	ix.gui.actMenu.Paint = function(self, w, h)
		Derma_DrawBackgroundBlur(self, self.m_fCreateTime)
		
		surface.SetDrawColor(0, 0, 0, 220)
		surface.DrawRect(0, 0, w, h)
		
		surface.SetDrawColor(ix.config.Get("color", color_white))
		surface.DrawOutlinedRect(0, 0, w, h)
		
		surface.SetDrawColor(ix.config.Get("color", color_white))
		surface.DrawRect(0, 0, w, 32)
		
		draw.SimpleText(L("actMenuDesc"):upper(), "ixMenuButtonFontSmall", 8, 16, color_black, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end

	-- Search Bar
	local search = ix.gui.actMenu:Add("ixIconTextEntry")
	search:SetPos(8, 40)
	search:SetSize(width - 16, 32)
	search:SetFont("ixMenuButtonFontSmall")
	if (search.SetPlaceholderText) then
		search:SetPlaceholderText(L("search").."...")
	end

	local scroll = ix.gui.actMenu:Add("DScrollPanel")
	scroll:SetPos(8, 80)
	scroll:SetSize(width - 16, height - 88)

	local layout = scroll:Add("DIconLayout")
	layout:Dock(TOP)
	layout:SetSpaceX(4)
	layout:SetSpaceY(4)

	local function RebuildActs(filter)
		layout:Clear()
		filter = (filter or ""):lower()

		local currentAngle = client:GetNetVar("actEnterAngle")
		if (currentAngle) then
			local btn = layout:Add("DButton")
			btn:SetSize(width - 32, 40)
			btn:SetText(L("actExit"):upper())
			btn:SetFont("ixMenuButtonFontSmall")
			btn:SetTextColor(Color(255, 100, 100))
			btn.Paint = function(self, w, h)
				local alpha = 100
				if (self:IsHovered()) then
					alpha = 180
				end
				surface.SetDrawColor(80, 20, 20, alpha)
				surface.DrawRect(0, 0, w, h)
				surface.SetDrawColor(255, 100, 100)
				surface.DrawOutlinedRect(0, 0, w, h)
			end
			btn.DoClick = function()
				ix.command.Send("ExitAct")
				ix.gui.actMenu:Remove()
			end
		end

		for _, actInfo in ipairs(availableActs) do
			if (filter != "" and !actInfo.name:lower():find(filter, 1, true)) then
				continue
			end

			local variants = actInfo.variants
			for i = 1, variants do
				local label = actInfo.name
				if (variants > 1) then
					label = label .. " (" .. i .. ")"
				end

				local btn = layout:Add("DButton")
				btn:SetSize((width - 32) / 3 - 4, 40)
				btn:SetText(label:upper())
				btn:SetFont("ixMenuButtonFontSmall")
				btn:SetTextColor(color_white)
				btn.Paint = function(self, w, h)
					local alpha = 100
					if (self:IsHovered()) then
						alpha = 200
						surface.SetDrawColor(ix.config.Get("color", color_white))
					else
						surface.SetDrawColor(40, 40, 40, alpha)
					end
					
					surface.DrawRect(0, 0, w, h)
					
					if (self:IsHovered()) then
						self:SetTextColor(color_black)
					else
						self:SetTextColor(color_white)
						surface.SetDrawColor(ix.config.Get("color", color_white))
						surface.DrawOutlinedRect(0, 0, w, h)
					end
				end

				btn.DoClick = function()
					ix.command.Send("act" .. actInfo.name:lower(), i)
					ix.gui.actMenu:Remove()
				end
			end
		end
	end

	search.OnValueChange = function(this, value)
		RebuildActs(value)
	end

	RebuildActs("")

	-- Close button
	local close = ix.gui.actMenu:Add("DButton")
	close:SetSize(32, 32)
	close:SetPos(width - 32, 0)
	close:SetText("✕")
	close:SetFont("ixMenuButtonFontSmall")
	close:SetTextColor(color_black)
	close.Paint = nil
	close.DoClick = function()
		ix.gui.actMenu:Remove()
	end
	
	ix.gui.actMenu:SetAlpha(0)
	ix.gui.actMenu:AlphaTo(255, 0.2)
end

concommand.Add("ix_actmenu", function()
	PLUGIN:OpenActMenu()
end)

concommand.Add("+actmenu", function()
	PLUGIN:OpenActMenu()
end)

concommand.Add("-actmenu", function()
	if (IsValid(ix.gui.actMenu)) then
		ix.gui.actMenu:Remove()
	end
end)
