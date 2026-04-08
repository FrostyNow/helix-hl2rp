local PLUGIN = PLUGIN

PLUGIN.name = "Furniture"
PLUGIN.author = "Frosty"
PLUGIN.description = "A simplified furniture shop integrated with Helix Area properties."

-- Simple list: model and price only
PLUGIN.FurnitureList = {
	{model = "models/props_c17/FurnitureChair001a.mdl", price = 110},
	{model = "models/props_c17/FurnitureTable001a.mdl", price = 240},
	{model = "models/props_c17/FurnitureCouch001a.mdl", price = 500},
	{model = "models/props_c17/FurnitureCouch002a.mdl", price = 500},
	{model = "models/props_interiors/Furniture_Couch01a.mdl", price = 550},
	{model = "models/props_c17/FurnitureShelf001b.mdl", price = 180, wall = true},
	{model = "models/props_interiors/refrigerator01a.mdl", price = 925},
	{model = "models/props_c17/FurnitureCupboard001a.mdl", price = 300},
	{model = "models/props_c17/FurnitureFireplace001a.mdl", price = 700},
	{model = "models/props_c17/FurnitureRadiator001a.mdl", price = 140},
	{model = "models/props_c17/FurnitureTable001a.mdl", price = 240},
	{model = "models/props_c17/FurnitureTable002a.mdl", price = 240},
	{model = "models/props_c17/FurnitureTable003a.mdl", price = 240},
	{model = "models/props_c17/FurnitureWashingmachine001a.mdl", price = 1050},
	{model = "models/props_lab/filecabinet02.mdl", price = 225},
	{model = "models/props_interiors/Furniture_chair01a.mdl", price = 125},
	{model = "models/props_interiors/Furniture_chair03a.mdl", price = 125},
	{model = "models/props_interiors/Furniture_Couch02a.mdl", price = 575},
	{model = "models/props_interiors/Furniture_Lamp01a.mdl", price = 90},
	{model = "models/props_interiors/Furniture_shelf01a.mdl", price = 200},
	{model = "models/props_interiors/Furniture_Vanity01a.mdl", price = 365},
	{model = "models/props_interiors/Furniture_Vanity01a.mdl", price = 365},
	{model = "models/props_interiors/SinkKitchen01a.mdl", price = 465, wall = true},
	{model = "models/props_wasteland/controlroom_chair001a.mdl", price = 140},
	{model = "models/props_wasteland/controlroom_desk001a.mdl", price = 325},
	{model = "models/props_wasteland/controlroom_desk001b.mdl", price = 325},
	{model = "models/props_wasteland/kitchen_shelf002a.mdl", price = 215},
	{model = "models/props_wasteland/kitchen_shelf001a.mdl", price = 215},
	{model = "models/props_wasteland/prison_heater001a.mdl", price = 160},
	{model = "models/props_wasteland/prison_shelf002a.mdl", price = 180},
	{model = "models/props_c17/chair_stool01a.mdl", price = 75},
	{model = "models/props_c17/chair_office01a.mdl", price = 150},
	{model = "models/props_c17/clock01.mdl", price = 65},
	{model = "models/props_combine/breenclock.mdl", price = 200},
	{model = "models/props_junk/bicycle01a.mdl", price = 250},
	{model = "models/props_junk/garbage_carboard002a.mdl", price = 25},
	{model = "models/props_junk/MetalBucket01a.mdl", price = 60},
	{model = "models/props_junk/MetalBucket02a.mdl", price = 60},
	{model = "models/props_junk/PlasticCrate01a.mdl", price = 90},
	{model = "models/props_lab/corkboard002.mdl", price = 110},
	{model = "models/props_lab/desklamp01.mdl", price = 100},
	{model = "models/nova/chair_plastic01.mdl", price = 90},
	{model = "models/props_junk/TrashBin01a.mdl", price = 75},

	-- Portal
	{model = "models/props/table_reference.mdl", price = 200},
	{model = "models/props/lab_chair/lab_chair.mdl", price = 150},
	{model = "models/props/lab_desk01/lab_desk01.mdl", price = 350},
	{model = "models/props/lab_desk02/lab_desk02.mdl", price = 350},
	{model = "models/props/lab_desk03/lab_desk03.mdl", price = 350},
	{model = "models/props/lab_desk04/lab_desk04.mdl", price = 350},
	{model = "models/props/lab_desk05/lab_desk05.mdl", price = 350},
	{model = "models/props/lab_shelf/lab_shelf.mdl", price = 400, wall = true},
	{model = "models/props/lab_shelf_small/lab_shelf_small.mdl", price = 250, wall = true},
	{model = "models/props_bts/bts_chair.mdl", price = 150},
	{model = "models/props_bts/bts_stool_static.mdl", price = 150},
	{model = "models/props_bts/bts_table_static.mdl", price = 260},

	-- Addons
	{model = "models/props_c17/bedwithmattress.mdl", price = 630},
	{model = "models/tv_monitor03a.mdl", price = 400},
	{model = "models/tv_monitor03b.mdl", price = 400},
	{model = "models/props_lab/filedesk01a.mdl", price = 310},
	{model = "models/props_lab/paperbin001a.mdl", price = 65},
	{model = "models/props_megapack/bed03.mdl", price = 700},
	{model = "models/props_megapack/bed04.mdl", price = 700},
	{model = "models/props_megapack/bed05.mdl", price = 700},
	{model = "models/props_megapack/bed06.mdl", price = 700},
	{model = "models/props_megapack/bed07.mdl", price = 700},
	{model = "models/props_megapack/bed08.mdl", price = 700},
	{model = "models/props_megapack/chair04.mdl", price = 160},
	{model = "models/props_megapack/chair05.mdl", price = 160},
	{model = "models/props_megapack/chair06.mdl", price = 160},
	{model = "models/props_megapack/chair07.mdl", price = 160},
	{model = "models/props_megapack/chair08.mdl", price = 160},
	{model = "models/props_megapack/shelf02.mdl", price = 265},
	{model = "models/props_megapack/shelf03.mdl", price = 265},
	{model = "models/props_megapack/shelf04.mdl", price = 265},
	{model = "models/props_megapack/shelf05.mdl", price = 265},
	{model = "models/props_megapack/shelf06.mdl", price = 265},
	{model = "models/props_megapack/shelf07.mdl", price = 265},
	{model = "models/props_megapack/shelf08.mdl", price = 265},
	{model = "models/props_megapack/shelf09.mdl", price = 265},
	{model = "models/props_megapack/shelf10.mdl", price = 265},
	{model = "models/props_megapack/shelf11.mdl", price = 265},
	{model = "models/props_megapack/sofa01.mdl", price = 600},
	{model = "models/props_megapack/sofa02.mdl", price = 600},
	{model = "models/props_megapack/sofa03.mdl", price = 600},
	{model = "models/props_megapack/sofa04.mdl", price = 600},
	{model = "models/props_megapack/sofa05.mdl", price = 600},
	{model = "models/props_megapack/sofa06.mdl", price = 600},
	{model = "models/props_megapack/sofa07.mdl", price = 600},
	{model = "models/props_megapack/table01.mdl", price = 365},
	{model = "models/props_megapack/table02.mdl", price = 365},
	{model = "models/props_megapack/table03.mdl", price = 365},
	{model = "models/props_megapack/table04.mdl", price = 365},
	{model = "models/props_megapack/table05.mdl", price = 365},
	{model = "models/props_megapack/table06.mdl", price = 365},
	{model = "models/props_megapack/table07.mdl", price = 365},
	{model = "models/props_megapack/table08.mdl", price = 365},
	{model = "models/props_megapack/table09.mdl", price = 365},
	{model = "models/leak_props/props_c17/chair01a.mdl", price = 140},
	{model = "models/leak_props/props_c17/furniturechair002a.mdl", price = 140},
	{model = "models/leak_props/props_wasteland/controlroom_phone001b.mdl", price = 160},
	{model = "models/props/industrial17/booth.mdl", price = 435},
	{model = "models/props/industrial17/table.mdl", price = 265},
	{model = "models/fishy/furniture/piano_seat.mdl", price = 185},
	{model = "models/hls/alyxports/radioset_1.mdl", price = 365},
	{model = "models/props/coop_cementplant/coop_shelf/coop_shelf.mdl", price = 300},
	{model = "models/props/de_house/de_house_table01.mdl", price = 365},
	{model = "models/props/de_inferno/hr_i/inferno_chair/inferno_chair.mdl", price = 160},
	{model = "models/props/gg_vietnam/dirty_mattress03.mdl", price = 140},
	{model = "models/props/hr_massive/survival_mattress/survival_mattress_01.mdl", price = 160},
	{model = "models/props/hr_massive/survival_shelves/survival_shelf_01.mdl", price = 240},
	{model = "models/props_downtown/side_table.mdl", price = 190},
	{model = "models/props_furniture/hotel_chair.mdl", price = 225},
	{model = "models/props_furniture/kitchen_countertop1.mdl", price = 635},
	{model = "models/props_furniture/kitchen_shelf1.mdl", price = 265},
	{model = "models/props_highway/plywood_01.mdl", price = 75},
	{model = "models/props_highway/plywood_02.mdl", price = 75},
	{model = "models/props_interiors/bed.mdl", price = 700},
	{model = "models/props_interiors/bookcasehutch01.mdl", price = 465},
	{model = "models/props_interiors/books01.mdl", price = 90},
	{model = "models/props_interiors/books02.mdl", price = 90},
	{model = "models/props_interiors/chair_office2.mdl", price = 200},
	{model = "models/props_interiors/coffee_table_rectangular.mdl", price = 275},
	{model = "models/props_interiors/desk_metal.mdl", price = 365},
	{model = "models/props_interiors/dresser_short.mdl", price = 325},
	{model = "models/props_interiors/lamp_floor.mdl", price = 160},
	{model = "models/props_interiors/table_bedside.mdl", price = 180},
	{model = "models/props_interiors/table_console.mdl", price = 240},
	{model = "models/props_interiors/table_end.mdl", price = 180},
	{model = "models/props_interiors/table_folding.mdl", price = 160},
	{model = "models/props_interiors/table_kitchen.mdl", price = 350},
	{model = "models/props_urban/hotel_chair001.mdl", price = 240},
	{model = "models/props_urban/hotel_halfmoon_table001.mdl", price = 290},
	{model = "models/env/furniture/decosofa_wood/decosofa_wood_dou.mdl", price = 800},
	{model = "models/env/furniture/largedesk/largedesk.mdl", price = 535},
	{model = "models/env/furniture/pool_recliner/pool_recliner.mdl", price = 400},
	{model = "models/env/furniture/wc_double_cupboard/wc_double_cupboard.mdl", price = 465},
	{model = "models/highrise/lobby_chair_01.mdl", price = 275},
	{model = "models/highrise/lobby_chair_02.mdl", price = 275},
	{model = "models/props_downtown/bed_motel01.mdl", price = 565},
	{model = "models/props_downtown/booth_table.mdl", price = 400},
	{model = "models/props_equipment/sleeping_bag1.mdl", price = 210},
	{model = "models/props_equipment/sleeping_bag2.mdl", price = 210},
	{model = "models/props_furniture/cafe_barstool1.mdl", price = 140},
	{model = "models/props_furniture/piano_bench.mdl", price = 180},
	{model = "models/props_interiors/bed_motel.mdl", price = 600},
	{model = "models/props_interiors/chair01.mdl", price = 175},
	{model = "models/props_interiors/chair_cafeteria.mdl", price = 125},
	{model = "models/props_interiors/chairlobby01.mdl", price = 240},
	{model = "models/props_interiors/desk_executive.mdl", price = 635},
	{model = "models/props_interiors/dining_table_round.mdl", price = 400},
	{model = "models/props_interiors/dinning_table_oval.mdl", price = 430},
	{model = "models/props_interiors/lamp_table02.mdl", price = 140},
	{model = "models/props_interiors/ottoman01.mdl", price = 180},
	{model = "models/props_interiors/side_table_square.mdl", price = 210},
	{model = "models/props_interiors/sofa01.mdl", price = 635},
	{model = "models/props_interiors/sofa02.mdl", price = 700},
	{model = "models/props_interiors/sofa_chair02.mdl", price = 365},
	{model = "models/props_interiors/table_cafeteria.mdl", price = 310},
	{model = "models/props_interiors/toiletpaperdispenser_residential.mdl", price = 75, wall = true},
	{model = "models/props_interiors/toiletpaperroll.mdl", price = 25},
	{model = "models/props_interiors/trashcankitchen01.mdl", price = 125},
	{model = "models/props_interiors/water_cooler.mdl", price = 865},
	{model = "models/props_office/desk_01.mdl", price = 400},
	{model = "models/props_office/file_cabinet_03.mdl", price = 310},
	{model = "models/props_urban/plastic_chair001.mdl", price = 90},
	{model = "models/props_warehouse/office_furniture_coffee_table.mdl", price = 240},
	{model = "models/props_warehouse/office_furniture_couch.mdl", price = 565},
	{model = "models/props_warehouse/office_furniture_desk.mdl", price = 430},
	{model = "models/props_warehouse/office_furniture_desk_corner.mdl", price = 465},
	{model = "models/testmodels/sofa_double.mdl", price = 750},
	{model = "models/testmodels/sofa_single.mdl", price = 400},
	{model = "models/u4lab/chair_office_a.mdl", price = 180},
}

