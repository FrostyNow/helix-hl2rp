
ITEM.name = "Flare"
ITEM.model = Model("models/props_junk/flare.mdl")
ITEM.description = "itemFlareDesc"
ITEM.price = 45
ITEM.category = "Utility"
ITEM.isStackable = true
ITEM.factions = {FACTION_MPF, FACTION_OWS, FACTION_CONSCRIPT}
ITEM.classes = {CLASS_REBEL}

ITEM.functions.Use = {
	icon = "icon16/asterisk_orange.png",
	OnRun = function(item)
		local client = item.player
		local pos = client:GetShootPos()
		local forward = client:GetAimVector()

		-- Create the physical prop
		local entity = ents.Create("prop_physics")
		entity:SetModel(item.model)
		entity:SetPos(pos + forward * 10)
		entity:SetAngles(client:EyeAngles())
		entity:Spawn()
		entity:Activate()

		-- The secret trick: simulating a pickup/drop triggers the HL2 flare's 
		-- native 'onpickup create_flare' interaction at the engine level.
		if client:IsPlayerHolding() then
			client:DropObject()
		end

		client:SimulateGravGunPickup(entity, false)
		client:SimulateGravGunDrop(entity)

		-- Add physics velocity (toss it)
		local phys = entity:GetPhysicsObject()
		if (IsValid(phys)) then
			phys:SetVelocity(forward * 400 + Vector(0, 0, 100))
			phys:AddAngleVelocity(Vector(math.random(-10, 10), math.random(-100, 100), math.random(-10, 10)))
		end

		-- Cleanup prop after 5 minutes
		timer.Simple(300, function()
			if (IsValid(entity)) then
				entity:Remove()
			end
		end)

		return true
	end,
	OnCanRun = function(item)
		return !IsValid(item.entity)
	end
}


if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(team.GetColor(FACTION_MPF))
		data:SetText(L("securitizedItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end