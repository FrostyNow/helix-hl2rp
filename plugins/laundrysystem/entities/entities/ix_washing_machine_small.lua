local PLUGIN = PLUGIN

AddCSLuaFile()

ENT.Base 			= "base_gmodentity"
ENT.Type 			= "anim"
ENT.PrintName		= "Washing Machine"
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
        self:SetModel("models/props_c17/FurnitureWashingmachine001a.mdl")
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
                cloth:SetPos(pos + self:GetUp() * 30 + self:GetForward() * 5)
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
	function ENT:Draw()
		self:DrawModel()
	end

	local ms = math.sin
	local mc = math.cos
	local GLOW_MATERIAL = Material("sprites/glow04_noz.vmt")
	local MAX_LIGHT_DIST = 512 * 512
	
	function ENT:DrawTranslucent()
		-- Point 3: PVS Check - skip lighting if the entity is not in a potentially visible set
		if (!self:TestPVS()) then
			return
		end

		local position = self:GetPos()
		position = position + self:GetForward() * -8
		position = position + self:GetUp() * 20
		position = position + self:GetRight() * 9
		
		-- Point 4: Performance - only create lighting when the player is close
		local distSqr = EyePos():DistToSqr(position)
		if (distSqr > MAX_LIGHT_DIST) then
			return
		end

		local rt = RealTime()
		local distAlpha = math.Clamp(255 - (math.sqrt(distSqr) / 512 * 255), 0, 255)
		local color = Color(255, 44, 44)

		if (self:GetWashing()) then
			local alpha = math.Clamp(math.abs(ms(6 * rt) + ms(14 * rt) + mc(22 * rt)) * 500, 0, 255)
			color = Color(44, 255, 44)
			render.SetMaterial(GLOW_MATERIAL)
			render.DrawSprite(position, 10, 10, Color(44, 255, 44, (alpha / 255) * distAlpha))
		else
			local alpha = math.Clamp(math.abs(ms(2 * rt)) * 255, 0, 255)
			render.SetMaterial(GLOW_MATERIAL)
			render.DrawSprite(position, 10, 10, Color(255, 44, 44, (alpha / 255) * distAlpha))
		end

		local dlight = DynamicLight(self:EntIndex())
		if (dlight) then
			dlight.pos = position
			dlight.r = color.r
			dlight.g = color.g
			dlight.b = color.b
			dlight.brightness = 2
			dlight.Decay = 1000
			dlight.Size = 64
			dlight.DieTime = CurTime() + 0.1
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