-- Configs
ix.config.Add("furnitureEnabled", true, "Wether furniture placement is enabled.", nil, {
	category = "Furniture"
})

-- Register F flag
ix.flag.Add("F", "Access to buy and place furniture.")

-- Setup Area Property
function PLUGIN:SetupAreaProperties()
	if (ix.area) then
		ix.area.AddProperty("furniture", ix.type.bool, false)
	end
end

-- Check if a position is within a furniture-enabled area
function PLUGIN:IsInZone(pos)
	if (!ix.area or !ix.area.stored or table.Count(ix.area.stored) == 0) then return true end

	for _, v in pairs(ix.area.stored) do
		local min = Vector(math.min(v.startPosition.x, v.endPosition.x), math.min(v.startPosition.y, v.endPosition.y), math.min(v.startPosition.z, v.endPosition.z))
		local max = Vector(math.max(v.startPosition.x, v.endPosition.x), math.max(v.startPosition.y, v.endPosition.y), math.max(v.startPosition.z, v.endPosition.z))

		-- Add a tiny bit of padding (1 unit) to the area bounds to avoid floating point issues
		min:Sub(Vector(1, 1, 1))
		max:Add(Vector(1, 1, 1))

		if (pos:WithinAABox(min, max)) then
			if (v.properties and v.properties.furniture) then
				return true
			end
		end
	end

	return false
