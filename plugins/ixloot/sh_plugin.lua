local PLUGIN = PLUGIN

PLUGIN.name = "Lootable Containers"
PLUGIN.description = "Allows you to loot certin crates to obtain loot items."
PLUGIN.author = "Riggs Mackay"
PLUGIN.schema = "Any"
PLUGIN.license = [[
Copyright 2022 Riggs Mackay

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

-- loot weights: higher number = more common
PLUGIN.randomLoot = {}
PLUGIN.randomLoot.common = {
	["acid"] = 2,
	["adhesive"] = 4,
	["aluminium"] = 2,
	["bucket"] = 2,
	["buttercup"] = 3,
	["cafeteriatray"] = 2,
	["camera"] = 1,
	["cigarettecarton"] = 2,
	["cigarettepack"] = 3,
	["cloth"] = 5,
	["coffeecup"] = 4,
	["coffeepot"] = 4,
	["ducttape"] = 2,
	["empty_can"] = 6,
	["flashlight"] = 1,
	["fryingpan"] = 2,
	["glass"] = 4,
	["glue"] = 3,
	["hotplate"] = 1,
	["leather"] = 2,
	["money"] = 3,
	["oil"] = 4,
	["plastic"] = 4,
	["plastic_bottle"] = 5,
	["pressurecooker"] = 2,
	["request_device"] = 1,
	["steel"] = 4,
	["turpentine"] = 3,
	["water_empty"] = 6,
	["wood"] = 5,
	["wrench"] = 1,
	["book"] = 2,
	["phone"] = 1,
	["water"] = 3,
	["water_sparkling"] = 2,
	["water_special"] = 2,
	["beer"] = 3,
	["vodka"] = 2,
	["gin"] = 1,
	["whiskey"] = 1,
	["moonshine"] = 3,
	["bourbon"] = 1,
	["wine"] = 1,
	["bandage"] = 1,
	["canned_ham"] = 1,
	["canned_soup"] = 1,
	["paper"] = 2,
	["note"] = 1,
	["ration"] = 1,
	["coke_bottle"] = 2,
	["carrot"] = 3,
	["onion"] = 3,
	["bleach"] = 3,
	["chinese_takeout"] = 3,
	["chocolate"] = 1,
	["corn"] = 3,
	["milk"] = 1,
	["mineral_water"] = 1,
	["pepsi"] = 1,
	["headcrab"] = 1,
	["tomato"] = 1,
	["coke_bottle_empty"] = 2,
}

PLUGIN.randomLoot.rare = {
	["antidepressants"] = 3,
	["ballisticfiber"] = 2,
	["battery"] = 3,
	["book"] = 3,
	["emp"] = 1,
	["flashlight"] = 3,
	["gunpowder"] = 3,
	["handheld_radio"] = 1,
	["walkietalkie"] = 1,
	["unionkey"] = 1,
	["bag"] = 1,
	["satchel"] = 1,
	["suitcase"] = 1,
	["pistol"] = 1,
	["pistolammo"] = 1,
	["health_vial"] = 1,
	["headcrab"] = 3,
	["medkit"] = 2,
	["pot"] = 1,
	["pan"] = 1,
	["pipe"] = 1,
	["axe"] = 1,
	["bottle_shard"] = 1,
	["manhack"] = 1,
	["manhack_gib01"] = 1,
	["manhack_gib02"] = 1,
	["manhack_gib03"] = 1,
	["manhack_gib04"] = 1,
	["manhack_gib05"] = 1,
	["scanner_gib01"] = 1,
	["scanner_gib02"] = 1,
	["scanner_gib04"] = 1,
	["scanner_gib05"] = 1,
	["sensormodule"] = 1,
}

ix.util.Include("sv_plugin.lua")

ix.lang.AddTable("english", {
	ixlootNotEating = "You cannot loot anything while you are eating!",
	ixlootNoItem = "There is nothing in the container!",
	ixlootNotFaction = "Your faction is not allowed to loot containers.",
	ixlootGained = "You have gained %s.",
	lootableContainerDesc = "You might find useful items in.",
})
ix.lang.AddTable("korean", {
	ixlootNotEating = "뭔가를 먹고 있을 때는 살펴볼 수 없습니다!",
	ixlootNoItem = "아무것도 들어있지 않습니다!",
	ixlootNotFaction = "해당 세력은 보관함을 살펴볼 수 없습니다.",
	ixlootGained = "다음을 얻었습니다: %s.",
	lootableContainerDesc = "안에서 쓸모 있는 물건을 찾을 수 있을지도 모릅니다.",
})

if ( CLIENT ) then
	function PLUGIN:PopulateEntityInfo(ent, tooltip)
		local ply = LocalPlayer()
		local ent = ent:GetClass()

		if ( ply:IsCombine() ) then
			return false
		end

		if not ( ent:find("ix_loot") ) then
			return false
		end

		-- local title = tooltip:AddRow("loot")
		-- title:SetText(L("Lootable Container"))
		-- title:SetImportant()
		-- title:SizeToContents()

		local desc = tooltip:AddRow("desc")
		desc:SetText(L("lootableContainerDesc"))
		desc:SizeToContents()
	end
end
