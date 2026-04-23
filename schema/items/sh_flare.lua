
ITEM.name = "Flare"
ITEM.model = Model("models/props_junk/flare.mdl")
ITEM.description = "itemFlareDesc"
ITEM.price = 45
ITEM.category = "Utility"
ITEM.isStackable = true
ITEM.factions = {FACTION_MPF, FACTION_OWS, FACTION_CONSCRIPT}
ITEM.classes = {CLASS_REBEL}

ITEM.functions.Launch = {
	icon = "icon16/arrow_up.png",
	OnRun = function(item)
		if (not SERVER) then return true end

		local client = item.player
		local eyeAngles = client:EyeAngles()

		-- Create env_flare pointing straight up, launched from above the player's head
		local flare = ents.Create("env_flare")
		flare:SetPos(client:GetPos() + Vector(0, 0, 90))
		flare:SetAngles(Angle(-85, eyeAngles.y, 0))
		flare:Spawn()
		flare:Activate()

		-- Burn for 15 seconds then auto-remove, launch upward fast
		flare:Fire("Start", "15", 0)
		flare:Fire("Launch", "1500", 0)

		-- At peak (~2.5s), manually drift it down slowly for the remaining 12.5s
		timer.Simple(2.5, function()
			if (not IsValid(flare)) then return end

			local elapsed = 0
			local timerName = "flare_descent_" .. flare:EntIndex()

			timer.Create(timerName, 0.5, 25, function()
				if (not IsValid(flare)) then
					timer.Remove(timerName)
					return
				end

				elapsed = elapsed + 0.1
				local drop = elapsed * elapsed * 8  -- gentle quadratic fall, ~125 units total
				flare:SetPos(flare:GetPos() - Vector(0, 0, drop * 0.1))
			end)
		end)

		-- Spawn spent casing on the ground at the player's feet
		local trace = util.TraceLine({
			start = client:GetPos(),
			endpos = client:GetPos() - Vector(0, 0, 100),
			filter = client,
		})

		local spent = ents.Create("prop_physics")
		spent:SetModel(item.model)
		spent:SetPos(trace.HitPos + Vector(0, 0, 2))
		spent:SetAngles(Angle(0, math.random(0, 360), 0))
		spent:SetSkin(1)
		spent:Spawn()
		spent:Activate()

		timer.Simple(300, function()
			if (IsValid(spent)) then spent:Remove() end
		end)

		return true
	end,
	OnCanRun = function(item)
		return !IsValid(item.entity)
	end
}

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