end

ix.command.Add("Furniture", {
	description = "@furnitureShopOpen",
	OnRun = function(self, client)
		if (!ix.config.Get("furnitureEnabled", true)) then
			return "@furnitureDisabledMsg"
		end

		-- if (!client:GetCharacter():HasFlags("F") and !client:IsAdmin()) then
		-- 	return "@furnitureNoFlag"
		-- end

		net.Start("ixFurnitureOpenMenu")
		net.Send(client)
	end
})

ix.command.Add("AreaFurniture", {
	description = "@areaFurnitureDesc",
	adminOnly = true,
	OnRun = function(self, client)
		local areaID = client:GetArea()

		if (!client:IsInArea() or !areaID or areaID == "") then
			return "@areaFurnitureReq"
		end

		local areaInfo = ix.area.stored[areaID]
		if (!areaInfo) then
			return "@areaFurnitureInvalid"
		end

		areaInfo.properties.furniture = not areaInfo.properties.furniture

		-- Sync to all clients
		net.Start("ixAreaAdd")
			net.WriteString(areaID)
			net.WriteString(areaInfo.type)
			net.WriteVector(areaInfo.startPosition)
			net.WriteVector(areaInfo.endPosition)
			net.WriteTable(areaInfo.properties)
		net.Broadcast()

		-- Save
		local areaPlugin = ix.plugin.list["area"]
		if (areaPlugin) then
			areaPlugin:SaveData()
		end

		if (areaInfo.properties.furniture) then
			client:NotifyLocalized("areaFurnitureEnabled", areaID)
		else
			client:NotifyLocalized("areaFurnitureDisabled", areaID)
		end
	end
})

