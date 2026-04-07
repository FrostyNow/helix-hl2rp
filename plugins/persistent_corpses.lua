
--[[
Copyright 2018 - 2019 Igor Radovanovic
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]


local PLUGIN = PLUGIN

PLUGIN.name = "Persistent Corpses"
PLUGIN.author = "`impulse | Modified by Frosty"
PLUGIN.description = "Makes player corpses stay on the map after the player has respawned."
PLUGIN.hardCorpseMax = 64

ix.config.Add("persistentCorpses", true, "Whether or not corpses remain on the map after a player dies and respawns.", nil, {
	category = "Persistent Corpses"
})

ix.config.Add("corpseMax", 30, "Maximum number of corpses that are allowed to be spawned.", nil, {
	data = {min = 0, max = PLUGIN.hardCorpseMax},
	category = "Persistent Corpses"
})

ix.config.Add("corpseDecayTime", 0, "How long it takes for a corpse to decay in seconds. Set to 0 to never decay.", nil, {
	data = {min = 0, max = 1800},
	category = "Persistent Corpses"
})

ix.config.Add("dropItemsOnDeath", false, "Whether or not to drop specific items on death.", nil, {
	category = "Persistent Corpses"
})

ix.config.Add("dropWeaponOnly", false, "Wheter or not to drop weapons only on death.", nil, {
	category = "Persistent Corpses"
})

ix.config.Add("deathWeaponDura", false, "If true weapons will take damage.", nil, {
	category = "Persistent Corpses"
})

ix.config.Add("deathWeaponDuraDmg", 4, "How much damage a weapon will take from a playerdeath.", nil, {
	data = {min = 0, max = 10},
	category = "Persistent Corpses"
})

ix.config.Add("deathItemMaxDrop", 5, "How many items that can drop from one death.", nil, {
	data = {min = 0, max = 50},
	category = "Persistent Corpses"
})

ix.config.Add("deathItemDropChance", 75, "How big the chance to drop items is.", nil, {
	data = {min = 1, max = 100},
	category = "Persistent Corpses"
})

ix.config.Add("dropMoneyOnDeath", false, "Whether or not to drop money on death.", nil, {
	category = "Persistent Corpses"
})

do
	ix.lang.AddTable("english", {
		itemLost = "You've lost item %s.",
		moneyLost = "You've lost %s.",
		corpseName = "%s's Belongings",
		searchCorpse = "Search",
		revive = "Revive",
		reviveNotify = "You have revived %s using %s.",
		noHealItem = "You don't have medical items for revival.",
		lowMedicalSkill = "You don't have enough medical skill to use this.",
		searchingCorpse = "Searching...",
		revivingCorpse = "Reviving...",
	})

	ix.lang.AddTable("korean", {
		itemLost = "당신은 %s(을)를 잃었습니다.",
		moneyLost = "당신은 %s(을)를 잃었습니다.",
		corpseName = "%s의 소지품",
		searchCorpse = "수색하기",
		revive = "소생시키기",
		reviveNotify = "%s(을)를 사용하여 %s(을)를 소생시켰습니다.",
		noHealItem = "소생에 필요한 의료 도구가 없습니다.",
		lowMedicalSkill = "이 도구를 사용하기 위한 의료 기술이 부족합니다.",
		searchingCorpse = "수색 중...",
		revivingCorpse = "소생 중...",
	})
end

function PLUGIN:CanTransferItem(item, curInv, inventory)
	if (inventory and inventory.vars and inventory.vars.isCorpseInventory and !inventory.ixIsInitializing) then
		return false
	end
end

if (CLIENT) then
	function PLUGIN:OnEntityCreated(entity)
		if (entity:GetClass() == "prop_ragdoll") then
			entity.GetEntityMenu = function(this, client)
				local options = {}

				if (this:GetNetVar("ixInventory")) then
					options[L"searchCorpse"] = function()
						return true
					end
				end

				local target = this:GetNetVar("player")
				if (IsValid(target) and !target:Alive()) then
					options[L"revive"] = function()
						return true
					end
				end

				if (this:GetNetVar("ixRestricted")) then
					options[L"unTying"] = function()
						return true
					end
				end

				return options
			end
		end
	end

	function PLUGIN:PopulateEntityInfo(entity, tooltip)
		if (entity:GetClass() == "prop_ragdoll" and entity:GetNetVar("ixRestricted")) then
			local panel = tooltip:AddRow("ziptie")
			panel:SetBackgroundColor(derma.GetColor("Warning", tooltip))
			panel:SetText(L("tiedUp"))
			panel:SetFont("ixMediumFont")
			panel:SizeToContents()
		end
	end
end

if (SERVER) then
	PLUGIN.corpses = {}

	local REVIVE_ITEMS = {
		health_kit = true,
		health_vial = true,
		aed = true
	}

	-- disable the regular hl2 ragdolls
	function PLUGIN:ShouldSpawnClientRagdoll(client)
		return false
	end

	function PLUGIN:PlayerSpawn(client)
		client:SetLocalVar("ragdoll", nil)
	end

	function PLUGIN:ShouldRemoveRagdollOnDeath(client)
		return false
	end

	function PLUGIN:PlayerInitialSpawn(client)
		self:CleanupCorpses()
	end

	function PLUGIN:CleanupCorpses(maxCorpses)
		maxCorpses = maxCorpses or ix.config.Get("corpseMax", 8)
		local toRemove = {}

		if (#self.corpses > maxCorpses) then
			for k, v in ipairs(self.corpses) do
				if (!IsValid(v)) then
					toRemove[#toRemove + 1] = k
				elseif (#self.corpses - #toRemove > maxCorpses) then
					v:Remove()
					toRemove[#toRemove + 1] = k
				end
			end
		end

		for k, _ in ipairs(toRemove) do
			table.remove(self.corpses, k)
		end
	end

	function PLUGIN:DoPlayerDeath(client, attacker, damageinfo)
		if (!ix.config.Get("persistentCorpses", true)) then
			return
		end

		if (hook.Run("ShouldSpawnPlayerCorpse") == false) then
			return
		end

		-- remove old corpse if we've hit the limit
		local maxCorpses = ix.config.Get("corpseMax", 8)

		if (maxCorpses == 0) then
			return
		end

		-- Clear player link from any previous corpses
		for _, v in ipairs(ents.FindByClass("prop_ragdoll")) do
			if (v:GetNetVar("player") == client) then
				v:SetNetVar("player", nil)
			end
		end

		local entity = IsValid(client.ixRagdoll) and client.ixRagdoll or client:CreateServerRagdoll()
		local decayTime = ix.config.Get("corpseDecayTime", 60)
		local uniqueID = "ixCorpseDecay" .. entity:EntIndex()

		entity:RemoveCallOnRemove("fixer")
		entity:CallOnRemove("ixPersistentCorpse", function(ragdoll)

			if (ragdoll.ixInventory) then
				local inventory = ix.item.inventories[ragdoll.ixInventory]
				if (inventory) then
					if (ragdoll.ixIsReviving and IsValid(client) and client:GetCharacter()) then
						local char = client:GetCharacter()
						local playerInv = char:GetInventory()
						for _, item in pairs(inventory:GetItems()) do
							local bSuccess = item:Transfer(playerInv:GetID(), nil, nil, client)
							if (!bSuccess) then
								item:Transfer()
								if (item:GetEntity()) then
									item:GetEntity():SetPos(client:GetPos() + Vector(math.Rand(-8,8), math.Rand(-8,8), 10))
								end
							end
						end
						if (ragdoll.GetMoney and ragdoll:GetMoney() > 0) then
							char:GiveMoney(ragdoll:GetMoney())
						end
					end

					for _, item in pairs(inventory:GetItems()) do
						item:Remove()
					end
					ix.item.inventories[ragdoll.ixInventory] = nil
					
					local query = mysql:Delete("ix_items")
						query:Where("inventory_id", ragdoll.ixInventory)
					query:Execute()
				end
			end

			if (IsValid(client) and !client:Alive()) then
				client:SetLocalVar("ragdoll", nil)
			end

			local index

			for k, v in ipairs(PLUGIN.corpses) do
				if (v == ragdoll) then
					index = k
					break
				end
			end

			if (index) then
				table.remove(PLUGIN.corpses, index)
			end

			if (timer.Exists(uniqueID)) then
				timer.Remove(uniqueID)
			end
		end)

		-- start decay process only if we have a time set
		if (decayTime > 0) then
			timer.Create(uniqueID, decayTime, 1, function()
				if (IsValid(entity)) then
					entity:Remove()
				else
					timer.Remove(uniqueID)
				end
			end)
		end

		-- remove reference to ragdoll so it isn't removed on spawn when SetRagdolled is called
		client.ixRagdoll = nil
		-- remove reference to the player so no more damage can be dealt
		entity.ixPlayer = nil

		self.corpses[#self.corpses + 1] = entity

		-- clean up old corpses after we've added this one
		if (#self.corpses >= maxCorpses) then
			self:CleanupCorpses(maxCorpses)
		end

		hook.Run("OnPlayerCorpseCreated", client, entity)
	end

	function PLUGIN:OnPlayerCorpseCreated(client, entity)
		if (!client:GetCharacter()) then
			return
		end

		entity.ixPlayerName = client:GetName()
		entity:SetNetVar("ixPlayerName", client:GetName())
		entity:SetNetVar("player", client)
		entity.ShowPlayerInteraction = true

		if (client:IsRestricted()) then
			entity:SetNetVar("ixRestricted", true)
		end

		if (client:IsAdmin()) then
			return
		end
		
		if (ix.config.Get("dropItemsOnDeath", false)) then
			local invID = os.time() + entity:EntIndex() + math.random(1, 99999)
			local inventory = ix.inventory.Create(8, 8, invID)
			inventory.noSave = true
			inventory.vars.isCorpseInventory = true

			entity.ixInventory = invID
			entity:SetNetVar("ixInventory", invID)

			function entity:OnOptionSelected(activator, option, data)
			end

			function entity:GetMoney()
				return self.ixMoney or 0
			end

			function entity:GetInventory()
				return ix.item.inventories[self.ixInventory]
			end

			function entity:GetDisplayName()
				return "Corpse (" .. (self:GetNetVar("ixPlayerName") or "Unknown") .. ")"
			end

			function entity:SetMoney(amount)
				if (self.ixIsInitialized and amount > (self.ixMoney or 0)) then
					return
				end

				self.ixMoney = amount
			end

			local items = client:GetCharacter():GetInventory():GetItems(false)
			local itemNames = {}
			local counter = 0

			inventory.ixIsInitializing = true
			for k, item in pairs( items ) do
				if ix.config.Get("deathWeaponDura") then
					if (item:GetData("Durability", false)) then
						item:SetData("Durability", math.max( item:GetData("Durability") - math.random(ix.config.Get("deathWeaponDuraDmg", 4) * item.maxDurability * 0.1), 0))
					end
				end

				if (item.noDeathDrop != true) then
					if (counter < ix.config.Get("deathItemMaxDrop", 1)) then
						if math.random(100) < ix.config.Get("deathItemDropChance", 50) then
							if (ix.config.Get("dropWeaponOnly", true)) then
								if (item.base == "base_weapon") then
									if (item:GetData("equip", false)) then
										item:SetData("equip", false)
									end
									
									if (ix.config.Get("dropItemsOnDeath")) then
										local bSuccess = item:Transfer(invID, nil, nil, client)
										if (!bSuccess) then
											item:Transfer()
											if item:GetEntity() then
												item:GetEntity():SetPos(client:GetPos() + Vector( math.Rand(-8,8), math.Rand(-8,8), counter * 5 ))
											end
										end
									else
										item:Remove()
									end
								end
							else
								if (item:GetData("equip", false)) then
									if (item.base == "base_armor" or item.base == "base_outfit" or item.base == "base_houtfit") then
										item:RemoveOutfit(client)
									elseif (item.base == "base_pacoutfit") then
										item:RemovePart(client)
									end
									item:SetData("equip", false)
								end
								
								if (ix.config.Get("dropItemsOnDeath")) then
									local bSuccess = item:Transfer(invID, nil, nil, client)
									if (!bSuccess) then
										item:Transfer()
										if item:GetEntity() then
											item:GetEntity():SetPos(client:GetPos() + Vector( math.Rand(-8,8), math.Rand(-8,8), counter * 5 ))
										end
									end
								else
									item:Remove()
								end
							end
							table.Add(itemNames, {item.name})
							counter = counter + 1
						end
					end
				end
			end

			inventory.ixIsInitializing = nil

			if client:Alive() then
				for j, name in pairs(itemNames) do
					client:NotifyLocalized("itemLost", name)
				end
			else
				-- timer.Simple(ix.config.Get("spawnTime", 5) + 1, function()
					for j, name in pairs(itemNames) do
						client:NotifyLocalized("itemLost", name)
					end
				-- end)
			end
		end
		
		if (ix.config.Get("dropMoneyOnDeath", false)) then
			local char = client:GetCharacter()
			local lck = char:GetAttribute("lck", 0)
			local lckMlt = ix.config.Get("luckMultiplier", 1)
			local maxAttr = ix.config.Get("maxAttributes", 100)
			local luckFactor = math.Clamp(1 - (lck / maxAttr) * lckMlt, 0, 1)
			local maxDrop = math.floor(char:GetMoney() / 2 * luckFactor)
			local amount = maxDrop > 0 and math.random(0, maxDrop) or 0
			
			if (amount > 0) then
				char:TakeMoney(amount)
				if (entity.SetMoney) then
					entity:SetMoney(amount)
					entity.ixIsInitialized = true
				else
					ix.currency.Spawn(client:GetPos() + Vector( math.Rand(-8,8), math.Rand(-8,8), 5), amount)
				end
				
				-- timer.Simple(ix.config.Get("spawnTime", 5) + 1, function()
					client:NotifyLocalized( "moneyLost", ix.currency.Get(amount, client) )
				-- end)
			end
		end
	end

	function PLUGIN:IsReviveItem(item)
		return item and REVIVE_ITEMS[item.uniqueID] == true
	end

	function PLUGIN:GetReviveItem(inventory)
		if (!inventory) then
			return nil
		end

		return inventory:HasItem("health_kit") or inventory:HasItem("health_vial") or inventory:HasItem("aed")
	end

	function PLUGIN:StartCorpseRevive(client, entity, item)
		if (!IsValid(client) or !IsValid(entity) or entity:GetClass() != "prop_ragdoll") then
			return false
		end

		local target = entity:GetNetVar("player")

		if (!IsValid(target) or target:Alive()) then
			return false
		end

		local character = client:GetCharacter()

		if (!character) then
			return false
		end

		local inventory = character:GetInventory()
		item = item or self:GetReviveItem(inventory)

		if (!self:IsReviveItem(item) or item.invID != inventory:GetID()) then
			client:NotifyLocalized("noHealItem")
			return true
		end

		if (character:GetAttribute("int", 0) < (item.medAttr or 0)) then
			client:NotifyLocalized("lowMedicalSkill")
			return true
		end

		client:SetAction("@revivingCorpse", 3)

		local uniqueID = "ixCorpseRevive_" .. client:SteamID64()
		local itemID = item:GetID()

		timer.Create(uniqueID, 0.1, 30, function()
			if (!IsValid(entity) or !IsValid(client) or !client:Alive() or !IsValid(target) or target:Alive()) then
				timer.Remove(uniqueID)

				if (IsValid(client)) then
					client:SetAction()
				end

				return
			end

			if (client:GetPos():DistToSqr(entity:GetPos()) > 6400) then
				timer.Remove(uniqueID)
				client:SetAction()
				client:NotifyLocalized("tooFar")
				return
			end

			if (timer.RepsLeft(uniqueID) == 0) then
				local liveItem = ix.item.instances[itemID]

				if (!liveItem or liveItem.bPendingRemoval or liveItem.invID != inventory:GetID()) then
					client:SetAction()
					return
				end

				local pos = entity:GetPos()
				local angles = entity:GetAngles()
				local amount = liveItem.healthPoint or 25

				if (amount < 0) then
					amount = target:GetMaxHealth()
				end

				entity.ixIsReviving = true
				local bRestricted = entity:GetNetVar("ixRestricted")

				target.ixIsReviving = true
				target:Spawn()
				timer.Simple(0, function()
					if (IsValid(target)) then
						local revivePos = pos
						local playerMins = target:OBBMins()
						local playerMaxs = target:OBBMaxs()

						-- Helper function to check if a position is safe for a player
						local function IsSafe(checkPos)
							local trace = {
								start = checkPos,
								endpos = checkPos,
								filter = {target, entity},
								mins = playerMins,
								maxs = playerMaxs,
								mask = MASK_PLAYERSOLID
							}
							return !util.TraceEntity(trace, target).StartSolid
						end

						-- If the current position is not safe, look for the nearest empty space
						if (!IsSafe(revivePos)) then
							local found = false
							-- Try searching in a circle around the corpse
							for i = 1, 3 do
								local distance = i * 32
								for j = 0, 7 do
									local ang = j * 45
									local rad = math.rad(ang)
									local offset = Vector(math.cos(rad) * distance, math.sin(rad) * distance, 8)
									local testPos = pos + offset

									if (IsSafe(testPos)) then
										revivePos = testPos
										found = true
										break
									end
								end
								if (found) then break end
							end
						else
							revivePos = revivePos + Vector(0, 0, 8)
						end

						target:SetPos(revivePos)
						target:SetEyeAngles(Angle(0, angles.y, 0))
						target:SetHealth(amount)

						if (bRestricted) then
							target:SetRestricted(true)
						end
					end
				end)

				liveItem:Remove()

				if (liveItem.sound) then
					client:EmitSound(liveItem.sound)
				end

				client:NotifyLocalized("reviveNotify", L(liveItem.name, client), target:GetName())
				target:NotifyLocalized("revive03", client:GetName())

				entity:Remove()
			end
		end)

		return true
	end

	function PLUGIN:PlayerInteractEntity(client, entity, option, data)
		if (entity:GetClass() != "prop_ragdoll") then return end

		local invID = entity:GetNetVar("ixInventory")
		local target = entity:GetNetVar("player")

		local isSearch = (option == L("searchCorpse", client))
		local isRevive = (option == L("revive", client))
		local isUntie = (option == L("unTying", client))

		if (invID and isSearch) then
			local inventory = ix.item.inventories[invID]

			if (inventory and (client.ixNextOpen or 0) < CurTime()) then
				client:SetAction("@searchingCorpse", 3)
				
				local uniqueID = "ixCorpseSearch_" .. client:SteamID64()
				timer.Create(uniqueID, 0.1, 30, function()
					if (!IsValid(entity) or !IsValid(client) or !client:Alive()) then 
						timer.Remove(uniqueID)
						if (IsValid(client)) then client:SetAction() end
						return 
					end
					
					-- 2 meters is roughly 80 units
					if (client:GetPos():DistToSqr(entity:GetPos()) > 6400) then
						timer.Remove(uniqueID)
						client:SetAction()
						client:NotifyLocalized("tooFar")
						return
					end

					if (timer.RepsLeft(uniqueID) == 0) then
						local name = L("corpseName", client, entity:GetNetVar("ixPlayerName") or "Unknown")

						ix.storage.Open(client, inventory, {
							name = name,
							entity = entity,
							searchTime = 0,
							data = {money = entity.GetMoney and entity:GetMoney() or 0},
							OnPlayerClose = function()
								ix.log.Add(client, "closeContainer", name, inventory:GetID())
							end
						})

						client.ixNextOpen = CurTime() + 1.5
					end
				end)
			end
		elseif (isRevive) then
			self:StartCorpseRevive(client, entity)
		elseif (isUntie) then
			if (!client:IsRestricted() and entity:GetNetVar("ixRestricted")) then
				client:SetAction("@unTying", 5)
				client:DoStaredAction(entity, function()
					entity:SetNetVar("ixRestricted", false)
					if (IsValid(target) and target:IsPlayer()) then
						target:SetRestricted(false)
					end
				end, 5, function()
					if (IsValid(client)) then
						client:SetAction()
					end
				end)
			end
		end
	end

	function PLUGIN:PlayerUse(client, entity)
		if (entity:GetClass() == "prop_ragdoll" and entity:GetNetVar("ixInventory")) then
			return false
		end
	end

	function PLUGIN:InitializedPlugins()
		local COMMAND = ix.command.list["revive"]
		if (COMMAND) then
			local oldOnRun = COMMAND.OnRun
			COMMAND.OnRun = function(self, client, target)
				local ragdoll = target:GetRagdollEntity()
				if (!IsValid(ragdoll)) then
					for _, v in ipairs(ents.FindByClass("prop_ragdoll")) do
						if (v:GetNetVar("player") == target) then
							ragdoll = v
							break
						end
					end
				end
				if (IsValid(ragdoll)) then
					ragdoll.ixIsReviving = true

					if (ragdoll:GetNetVar("ixRestricted")) then
						target.ixIsReviving = true
						timer.Simple(0, function()
							if (IsValid(target)) then
								target:SetRestricted(true)
							end
						end)
					end
				end
				return oldOnRun(self, client, target)
			end
		end
	end

	--  No salary while dead or ragdolled
	function PLUGIN:CanPlayerEarnSalary(client, faction)
		if not client:Alive() then return false end
		if client:IsRagdoll() then return false end
	end
end
