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

		if (ixloot.randomLoot.common) then
			for itemID, weight in pairs(ixloot.randomLoot.common) do
				for i = 1, weight do
					table.insert(PLUGIN.items.common, itemID)
				end
			end
		end

		if (ixloot.randomLoot.rare) then
			for itemID, weight in pairs(ixloot.randomLoot.rare) do
				for i = 1, weight do
					table.insert(PLUGIN.items.rare, itemID)
				end
			end
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
