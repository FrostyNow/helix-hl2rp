
local PLUGIN = PLUGIN or {}

PLUGIN.name = "Context Menu Options"
PLUGIN.author = "Gary Tate"
PLUGIN.description = "Adds several context options on players."
PLUGIN.license = [[
The MIT License (MIT)
Copyright (c) 2020 Gary Tate
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

CAMI.RegisterPrivilege({
	Name = "Helix - Admin Context Options",
	MinAccess = "admin"
})

local MAX_POSITIVE_INT = 2000
local PromptPositiveInteger

if (CLIENT) then
	local function ReverseConcat(tableData)
		local text = ""

		for key, _ in pairs(tableData) do
			text = text .. key
		end

		return text
	end

	local function ChangeFlag(characterID, flags)
		net.Start("SCOREFLAGS:CHANGEFLAG")
			net.WriteString(tostring(characterID))
			net.WriteString(ReverseConcat(flags))
		net.SendToServer()
	end

	local function OpenFlagEditor(targetPlayer)
		local targetCharacter = IsValid(targetPlayer) and targetPlayer:GetCharacter()

		if (!targetCharacter) then
			LocalPlayer():Notify(L("charNoExist"))
			return
		end

		local stagedFlags = {}
		local performanceMode = ix.config.Get("scoreboardflagsPerformance")

		local frame = vgui.Create("DFrame")
		frame:SetSize(math.floor(math.min(ScrW() * 0.8, 1000)), math.floor(math.min(ScrH() * 0.8, 700)))
		frame:SetTitle(L("editFlags"))
		frame:Center()
		frame:MakePopup()

		local flagList = vgui.Create("ixSettings", frame)
		flagList:Dock(FILL)

		for key, flagData in pairs(ix.flag.list) do
			if (ispanel(flagData)) then
				continue
			end

			local row = flagList:AddRow(ix.type.bool)
			if (targetCharacter:HasFlags(key)) then
				row.setting:SetChecked(true)
			end

			row:SetText("[" .. key .. "] " .. flagData.description)
			row.setting:SizeToContents()
			row:SizeToContents()

			row.OnValueChanged = function(panel, bEnabled)
				if (performanceMode) then
					if (stagedFlags[key]) then
						stagedFlags[key] = nil
					else
						stagedFlags[key] = true
					end
				else
					ChangeFlag(targetCharacter:GetID(), {[key] = true})
				end
			end
		end

		if (performanceMode) then
			local saveButton = vgui.Create("ixMenuButton", frame)
			saveButton:SetSize(frame:GetWide(), 35)
			saveButton:SetPos(0, frame:GetTall() - 35.5)
			saveButton:SetText(L("save"))

			function saveButton:DoClick()
				if (table.IsEmpty(stagedFlags)) then
					LocalPlayer():Notify(L("noFlagsEdited"))
					return
				end

				ChangeFlag(targetCharacter:GetID(), stagedFlags)
				stagedFlags = {}
			end

			flagList:Dock(NODOCK)
			flagList:SetSize(frame:GetWide(), frame:GetTall() - (saveButton:GetTall() * 2))
			flagList:SetPos(0, saveButton:GetTall())
		end

		flagList:SizeToContents()
		frame:SizeToContents()
	end

	function PromptPositiveInteger(title, initialValue, callback)
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
end

properties.Add("ixViewPlayerProperty", {
	MenuLabel = "#View Player",
	Order = 1,
	MenuIcon = "icon16/user.png",
	Format = "%s | %s\nHealth: %s\nArmor: %s",

	Filter = function(self, entity, client)
		return CAMI.PlayerHasAccess(client, "Helix - Admin Context Options", nil) and entity:IsPlayer()
	end,

	Action = function(self, entity)
		self:MsgStart()
			net.WriteEntity(entity)
		self:MsgEnd()
	end,

	Receive = function(self, length, client)
		if (CAMI.PlayerHasAccess(client, "Helix - Admin Context Options", nil)) then
			local entity = net.ReadEntity()
			client:NotifyLocalized(string.format(self.Format, entity:Nick(), entity:SteamID(), entity:Health(), entity:Armor()))
		end
	end
})

properties.Add("ixSetHealthProperty", {
	MenuLabel = "#Health",
	Order = 2,
	MenuIcon = "icon16/heart.png",

	Filter = function(self, entity, client)
		return CAMI.PlayerHasAccess(client, "Helix - Admin Context Options", nil) and entity:IsPlayer()
	end,

	MenuOpen = function( self, option, ent, tr )
		local submenu = option:AddSubMenu()
		local target = IsValid(ent.AttachedEntity) and ent.AttachedEntity or ent

		submenu:AddOption("Set Value...", function()
			PromptPositiveInteger("Set Health", target:Health(), function(value)
				self:SetHealth(ent, value)
			end)
		end)

		submenu:AddOption("Heal to Max Health", function()
			self:SetHealth(ent, math.max(1, math.floor(target:GetMaxHealth() or 1)))
		end)

	end,

	Action = function(self, entity)
		-- not used
	end,

	SetHealth = function(self, target, health)
		self:MsgStart()
			net.WriteEntity(target)
			net.WriteUInt(math.Clamp(math.floor(tonumber(health) or 1), 1, MAX_POSITIVE_INT), 31)
		self:MsgEnd()
	end,

	Receive = function(self, length, client)
		if (CAMI.PlayerHasAccess(client, "Helix - Admin Context Options", nil)) then
			local entity = net.ReadEntity()
			local health = math.floor(net.ReadUInt(31) or 1)

			if (health < 1) then
				return
			end

			entity:SetHealth(health)
			client:EmitSound("buttons/button14.wav", 65, 100, 1)
		end
	end
})

properties.Add("ixSetArmorProperty", {
	MenuLabel = "#Armor",
	Order = 3,
	MenuIcon = "icon16/shield.png",

	Filter = function(self, entity, client)
		return CAMI.PlayerHasAccess(client, "Helix - Admin Context Options", nil) and entity:IsPlayer()
	end,

	MenuOpen = function( self, option, ent, tr )
		local submenu = option:AddSubMenu()
		local target = IsValid(ent.AttachedEntity) and ent.AttachedEntity or ent

		submenu:AddOption("Set Value...", function()
			PromptPositiveInteger("Set Armor", target:Armor(), function(value)
				self:SetArmor(ent, value)
			end)
		end)

	end,

	Action = function(self, entity)
		-- not used
	end,

	SetArmor = function(self, target, armor)
		self:MsgStart()
			net.WriteEntity(target)
			net.WriteUInt(math.Clamp(math.floor(tonumber(armor) or 1), 1, MAX_POSITIVE_INT), 31)
		self:MsgEnd()
	end,

	Receive = function(self, length, client)
		if (CAMI.PlayerHasAccess(client, "Helix - Admin Context Options", nil)) then
			local entity = net.ReadEntity()
			local armor = math.floor(net.ReadUInt(31) or 1)

			if (armor < 1) then
				return
			end

			entity:SetArmor(armor)
			client:EmitSound("buttons/button14.wav", 65, 100, 1)
		end
	end
})

properties.Add("ixSetDescriptionProperty", {
	MenuLabel = "#Edit Description",
	Order = 4,
	MenuIcon = "icon16/book_edit.png",

	Filter = function(self, entity, client)
		return CAMI.PlayerHasAccess(client, "Helix - Admin Context Options", nil) and entity:IsPlayer()
	end,

	Action = function(self, entity)
		self:MsgStart()
			net.WriteEntity(entity)
		self:MsgEnd()
	end,

	Receive = function(self, length, client)
		if (CAMI.PlayerHasAccess(client, "Helix - Admin Context Options", nil)) then
			local entity = net.ReadEntity()
			client:RequestString("Set the character's description.", "New Description", function(text)
				entity:GetCharacter():SetDescription(text)
			end, entity:GetCharacter():GetDescription())
		end
	end

})

properties.Add("ixViewSteamProfileProperty", {
	MenuLabel = "#View Steam Profile",
	Order = 11,
	MenuIcon = "icon16/world_link.png",

	Filter = function(self, entity, client)
		return entity:IsPlayer()
	end,

	Action = function(self, entity)
		entity:ShowProfile()
	end
})

properties.Add("ixCopySteamIDProperty", {
	MenuLabel = "#Copy SteamID",
	Order = 12,
	MenuIcon = "icon16/page_copy.png",

	Filter = function(self, entity, client)
		return entity:IsPlayer()
	end,

	Action = function(self, entity)
		SetClipboardText(entity:IsBot() and entity:EntIndex() or entity:SteamID())
	end
})

properties.Add("ixEditFlagsProperty", {
	MenuLabel = "#Edit Flags",
	Order = 13,
	MenuIcon = "icon16/key.png",

	Filter = function(self, entity, client)
		return entity:IsPlayer() and ix.command.HasAccess(client, "CharGiveFlag")
	end,

	Action = function(self, entity)
		if (CLIENT) then
			OpenFlagEditor(entity)
		end
	end
})
