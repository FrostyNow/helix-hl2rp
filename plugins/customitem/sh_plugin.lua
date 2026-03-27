
local PLUGIN = PLUGIN

PLUGIN.name = "Custom Items"
PLUGIN.author = "Gary Tate | Heavily modified by Frosty"
PLUGIN.description = "Enables staff members to create custom items. Now supports all items to rename with context menu property!"
PLUGIN.readme = [[
Enables staff members to create custom items.

Support for this plugin can be found here: https://discord.gg/mntpDMU
]]

do
	local ITEM = ix.meta.item

	function ITEM:GetName()
		return self:GetData("customName", (CLIENT and L(self.name) or self.name))
	end
end

ix.command.Add("CreateCustomItem", {
	description = "@cmdCreateCustomItem",
	superAdminOnly = true,
	arguments = {
		ix.type.string,
		ix.type.string,
		ix.type.string
	},
	OnRun = function(self, client, name, model, description)
		client:GetCharacter():GetInventory():Add("customitem", 1, {
			customName = name,
			customModel = model,
			customDescription = description
		})
	end
})

if (CLIENT) then
	local function CanEdit(entity, client)
		if (!IsValid(entity) or entity:GetClass() != "ix_item") then return false end
		if (!client:IsAdmin()) then return false end

		return true
	end

	local function IsCustomItem(entity)
		local item = entity:GetItemTable()
		return item and item.uniqueID == "customitem"
	end

	properties.Add("custom_item_name", {
		MenuLabel = "Replace Name",
		Order = 1101,
		MenuIcon = "icon16/textfield_rename.png",
		Filter = function(self, entity, client)
			return CanEdit(entity, client)
		end,
		Action = function(self, entity)
			local item = entity:GetItemTable()
			Derma_StringRequest(
				"Replace Name",
				"Enter the new name for this item.",
				item:GetName(),
				function(text)
					if (text) then
						net.Start("ixCustomItemProperty")
							net.WriteEntity(entity)
							net.WriteUInt(1, 2)
							net.WriteString(text)
						net.SendToServer()
					end
				end
			)
		end
	})

	properties.Add("custom_item_desc", {
		MenuLabel = "Replace Description",
		Order = 1102,
		MenuIcon = "icon16/comment_edit.png",
		Filter = function(self, entity, client)
			return CanEdit(entity, client) and IsCustomItem(entity)
		end,
		Action = function(self, entity)
			local item = entity:GetItemTable()
			Derma_StringRequest(
				"Replace Description",
				"Enter the new description for this item.",
				item:GetDescription(),
				function(text)
					if (text) then
						net.Start("ixCustomItemProperty")
							net.WriteEntity(entity)
							net.WriteUInt(2, 2)
							net.WriteString(text)
						net.SendToServer()
					end
				end
			)
		end
	})

	properties.Add("custom_item_model", {
		MenuLabel = "Replace Model",
		Order = 1103,
		MenuIcon = "icon16/magnifier.png",
		Filter = function(self, entity, client)
			return CanEdit(entity, client) and IsCustomItem(entity)
		end,
		Action = function(self, entity)
			local item = entity:GetItemTable()
			Derma_StringRequest(
				"Replace Model",
				"Enter the new model path for this item.",
				item:GetModel(),
				function(text)
					if (text) then
						net.Start("ixCustomItemProperty")
							net.WriteEntity(entity)
							net.WriteUInt(3, 2)
							net.WriteString(text)
						net.SendToServer()
					end
				end
			)
		end
	})
end

if (SERVER) then
	util.AddNetworkString("ixCustomItemProperty")

	net.Receive("ixCustomItemProperty", function(length, client)
		if (!client:IsAdmin()) then return end

		local entity = net.ReadEntity()
		local type = net.ReadUInt(2)
		local text = net.ReadString()

		if (IsValid(entity) and entity:GetClass() == "ix_item") then
			local item = entity:GetItemTable()

			if (item) then
				if (type == 1) then
					local newName = (text == "" and nil or text)
					item:SetData("customName", newName)

					if (newName) then
						client:NotifyLocalized("customItemNameChanged", text)
					else
						client:NotifyLocalized("customItemNameReset")
					end
				elseif (type == 2 and item.uniqueID == "customitem") then
					local newDesc = (text == "" and nil or text)
					item:SetData("customDescription", newDesc)

					if (newDesc) then
						client:NotifyLocalized("customItemDescChanged")
					else
						client:NotifyLocalized("customItemDescReset")
					end
				elseif (type == 3 and item.uniqueID == "customitem") then
					local newModel = (text == "" and nil or text)
					item:SetData("customModel", newModel)

					-- Update the entity model immediately if it's on the ground
					local ent = item:GetEntity()
					if (IsValid(ent)) then
						ent:SetModel(item:GetModel())
						ent:PhysicsInit(SOLID_VPHYSICS)
						ent:SetSolid(SOLID_VPHYSICS)

						local phys = ent:GetPhysicsObject()
						if (IsValid(phys)) then
							phys:Wake()
						end
					end

					if (newModel) then
						client:NotifyLocalized("customItemModelChanged", text)
					else
						client:NotifyLocalized("customItemModelReset")
					end
				end
			end
		end
	end)
end

