ITEM.name = "IR Night Vision"
ITEM.description = "irnvGogDesc"
ITEM.model = "models/props_junk/cardboard_box004a.mdl"
ITEM.price = 250000
ITEM.width = 1
ITEM.height = 1
ITEM.outfitCategory = "goggles"
ITEM.blocksFlashlight = true

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
					["Model"] = "models/warz/miltnvg.mdl",
					["UniqueID"] = "IRNV_MODEL",
				},
			},
		},
		["self"] = {
			["EditorExpand"] = true,
			["UniqueID"] = "IRNV",
			["ClassName"] = "group",
			["Name"] = "my outfit",
			["Description"] = "add parts to me!",
		},
	},
}

local function OnEquipped(item, result)
	if (item:GetData("equip")) then
		netstream.Start(item.player, "ixFLIRToggle", true)
		item.player:ScreenFade(1, Color(255, 255, 255, 100), .4, 0)
	end
end

local function OnUnequipped(item, result)
	if (!item:GetData("equip")) then
		netstream.Start(item.player, "ixFLIRToggle", false)
		item.player:ScreenFade(1, Color(255, 255, 255, 100), .4, 0)
	end
end

ITEM:PostHook("Equip", OnEquipped)
ITEM:PostHook("EquipUn", OnUnequipped)
