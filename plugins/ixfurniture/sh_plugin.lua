local PLUGIN = PLUGIN

PLUGIN.name = "Furniture"
PLUGIN.author = "Frosty"
PLUGIN.description = "A simplified furniture shop integrated with Helix Area properties."

-- Simple list: model and price only
PLUGIN.FurnitureList = {
	{model = "models/props_c17/FurnitureChair001a.mdl", price = 100},
	{model = "models/props_c17/FurnitureTable001a.mdl", price = 250},
	{model = "models/props_c17/FurnitureDrawer001a.mdl", price = 350},
	{model = "models/props_interiors/Furniture_Couch01a.mdl", price = 500},
	{model = "models/props_c17/canister01a.mdl", price = 50},
	{model = "models/props_junk/wood_pallet001a.mdl", price = 30},
	{model = "models/props_c17/FurnitureShelf001b.mdl", price = 150},
	{model = "models/props_interiors/refrigerator01a.mdl", price = 800},
}

-- Configs
ix.config.Add("furnitureEnabled", true, "Wether furniture placement is enabled.", nil, {
	category = "Furniture"
})

-- Register F flag
ix.flag.Add("F", "furnitureFlagDesc")

-- Setup Area Property
function PLUGIN:SetupAreaProperties()
	if (ix.area) then
		ix.area.AddProperty("furniture", ix.type.bool, false)
	end
end

-- Check if a position is within a furniture-enabled area
function PLUGIN:IsInZone(pos)
	if (!ix.area) then return true end

	local areaID = ix.area.GetPos(pos)
	if (areaID) then
		local area = ix.area.stored[areaID]
		if (area and area.properties and area.properties.furniture) then
			return true
		end
	end

	return false
end

ix.command.Add("Furniture", {
	description = "furnitureShopOpen",
	OnRun = function(self, client)
		if (!ix.config.Get("furnitureEnabled", true)) then
			return "@furnitureDisabledMsg"
		end

		if (!client:GetCharacter():HasFlags("F") and !client:IsAdmin()) then
			return "@furnitureNoFlag"
		end

		net.Start("ixFurnitureOpenMenu")
		net.Send(client)
	end
})

