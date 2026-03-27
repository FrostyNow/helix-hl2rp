
local PLUGIN = PLUGIN

include("shared.lua")

function ENT:CreateTexMat()
	PLUGIN.terminalMaterialIdx = PLUGIN.terminalMaterialIdx + 1

	self.tex = GetRenderTarget("ctouniquert" .. PLUGIN.terminalMaterialIdx, 512, 256, false)
	self.mat = CreateMaterial("ctouniquemat" .. PLUGIN.terminalMaterialIdx, "UnlitGeneric", {
		["$basetexture"] = self.tex,
	})
end

function ENT:Think()
	if (!self.tex or !self.mat) then
		self:CreateTexMat()
	end

	if ((self.nextTrace or 0) < CurTime()) then
		PLUGIN.terminalsToDraw[self] = LocalPlayer():IsLineOfSightClear(self)
		self.nextTrace = CurTime() + 0.1
	end
end

function ENT:Draw()
	self:DrawModel()
end
