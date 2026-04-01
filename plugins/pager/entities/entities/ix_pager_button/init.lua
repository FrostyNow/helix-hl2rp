include("shared.lua")

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

function ENT:Initialize()
	self:SetModel("models/props_combine/combinebutton.mdl")
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)

	local physObj = self:GetPhysicsObject()
	if (IsValid(physObj)) then
		physObj:Wake()
	end

	self.ixPairedItems = self.ixPairedItems or {}
	self:SetNetVar("hasPairs", false)
	self.nextUseTime = 0
end

function ENT:Think()
	if (self:GetCycle() < 1) then
		self:NextThink(CurTime())
		return true
	end
end

function ENT:Use(client)
	-- 5-second cooldown check (ignores sound and animation if active)
	if (CurTime() < self.nextUseTime) then
		return
	end
	
	self:EmitSound("buttons/combine_button1.wav")
	self.nextUseTime = CurTime() + 5
	
	local plugin = ix.plugin.Get("pager")
	if (!plugin) then return end

	local count = 0

	-- Signal each paired item instance ONLY if it is currently in a player's possession
	for itemID, _ in pairs(self.ixPairedItems) do
		local item = ix.item.instances[tonumber(itemID)]
		if (item) then
			-- GetOwner() efficiently finds the player holding the item (including bag recursion)
			local owner = item:GetOwner()
			if (IsValid(owner) and owner:IsPlayer()) then
				plugin:SendPagerIt(owner)
				count = count + 1
			end
		end
	end

	if (count > 0) then
		client:NotifyLocalized("sentButtonSignals", count)
		self:SetNetVar("hasPairs", true) -- Maintain green if successful
	else
		plugin:SendPagerButtonFail(client)
		self:SetNetVar("hasPairs", false) -- Turn red if no pagers responded
	end

	-- Animation trigger at the end
	self:ResetSequence("press")
	self:SetPlaybackRate(1.0)
	self:NextThink(CurTime())
end

function ENT:PairPager(itemID)
	self.ixPairedItems[itemID] = true
	self:SetNetVar("hasPairs", true)
end

-- Save/Load support
function ENT:OnSave()
	local physObj = self:GetPhysicsObject()
	local bMotionDisabled = true
	
	if (IsValid(physObj)) then
		bMotionDisabled = !physObj:IsMotionEnabled()
	end

	return {
		pairedItems = self.ixPairedItems,
		motionDisabled = bMotionDisabled
	}
end

function ENT:OnRestore(data)
	self.ixPairedItems = data.pairedItems or {}
	self:SetNetVar("hasPairs", table.Count(self.ixPairedItems) > 0)
	
	if (data.motionDisabled ~= nil) then
		local physObj = self:GetPhysicsObject()
		if (IsValid(physObj)) then
			physObj:EnableMotion(!data.motionDisabled)
		end
	end
end
