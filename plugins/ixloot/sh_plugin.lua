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

-- doubled the items in the table so that they are more common than anything else. If you get what I mean.
PLUGIN.randomLoot = {}
PLUGIN.randomLoot.common = {
	"acid",
	"acid",
	"adhesive",
	"adhesive",
	"adhesive",
	"adhesive",
	"aluminium",
	"aluminium",
	"bucket",
	"bucket",
	"cafeteriatray",
	"cafeteriatray",
	"camera",
	"cigarettecarton",
	"cigarettecarton",
	"cigarettepack",
	"cigarettepack",
	"cigarettepack",
	"cloth",
	"cloth",
	"cloth",
	"cloth",
	"cloth",
	"coffeecup",
	"coffeecup",
	"coffeecup",
	"coffeecup",
	"coffeepot",
	"coffeepot",
	"coffeepot",
	"coffeepot",
	"ducttape",
	"ducttape",
	"empty_can",
	"empty_can",
	"empty_can",
	"empty_can",
	"empty_can",
	"empty_can",
	"fryingpan",
	"fryingpan",
	"glass",
	"glass",
	"glass",
	"glass",
	"hotplate",
	"leather",
	"leather",
	"money",
	"money",
	"money",
	"oil",
	"oil",
	"oil",
	"oil",
	"pan",
	"pan",
	"plastic",
	"plastic",
	"plastic",
	"plastic",
	"pressurecooker",
	"pressurecooker",
	"request_device",
	"sensormodule",
	"sensormodule",
	"steel",
	"steel",
	"steel",
	"steel",
	"turpentine",
	"turpentine",
	"turpentine",
	"water_empty",
	"water_empty",
	"water_empty",
	"water_empty",
	"water_empty",
	"water_empty",
	"water_sparkling_empty",
	"water_sparkling_empty",
	"water_sparkling_empty",
	"water_sparkling_empty",
	"water_special_empty",
	"water_special_empty",
	"water_special_empty",
	"wood",
	"wood",
	"wood",
	"wood",
	"wood",
	"wrench",
}

PLUGIN.randomLoot.rare = {
	"antidepressants",
	"antidepressants",
	"antidepressants",
	"ballisticfiber",
	"ballisticfiber",
	"battery",
	"battery",
	"battery",
	"book",
	"book",
	"book",
	"emp",
	"gunpowder",
	"gunpowder",
	"gunpowder",
	"phone",
	"handheld_radio",
}

ix.util.Include("sv_plugin.lua")

ix.lang.AddTable("english", {
	ixlootNotEating = "You cannot loot anything while you are eating!",
	ixlootNoItem = "There is nothing in the container!",
	ixlootNotFaction = "Your Faction is not allowed to loot containers.",
	ixlootGained = "You have gained %s.",
})
ix.lang.AddTable("korean", {
	ixlootNotEating = "뭔가를 먹고 있을 때는 살펴볼 수 없습니다!",
	ixlootNoItem = "아무것도 들어있지 않습니다!",
	ixlootNotFaction = "해당 세력은 보관함을 살펴볼 수 없습니다.",
	ixlootGained = "다음을 얻었습니다: %s.",
})

if ( CLIENT ) then
	function PLUGIN:PopulateEntityInfo(ent, tooltip)
		local ply = LocalPlayer()
		local ent = ent:GetClass()

		if ( ply:IsCombine() or ply:IsDispatch() ) then
			return false
		end

		if not ( ent:find("ix_loot") ) then
			return false
		end

		local title = tooltip:AddRow("loot")
		title:SetText("Lootable Container")
		title:SetImportant()
		title:SizeToContents()
	end
end