ix.command.Add("FurnitureRemove", {
	description = "@furnitureRemoveDesc",
	OnRun = function(self, client)
		local trace = client:GetEyeTrace()
		local entity = trace.Entity

		if (IsValid(entity) and entity:GetClass() == "ix_furniture") then
			local char = client:GetCharacter()
			
			if (char:GetID() == entity:GetOwnerCID() or client:IsAdmin()) then
				local furnitureID = tonumber(entity:GetFurnitureID())
				local furnitureData = PLUGIN.FurnitureList[furnitureID]
				
				local refund = 0
				if (furnitureData) then
					refund = math.floor(furnitureData.price * 0.5)
				end

				char:GiveMoney(refund)
				client:NotifyLocalized("furnitureRefundMsg", ix.currency.Get(refund, client))
				entity:Remove()
			else
				client:NotifyLocalized("furnitureNotOwner")
			end
		else
			client:NotifyLocalized("furnitureNotLooking")
		end
	end
})

ix.command.Add("FurnitureRepair", {
	description = "@furnitureRepairDesc",
	OnRun = function(self, client)
		local trace = client:GetEyeTrace()
		local entity = trace.Entity

		if (IsValid(entity) and entity:GetClass() == "ix_furniture") then
			local char = client:GetCharacter()
			local hp = entity:Health()
			local maxHP = entity:GetMaxHealth()
			
			if (hp >= maxHP) then
				return "@furnitureAlreadyFullHP"
			end

			local furnitureID = tonumber(entity:GetFurnitureID())
			local furnitureData = PLUGIN.FurnitureList[furnitureID]
			if (!furnitureData) then return end

			local missingHP = maxHP - hp
			local repairCost = math.ceil((missingHP / maxHP) * furnitureData.price * 0.5) -- 50% of value for full repair

			if (!char:HasMoney(repairCost)) then
				return L("furnitureNoMoneyRepair", client, ix.currency.Get(repairCost, client))
			end

			char:TakeMoney(repairCost)
			entity:SetHealth(maxHP)
			
			client:NotifyLocalized("furnitureRepaired", ix.currency.Get(repairCost, client))
			entity:EmitSound("physics/metal/metal_box_impact_soft" .. math.random(1, 3) .. ".wav")
		else
			return "@furnitureNotLooking"
		end
	end
})

