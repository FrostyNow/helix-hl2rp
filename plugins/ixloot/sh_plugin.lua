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
	"bucket",
	"comp_adhesive",
	"comp_acid",
	"comp_aluminium",
	"comp_antiseptic",
	-- "comp_bone",
	"comp_ceramic",
	"comp_steel",
	"comp_concrete",
	"comp_cloth",
	"comp_copper",
	"comp_cork",
	"comp_fertilizer",
	"comp_gears",
	"comp_glass",
	"comp_lead",
	"comp_leather",
	"comp_oil",
	"comp_plastic",
	"comp_rubber",
	"comp_screw",
	"comp_spring",
	"comp_wood",
	"glass_bottle_generic",
	"misc_hide",
	"misc_battery",
	"misc_charcoal",
	"misc_dried_eggprotein",
	"misc_dried_spices",
	"misc_dried_tea",
	"misc_dried_vegetable",
	"misc_margarine",
	"misc_plank",
	"misc_buttercup",
	"misc_cafeteriatray",
	"misc_camera",
	"misc_cigarettecarton",
	"misc_cigarettepack",
	"misc_ducttape",
	"misc_glue",
	"misc_hotplate",
	"misc_telephone",
	"misc_coffeecup",
	"misc_turpentine",
	"misc_money",
	"misc_plasticbottle",
	"misc_tool_coffeepot",
	"misc_tool_hammer",
	"misc_tool_pressurecooker",
	"misc_tool_screwdriver",
	"misc_tool_wrench",
	"empty_can",
	"flashlight",
	"request_device",
	"shot_glass",
	"water_empty",
	"book",
	"water",
	"water_sparkling",
	"water_special",
	"beer",
	"vodka",
	"moonshine",
	"wine",
	"bandage",
	"canned_ham",
	"canned_soup",
	"paper",
	"note",
	"ration",
	"coke_bottle",
	"carrot",
	"onion",
	"bleach",
	"chinese_takeout",
	"chocolate",
	"corn",
	"milk",
	"mineral_water",
	"pepsi",
	"headcrab",
	"tomato",
	"coke_bottle_empty",
	"ration_token",
	"coupon",
	"coffee_beans",
	"vegetable_oil",
	"misc_canister",
	"misc_plate",
	"newspaper",
	"resin",
	"comp_combine_steel",
	"misc_ashtray",
	"zucchini",
	"apple",
	"banana",
	"orange",
	"pear",
	"pineapple",
	"potato",
	"watermelon_slice",
	"sauce",
	"junk_fork",
	"junk_knife",
	"junk_payphone_receiver",
	"junk_plasticbox",
	"junk_spraycan",
	"junk_the_terminal",
	"junk_waste_paper",
	"coin",
	"pesticide",
	"watering_can",
	"lottery",
}

PLUGIN.randomLoot.rare = {
	"resin",
	"comp_combine_steel",
	"antlion_grub",
	"gin",
	"whiskey",
	"bourbon",
	"antidepressants",
	"comp_ballisticfiber",
	"comp_circuitry",
	"comp_crystal",
	"comp_fiberglass",
	"comp_fiberoptic",
	"comp_gold",
	-- "comp_nuclear",
	"comp_silver",
	"misc_gunpowder",
	"battery",
	"book",
	"emp",
	"flashlight",
	"handheld_radio",
	"walkietalkie",
	"unionkey",
	"bag",
	"satchel",
	"suitcase",
	-- "pistol",
	-- "pistolammo",
	"health_vial",
	"headcrab",
	"medkit",
	"pot",
	"pan",
	"pipe",
	"axe",
	"bottle_shard",
	"manhack",
	"manhack_gib01",
	"manhack_gib02",
	"manhack_gib03",
	"manhack_gib04",
	"manhack_gib05",
	"scanner_gib01",
	"scanner_gib02",
	"scanner_gib04",
	"scanner_gib05",
	"misc_gunparts_pistol",
	"misc_gunparts_rifle",
	"misc_gunparts_shotgun",
	"misc_gunparts_smg",
	"citizen_gasmask",
	"gasmask_filter",
	"extinguisher",
	"prewar_ration",
	"sandwich",
	"egg_raw",
	"pot_large",
	"duffle_bag",
	"flare",
	"shovel",
	"lottery_box",
	"pager",
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
