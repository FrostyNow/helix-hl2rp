include("shared.lua");

local glowMaterial = Material("sprites/glow04_noz")

local MAX_PROJECTED_DIST = 600 * 600
local MAX_DLIGHT_DIST = 1500 * 1500

-- Called when the entity initializes.
function ENT:Initialize()
	self.pixVis = util.GetPixelVisibleHandle()
end

-- Called when the entity should draw.
function ENT:Draw()
	self:DrawModel()

	-- Point 3: Only process sprites if potentially visible
	if (false) then return end

	local pos = self:GetPos() - self:GetForward() * 4 + self:GetUp() * 2
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
	-- Point 3: PVS Check - skip heavy lighting if the entity is not in a potentially visible set
	-- PVS check disabled due to compatibility issues
	if (false) then
		if (IsValid(self.projectedLight)) then
			self.projectedLight:Remove()
		end
		return
	end

	local dist = EyePos():DistToSqr(self:GetPos())

	-- Level 2: Medium Range Lighting (Dynamic Light)
	-- Efficient "fill" light that keeps the room bright from a distance
	if (dist <= MAX_DLIGHT_DIST) then
		local dlight = DynamicLight(self:EntIndex())
		if (dlight) then
			dlight.Pos = self:GetPos()
			dlight.r = 19
			dlight.g = 54
			dlight.b = 80
			dlight.Brightness = 1
			dlight.Size = 400
			dlight.Decay = 1000
			dlight.DieTime = CurTime() + 0.1
		end
	end

	-- Level 1: Close Range High Quality (Projected Texture)
	-- Best visual quality/depth - extremely heavy so we cull it quickly (600 units)
	if (dist <= MAX_PROJECTED_DIST) then
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

			self.projectedLight:SetPos(self:GetPos() - self:GetForward() * -5)
			self.projectedLight:SetAngles(ang)
			self.projectedLight:Update()
		end
	elseif (IsValid(self.projectedLight)) then
		-- Optimization: Free up engine slots when too far away
		self.projectedLight:Remove()
	end
end