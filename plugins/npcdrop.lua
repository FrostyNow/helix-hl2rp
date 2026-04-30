local PLUGIN = PLUGIN

PLUGIN.name = "NPC Drop"
PLUGIN.author = "mxd | Heavily modified by Frosty"
PLUGIN.description = "Makes NPC Drop items when they die."
PLUGIN.schema = "Any"
PLUGIN.license = [[
Copyright (c) 2025 mxd (mixvd)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

ix.lang.AddTable("english", {
	npcdrop_blunt = "Melee Weapon",
	npcdrop_rifle = "Rifle",
	npcdrop_shotgun = "Shotgun",
	npcdrop_pistol = "Pistol",
	npcdrop_grenade = "Grenade",
	npcdrop_explosive = "Explosive",
	npcdrop_weapon = "Weapon"
})

ix.lang.AddTable("korean", {
	npcdrop_blunt = "근접 무기",
	npcdrop_rifle = "소총",
	npcdrop_shotgun = "산탄총",
	npcdrop_pistol = "권총",
	npcdrop_grenade = "수류탄",
	npcdrop_explosive = "폭발물",
	npcdrop_weapon = "무기"
})

PLUGIN.items = PLUGIN.items or {}
PLUGIN.items.common = {"pistol"}
PLUGIN.items.rare = {"shotgun"}

PLUGIN.replaceList = {
	["item_healthvial"] = "health_vial",
	["item_healthkit"] = "health_kit",
	["item_battery"] = "battery",
	["item_ammo_smg1"] = "smg1ammo",
	["item_ammo_smg1_large"] = "smg1ammo",
	["item_ammo_smg1_grenade"] = "smg1grenadeammo",
	["item_ammo_pistol"] = "pistolammo",
	["item_ammo_pistol_large"] = "pistolammo",
	["item_ammo_ar2"] = "ar2ammo",
	["item_ammo_ar2_large"] = "ar2ammo",
	["item_ammo_ar2_altfire"] = "ar2orbammo",
	["item_ammo_357"] = "357ammo",
	["item_ammo_357_large"] = "357ammo",
	["item_box_buckshot"] = "shotgunammo",
	["item_ammo_crossbow"] = "crossbowammo",
	["item_rpg_round"] = "rocketammo",

	["weapon_smg1"] = "smg1",
	["weapon_pistol"] = "pistol",
	["weapon_ar2"] = "ar2",
	["weapon_shotgun"] = "shotgun",
	["weapon_357"] = "357",
	["weapon_crossbow"] = "crossbow",
	["weapon_frag"] = "grenade",
	["weapon_rpg"] = "rpg",
	["weapon_crowbar"] = "crowbar",
	["weapon_stunstick"] = "stunstick",
}

PLUGIN.weaponAmmoMap = { -- to do: replace with cs:s magazines
	["weapon_smg1"]   = "smg1mag",
	["weapon_pistol"] = "pistolmag",
	["weapon_ar2"]    = "ar2ammo",
	["weapon_shotgun"] = "buckshot",
	["weapon_357"]    = "357ammo",
	["weapon_crossbow"] = "crossbowammo",
	["weapon_rpg"]    = "rocketammo",
}

PLUGIN.recentDeaths = PLUGIN.recentDeaths or {}

ix.config.Add("removeUnlistedNPCDrops", false, "Wether to remove NPC drops that are not in the replace list.", nil, {
	category = "NPC Drop"
})

ix.config.Add("spawnCustomNPCDrops", true, "Whether to spawn custom decoration items for unlisted NPC drops if they aren't removed.", nil, {
	category = "NPC Drop"
})

local holdTypeToLang = {
	["smg"] = "npcdrop_rifle",
	["ar2"] = "npcdrop_rifle",
	["shotgun"] = "npcdrop_rifle",
	["crossbow"] = "npcdrop_rifle",
	["shotgun"] = "npcdrop_shotgun",
	["pistol"] = "npcdrop_pistol",
	["revolver"] = "npcdrop_pistol",
	["melee"] = "npcdrop_blunt",
	["melee2"] = "npcdrop_blunt",
	["grenade"] = "npcdrop_grenade",
	["slam"] = "npcdrop_explosive",
	["rpg"] = "npcdrop_explosive"
}

function PLUGIN:GetCustomItemType(entity)
	if (!IsValid(entity)) then return nil end

	local className = entity:GetClass()

	-- Ignore NPC-only weapons (e.g. zombie claws, headcrab attacks) that are not
	-- registered as scripted SWEPs and therefore cannot be used by players.
	if (!weapons.Get(className)) then return nil end

	local holdType = entity.GetHoldType and entity:GetHoldType() or ""

	if (holdType == "") then
		if (className:find("smg1") or className:find("ar2") or className:find("shotgun") or className:find("crossbow")) then holdType = "smg"
		elseif (className:find("pistol") or className:find("357")) then holdType = "pistol"
		elseif (className:find("crowbar") or className:find("stunstick")) then holdType = "melee"
		elseif (className:find("frag")) then holdType = "grenade"
		elseif (className:find("rpg") or className:find("slam")) then holdType = "slam"
		end
	end

	local langKey = holdTypeToLang[holdType]
	if (langKey) then
		return langKey
	end

	if (entity:IsWeapon() or className:sub(1, 7) == "weapon_") then
		return "npcdrop_weapon"
	end

	return nil
end

function PLUGIN:InitializedPlugins()
	local ixloot = ix.plugin.list["ixloot"]
	
	if (ixloot and ixloot.randomLoot) then
		PLUGIN.items.common = {}
		PLUGIN.items.rare = {}

		local function ProcessLootTable(src, dest)
			for k, v in pairs(src) do
				local itemID
				local weight

				if (type(v) == "number") then
					itemID = k
					weight = v
				elseif (type(v) == "string") then
					itemID = v
					local itemTable = ix.item.list[itemID]
					local price = (itemTable and itemTable.price) or 10
					weight = math.Clamp(math.floor(100 / math.max(1, price)), 1, 100)
				end

				if (itemID and weight) then
					for i = 1, weight do
						table.insert(dest, itemID)
					end
				end
			end
		end

		if (ixloot.randomLoot.common) then
			ProcessLootTable(ixloot.randomLoot.common, PLUGIN.items.common)
		end

		if (ixloot.randomLoot.rare) then
			ProcessLootTable(ixloot.randomLoot.rare, PLUGIN.items.rare)
		end
	end
end

function PLUGIN:GetRandomDrop()
	if (not ix.plugin.list["ixloot"]) then return "uniqueID" end
	
	local rareChance = math.random(100)
	if (rareChance <= ix.config.Get("spawnerRareItemChance", 5) and #self.items.rare > 0) then
		return table.Random(self.items.rare)
	elseif (#self.items.common > 0) then
		return table.Random(self.items.common)
	end
	
	return "uniqueID"
end

function PLUGIN:OnNPCKilled(entity)
	local class = entity:GetClass()
	local rand = math.random(1, 2)
	local position = entity:GetPos() + Vector(0, 0, 8)

	if (entity.ixLastDamageType and bit.band(entity.ixLastDamageType, DMG_DISSOLVE) != 0) then
		return
	end

	local activeWeapon = entity:GetActiveWeapon()
	if (IsValid(activeWeapon)) then
		local weaponClass = activeWeapon:GetClass()
		local replacement = self.replaceList[weaponClass]

		if (replacement and ix.item.list[replacement]) then
			local maxClip = activeWeapon:GetMaxClip1()
			local randomAmmo = maxClip > 0 and math.random(1, maxClip) or 0
			activeWeapon:Remove()
			ix.item.Spawn(replacement, position, nil, nil, randomAmmo > 0 and {ammo = randomAmmo} or nil)

			local ammoItem = self.weaponAmmoMap[weaponClass]
			if (ammoItem and ix.item.list[ammoItem] and math.random(100) <= 60) then
				local ammoCount = math.random(1, 2)
				for i = 1, ammoCount do
					ix.item.Spawn(ammoItem, position + Vector(math.random(-8, 8), math.random(-8, 8), 0))
				end
			end
		elseif (ix.config.Get("removeUnlistedNPCDrops", false)) then
			activeWeapon:Remove()
		elseif (ix.config.Get("spawnCustomNPCDrops", true) and ix.plugin.list["customitem"] and ix.plugin.list["disallow_item_taking"]) then
			local model = activeWeapon:GetModel()
			local name = self:GetCustomItemType(activeWeapon)

			if (name and model and model != "" and util.IsValidModel(model) and model:lower() != "models/error.mdl") then
				activeWeapon:Remove()
				ix.item.Spawn("customitem", position, nil, nil, {
					name = name,
					description = "",
					model = model,
					cannotTake = true
				})
			end
		end
	end

	if (class == "npc_zombie") then
		if rand == 1 then
			local item = self:GetRandomDrop()
			timer.Simple(0, function()
				ix.item.Spawn(item, position)
			end)
		end
	end
	if (class == "npc_barnacle") then
		if rand == 1 then
			local item = self:GetRandomDrop()
			timer.Simple(0, function()
				ix.item.Spawn(item, position)
			end)
		end
	end
	-- to do: replace gibs with items
	-- if (class == "npc_cscanner") then
	-- 	if rand == 1 then
	-- 		timer.Simple(0, function()
	-- 			ix.item.Spawn("comp_combine_steel", position)
	-- 		end)
	-- 	end
	-- end
	-- if (class == "npc_turret_floor") then
	-- 	if rand == 1 then
	-- 		timer.Simple(0, function()
	-- 			ix.item.Spawn("comp_combine_steel", position)
	-- 		end)
	-- 	end
	-- end

	if (SERVER) then
		local deathPos = entity:GetPos() + Vector(0, 0, 10)
		local t = CurTime()

		table.insert(self.recentDeaths, {pos = deathPos, time = t, isCrate = false})

		timer.Simple(1, function()
			if (!self or !self.recentDeaths) then return end
			for k, v in ipairs(self.recentDeaths) do
				if (v.time == t) then
					table.remove(self.recentDeaths, k)
					break
				end
			end
		end)
	end
end

-- item_item_crate
function PLUGIN:EntityTakeDamage(target, dmg)
	if (!SERVER) then return end

	local className = target:GetClass()
	local damageType = dmg:GetDamageType()
	local isDissolving = bit.band(damageType, DMG_DISSOLVE) != 0

	if (target:IsNPC()) then
		target.ixLastDamageType = damageType
	end

	if (className == "item_item_crate" and target:Health() > 0 and (target:Health() - dmg:GetDamage() <= 0)) then
		if (isDissolving) then return end

		local pos = target:GetPos()
		local t = CurTime()

		table.insert(self.recentDeaths, {pos = pos, time = t, isCrate = true})

		timer.Simple(1, function()
			if (!self or !self.recentDeaths) then return end
			for k, v in ipairs(self.recentDeaths) do
				if (v.time == t) then
					table.remove(self.recentDeaths, k)
					break
				end
			end
		end)
	end
end

function PLUGIN:OnEntityCreated(ent)
	if (!SERVER) then return end

	timer.Simple(0, function()
		if (!IsValid(ent)) then return end

		local className = ent:GetClass()
		local replacementItemID = self.replaceList[className]

		if (replacementItemID) then
			local entPos = ent:GetPos()
			local isNPCDrop = false
			local sourceData = nil

			for k, death in ipairs(self.recentDeaths) do
				if (entPos:Distance(death.pos) < 30) then
					isNPCDrop = true
					sourceData = death
					break
				end
			end

			if (isNPCDrop) then
				local pos = ent:GetPos()
				local ang = ent:GetAngles()

				if (replacementItemID and ix.item.list[replacementItemID]) then
					local maxClip = ent:IsWeapon() and ent:GetMaxClip1() or 0
					local randomAmmo = maxClip > 0 and math.random(1, maxClip) or 0
					ent:Remove()

					ix.item.Spawn(replacementItemID, pos, function(item, itemEnt)
						if (IsValid(itemEnt)) then
							itemEnt:SetAngles(ang)
							local phys = itemEnt:GetPhysicsObject()
							if (IsValid(phys)) then
								phys:Wake()
							end
						end
					end, nil, randomAmmo > 0 and {ammo = randomAmmo} or nil)

					local ammoItem = PLUGIN.weaponAmmoMap[className]
					if (ammoItem and ix.item.list[ammoItem] and math.random(100) <= 60) then
						local ammoCount = math.random(1, 2)
						for i = 1, ammoCount do
							ix.item.Spawn(ammoItem, pos + Vector(math.random(-8, 8), math.random(-8, 8), 0))
						end
					end
				elseif (sourceData and sourceData.isCrate) then
					return
				elseif (ix.config.Get("removeUnlistedNPCDrops", false)) then
					ent:Remove()
				elseif (ix.config.Get("spawnCustomNPCDrops", true) and ix.plugin.list["customitem"] and ix.plugin.list["disallow_item_taking"]) then
					local model = ent:GetModel()
					local name = self:GetCustomItemType(ent)

					if (name and model and model != "" and util.IsValidModel(model) and model:lower() != "models/error.mdl") then
						ent:Remove()
						ix.item.Spawn("customitem", pos, nil, ang, {
							name = name,
							description = "",
							model = model,
							cannotTake = true
						})
					end
				end
			end
		end
	end)
end

