
function Schema:CanPlayerUseBusiness(client, uniqueID)
	if (client:IsAdmin()) then
		return true
	else
		return false
	end
end

-- called when the client wants to view the combine data for the given target
function Schema:CanPlayerViewData(client, target)
	return client:IsCombine() and (!target:IsCombine() and target:Team() != FACTION_ADMIN)
end

-- called when the client wants to edit the combine data for the given target
function Schema:CanPlayerEditData(client, target)
	return client:IsCombine() and (!target:IsCombine() and target:Team() != FACTION_ADMIN)
end

function Schema:CanPlayerViewObjectives(client)
	return client:IsCombine()
end

function Schema:CanPlayerEditObjectives(client)
	if (!client:IsCombine() or !client:GetCharacter()) then
		return false
	end

	local bCanEdit = false
	local name = client:GetCharacter():GetName()

	for k, v in ipairs({"OfC", "EpU", "DvL", "SeC"}) do
		if (self:IsCombineRank(name, v)) then
			bCanEdit = true
			break
		end
	end

	return bCanEdit
end

function Schema:CanDrive(client)
	return client:IsAdmin()
end

if (SERVER) then
	local ADMIN_SET_VALUE_MAX = 2000

	util.AddNetworkString("ixAdminSetHealth")
	util.AddNetworkString("ixAdminSetArmor")

	net.Receive("ixAdminSetHealth", function(_, client)
		if (!IsValid(client) or !client:IsAdmin()) then
			return
		end

		local target = net.ReadEntity()
		local value = net.ReadUInt(31)

		if (!IsValid(target) or !target:IsPlayer()) then
			return
		end

		value = math.floor(tonumber(value) or 0)

		if (value < 1) then
			return
		end

		value = math.min(value, ADMIN_SET_VALUE_MAX)
		target:SetHealth(value)
		client:EmitSound("buttons/button14.wav", 65, 100, 1)
	end)

	net.Receive("ixAdminSetArmor", function(_, client)
		if (!IsValid(client) or !client:IsAdmin()) then
			return
		end

		local target = net.ReadEntity()
		local value = net.ReadUInt(31)

		if (!IsValid(target) or !target:IsPlayer()) then
			return
		end

		value = math.floor(tonumber(value) or 0)

		if (value < 1) then
			return
		end

		value = math.min(value, ADMIN_SET_VALUE_MAX)
		target:SetArmor(value)
		client:EmitSound("buttons/button14.wav", 65, 100, 1)
	end)
end

if (CLIENT) then
	local MAX_POSITIVE_INT = 2000

	local function OpenValueSlider(title, initialValue, callback)
		local frame = vgui.Create("DFrame")
		frame:SetTitle(title)
		frame:SetSize(420, 170)
		frame:Center()
		frame:MakePopup()

		local slider = frame:Add("DNumSlider")
		slider:Dock(TOP)
		slider:DockMargin(10, 10, 10, 0)
		slider:SetText("Value")
		slider:SetMin(1)
		slider:SetMax(MAX_POSITIVE_INT)
		slider:SetDecimals(0)
		slider:SetValue(math.Clamp(math.floor(tonumber(initialValue) or 1), 1, MAX_POSITIVE_INT))

		local entry = frame:Add("DTextEntry")
		entry:Dock(TOP)
		entry:DockMargin(10, 8, 10, 0)
		entry:SetNumeric(true)
		entry:SetValue(tostring(math.Clamp(math.floor(tonumber(initialValue) or 1), 1, MAX_POSITIVE_INT)))

		function entry:OnEnter()
			local value = math.floor(tonumber(self:GetValue()) or 0)

			if (value >= 1) then
				slider:SetValue(math.Clamp(value, 1, MAX_POSITIVE_INT))
			end
		end

		local buttonPanel = frame:Add("DPanel")
		buttonPanel:Dock(BOTTOM)
		buttonPanel:SetTall(40)
		buttonPanel.Paint = nil

		local confirm = buttonPanel:Add("DButton")
		confirm:Dock(LEFT)
		confirm:DockMargin(10, 6, 6, 6)
		confirm:SetWide(90)
		confirm:SetText("Apply")
		confirm.DoClick = function()
			local value = math.floor(tonumber(entry:GetValue()) or slider:GetValue() or 0)

			if (value < 1) then
				LocalPlayer():Notify("Please enter a positive integer (>= 1).")
				return
			end

			callback(math.Clamp(value, 1, MAX_POSITIVE_INT))
			frame:Close()
		end

		local cancel = buttonPanel:Add("DButton")
		cancel:Dock(RIGHT)
		cancel:DockMargin(6, 6, 10, 6)
		cancel:SetWide(90)
		cancel:SetText(L("cancel"))
		cancel.DoClick = function()
			frame:Close()
		end

		slider.OnValueChanged = function(_, value)
			value = math.Clamp(math.floor(value or 1), 1, MAX_POSITIVE_INT)
			entry:SetValue(tostring(value))
		end
	end

	function Schema:PopulateScoreboardPlayerMenu(target, menu)
		local client = LocalPlayer()
		local character = IsValid(target) and target:GetCharacter()

		if (!IsValid(client) or !character) then
			return
		end

		if (client:IsAdmin()) then
			local healthMenu = menu:AddSubMenu("Set Health")
			healthMenu:AddOption("Set Value...", function()
				OpenValueSlider("Set Health", target:Health(), function(value)
					net.Start("ixAdminSetHealth")
						net.WriteEntity(target)
						net.WriteUInt(value, 31)
					net.SendToServer()
				end)
			end)
			healthMenu:AddOption("Heal to Max Health", function()
				local maxHealth = math.max(1, math.floor(target:GetMaxHealth() or 1))

				net.Start("ixAdminSetHealth")
					net.WriteEntity(target)
					net.WriteUInt(math.Clamp(maxHealth, 1, MAX_POSITIVE_INT), 31)
				net.SendToServer()
			end)

			local armorMenu = menu:AddSubMenu("Set Armor")
			armorMenu:AddOption("Set Value...", function()
				OpenValueSlider("Set Armor", target:Armor(), function(value)
					net.Start("ixAdminSetArmor")
						net.WriteEntity(target)
						net.WriteUInt(value, 31)
					net.SendToServer()
				end)
			end)
		end

		if (ix.command.HasAccess(client, "CharEditBodygroup") and #target:GetBodyGroups() > 1) then
			menu:AddOption("Edit Bodygroups", function()
				local panel = vgui.Create("ixBodygroupView")
				panel:Display(target)
			end)
		end

		if (ix.command.HasAccess(client, "CharSetName")) then
			menu:AddOption(L("cmdCharSetNameTitle"), function()
				Derma_StringRequest(L("cmdCharSetNameTitle"), L("cmdCharSetName"), character:GetName(), function(text)
					ix.command.Send("CharSetName", character:GetName(), text)
				end)
			end)
		end

		if (ix.command.HasAccess(client, "CharSetDesc")) then
			menu:AddOption(L("cmdCharDescTitle"), function()
				Derma_StringRequest(L("cmdCharDescTitle"), L("cmdCharDescDescription"), character:GetDescription(), function(text)
					ix.command.Send("CharSetDesc", character:GetName(), text)
				end)
			end)
		end
	end
end
