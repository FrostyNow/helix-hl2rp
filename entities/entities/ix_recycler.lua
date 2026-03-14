
AddCSLuaFile()

ENT.Type = "anim"
ENT.PrintName = "Recycler"
ENT.Author = "Black Tea"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.Category = "Helix"
ENT.RenderGroup = RENDERGROUP_BOTH

local RECYCLER_INVENTORY_FLAG = "isRecyclerInventory"
local RECYCLE_TARGETS = {
	water_empty = true
}

local function IsRecyclableItem(item)
	return istable(item) and (item.isjunk or RECYCLE_TARGETS[item.uniqueID] == true)
end

hook.Add("CanTransferItem", "ixRecyclerTransferRestrictions", function(item, curInv, inventory)
	if (!inventory or !inventory.vars or !inventory.vars[RECYCLER_INVENTORY_FLAG]) then
		return
	end

	if (curInv and curInv.GetID and curInv:GetID() == inventory:GetID()) then
		return
	end

	if (!IsRecyclableItem(item)) then
		if (SERVER) then
			local owner = item.GetOwner and item:GetOwner()

			if (IsValid(owner)) then
				owner:NotifyLocalized("recyclerJunkOnly")
			end
		end

		return false
	end
end)

ix.lang.AddTable("english", {
	recyclerDesc = "Recycle junk to earn money.",
	recyclerWeightError = "You must have more junk to recycle.",
	recyclerProcessed = "You processed %s units of junk.",
	recyclerBusy = "This machine is busy.",
	recyclerPayout = "You've got %s from this machine.",
	recyclerJunkOnly = "Only junk can be placed in the recycler.",
	recyclerStorageName = "Recycler Hopper"
})

ix.lang.AddTable("korean", {
	["Recycler"] = "폐품 수집기",
	recyclerDesc = "폐품을 재활용하면 돈을 환급해줍니다.",
	recyclerWeightError = "재활용하려면 더 많은 폐품이 필요합니다.",
	recyclerProcessed = "%s 만큼의 폐품을 처리했습니다.",
	recyclerBusy = "기계가 작동 중입니다.",
	recyclerPayout = "기계에서 %s을 받았습니다.",
	recyclerJunkOnly = "재활용기에는 폐품만 넣을 수 있습니다.",
	recyclerStorageName = "재활용 투입구"
})

ENT.CurrencyPerKG = 5

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "RecycleAmount")
	self:NetworkVar("Int", 1, "MoneyHolding")
	self:NetworkVar("Bool", 0, "IsActivated")
	self:NetworkVar("Bool", 1, "IsHoldingTokens")
end

