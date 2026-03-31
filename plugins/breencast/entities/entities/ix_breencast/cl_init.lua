include("shared.lua")

function ENT:Draw()
	self:DrawModel()
end

function ENT:Think()
	self:FrameAdvance(FrameTime())
	self:SetNextClientThink(CurTime())

	return true
end
