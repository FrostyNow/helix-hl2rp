AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
	self.BaseClass.Initialize(self)

	if (SERVER) then
		self:setClawScanner()
	end
end
