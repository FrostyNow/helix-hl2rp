local PLUGIN = PLUGIN

PLUGIN.name = "NPC Drop"
PLUGIN.author = "mxd"
PLUGIN.description = "Makes NPC Drop items when they die."
PLUGIN.schema = "Any"
PLUGIN.license = [[
Copyright (c) 2025 mxd (mixvd)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

PLUGIN.items = PLUGIN.items or {}
PLUGIN.items.common = {"pistol"}
PLUGIN.items.rare = {"shotgun"}

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

	if (class == "npc_zombie") then
		if rand == 1 then
			ix.item.Spawn(self:GetRandomDrop(), entity:GetPos() + Vector(0, 0, 8))
		end
	end
	if (class == "npc_barnacle") then
		if rand == 1 then
			ix.item.Spawn(self:GetRandomDrop(), entity:GetPos() + Vector(0, 0, 8))
		end
	end
	if (class == "npc_combine_s") then
		rand = math.random(1, 10)
		if rand > 6 then
			ix.item.Spawn("smg1ammo", entity:GetPos() + Vector(0, 0, 8))
		elseif rand > 9 then
			ix.item.Spawn("smg1", entity:GetPos() + Vector(0, 0, 8))
		end
	end
	if (class == "npc_metropolice") then
		rand = math.random(1, 10)
		if rand > 6 then
			ix.item.Spawn("pistolammo", entity:GetPos() + Vector(0, 0, 8))
		elseif rand > 9 then
			ix.item.Spawn("pistol", entity:GetPos() + Vector(0, 0, 8))
		end
	end
	if (class == "npc_cscanner") then
		if rand == 1 then
			ix.item.Spawn("comp_combine_steel", entity:GetPos() + Vector(0, 0, 8))
		end
	end
	if (class == "npc_turret_floor") then
		if rand == 1 then
			ix.item.Spawn("comp_combine_steel", entity:GetPos() + Vector(0, 0, 8))
		end
	end
	-- if (class == "npc_headcrab") then
	-- 	if rand == 1 or rand == 2 then
	-- 		ix.item.Spawn(self:GetRandomDrop(), entity:GetPos() + Vector(0, 0, 8))
	-- 	end
	-- end
	-- if (class == "npc_antlion") then
	-- 	if rand == 1 and rand == 2 then
	-- 		ix.item.Spawn(self:GetRandomDrop(), entity:GetPos() + Vector(0, 0, 8))
	-- 	end
	-- end
end
