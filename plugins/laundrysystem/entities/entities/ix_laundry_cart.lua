local PLUGIN = PLUGIN

AddCSLuaFile()

ENT.Base 			= "base_gmodentity"
ENT.Type 			= "anim"
ENT.PrintName		= "Industrial Laundry Cart"
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
        self:SetModel("models/props_wasteland/laundry_cart001.mdl")
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
        local ang = self:GetAngles()
        self.ClothTable = {}

        for _, ent in pairs(ents.FindInSphere(pos + (ang:Forward() * 20), 20)) do
            if ( ent:GetClass() == "ix_cloth" and ent:GetClean() ) then
                if ( !table.HasValue(self.ClothTable, ent) ) then
                    table.insert(self.ClothTable, ent)
                end
            end
        end

        for _, ent in pairs(ents.FindInSphere(pos - (ang:Forward() * 20), 20)) do
            if ( ent:GetClass() == "ix_cloth" and ent:GetClean() ) then
                if ( !table.HasValue(self.ClothTable, ent) ) then
                    table.insert(self.ClothTable, ent)
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

        local pos = self:LocalToWorld(self:OBBCenter())
        local ang = self:GetAngles()

        cam.Start3D2D(pos + (ang:Up() * 5) + (ang:Right() * 21), ang + Angle(0, 0, 90), 0.25)
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
