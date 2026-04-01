local PLUGIN = PLUGIN

PLUGIN.name = "Admin Item Spawnmenu"
PLUGIN.author = "Unknown"
PLUGIN.description = "Adds a spawn-menu tab with all registered items listed by category."

CAMI.RegisterPrivilege({
	Name = "Helix - Item Menu",
	MinAccess = "admin"
})

ix.lang.AddTable("english", {
	items = "Items",
	spawnIntoContainer = "Spawn into Container",
	containerFull = "This container is full.",
})
ix.lang.AddTable("korean", {
	items = "아이템",
	spawnIntoContainer = "보관함에 스폰",
	containerFull = "이 보관함은 가득 찼습니다.",
})

if (SERVER) then
	netstream.Hook("MenuItemSpawn", function(ply, uniqueID)
		if (!IsValid(ply)) then return end
		if (!CAMI.PlayerHasAccess(ply, "Helix - Item Menu")) then return end

		local trace = ply:GetEyeTraceNoCursor()
		local pos = trace.HitPos

		if (uniqueID == "goldgnome") and not (ply:SteamID() == "STEAM_0:1:1395956") then
			ply:Notify(ply:Nick().." don't you even dare spawn that shit.")
			return false
		end

		ix.item.Spawn(uniqueID, pos, function(item, ent)
			if (IsValid(ent)) then
				local min = ent:OBBMins()
				
				-- Adjust Z position based on the bounding box to prevent it from clipping into the ground
				-- without dropping it from the air
				ent:SetPos(pos - Vector(0, 0, min.z))
			end
		end)

		ix.log.Add(ply, "itemListSpawnedItem", uniqueID)

		hook.Run("PlayerSpawnedItem", ply, pos, uniqueID)
	end)

	netstream.Hook("MenuItemGive", function(ply, uniqueID)
		if (!IsValid(ply)) then return end
		if (!CAMI.PlayerHasAccess(ply, "Helix - Item Menu")) then return end

		local character = ply:GetCharacter()
		local inventory = character:GetInventory()

		if (uniqueID == "goldgnome") and not (ply:SteamID() == "STEAM_0:1:1395956") then
			ply:Notify(ply:Nick().." don't you even dare spawn that shit.")
			return false
		end

		inventory:Add(uniqueID, 1)
		ix.log.Add(ply, "itemListGiveItem", uniqueID)

		hook.Run("PlayerGaveItem", ply, ply:GetCharacter(), uniqueID, 1)
	end)

	netstream.Hook("MenuItemSpawnIntoContainer", function(ply, uniqueID, entity)
		if (!IsValid(ply)) then return end
		if (!CAMI.PlayerHasAccess(ply, "Helix - Item Menu")) then return end

		if (!IsValid(entity) or entity:GetClass() ~= "ix_container") then
			return
		end

		local inventory = entity:GetInventory()
		if (!inventory) then
			ply:Notify("This container has no inventory.")
			return
		end

		local itemTable = ix.item.Get(uniqueID)
		if (!itemTable) then return end

		local x, y, error = inventory:CanAdd(uniqueID)
		if (!x) then
			ply:Notify(error or L("containerFull", ply))
			return
		end

		inventory:Add(uniqueID)
		ix.log.Add(ply, "itemListSpawnedIntoContainer", itemTable.name, entity:GetDisplayName())
		ply:Notify(string.format("Spawned %s into %s.", itemTable.name, entity:GetDisplayName()))
	end)

	function PLUGIN:PlayerLoadedCharacter(ply)
		netstream.Start(ply, "CheckForItemTab")
	end

	ix.log.AddType("itemListSpawnedItem", function(ply, name)
		return string.format("%s has spawned a %s.", ply:GetName(), name)
	end)
	ix.log.AddType("itemListGiveItem", function(ply, name)
		return string.format("%s has given himself a %s.", ply:GetName(), name)
	end)
	ix.log.AddType("itemListSpawnedIntoContainer", function(ply, name, containerName)
		return string.format("%s has spawned a %s into %s.", ply:GetName(), name, containerName)
	end)
