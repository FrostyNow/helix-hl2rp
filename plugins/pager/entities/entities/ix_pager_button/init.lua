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

	self.ixPairedChars = self.ixPairedChars or {}
	self:SetNetVar("hasPairs", false)
end

function ENT:Use(client)
	self:EmitSound("buttons/combine_button1.wav")
	
	local onlinePlayers = {}
	for _, v in player.Iterator() do
		local char = v:GetCharacter()
		if (char) then
			onlinePlayers[char:GetID()] = v
		end
	end

	local count = 0
	local plugin = ix.plugin.Get("pager")
	
	if (plugin) then
		for charID, _ in pairs(self.ixPairedChars) do
			local targetPlayer = onlinePlayers[charID]
			if (IsValid(targetPlayer)) then
				plugin:SendPagerIt(targetPlayer)
				count = count + 1
			end
		end
	end

	if (count > 0) then
		client:NotifyLocalized("Pager signal sent to " .. count .. " paired characters.")
	else
		-- When signaling fails, output a random 'me' instead of notification
		local phrases = {
			"pagerButtonFail1",
			"pagerButtonFail2",
			"pagerButtonFail3"
		}
		local phrase = table.Random(phrases)
		
		-- Use the plugin's me sender to output from the button location
		if (plugin) then
			-- SendNovelMe usually takes a player, but here we want it from the button
			-- Standard 'me' chat needs a speaker. Let's use the person who pressed it.
			-- Or if we want it to be 'it' (unbound to player), we use SendPagerIt but localized.
			-- The user said 'me', so we'll use the user as the speaker of the fruitless action.
			plugin:SendPagerButtonFail(client)
		end
	end
end

function ENT:PairCharacter(charID)
	self.ixPairedChars[charID] = true
	self:SetNetVar("hasPairs", true)
	-- Notification to client is handled in item OnRun
end

-- Save/Load support
function ENT:OnSave()
	local physObj = self:GetPhysicsObject()
	local bMotionDisabled = true
	
	if (IsValid(physObj)) then
		bMotionDisabled = !physObj:IsMotionEnabled()
	end

	return {
		pairedChars = self.ixPairedChars,
		motionDisabled = bMotionDisabled
	}
end

function ENT:OnRestore(data)
	self.ixPairedChars = data.pairedChars or {}
	self:SetNetVar("hasPairs", table.Count(self.ixPairedChars) > 0)
	
	if (data.motionDisabled ~= nil) then
		local physObj = self:GetPhysicsObject()
		if (IsValid(physObj)) then
			physObj:EnableMotion(!data.motionDisabled)
		end
	end
end
