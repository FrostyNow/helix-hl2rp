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
	["bucket"] = 50, -- price 2
	["comp_adhesive"] = 33, -- price 3
	["comp_acid"] = 33, -- price 3
	["comp_aluminium"] = 33, -- price 3
	["comp_antiseptic"] = 33, -- price 3
	-- ["comp_bone"] = 33, -- price 3 (default)
	["comp_ceramic"] = 33, -- price 3
	["comp_steel"] = 33, -- price 3
	["comp_concrete"] = 33, -- price 3
	["comp_cloth"] = 33, -- price 3
	["comp_copper"] = 33, -- price 3
	["comp_cork"] = 33, -- price 3
	["comp_fertilizer"] = 33, -- price 3
	["comp_gears"] = 33, -- price 3
	["comp_glass"] = 33, -- price 3
	["comp_lead"] = 33, -- price 3
	["comp_leather"] = 33, -- price 3
	["comp_oil"] = 33, -- price 3
	["comp_plastic"] = 33, -- price 3
	["comp_rubber"] = 33, -- price 3
	["comp_screw"] = 33, -- price 3
	["comp_spring"] = 33, -- price 3
	["comp_wood"] = 33, -- price 3
	["glass_bottle_generic"] = 25, -- price 4
	["misc_hide"] = 33, -- price 3
	["misc_battery"] = 1, -- price 75
	["misc_charcoal"] = 33, -- price 3
	["misc_dried_eggprotein"] = 33, -- price 3
	["misc_dried_spices"] = 33, -- price 3
	["misc_dried_tea"] = 33, -- price 3
	["misc_dried_vegetable"] = 33, -- price 3
	["misc_margarine"] = 33, -- price 3
	["misc_plank"] = 33, -- price 3
	["misc_buttercup"] = 33, -- price 3
	["misc_cafeteriatray"] = 33, -- price 3
	["misc_camera"] = 33, -- price 3
	["misc_cigarettecarton"] = 33, -- price 3
	["misc_cigarettepack"] = 33, -- price 3
	["misc_ducttape"] = 33, -- price 3
	["misc_glue"] = 33, -- price 3
	["misc_hotplate"] = 33, -- price 3
	["misc_telephone"] = 33, -- price 3
	["misc_coffeecup"] = 33, -- price 3
	["misc_turpentine"] = 33, -- price 3
	["misc_money"] = 10, -- price 10
	["misc_plasticbottle"] = 33, -- price 3
	["misc_tool_coffeepot"] = 10, -- price 10
	["misc_tool_hammer"] = 10, -- price 10
	["misc_tool_pressurecooker"] = 10, -- price 10
	["misc_tool_screwdriver"] = 10, -- price 10
	["misc_tool_wrench"] = 10, -- price 10
	["empty_can"] = 100, -- price 1
	["flashlight"] = 2, -- price 50
	["request_device"] = 2, -- price 50
	["shot_glass"] = 20, -- price 5
	["water_empty"] = 100, -- price 1
	["book"] = 1, -- price 100
	["water"] = 6, -- price 15
	["water_sparkling"] = 5, -- price 20
	["water_special"] = 2, -- price 35
	["beer"] = 2, -- price 40
	["vodka"] = 2, -- price 40
	["moonshine"] = 4, -- price 25
	["wine"] = 2, -- price 40
	["bandage"] = 2, -- price 40
	["canned_ham"] = 5, -- price 20
	["canned_soup"] = 5, -- price 20
	["paper"] = 33, -- price 3
	["note"] = 10, -- price 10
	["ration"] = 5, -- price 20
	["coke_bottle"] = 4, -- price 25
	["carrot"] = 10, -- price 10
	["onion"] = 6, -- price 15
	["bleach"] = 3, -- price 30
	["chinese_takeout"] = 6, -- price 15
	["chocolate"] = 5, -- price 20
	["corn"] = 10, -- price 10
	["milk"] = 4, -- price 25
	["mineral_water"] = 3, -- price 30
	["pepsi"] = 4, -- price 25
	["headcrab"] = 16, -- price 6
	["tomato"] = 6, -- price 15
	["coke_bottle_empty"] = 20, -- price 5
	["ration_token"] = 1, -- price 100
	["coupon"] = 2, -- price 50
	["coffee_beans"] = 20, -- price 5
	["vegetable_oil"] = 6, -- price 15
	["misc_canister"] = 10, -- price 10
	["misc_plate"] = 50, -- price 2
	["newspaper"] = 1, -- price 100
	["resin"] = 20, -- price 5
	["comp_combine_steel"] = 20, -- price 5
	["misc_ashtray"] = 33, -- price 3
	["zucchini"] = 6, -- price 15
	["apple"] = 3, -- price 30
	["banana"] = 2, -- price 35
	["orange"] = 5, -- price 20
	["pear"] = 5, -- price 20
	["pineapple"] = 2, -- price 45
	["potato"] = 10, -- price 10
	["watermelon_slice"] = 10, -- price 10
	["sauce"] = 20, -- price 5
	["junk_fork"] = 50, -- price 2
	["junk_knife"] = 100, -- price 1
	["junk_payphone_receiver"] = 20, -- price 5
	["junk_plasticbox"] = 50, -- price 2
	["junk_spraycan"] = 33, -- price 3
	["junk_the_terminal"] = 10, -- price 10
	["junk_waste_paper"] = 50, -- price 2
	["coin"] = 100, -- price 1
	["pesticide"] = 2, -- price 50
	["watering_can"] = 1, -- price 60
}

PLUGIN.randomLoot.rare = {
	["resin"] = 5,
	["comp_combine_steel"] = 5,
	["antlion_grub"] = 1,
	["gin"] = 2,
	["whiskey"] = 2,
	["bourbon"] = 2,
	["antidepressants"] = 2,
	["comp_ballisticfiber"] = 2,
	["comp_circuitry"] = 3,
	["comp_crystal"] = 2,
	["comp_fiberglass"] = 2,
	["comp_fiberoptic"] = 2,
	["comp_gold"] = 1,
	-- ["comp_nuclear"] = 1,
	["comp_silver"] = 1,
	["misc_gunpowder"] = 2,
	["battery"] = 3,
	["book"] = 3,
	["emp"] = 1,
	["flashlight"] = 3,
	["handheld_radio"] = 1,
	["walkietalkie"] = 1,
	["unionkey"] = 1,
	["bag"] = 1,
	["satchel"] = 1,
	["suitcase"] = 1,
	-- ["pistol"] = 1,
	-- ["pistolammo"] = 1,
	["health_vial"] = 1,
	["headcrab"] = 3,
	["medkit"] = 2,
	["pot"] = 1,
	["pan"] = 1,
	["pipe"] = 1,
	["axe"] = 1,
	["bottle_shard"] = 3,
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
	["misc_gunparts_pistol"] = 1,
	["misc_gunparts_rifle"] = 1,
	["misc_gunparts_shotgun"] = 1,
	["misc_gunparts_smg"] = 1,
	["citizen_gasmask"] = 1,
	["gasmask_filter"] = 1,
	["extinguisher"] = 2,
	["prewar_ration"] = 1,
	["sandwich"] = 1,
	["egg_raw"] = 1,
	["pot_large"] = 1,
	["duffle_bag"] = 1,
	["flare"] = 1,
	["shovel"] = 1,
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