ix.command.Add("AreaFurniture", {
	description = "areaFurnitureDesc",
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
	description = "furnitureRemoveDesc",
	OnRun = function(self, client)
		local trace = client:GetEyeTrace()
		local entity = trace.Entity

		if (IsValid(entity) and entity:GetClass() == "ix_furniture") then
			local char = client:GetCharacter()
			
			if (char:GetID() == entity:GetOwnerCID() or client:IsAdmin()) then
				local furnitureID = entity:GetFurnitureID()
				local index = tonumber(furnitureID)
				local furnitureData = PLUGIN.FurnitureList[index]
				
				local refund = 0
				if (furnitureData) then
					refund = math.floor(furnitureData.price * 0.5)
				end

				char:GiveMoney(refund)
				client:NotifyLocalized("furnitureRefundMsg", ix.currency.Get(refund))
				entity:Remove()
			else
				client:NotifyLocalized("furnitureNotOwner")
			end
		else
			client:NotifyLocalized("furnitureNotLooking")
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
		if (!char:HasFlags("F") and !client:IsAdmin()) then
			client:NotifyLocalized("furnitureNoFlag")
			return
		end

		-- Check Cooldown (10s)
		local nextTime = client.ixFurnitureCooldown or 0
		if (nextTime > CurTime()) then
			client:NotifyLocalized("furnitureCooldown", math.ceil(nextTime - CurTime()))
			return
		end

		local index = net.ReadUInt(8)
		local pos = net.ReadVector()
		local ang = net.ReadAngle()

		if (!PLUGIN:IsInZone(pos)) then
			client:NotifyLocalized("furnitureNotInZone")
			return
		end

		local furnitureData = PLUGIN.FurnitureList[index]
		if (!furnitureData) then return end

		if (!char:HasMoney(furnitureData.price)) then
			client:NotifyLocalized("furnitureNoMoney")
			return
		end

		if (client:GetPos():DistToSqr(pos) > 100000) then return end

		char:TakeMoney(furnitureData.price)

		local entity = ents.Create("ix_furniture")
		entity:SetPos(pos)
		entity:SetAngles(ang)
		entity:SetModel(furnitureData.model)
		entity:Spawn()
		
		entity:SetFurnitureID(tostring(index))
		entity:SetOwnerCID(char:GetID())
		entity:SetOwnerName(char:GetName())

		local phys = entity:GetPhysicsObject()
		if (IsValid(phys)) then
			phys:EnableMotion(false)
		end

		-- Set Cooldown
		client.ixFurnitureCooldown = CurTime() + 10

		client:NotifyLocalized("furniturePlaced")
	end)
end

if (CLIENT) then
	net.Receive("ixFurnitureOpenMenu", function()
		if (IsValid(ix.gui.furnitureMenu)) then
			ix.gui.furnitureMenu:Remove()
		end

		local frame = vgui.Create("ixFrame")
		frame:SetTitle(L("furnitureCatalog"))
		frame:SetSize(450, 500)
		frame:Center()
		frame:MakePopup()
		ix.gui.furnitureMenu = frame

		local scroll = frame:Add("DScrollPanel")
		scroll:Dock(FILL)
		scroll:DockMargin(5, 5, 5, 5)

		local grid = scroll:Add("DIconLayout")
		grid:Dock(TOP)
		grid:SetSpaceX(5)
		grid:SetSpaceY(5)

		for k, v in ipairs(PLUGIN.FurnitureList) do
			local icon = grid:Add("SpawnIcon")
			icon:SetSize(100, 100)
			icon:SetModel(v.model)
			icon:SetTooltip(L("furniturePrice", ix.currency.Get(v.price)))
			
			local label = icon:Add("DLabel")
			label:SetText(ix.currency.Get(v.price))
			label:SetFont("ixSmallFont")
			label:Dock(BOTTOM)
			label:SetContentAlignment(5)
			label:SetBackgroundColor(Color(0, 0, 0, 200))
			label:SetPaintBackground(true)

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
				ix.gui.furnitureGhost = ghost

				LocalPlayer():NotifyLocalized("furniturePlaceMode")
			end
		end
	end)

	function PLUGIN:Think()
		local ghost = ix.gui.furnitureGhost
		if (IsValid(ghost)) then
			local client = LocalPlayer()
			
			if (client:GetMoveType() == MOVETYPE_NOCLIP or !client:IsOnGround()) then
				ghost:Remove()
				return
			end

			local trace = util.TraceLine({
				start = client:EyePos(),
				endpos = client:EyePos() + client:GetAimVector() * 250,
				filter = {client, ghost}
			})

			local pos = trace.HitPos
			local ang = Angle(0, client:EyeAngles().y + 180, 0)
			
			ghost:SetAngles(ang)

			local mins, _ = ghost:GetModelBounds()
			local center = ghost:OBBCenter()
			local offset = ghost:LocalToWorld(Vector(center.x, center.y, mins.z)) - ghost:GetPos()
			
			ghost:SetPos(pos - offset)

			local mins, maxs = ghost:GetModelBounds()
			local tr = util.TraceHull({
				start = pos + Vector(0, 0, 5),
				endpos = pos + Vector(0, 0, 5),
				mins = mins + Vector(1, 1, 1),
				maxs = maxs - Vector(1, 1, 1),
				filter = {client, ghost}
			})

			local inZone = self:IsInZone(pos)

			if ((tr.Hit and not tr.HitWorld) or not trace.HitWorld or trace.HitNormal.z < 0.7 or not inZone) then
				ghost:SetColor(Color(255, 50, 50, 150))
				ghost.canPlace = false
			else
				ghost:SetColor(Color(50, 255, 50, 150))
				ghost.canPlace = true
			end
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
					net.SendToServer()

					ghost:Remove()
					surface.PlaySound("physics/wood/wood_panel_impact_soft1.wav")
				else
					surface.PlaySound("buttons/button10.wav")
				end
				return true
			end
		end
	end

	function PLUGIN:HUDPaint()
		local client = LocalPlayer()
		local entity = client:GetEyeTrace().Entity

		if (IsValid(entity) and entity:GetClass() == "ix_furniture") then
			local x, y = ScrW() / 2, ScrH() / 2
			local alpha = 80 -- More subtle alpha
			
			draw.SimpleText(L("furnitureOwner", entity:GetOwnerName()), "ixSmallFont", x, y + 45, Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER)
			draw.SimpleText(L("furnitureHP", entity:Health(), entity:GetMaxHealth()), "ixSmallFont", x, y + 60, Color(255, 180, 180, alpha), TEXT_ALIGN_CENTER)
		end
	end
end