if (SERVER) then
	ix.recyclerInventorySeed = ix.recyclerInventorySeed or 2000000000
	ENT.RecycleTime = 30
	ENT.TokenHoldTime = 60
	ENT.RecyclerInventoryWidth = 8
	ENT.RecyclerInventoryHeight = 8

	local function GetNextRecyclerInventoryID()
		repeat
			ix.recyclerInventorySeed = ix.recyclerInventorySeed + 1
		until (!ix.item.inventories[ix.recyclerInventorySeed])

		return ix.recyclerInventorySeed
	end

	function ENT:CreateRecyclerInventory()
		if (self.ixRecyclerInventoryID and ix.item.inventories[self.ixRecyclerInventoryID]) then
			return ix.item.inventories[self.ixRecyclerInventoryID]
		end

		local inventory = ix.inventory.Create(self.RecyclerInventoryWidth, self.RecyclerInventoryHeight, GetNextRecyclerInventoryID())
		inventory.noSave = true
		inventory.vars[RECYCLER_INVENTORY_FLAG] = true
		inventory.vars.recyclerEntityID = self:EntIndex()
		self.ixRecyclerInventoryID = inventory:GetID()

		return inventory
	end

	function ENT:GetInventory()
		return self.ixRecyclerInventoryID and ix.item.inventories[self.ixRecyclerInventoryID] or nil
	end

	function ENT:DestroyRecyclerInventory()
		local inventory = self:GetInventory()

		if (!inventory) then
			return
		end

		if (inventory.storageInfo) then
			ix.storage.Close(inventory)
		end

		for _, item in pairs(inventory:GetItems()) do
			item:Remove()
		end

		ix.item.inventories[inventory:GetID()] = nil
		self.ixRecyclerInventoryID = nil
	end

	function ENT:GetRecyclePayload()
		local inventory = self:GetInventory()

		if (!inventory) then
			return 0, {}
		end

		local totalValue = 0
		local itemsToRecycle = {}

		for _, item in pairs(inventory:GetItems()) do
			if (!IsRecyclableItem(item)) then
				continue
			end

			local price = item.price or 1
			local area = (item.width or 1) * (item.height or 1)
			local itemValue = price * 0.3 * (1 + (area * 0.25))

			totalValue = totalValue + itemValue
			itemsToRecycle[#itemsToRecycle + 1] = item
		end

		return math.floor(totalValue), itemsToRecycle
	end

	function ENT:OpenRecyclerStorage(client)
		local inventory = self:GetInventory() or self:CreateRecyclerInventory()

		if (!inventory or (client.ixNextOpen or 0) >= CurTime()) then
			return
		end

		ix.storage.Open(client, inventory, {
			name = "recyclerStorageName",
			entity = self,
			searchTime = 0,
			OnPlayerClose = function(ply)
				if (!IsValid(self) or !IsValid(ply) or !self:CanTurnOn(ply)) then
					return
				end

				self:TurnOn(ply)
			end
		})

		client.ixNextOpen = CurTime() + 0.5
	end

	function ENT:Initialize()
		self:SetModel("models/props_wasteland/laundry_dryer002.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetUseType(SIMPLE_USE)
		
		self:SetRecycleAmount(0)
		self:SetMoneyHolding(0)
		self:SetIsActivated(false)
		self:SetIsHoldingTokens(false)
		self:CreateRecyclerInventory()
		
		self.timeGen = CurTime()
		self.timeHold = CurTime()
		
		local physicsObject = self:GetPhysicsObject()
		if (IsValid(physicsObject)) then
			physicsObject:Wake()
		end
	end

	function ENT:OnRemove()
		self:DestroyRecyclerInventory()

		if (self.loopsound) then
			self.loopsound:Stop()
			self.loopsound = nil
		end
	end

	function ENT:TurnOff()
		self:SetIsActivated(false)
		self:SetIsHoldingTokens(true)
		self:SetMoneyHolding(self:GetRecycleAmount() * self.CurrencyPerKG)
		self.timeHold = CurTime() + self.TokenHoldTime
		self:EmitSound("plats/elevator_stop.wav")
		
		if (self.loopsound) then
			self.loopsound:Stop()
			self.loopsound = nil
		end
	end

	function ENT:TurnOn(client)
		if (!IsValid(client) or !client:GetCharacter()) then
			return
		end

		local totalValue, itemsToRecycle = self:GetRecyclePayload()

		if (totalValue < 5) then
			client:NotifyLocalized("recyclerWeightError")
			return false
		end

		for _, item in pairs(itemsToRecycle) do
			item:Remove()
		end

		self.activator = client
		client:NotifyLocalized("recyclerProcessed", ix.currency.Get(totalValue, client))

		self.loopsound = CreateSound(self, "ambient/machines/machine3.wav")
		self.loopsound:Play()
		
		self:SetIsActivated(true)
		self:SetRecycleAmount(totalValue)
		self.timeGen = CurTime() + self.RecycleTime
		return true
	end

	function ENT:Think()
		if (self:GetIsActivated()) then
			if (self.timeGen < CurTime()) then
				self:TurnOff()
			end
		else
			if (self:GetIsHoldingTokens() and self.timeHold < CurTime()) then
				self:EmitSound("hl1/fvox/dadeda.wav", 60, 100)
				self:EmitSound("ambient/machines/combine_terminal_idle1.wav", 60, 100)
				self:SetIsHoldingTokens(false)
				self.activator = nil
			end
		end
		
		self:NextThink(CurTime() + 1)
		return true
	end

	function ENT:CanTurnOn(client)
		return (!self:GetIsActivated() and !self:GetIsHoldingTokens())
	end

	function ENT:Use(client)
		if (self:GetIsHoldingTokens() and self.activator == client and !self.idle) then
			self.idle = true
			self:EmitSound("ambient/machines/combine_terminal_idle4.wav", 80, 130)
			
			timer.Simple(1, function()
				if (!IsValid(self) or !IsValid(client)) then return end
				self.idle = false
				self:EmitSound("hl1/fvox/deeoo.wav", 60, 150)
				
				local money = self:GetMoneyHolding()
				client:NotifyLocalized("recyclerPayout", ix.currency.Get(money, client))
				
				local char = client:GetCharacter()
				if (char) then
					char:GiveMoney(money)
				end
				
				self:SetIsHoldingTokens(false)
			end)
			
			self.activator = nil
			return
		end
		
		if (self:GetIsActivated()) then
			client:NotifyLocalized("recyclerBusy")
			self:EmitSound("common/wpn_denyselect.wav", 80, 130)
			return
		end

		if (self:CanTurnOn(client)) then
			self:OpenRecyclerStorage(client)
		else
			client:NotifyLocalized("recyclerBusy")
			self:EmitSound("common/wpn_denyselect.wav", 80, 130)
		end
	end
else
	ENT.modelData = {
		["cylinder"] = {
			model = "models/props_wasteland/laundry_washer001a.mdl",
			size = 0.6,
			angle = Angle(-90, 0, 0),
			position = Vector(5.7164611816406, 2.4400634765625, 5.051220703125),
			scale = Vector(1, 1, 1),
		},
		["card"] = {
			model = "models/props_lab/powerbox03a.mdl",
			size = 1,
			angle = Angle(0, 0, 0),
			position = Vector(17.266235351563, -27.982055664063, -8.01220703125),
			scale = Vector(1, 1, 1),
		},
		["comlock"] = {
			model = "models/props_combine/combine_lock01.mdl",
			size = 1,
			angle = Angle(0, -90, 0),
			position = Vector(18.120361328125, -30.808715820313, 7.033935546875),
			scale = Vector(1, 0.69999998807907, 1.2000000476837),
		},
		["display"] = {
			model = "models/props_lab/reciever01d.mdl",
			size = 1,
			angle = Angle(0, 0, 0),
			position = Vector(9.527954101563, -27.65576171875, -19.580200195313),
			scale = Vector(1, 1, 1),
		},
	}

	function ENT:OnRemove()
		if (self.models) then
			for _, v in pairs(self.models) do
				if (IsValid(v)) then
					v:Remove()
				end
			end
		end
	end

	function ENT:Draw()
		self:DrawModel()
		self.models = self.models or {}

		for k, v in pairs(self.modelData) do
			local drawingmodel = self.models[k]

			if (!IsValid(drawingmodel)) then		
				self.models[k] = ClientsideModel(v.model, RENDERGROUP_BOTH)
				drawingmodel = self.models[k]
				drawingmodel:SetColor(v.color or color_white)

				if (v.scale) then
					local matrix = Matrix()
					matrix:Scale((v.scale or Vector(1, 1, 1)) * (v.size or 1))
					drawingmodel:EnableMatrix("RenderMultiply", matrix)
				end
				
				if (v.material) then
					drawingmodel:SetMaterial(v.material)
				end
				
				drawingmodel:SetParent(self)
			end

			if (IsValid(drawingmodel)) then
				local pos, ang = self:GetPos() - self:GetForward() * -5, self:GetAngles()
				local ang2 = Angle(ang.p, ang.y, ang.r) -- Copy

				drawingmodel.offset = drawingmodel.offset or Vector(0, 0, 0)
				pos = pos + self:GetForward() * v.position.x + self:GetUp() * v.position.z + self:GetRight() * -v.position.y
				pos = pos + self:GetForward() * drawingmodel.offset.x + self:GetUp() * drawingmodel.offset.z + self:GetRight() * -drawingmodel.offset.y

				ang2:RotateAroundAxis(self:GetRight(), v.angle.pitch)
				ang2:RotateAroundAxis(self:GetUp(), v.angle.yaw)
				ang2:RotateAroundAxis(self:GetForward(), v.angle.roll)

				drawingmodel:SetRenderOrigin(pos)
				drawingmodel:SetRenderAngles(ang2)
				drawingmodel:DrawModel()
			end
		end
		
		if (self.models) then
			local mdl = self.models.cylinder
			if (IsValid(mdl)) then
				mdl.offset = mdl.offset or Vector(0, 0, 0)
				if (self:GetIsActivated()) then
					mdl.offset = LerpVector(FrameTime(), mdl.offset, Vector(-3, 0, 0))
				else
					mdl.offset = LerpVector(FrameTime(), mdl.offset, Vector(0, 0, 0))
				end
			end
		end
	end

	local sx, sy = 100, 50
	local ms = math.sin
	local mc = math.cos
	local GLOW_MATERIAL = Material("sprites/glow04_noz.vmt")
	
	function ENT:DrawTranslucent()
		if (self.models) then
			local rt = RealTime()
			
			-- Calculate distance-based alpha
			local distance = LocalPlayer():GetPos():Distance(self:GetPos())
			local distalpha = math.Clamp(255 - (distance / 512 * 255), 0, 255)
			if (distalpha <= 0) then return end

			local mdl = self.models.comlock
			if (IsValid(mdl)) then
				local pos = mdl:GetPos()
				pos = pos + self:GetForward() * 5.4
				pos = pos + self:GetUp() * -10.6
				pos = pos + self:GetRight() * -3.8
				
				local color = Color(255, 44, 44)
				if (self:GetIsActivated()) then
					local alpha = math.Clamp(math.abs(ms(6 * rt) + ms(14 * rt) + mc(22 * rt)) * 500, 0, 255)
					color = Color(44, 255, 44)
					render.SetMaterial(GLOW_MATERIAL)
					render.DrawSprite(pos, 12, 12, Color(44, 255, 44, (alpha / 255) * distalpha))
				else
					local alpha = math.Clamp(math.abs(ms(2 * rt)) * 255, 0, 255)
					render.SetMaterial(GLOW_MATERIAL)
					if (self:GetIsHoldingTokens()) then
						color = Color(255, 150, 10)
						render.DrawSprite(pos, 12, 12, Color(255, 150, 10, (alpha / 255) * distalpha))
					else
						color = Color(255, 44, 44)
						render.DrawSprite(pos, 12, 12, Color(255, 44, 44, (alpha / 255) * distalpha))
					end
				end

				local dlight = DynamicLight(self:EntIndex())
				if (dlight) then
					dlight.pos = pos
					dlight.r = color.r
					dlight.g = color.g
					dlight.b = color.b
					dlight.brightness = 2
					dlight.Decay = 1000
					dlight.Size = 64
					dlight.DieTime = CurTime() + 0.1
				end
			end

			local mdlDisplay = self.models.display
			if (IsValid(mdlDisplay)) then
				local pos, ang = mdlDisplay:GetPos(), mdlDisplay:GetAngles()
				pos = pos + self:GetForward() * 5.76
				pos = pos + self:GetUp() * -0.4
				pos = pos + self:GetRight() * 2.80
				
				ang:RotateAroundAxis(self:GetRight(), -90)
				ang:RotateAroundAxis(self:GetForward(), 90)
				
				cam.Start3D2D(pos, ang, 0.05)
					surface.SetDrawColor(0, 200, 20, distalpha)
					surface.DrawRect(-sx / 2, -sy / 2, sx, sy)
					
					local currencySymbol = ix.currency.symbol or "tok"
					local text = self.CurrencyPerKG .. " " .. currencySymbol .. "/unit"
					
					if (self:GetIsActivated()) then
						text = self:GetRecycleAmount() .. " units"
					end
					
					if (self:GetIsHoldingTokens()) then
						text = self:GetMoneyHolding() .. " " .. currencySymbol .. "s"
					end 
					
					ix.util.DrawText(text, 0, 0, Color(255, 255, 255, distalpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, "ChatFont")
				cam.End3D2D()
			end
		end
	end

	function ENT:OnPopulateEntityInfo(container)
		local name = container:AddRow("name")
		name:SetImportant()
		name:SetText(L("Recycler"))
		name:SizeToContents()

		local desc = container:AddRow("desc")
		desc:SetText(L("recyclerDesc"))
		desc:SizeToContents()
	end
end