else
	local icons = {
		["Alcohol"] = "emoticon_tongue",
		["Ammo"] = "box",
		["Ammunition"] = "box",
		["Clothing"] = "user_suit",
		["Outfit"] = "user_suit",
		["Consumeables"] = "cake",
		["Containers"] = "briefcase",
		["Storage"] = "briefcase",
		["Food"] = "cake",
		["Junk"] = "bin",
		["Medical Items"] = "heart",
		["Medical"] = "heart",
		["misc"] = "brick",
		["Weapons"] = "gun",
		["Tools"] = "wrench",
		["Utility"] = "find",
		["Permits"] = "book",
		["ARC9 Attachments"] = "plugin",
		["misc"] = "zoom",
	}

	spawnmenu.AddContentType("ixItem", function(container, data)
		if (!data.name) then return end

		local icon = vgui.Create("ContentIcon", container)

		icon:SetContentType("ixItem")
		icon:SetSpawnName(data.uniqueID)
		icon:SetName(L(data.name))

		icon.model = vgui.Create("ModelImage", icon)
		icon.model:SetMouseInputEnabled(false)
		icon.model:SetKeyboardInputEnabled(false)
		icon.model:StretchToParent(16, 16, 16, 16)
		icon.model:SetModel(data:GetModel(), data:GetSkin(), "000000000")
		icon.model:MoveToBefore(icon.Image)

		icon:SetHelixTooltip(function(tooltip)
			ix.hud.PopulateItemTooltip(tooltip, data)
		end)

		function icon:DoClick()
			netstream.Start("MenuItemSpawn", data.uniqueID)
			surface.PlaySound("ui/buttonclickrelease.wav")
		end

		function icon:OpenMenu()
			local menu = DermaMenu()
			menu:AddOption("Copy Item ID to Clipboard", function()
				SetClipboardText(data.uniqueID)
			end)

			menu:AddOption("Give to Self", function()
				netstream.Start("MenuItemGive", data.uniqueID)
			end)

			local entity = LocalPlayer():GetEyeTraceNoCursor().Entity

			if (IsValid(entity) and entity:GetClass() == "ix_container") then
				menu:AddOption(L("spawnIntoContainer"), function()
					netstream.Start("MenuItemSpawnIntoContainer", data.uniqueID, entity)
				end)
			end

			menu:Open()

			for _, v in pairs(menu:GetChildren()[1]:GetChildren()) do
				if v:GetClassName() == "Label" then
					v:SetFont("ixMediumFont")
				end
			end
		end

		if (IsValid(container)) then
			container:Add(icon)
		end
	end)

	local function CreateItemsPanel()
		local base = vgui.Create("SpawnmenuContentPanel")
		local tree = base.ContentNavBar.Tree
		local categories = {}

		vgui.Create("ItemSearch", base.ContentNavBar)

		for _, v in SortedPairsByMemberValue(ix.item.list, "category") do
			if (!categories[v.category] and not string.match( v.name, "Base" )) then
				categories[v.category] = true

				local category = tree:AddNode(L(v.category), icons[v.category] and ("icon16/" .. icons[v.category] .. ".png") or "icon16/brick.png")

				function category:DoPopulate()
					if (self.Container) then return end

					self.Container = vgui.Create("ContentContainer", base)
					self.Container:SetVisible(false)
					self.Container:SetTriggerSpawnlistChange(false)


					for _, itemTable in SortedPairsByMemberValue(ix.item.list, "name") do
						if (itemTable.category == v.category and not string.match( itemTable.name, "Base" )) then
							spawnmenu.CreateContentIcon("ixItem", self.Container, itemTable)
						end
					end
				end

				function category:DoClick()
					self:DoPopulate()
					base:SwitchPanel(self.Container)
				end
			end
		end

		local FirstNode = tree:Root():GetChildNode(0)

		if (IsValid(FirstNode)) then
			FirstNode:InternalDoClick()
		end

		PLUGIN:PopulateContent(base, tree, nil)

		return base
	end

	local function GetLocalizedText(key)
		local lang = GetConVar("gmod_language"):GetString()
		if (lang == "ko") then
			if (ix.lang.stored["korean"] and ix.lang.stored["korean"][key]) then
				return ix.lang.stored["korean"][key]
			end
		end
		
		if (ix.lang.stored["english"] and ix.lang.stored["english"][key]) then
			return ix.lang.stored["english"][key]
		end

		return L(key)
	end

	spawnmenu.AddCreationTab(GetLocalizedText("items"), CreateItemsPanel, "icon16/script_key.png")

	netstream.Hook("CheckForItemTab", function()
		if !LocalPlayer():GetNWBool("spawnmenu_reloaded") then
			LocalPlayer():ConCommand( "spawnmenu_reload" )

			LocalPlayer():SetNWBool("spawnmenu_reloaded", true)
		end
	end)
end
