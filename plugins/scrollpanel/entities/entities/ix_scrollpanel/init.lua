AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

local SCALE = 0.1
local DEFAULT_FONT_SIZE = 24

function ENT:Initialize()
	self:SetModel("models/hunter/plates/plate.mdl")
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_BBOX)
	self:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
	self:DrawShadow(false)
	self:SetNetVar("text", "")
	self:SetNetVar("panelW", 400)
	self:SetNetVar("panelH", 300)
	self:SetNetVar("fontSize", DEFAULT_FONT_SIZE)
	self:UpdateBounds()
end

function ENT:UpdateBounds()
	local w = self:GetNetVar("panelW", 400)
	local h = self:GetNetVar("panelH", 300)
	local hw = w * SCALE / 2
	local hh = h * SCALE / 2
	self:SetCollisionBounds(Vector(-hw, -hh, -1), Vector(hw, hh, 1))
end