if (SERVER) then
	util.AddNetworkString("ixFurnitureOpenMenu")
	util.AddNetworkString("ixFurnitureStartPlace")
	util.AddNetworkString("ixFurniturePlace")

	function PLUGIN:SaveData()
		local data = {}

		for _, v in ipairs(ents.FindByClass("ix_furniture")) do
			data[#data + 1] = {
				pos = v:GetPos(),
				ang = v:GetAngles(),
				model = v:GetModel(),
				furnitureID = v:GetFurnitureID(),
				owner = v:GetOwnerCID(),
				ownerName = v:GetOwnerName()
			}
		end

		self:SetData(data)
	end

	function PLUGIN:LoadData()
		local data = self:GetData()

		if (data) then
			for _, v in ipairs(data) do
				local entity = ents.Create("ix_furniture")
				entity:SetPos(v.pos)
				entity:SetAngles(v.ang)
				entity:SetModel(v.model)
				entity:Spawn()
				
				entity:SetFurnitureID(v.furnitureID)
				entity:SetOwnerCID(v.owner)
				entity:SetOwnerName(v.ownerName or "Unknown")
				
				local phys = entity:GetPhysicsObject()
				if (IsValid(phys)) then
					phys:EnableMotion(false)
				end
			end
		end
	end

	net.Receive("ixFurniturePlace", function(len, client)
		local char = client:GetCharacter()
		if (!char) then return end

		-- Check global config
		if (!ix.config.Get("furnitureEnabled", true)) then
			client:NotifyLocalized("furnitureDisabledMsg")
			return
		end

		-- Check F flag
		-- if (!char:HasFlags("F") and !client:IsAdmin()) then
		-- 	client:NotifyLocalized("furnitureNoFlag")
		-- 	return
		-- end

		-- Check Cooldown (10s)
		local nextTime = client.ixFurnitureCooldown or 0
		if (nextTime > CurTime()) then
			client:NotifyLocalized("furnitureCooldown", math.ceil(nextTime - CurTime()))
			return
		end

		local furnitureIndex = net.ReadUInt(8)
		local pos = net.ReadVector()
		local ang = net.ReadAngle()
		local normal = net.ReadVector()

		local furnitureData = PLUGIN.FurnitureList[furnitureIndex]

		if (!furnitureData or !char or !char:HasMoney(furnitureData.price)) then return end

		local bValidSurface = false
		if (furnitureData.wall) then
			bValidSurface = (normal and normal.z < 0.3) -- Walls only
		else
			bValidSurface = (normal and normal.z > 0.6) -- Floors only
		end

		if (!PLUGIN:IsInZone(pos) or !bValidSurface) then
			client:NotifyLocalized("furnitureCanNotPlace")
			return
		end

		if (client:GetPos():DistToSqr(pos) > 100000) then return end

		char:TakeMoney(furnitureData.price)

		local entity = ents.Create("ix_furniture")
		entity:SetPos(pos)
		entity:SetAngles(ang)
		entity:SetModel(furnitureData.model)
		entity:Spawn()
		
		entity:SetFurnitureID(tostring(furnitureIndex))
		entity:SetOwnerCID(char:GetID())
		entity:SetOwnerName(char:GetName())

		local phys = entity:GetPhysicsObject()
		if (IsValid(phys)) then
			phys:EnableMotion(false)
		end

		-- Set Cooldown
		client.ixFurnitureCooldown = CurTime() + 3

		client:NotifyLocalized("furniturePlaced")
	end)
