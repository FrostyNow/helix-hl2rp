local PLUGIN = PLUGIN

AddCSLuaFile()

ENT.Base 			= "base_gmodentity"
ENT.Type 			= "anim"
ENT.PrintName		= "Washing Machine L"
ENT.Author			= "Riggs Mackay"
ENT.Purpose			= "Clean it dude."
ENT.Instructions	= "Press E"
ENT.Category 		= "HL2 RP: Laundry"

ENT.AutomaticFrameAdvance = true
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.PopulateEntityInfo = true
ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "WashState")
	self:NetworkVar("Float", 1, "ClothType")
	self:NetworkVar("Bool", 2, "Washing")

	if ( SERVER ) then
		self:NetworkVarNotify("Washing", self.OnWash)
	end
end

if ( SERVER ) then
    function ENT:Initialize()
        self:SetModel("models/props_wasteland/laundry_dryer002.mdl")
        self:PhysicsInit(SOLID_VPHYSICS) 
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)
    
        local phys = self:GetPhysicsObject()
        if (phys:IsValid()) then
            phys:Wake()
            phys:EnableMotion(false)
        end
    end

    function ENT:Use(activator, ply)
		if ((self.nextUse or 0) < CurTime()) then
            self.nextUse = CurTime() + 2
            if not (PLUGIN:CanUseLaundry(ply)) then
                ply:NotifyLocalized("laundryNoAccess")
                return
            end
        end
    end

    function ENT:Think()
        if (self:GetWashing()) then 
            return 
        end

        local pos = self:LocalToWorld(self:OBBCenter())
        local ang = self:GetAngles()
        ang:RotateAroundAxis(ang:Up(), 90)
        ang:RotateAroundAxis(ang:Forward(), 90)
    
        for _, ent in pairs(ents.FindInSphere(pos + (ang:Up() * 20) - (ang:Right() * 9), 15)) do
            if ( ent:GetClass() == "ix_cloth" and !ent:GetClean() ) then
                self:SetClothType(ent:GetClothType())
                self:SetWashing(true)
                self:SetWashState(ix.config.Get("laundryWashTime", 30))
                ent:Remove()
                break
            end
        end
    
        self:NextThink(CurTime() + 1)
        return true
    end
    
    function ENT:OnWash(ent, name, ov, nv)
        if timer.Exists("ixWashTimer"..self:EntIndex()) then return end
    
        timer.Create("ixWashTimer"..self:EntIndex(), 1, ix.config.Get("laundryWashTime", 30), function()

            if not ( self:IsValid() ) then 
                timer.Remove("ixWashTimer"..self:EntIndex())
                return
            end

            self:SetWashState(self:GetWashState() - 1)
    
            if ( self:GetWashState() == 0 ) then
                self:SetWashing(false)
                timer.Remove("ixWashTimer"..self:EntIndex())
    
                local pos = self:LocalToWorld(self:OBBCenter())
    
                local cloth = ents.Create("ix_cloth")
                if not cloth:IsValid() then return end
                cloth:SetPos(pos + self:GetForward() * 45)
                cloth:SetAngles(self:GetAngles())
                cloth:SetClothType(self:GetClothType())
                cloth:SetClean(true)
                cloth:Spawn()
    
                self:EmitSound("plats/elevbell1.wav")
            else
                self:EmitSound("plats/elevator_start1.wav", 60)
                self:EmitSound("plats/elevator_move_loop2.wav", 60)
                self:EmitSound("ambient/water/water_splash" .. math.random(1, 3) .. ".wav", 30)
            end
        end)
    end
    
    function ENT:OnRemove()
        if ( timer.Exists("ixWashTimer"..self:EntIndex()) ) then
            timer.Remove("ixWashTimer"..self:EntIndex())
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
		["comlock"] = {
			model = "models/props_combine/combine_lock01.mdl",
			size = 1,
			angle = Angle(0, -90, 0),
			position = Vector(18.120361328125, -30.808715820313, 7.033935546875),
			scale = Vector(1, 0.69999998807907, 1.2000000476837),
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
				if (self:GetWashing()) then
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
	local MAX_LIGHT_DIST = 512 * 512
	
	function ENT:DrawTranslucent()
		if (self.models) then
			-- Point 3: PVS Check - skip lighting if the entity is not in a potentially visible set
			if (false) then
				return
			end

			local position = self:GetPos()
			local distSqr = EyePos():DistToSqr(position)

			-- Point 4: Performance - only create lighting when the player is close
			if (distSqr > MAX_LIGHT_DIST) then
				return
			end

			local mdl = self.models.comlock
			if (IsValid(mdl)) then
				local rt = RealTime()
				local pos = mdl:GetPos()
				pos = pos + self:GetForward() * 5.4
				pos = pos + self:GetUp() * -10.6
				pos = pos + self:GetRight() * -3.8
				
				local distAlpha = math.Clamp(255 - (math.sqrt(distSqr) / 512 * 255), 0, 255)
				local color = Color(255, 44, 44)

				if (self:GetWashing()) then
					local alpha = math.Clamp(math.abs(ms(6 * rt) + ms(14 * rt) + mc(22 * rt)) * 500, 0, 255)
					color = Color(44, 255, 44)
					render.SetMaterial(GLOW_MATERIAL)
					render.DrawSprite(pos, 12, 12, Color(44, 255, 44, (alpha / 255) * distAlpha))
				else
					local alpha = math.Clamp(math.abs(ms(2 * rt)) * 255, 0, 255)
					render.SetMaterial(GLOW_MATERIAL)
                    render.DrawSprite(pos, 12, 12, Color(255, 44, 44, (alpha / 255) * distAlpha))
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
		end
	end

	function ENT:OnPopulateEntityInfo(tooltip)
		local name = tooltip:AddRow("name")
		name:SetImportant()
		name:SetText(L("Washing Machine"))
		name:SetBackgroundColor(ix.config.Get("color"))
		name:SizeToContents()

		local description = tooltip:AddRow("description")
		description:SetText(L"washingMachineDesc")
		description:SizeToContents()
	end
end

