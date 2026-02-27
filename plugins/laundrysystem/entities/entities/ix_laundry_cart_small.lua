local PLUGIN = PLUGIN

AddCSLuaFile()

ENT.Base 			= "base_gmodentity"
ENT.Type 			= "anim"
ENT.PrintName		= "Laundry Cart"
ENT.Author			= "Riggs Mackay"
ENT.Purpose			= "Clean it dude."
ENT.Instructions	= "Press E"
ENT.Category 		= "HL2 RP: Laundry"

ENT.AutomaticFrameAdvance = true
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.PopulateEntityInfo = true

function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "ClothesNumber")
end

if ( SERVER ) then
	function ENT:Initialize()
		self:SetModel("models/props_wasteland/laundry_cart002.mdl")
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
		
		if not self.ClothTable then return end
		if not (#self.ClothTable > 0) then return end
		if not ( ply:IsValid() ) then return end

		local char = ply:GetCharacter()
		if not ( char ) then return end

		local count = #self.ClothTable
		local min = ix.config.Get("laundryCartMin", 5)

		if (count < min) then
			ply:NotifyLocalized("laundryMinClothes", min)
			return
		end

		local max = ix.config.Get("laundryCartMax", 20)
		if (count > max) then
			count = max
		end

		local tokenReward = count * ix.config.Get("laundryTokensPerCloth", 3)
		local bGiveReward = ix.config.Get("laundryRewardTokens", false)


		if ( bGiveReward ) then
			char:GiveMoney(tokenReward)
			
			if ( count == 1 ) then
				ply:NotifyLocalized("laundryRewardSingle", ix.currency.Get(tokenReward, ply))
			else
				ply:NotifyLocalized("laundryReward", count, ix.currency.Get(tokenReward, ply))
			end
		else
			if ( count == 1 ) then
				ply:NotifyLocalized("laundryProcessedSingle")
			else
				ply:NotifyLocalized("laundryProcessed", count)
			end
		end


		for i = 1, count do
			local ent = self.ClothTable[i]
			if ( ent and ent:IsValid() ) then
				ent:Remove()
			end
		end
	end
		
	function ENT:Think()
		local pos = self:LocalToWorld(self:OBBCenter())
		self.ClothTable = {}

		-- Using a larger sphere to find candidates, then filtering by local coordinates
		-- to make the detection range "narrower on the sides" (Y axis in local space)
		for _, ent in pairs(ents.FindInSphere(pos, 30)) do
			if ( ent:GetClass() == "ix_cloth" and ent:GetClean() ) then
				local localPos = self:WorldToLocal(ent:GetPos())
				
				-- Adjust these values to fit the models/props_wasteland/laundry_cart002.mdl
				-- x: forward/back, y: left/right (sides), z: up/down
				if (math.abs(localPos.x) < 22 and math.abs(localPos.y) < 12) then
					if ( !table.HasValue(self.ClothTable, ent) ) then
						table.insert(self.ClothTable, ent)
					end
				end
			end
		end

		self:SetClothesNumber(#self.ClothTable)

		self:NextThink(CurTime() + 0.5)
		return true
	end
elseif ( CLIENT ) then
	function ENT:Draw()
		self:DrawModel()

		local pos = self:GetPos()
		local ang = self:GetAngles()

		-- Position text on the side of models/props_wasteland/laundry_cart002.mdl
		-- Reduced scale (0.1) as requested
		-- Moving "left" on this side means subtraction from Forward
		local textPos = pos + (ang:Up()) + (ang:Right() * 16.5) + (ang:Forward() * 3)
		local textAng = ang + Angle(0, 0, 90)

		cam.Start3D2D(textPos, textAng, 0.1)
			draw.SimpleText(L("laundryCleanClothes", self:GetClothesNumber()), "DermaLarge", 0, 0, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		cam.End3D2D()

		-- Opposite side
		-- Moving "left" on this side (which is rotated 180) means adding to Forward
		local textPos2 = pos + (ang:Up()) + (ang:Right() * -16.5) + (ang:Forward() * 3)
		local textAng2 = ang + Angle(0, 180, 90)

		cam.Start3D2D(textPos2, textAng2, 0.1)
			draw.SimpleText(L("laundryCleanClothes", self:GetClothesNumber()), "DermaLarge", 0, 0, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		cam.End3D2D()
	end

	function ENT:OnPopulateEntityInfo(tooltip)
		local name = tooltip:AddRow("name")
		name:SetImportant()
		name:SetText(L("Laundry Cart"))
		name:SetBackgroundColor(ix.config.Get("color"))
		name:SizeToContents()

		local description = tooltip:AddRow("description")
		description:SetText(L"laundryCartDesc")
		description:SizeToContents()
	end
end
