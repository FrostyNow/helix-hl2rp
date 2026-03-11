ITEM.name = "Night Vision"
ITEM.description = "nvgogDesc"
ITEM.model = "models/props_junk/cardboard_box004a.mdl"
ITEM.price = 110000
ITEM.width = 1
ITEM.height = 1
ITEM.outfitCategory = "goggles"

ITEM.pacData = {
	[1] = {
		["children"] = {
			[1] = {
				["children"] = {
				},
				["self"] = {
					["Angles"] = Angle(7.5132084020879e-05, -75, -90.000007629395),
					["Position"] = Vector(4.640625, 1.3984375, 0),
					["ClassName"] = "model",
					["Model"] = "models/warz/civinvg.mdl",
					["UniqueID"] = "NV_MODEL",
				},
			},
		},
		["self"] = {
			["EditorExpand"] = true,
			["UniqueID"] = "NIGHTVISION",
			["ClassName"] = "group",
			["Name"] = "my outfit",
			["Description"] = "add parts to me!",
		},
	},
}

local function OnEquipped(item)
	if (item:GetData("equip")) then
		netstream.Start(item.player, "ixNVToggle", true)
		item.player:ScreenFade(1, Color(255, 255, 255, 100), .4, 0)
	end
end

local function OnUnequipped(item)
	if (!item:GetData("equip")) then
		netstream.Start(item.player, "ixNVToggle", false)
		item.player:ScreenFade(1, Color(255, 255, 255, 100), .4, 0)
	end
end

ITEM:PostHook("Equip", OnEquipped)
ITEM:PostHook("EquipUn", OnUnequipped)
