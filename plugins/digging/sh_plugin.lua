local PLUGIN = PLUGIN

PLUGIN.name = "Digging"
PLUGIN.author = "Frosty"
PLUGIN.description = "Allows players to dig for loot using a shovel."

-- Diggable materials
local DIGGABLE_MATERIALS = {
	[MAT_DIRT] = true,
	[MAT_SAND] = true,
	[MAT_GRASS] = true,
	[MAT_SNOW] = true,
	[MAT_SLOSH] = true,
	[MAT_FOLIAGE] = true
}

ix.lang.AddTable("english", {
	digGained = "You have dug up: %s.",
	digMoneyGained = "You have dug up %s.",
	digNothing = "You didn't find anything.",
	digCooldown = "You need to wait a bit before digging again.",
	shovelRepaired = "The shovel has been repaired.",
	itemNoRepairKit = "You do not have a repair kit!"
})

ix.lang.AddTable("korean", {
	digGained = "다음을 캐냈습니다: %s.",
	digMoneyGained = "%s를 캐냈습니다.",
	digNothing = "아무것도 찾지 못했습니다.",
	digCooldown = "다시 땅을 파려면 잠시 기다려야 합니다.",
	shovelRepaired = "삽을 수리했습니다.",
	itemNoRepairKit = "수리 도구가 없습니다!"
})

if (SERVER) then
	function PLUGIN:KeyPress(client, key)
		if (key == IN_ATTACK) then
			local weapon = client:GetActiveWeapon()
			
			if (IsValid(weapon) and weapon:GetClass() == "weapon_hl2shovel") then
				local lastDig = client.ixLastDigTime or 0
				if (lastDig > CurTime()) then
					return
				end
				client.ixLastDigTime = CurTime() + 1.2 -- Match shovel attack rate

				-- Delay to sync with the shovel hitting the ground
				timer.Simple(0.4, function()
					if (IsValid(client) and client:Alive()) then
						local wep = client:GetActiveWeapon()
						
						if (IsValid(wep) and wep:GetClass() == "weapon_hl2shovel") then
							local trace = client:GetEyeTrace()
							
							-- Ensure it's a world hit, correct material, and within melee range
							if (trace.HitWorld and trace.HitPos:Distance(client:GetShootPos()) <= 90 and DIGGABLE_MATERIALS[trace.MatType]) then
								self:HandleDig(client, trace.HitPos, trace.MatType)
							end
						end
					end
				end)
			end
		end
	end

	function PLUGIN:HandleDig(client, pos, matType)
		local character = client:GetCharacter()
		if (!character) then return end

		-- Reduce durability
		local inventory = character:GetInventory()
		local item = inventory:HasItem("shovel")
		if (item) then
			item:ReduceDurability(1)
			
			if (item:GetData("durability", 100) <= 0) then
				client:NotifyLocalized("shovelBroken")
				
				if (item:GetData("equip")) then
					client:StripWeapon(item.class)
					item:SetData("equip", false)
				end
			end
		end

		-- Antlion Grub spawning for sand
		if (matType == MAT_SAND and math.random(1, 100) <= 10) then
			local grub = ents.Create("npc_antlion_grub")

			if (IsValid(grub)) then
				grub:SetPos(pos + Vector(0, 0, 8))
				grub:Spawn()
				grub:Activate()

				client:EmitSound("npc/antlion_grub/grub_idle"..math.random(1, 3)..".wav", 75, 100)
				return
			end
		end

		-- Chance based logic
		local luck = character:GetAttribute("lck", 0)
		local maxAtt = ix.config.Get("maxAttributes", 30)
		
		-- Base chance: 10%
		-- Bonus chance: up to 10% based on luck
		local chance = 10 + (luck / maxAtt) * 10
		
		if (math.random(1, 100) <= chance) then
			-- Money reward (30% chance when loot is found)
			if (math.random(1, 100) <= 30) then
				local multi = ix.config.Get("luckMultiplier", 1)
				local bonus = (luck / maxAtt) * 100 * multi
				local amount = math.Clamp(math.random(1, 5) + math.floor(bonus), 1, 100)
				
				character:GiveMoney(amount)
				client:NotifyLocalized("digMoneyGained", ix.currency.Get(amount, client))
				client:EmitSound("physics/surfaces/sand_impact_bullet1.wav", 75, 100)
				return
			end

			local lootPlugin = ix.plugin.Get("ixloot")
			if (lootPlugin and lootPlugin.randomLoot) then
				-- 90% common, 10% rare
				local poolType = (math.random(1, 100) <= 90) and "common" or "rare"
				local pool = lootPlugin.randomLoot[poolType]
				
				if (pool and #pool > 0) then
					local itemID = pool[math.random(#pool)]
					local inventory = character:GetInventory()
					
					if (inventory) then
						if (inventory:Add(itemID)) then
							local itemTable = ix.item.list[itemID]
							local itemName = itemTable and (L(itemTable.name, client)) or itemID
							
							client:NotifyLocalized("digGained", itemName)
							client:EmitSound("physics/surfaces/sand_impact_bullet1.wav", 75, 100)
							return
						else
							ix.item.Spawn(itemID, pos + Vector(0, 0, 8))

							local itemTable = ix.item.list[itemID]
							local itemName = itemTable and (L(itemTable.name, client)) or itemID
							
							client:NotifyLocalized("digGained", itemName)
							client:EmitSound("physics/surfaces/sand_impact_bullet1.wav", 75, 100)
							return
						end
					end
				end
			end
		end
		
		-- Failure sound
		local snd = "physics/surfaces/sand_impact_bullet"..math.random(1, 4)..".wav"
		client:EmitSound(snd, 65, math.random(90, 110))
	end
end
