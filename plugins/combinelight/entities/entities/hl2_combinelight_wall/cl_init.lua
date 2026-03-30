include("shared.lua");

local glowMaterial = Material("sprites/glow04_noz")

-- Called when the entity initializes.
function ENT:Initialize()
	self.pixVis = util.GetPixelVisibleHandle()
end

-- Called when the entity should draw.
function ENT:Draw()
	self:DrawModel()

	-- Position adjusted for combine_light002a (taller light)
	-- It's roughly 54 units up and 4 units forward from center
	local pos = self:GetPos() + self:GetUp() * 54 + self:GetForward() * 4
	local color = Color(19, 54, 80)

	if (!self.pixVis) then
		self.pixVis = util.GetPixelVisibleHandle()
	end

	local visibility = util.PixelVisible(pos, 16, self.pixVis)

	if (visibility > 0) then
		render.SetMaterial(glowMaterial)
		-- Core Bloom (Deep blue)
		render.DrawSprite(pos, 64 * visibility, 64 * visibility, color)
		-- Outer Bloom (Large, soft flare)
		render.DrawSprite(pos, 128 * visibility, 128 * visibility, Color(color.r, color.g, color.b, 50 * visibility))
		-- Center point
		render.DrawSprite(pos, 16 * visibility, 16 * visibility, Color(255, 255, 255, 200 * visibility))
	end
end

-- Called when the entity is removed.
function ENT:OnRemove()
	if (IsValid(self.projectedLight)) then
		self.projectedLight:Remove()
	end
end

-- Called when the entity should think.
function ENT:Think()
	local pos = self:GetPos() + self:GetUp() * 54 + self:GetForward() * 4
	
	local dlight = DynamicLight(self:EntIndex())
	if (dlight) then
		dlight.Pos = pos
		dlight.r = 19
		dlight.g = 54
		dlight.b = 80
		dlight.Brightness = 1
		dlight.Size = 400
		dlight.Decay = 1000
		dlight.DieTime = CurTime() + 0.1
	end

	if (!IsValid(self.projectedLight)) then
		self.projectedLight = ProjectedTexture()
		self.projectedLight:SetTexture("effects/flashlight001")
		self.projectedLight:SetFarZ(750)
		self.projectedLight:SetFOV(100)
		self.projectedLight:SetBrightness(5)
		self.projectedLight:SetColor(Color(19, 54, 80))
		self.projectedLight:SetEnableShadows(false)
	end

	if (IsValid(self.projectedLight)) then
		local ang = self:GetAngles()
		ang:RotateAroundAxis(self:GetUp(), 180) -- Rotate 180 degrees to face forward

		self.projectedLight:SetPos(pos)
		self.projectedLight:SetAngles(ang)
		self.projectedLight:Update()
	end
end