end

if (CLIENT) then
	net.Receive("ixFurnitureOpenMenu", function()
		if (IsValid(ix.gui.furnitureMenu)) then
			ix.gui.furnitureMenu:Remove()
		end

		local frame = vgui.Create("DFrame")
		frame:SetTitle("")
		frame:SetSize(ScrW() * 0.5, ScrH() * 0.6)
		frame:Center()
		frame:MakePopup()
		frame:ShowCloseButton(false)
		ix.gui.furnitureMenu = frame

		frame.Paint = function(s, w, h)
			surface.SetDrawColor(25, 25, 30, 240)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(40, 40, 45, 255)
			surface.DrawRect(0, 0, w, 40)
			draw.SimpleText(L("furnitureCatalog"):upper(), "ixMediumFont", 15, 20, Color(255, 255, 255, 180), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			surface.SetDrawColor(60, 60, 70, 255)
			surface.DrawOutlinedRect(0, 0, w, h)
		end

		local close = frame:Add("DButton")
		close:SetSize(40, 40)
		close:SetPos(frame:GetWide() - 40, 0)
		close:SetText("✕")
		close:SetFont("ixMediumFont")
		close:SetTextColor(Color(200, 200, 200))
		close.Paint = function(s, w, h)
			if (s:IsHovered()) then
				surface.SetDrawColor(200, 50, 50, 150)
				surface.DrawRect(0, 0, w, h)
			end
		end
		close.DoClick = function()
			frame:Remove()
		end

		local scroll = frame:Add("DScrollPanel")
		scroll:Dock(FILL)

		local iconSize = 110
		local iconSpacing = 10
		local frameWide = frame:GetWide() - 40
		local cols = math.floor(frameWide / (iconSize + iconSpacing))
		local totalGridWidth = (cols * iconSize) + ((cols - 1) * iconSpacing)
		local sidePadding = math.max(10, (frameWide - totalGridWidth) / 2)

		scroll:DockMargin(sidePadding, 50, sidePadding, 10)

		local grid = scroll:Add("DIconLayout")
		grid:Dock(TOP)
		grid:SetSpaceX(iconSpacing)
		grid:SetSpaceY(iconSpacing)

		for k, v in ipairs(PLUGIN.FurnitureList) do
			local icon = grid:Add("SpawnIcon")
			icon:SetSize(110, 110)
			icon:SetModel(v.model)
			icon:SetTooltip(L("furniturePrice", ix.currency.Get(v.price)))
			icon.PaintOver = function(s, w, h)
				if (s:IsHovered()) then
					surface.SetDrawColor(255, 255, 255, 5)
					surface.DrawRect(0, 0, w, h)
					surface.SetDrawColor(100, 200, 255, 200)
					surface.DrawOutlinedRect(0, 0, w, h)
				end
			end

			local label = icon:Add("DLabel")
			label:SetText(ix.currency.Get(v.price))
			label:SetFont("ixSmallFont")
			label:Dock(BOTTOM)
			label:SetContentAlignment(5)
			label:SetTall(20)
			label.Paint = function(s, w, h)
				surface.SetDrawColor(0, 0, 0, 180)
				surface.DrawRect(0, 0, w, h)
			end

			icon.DoClick = function()
				if (!LocalPlayer():GetCharacter():HasMoney(v.price)) then
					LocalPlayer():NotifyLocalized("furnitureNoMoney")
					return
				end

				frame:Remove()

				if (IsValid(ix.gui.furnitureGhost)) then ix.gui.furnitureGhost:Remove() end

				local ghost = ents.CreateClientProp(v.model)
				ghost:SetSolid(SOLID_VPHYSICS)
				ghost:SetRenderMode(RENDERMODE_TRANSALPHA)
				ghost.furnitureIndex = k
				ghost.angle = LocalPlayer():EyeAngles().y + 180
				ix.gui.furnitureGhost = ghost

				LocalPlayer():NotifyLocalized("furniturePlaceMode")
			end
		end

		grid:InvalidateLayout(true)
	end)

	function PLUGIN:Think()
		local ghost = ix.gui.furnitureGhost
		if (IsValid(ghost)) then
			local client = LocalPlayer()
			local trace = util.TraceLine({
				start = client:EyePos(),
				endpos = client:EyePos() + client:GetAimVector() * 250,
				filter = {client, ghost}
			})

			local pos = trace.HitPos
			local furnitureData = PLUGIN.FurnitureList[ghost.furnitureIndex]
			local ang = (furnitureData and furnitureData.wall) and (client:EyeAngles().y + 180) or ghost.angle
			local bValidSurface = false
			
			if (furnitureData and furnitureData.wall) then
				bValidSurface = (trace.HitNormal.z < 0.3)
				
				-- Offset calculation for wall alignment
				local mins, maxs = ghost:GetModelBounds()
				local thickness = math.abs(mins.y) 
				pos = pos + trace.HitNormal * thickness
			else
				bValidSurface = (trace.HitNormal.z > 0.6)
			end

			ghost:SetAngles(Angle(0, ang, 0))

			local mins, _ = ghost:GetModelBounds()
			local center = ghost:OBBCenter()
			local offset = ghost:LocalToWorld(Vector(center.x, center.y, mins.z)) - ghost:GetPos()
			
			-- Only apply floor offset for non-wall items
			if (furnitureData and furnitureData.wall) then
				ghost:SetPos(pos)
			else
				ghost:SetPos(pos - offset)
			end

			local bInZone = self:IsInZone(pos)

			if (!bInZone or !bValidSurface) then
				ghost:SetColor(Color(255, 0, 0, 150))
				ghost.canPlace = false
			else
				ghost:SetColor(Color(0, 255, 0, 150))
				ghost.canPlace = true
			end

			-- Store trace data for network use
			ghost.lastNormal = trace.HitNormal
		end
	end

	function PLUGIN:PlayerBindPress(client, bind, pressed)
		local ghost = ix.gui.furnitureGhost
		if (IsValid(ghost) and pressed) then
			if (bind:find("attack2")) then
				ghost:Remove()
				surface.PlaySound("buttons/button10.wav")
				return true
			elseif (bind:find("attack")) then
				if (ghost.canPlace) then
					net.Start("ixFurniturePlace")
						net.WriteUInt(ghost.furnitureIndex, 8)
						net.WriteVector(ghost:GetPos())
						net.WriteAngle(ghost:GetAngles())
						net.WriteVector(ghost.lastNormal or Vector(0, 0, 1))
					net.SendToServer()

					ghost:Remove()
					surface.PlaySound("physics/wood/wood_panel_impact_soft1.wav")
				else
					surface.PlaySound("buttons/button10.wav")
				end
				return true
			elseif (bind:find("invprev") or bind:find("invnext")) then
				local furnitureData = PLUGIN.FurnitureList[ghost.furnitureIndex]
				
				-- Only allow rotation for non-wall furniture
				if (furnitureData and !furnitureData.wall) then
					local multiplier = bind:find("invprev") and 1 or -1
					ghost.angle = ghost.angle + (10 * multiplier)
					return true
				end
			end
		end
	end

	function PLUGIN:HUDPaint()
		local client = LocalPlayer()
		local entity = client:GetEyeTrace().Entity

		if (IsValid(entity) and entity:GetClass() == "ix_furniture") then
			local w, h = ScrW(), ScrH()
			local x, y = w / 2, h - 100
			local alpha = 80
			
			-- Reverted to small font and removed Uppercase for a more subtle look
			draw.SimpleText(L("furnitureOwner", entity:GetOwnerName()), "ixSmallFont", x, y, Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			
			-- Health bar background
			local barW, barH = 150, 4 -- Made it slightly thinner and shorter for small font
			local health = math.Clamp(entity:Health() / entity:GetMaxHealth(), 0, 1)
			
			surface.SetDrawColor(0, 0, 0, 50)
			surface.DrawRect(x - barW / 2, y + 12, barW, barH) -- Adjusted offset
			
			-- Translucent health bar
			local color = Color(200, 50, 50, alpha)
			if (health > 0.5) then
				color = Color(50, 200, 50, alpha)
			elseif (health > 0.25) then
				color = Color(200, 150, 50, alpha)
			end
			
			surface.SetDrawColor(color)
			surface.DrawRect(x - barW / 2, y + 12, barW * health, barH)
		end
	end
end
