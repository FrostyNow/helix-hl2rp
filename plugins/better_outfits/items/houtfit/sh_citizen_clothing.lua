
local PLUGIN = PLUGIN

local function DefineCitizenClothing()
	local citizenModels = {
		"models/humans/pandafishizens/male_01.mdl",
		"models/humans/pandafishizens/male_02.mdl",
		"models/humans/pandafishizens/male_03.mdl",
		"models/humans/pandafishizens/male_04.mdl",
		"models/humans/pandafishizens/male_05.mdl",
		"models/humans/pandafishizens/male_06.mdl",
		"models/humans/pandafishizens/male_07.mdl",
		"models/humans/pandafishizens/male_08.mdl",
		"models/humans/pandafishizens/male_09.mdl",
		"models/humans/pandafishizens/male_10.mdl",
		"models/humans/pandafishizens/male_11.mdl",
		"models/humans/pandafishizens/male_12.mdl",
		"models/humans/pandafishizens/male_15.mdl",
		"models/humans/pandafishizens/male_16.mdl",
		"models/humans/pandafishizens/female_01.mdl",
		"models/humans/pandafishizens/female_02.mdl",
		"models/humans/pandafishizens/female_03.mdl",
		"models/humans/pandafishizens/female_04.mdl",
		"models/humans/pandafishizens/female_06.mdl",
		"models/humans/pandafishizens/female_07.mdl",
		"models/humans/pandafishizens/female_11.mdl",
		"models/humans/pandafishizens/female_17.mdl",
		"models/humans/pandafishizens/female_18.mdl",
		"models/humans/pandafishizens/female_19.mdl",
		"models/humans/pandafishizens/female_24.mdl"
	}

	local items = {
		-- Torso
		{id = "short_sleeve_top", category = "torso", index = 1, model = "models/tnb/items/aphelion/shirt_citizen1.mdl", price = 50},
		{id = "cwu_uniform_top", category = "torso", index = 2, model = "models/tnb/items/aphelion/shirt_citizen1.mdl", skin = 2, price = 120},
		{id = "cwu_medical_worker_uniform_top", category = "torso", index = 3, model = "models/tnb/items/aphelion/shirt_citizen1.mdl", skin = 2, price = 120},
		{id = "cwu_doctor_uniform_top", category = "torso", index = 4, model = "models/tnb/items/aphelion/shirt_citizen1.mdl", skin = 2, price = 120},
		{id = "cwu_uniform_top_orange", category = "torso", index = 5, model = "models/tnb/items/aphelion/shirt_citizen1.mdl", skin = 2, price = 120},
		{id = "cwu_uniform_top_blue", category = "torso", index = 6, model = "models/tnb/items/aphelion/shirt_citizen1.mdl", skin = 2, price = 120},
		{id = "cwu_uniform_top_yellow", category = "torso", index = 7, model = "models/tnb/items/aphelion/shirt_citizen1.mdl", skin = 2, price = 120},
		{id = "green_shirt", category = "torso", index = 8, model = "models/tnb/items/aphelion/shirt_citizen2.mdl", skin = 1, price = 50},
		{id = "camo_short_sleeve_shirt", category = "torso", index = 9, model = "models/tnb/items/aphelion/shirt_citizen1.mdl", skin = 2, price = 60},
		{id = "beige_shirt_grey_collar", category = "torso", index = 10, model = "models/props_c17/SuitCase_Passenger_Physics.mdl", price = 50},
		{id = "light_green_shirt_grey_collar", category = "torso", index = 11, model = "models/props_c17/SuitCase_Passenger_Physics.mdl", price = 50},
		{id = "white_shirt_grey_collar", category = "torso", index = 12, model = "models/props_c17/SuitCase_Passenger_Physics.mdl", price = 50},
		{id = "turquoise_shirt_grey_collar", category = "torso", index = 13, model = "models/props_c17/SuitCase_Passenger_Physics.mdl", price = 50},
		{id = "black_jacket", category = "torso", index = 14, model = "models/tnb/items/aphelion/shirt_citizen1.mdl", skin = 3, price = 80},
		{id = "black_jacket_unzipped", category = "torso", index = 15, model = "models/tnb/items/aphelion/shirt_citizen2.mdl", skin = 3, price = 80},
		{id = "red_plaid_shirt", category = "torso", index = 16, model = "models/props_c17/SuitCase_Passenger_Physics.mdl", price = 50},
		{id = "white_shirt", category = "torso", index = 17, model = "models/props_c17/SuitCase_Passenger_Physics.mdl", price = 50},
		{id = "skyblue_shirt", category = "torso", index = 18, model = "models/props_c17/SuitCase_Passenger_Physics.mdl", price = 50},
		{id = "grey_shirt_with_red_cross_armband", category = "torso", index = 19, model = "models/props_c17/SuitCase_Passenger_Physics.mdl", price = 60},
		{id = "grey_winter_coat", category = "torso", index = 20, model = "models/tnb/items/aphelion/wintercoat.mdl", price = 100},
		{id = "dark_grey_winter_coat", category = "torso", index = 21, model = "models/tnb/items/aphelion/wintercoat.mdl", price = 100},
		{id = "skyblue_grey_gortex", category = "torso", index = 22, model = "models/props_c17/SuitCase_Passenger_Physics.mdl", price = 100},
		{id = "turquoise_black_gortex", category = "torso", index = 23, model = "models/props_c17/SuitCase_Passenger_Physics.mdl", price = 100},
		{id = "black_red_gortex", category = "torso", index = 24, model = "models/props_c17/SuitCase_Passenger_Physics.mdl", price = 100},
		{id = "beige_shirt_cmb", category = "torso", index = 25, model = "models/props_c17/SuitCase_Passenger_Physics.mdl", price = 50, noBusiness = true},
		{id = "grey_shirt_cmb", category = "torso", index = 26, model = "models/props_c17/SuitCase_Passenger_Physics.mdl", price = 50, noBusiness = true},
		{id = "black_jacket_variant", category = "torso", index = 27, model = "models/props_c17/SuitCase_Passenger_Physics.mdl", price = 80},
		{id = "dark_orange_shirt_cmb", category = "torso", index = 28, model = "models/props_c17/SuitCase_Passenger_Physics.mdl", price = 50, noBusiness = true},
		{id = "lab_coat", category = "torso", index = 29, model = "models/props_c17/SuitCase_Passenger_Physics.mdl", price = 120},
		{id = "skyblue_lab_coat", category = "torso", index = 30, model = "models/props_c17/SuitCase_Passenger_Physics.mdl", price = 120},
		{id = "fur_collar_brown_winter_quilted_padding", category = "torso", index = 31, model = "models/props_c17/SuitCase_Passenger_Physics.mdl", price = 120},
		{id = "fur_collar_skyblue_winter_quilted_padding", category = "torso", index = 32, model = "models/props_c17/SuitCase_Passenger_Physics.mdl", price = 120},
		{id = "woodland_combat_uniform", category = "torso", index = 33, model = "models/props_c17/SuitCase_Passenger_Physics.mdl", price = 500, noBusiness = true},
		{id = "dark_brown_long_coat", category = "torso", index = 34, model = "models/props_c17/SuitCase_Passenger_Physics.mdl", price = 150},
		{id = "black_long_coat", category = "torso", index = 35, model = "models/props_c17/SuitCase_Passenger_Physics.mdl", price = 150},
		{id = "dark_brown_suit_top", category = "torso", index = 36, model = "models/props_c17/SuitCase_Passenger_Physics.mdl", price = 150},
		{id = "black_suit_top", category = "torso", index = 37, model = "models/props_c17/SuitCase_Passenger_Physics.mdl", price = 150},

		-- Legs
		{id = "grey_jeans", category = "legs", index = 1, model = "models/tnb/items/aphelion/pants_citizen.mdl", skin = 1, price = 50},
		{id = "dark_green_pants_stripe", category = "legs", index = 2, model = "models/tnb/items/aphelion/pants_citizen.mdl", skin = 3, price = 50},
		{id = "dark_blue_pants_stripe", category = "legs", index = 3, model = "models/tnb/items/aphelion/pants_citizen.mdl", skin = 3, price = 50},
		{id = "black_pants_stripe", category = "legs", index = 4, model = "models/tnb/items/aphelion/pants_citizen.mdl", skin = 3, price = 50},
		{id = "black_cargo_pants", category = "legs", index = 5, model = "models/tnb/items/aphelion/pants_citizen.mdl", skin = 2, price = 60},
		{id = "black_camo_pants", category = "legs", index = 6, model = "models/props_c17/SuitCase_Passenger_Physics.mdl", price = 60},
		{id = "dark_brown_pants", category = "legs", index = 7, model = "models/tnb/items/aphelion/pants_citizen.mdl", skin = 2, price = 50},
		{id = "woodland_combat_uniform_legs", category = "legs", index = 8, model = "models/tnb/items/aphelion/pants_rebel.mdl", price = 300, noBusiness = true},
		{id = "black_pants_and_boots", category = "legs", index = 9, model = "models/tnb/items/aphelion/pants_rebel.mdl", skin = 1, price = 60},
		{id = "black_pants", category = "legs", index = 10, model = "models/tnb/items/aphelion/pants_citizen.mdl", skin = 1, price = 50},
		{id = "light_jeans", category = "legs", index = 11, model = "models/tnb/items/aphelion/pants_citizen.mdl", skin = 1, price = 50},
		{id = "dark_green_pants_padded", category = "legs", index = 12, model = "models/tnb/items/aphelion/pants_rebel.mdl", price = 300, noBusiness = true},
		{id = "black_digital_camo_pants_padded", category = "legs", index = 13, model = "models/tnb/items/aphelion/pants_rebel.mdl", skin = 1, price = 300, noBusiness = true},
		{id = "jeans_padded", category = "legs", index = 14, model = "models/tnb/items/aphelion/pants_rebel.mdl", skin = 1, price = 300, noBusiness = true},
		{id = "black_pants_padded", category = "legs", index = 15, model = "models/tnb/items/aphelion/pants_rebel.mdl", skin = 1, price = 300, noBusiness = true},
		{id = "dark_green_pants_sneakers", category = "legs", index = 16, model = "models/tnb/items/aphelion/pants_citizen.mdl", skin = 1, price = 50},
		{id = "black_pants_sneakers", category = "legs", index = 17, model = "models/tnb/items/aphelion/pants_citizen.mdl", skin = 1, price = 50},
		{id = "dark_brown_suit_bottom", category = "legs", index = 18, model = "models/props_c17/SuitCase_Passenger_Physics.mdl", price = 100},
		{id = "black_suit_bottom", category = "legs", index = 19, model = "models/props_c17/SuitCase_Passenger_Physics.mdl", price = 100},

		-- Hands
		{id = "fingerless_gloves", category = "hands", index = 1, model = "models/tnb/items/aphelion/gloves.mdl", price = 30},
		{id = "gloves", category = "hands", index = 2, model = "models/tnb/items/aphelion/gloves.mdl", price = 40},
		{id = "surgical_gloves", category = "hands", index = 3, model = "models/tnb/items/aphelion/gloves.mdl", price = 30},
		{id = "gold_ring", category = "hands", index = 4, model = "models/props_junk/cardboard_box004a.mdl", price = 500},

		-- Headgear
		{id = "dark_grey_beanie", category = "headgear", index = 1, model = "models/tnb/items/aphelion/beanie.mdl", price = 30},
		{id = "green_beanie", category = "headgear", index = 2, model = "models/tnb/items/aphelion/beanie.mdl", price = 30},
		{id = "black_beanie", category = "headgear", index = 3, model = "models/tnb/items/aphelion/beanie.mdl", price = 30},
		{id = "dark_blue_beanie", category = "headgear", index = 4, model = "models/tnb/items/aphelion/beanie.mdl", price = 30},
		{id = "field_cap", category = "headgear", index = 5, model = "models/props_junk/cardboard_box004a.mdl", price = 30},
		{id = "boonie_hat", category = "headgear", index = 6, model = "models/props_junk/cardboard_box004a.mdl", price = 30},
		{id = "blue_ballcap", category = "headgear", index = 7, model = "models/props_junk/cardboard_box004a.mdl", price = 30},
		{id = "flat_cap", category = "headgear", index = 8, model = "models/props_junk/cardboard_box004a.mdl", price = 30},
		{id = "hard_helmet", category = "headgear", index = 9, model = "models/props_junk/cardboard_box004a.mdl", price = 50},
		{id = "ushanka", category = "headgear", index = 10, model = "models/props_junk/cardboard_box004a.mdl", price = 50},
		{id = "brown_flat_cap", category = "headgear", index = 11, model = "models/props_junk/cardboard_box004a.mdl", price = 30},
		{id = "combat_helmet", category = "headgear", index = 12, model = "models/props_junk/cardboard_box004a.mdl", price = 200, noBusiness = true, base = "base_armor", armorAmount = 30, damage = {.9, .9, .9, .9, .9, .9, .9}, hitGroups = {HITGROUP_HEAD}},

		-- Bag
		{id = "backpack", category = "bag", index = 1, model = "models/props_junk/cardboard_box004a.mdl", price = 100, isBag = true, invWidth = 3, invHeight = 2},

		-- Glasses
		{id = "glasses", category = "glasses", index = 1, model = "models/props_junk/cardboard_box004a.mdl", price = 80},
		{id = "goggles", category = "glasses", index = 2, model = "models/props_junk/cardboard_box004a.mdl", price = 100},
		{id = "sunglasses", category = "glasses", index = 3, model = "models/props_junk/cardboard_box004a.mdl", price = 80},

		-- Satchel
		{id = "satchel", category = "satchel", index = 1, model = "models/props_junk/cardboard_box004a.mdl", price = 80, isBag = true, invWidth = 2, invHeight = 2},

		-- Headstrap
		{id = "mask", category = "headstrap", index = 1, model = "models/props_junk/cardboard_box004a.mdl", price = 20},
		{id = "dust_mask", category = "headstrap", index = 2, model = "models/props_junk/cardboard_box004a.mdl", price = 20},
		{id = "gasmask", category = "headstrap", index = 3, model = "models/tnb/items/aphelion/gasmask.mdl", price = 200, noBusiness = true, base = "base_armor", gasmask = true, hitGroups = {HITGROUP_HEAD}},
		{id = "red_shemagh", category = "headstrap", index = 4, model = "models/tnb/items/aphelion/facewrap.mdl", price = 50, noBusiness = true},
		{id = "blue_shemagh", category = "headstrap", index = 5, model = "models/tnb/items/aphelion/facewrap.mdl", skin = 1, price = 50, noBusiness = true},
		{id = "black_shemagh", category = "headstrap", index = 6, model = "models/tnb/items/aphelion/facewrap.mdl", skin = 1, price = 50, noBusiness = true},

		-- Kevlar
		{id = "cp_vest", category = "kevlar", index = 1, model = "models/tnb/items/aphelion/shirt_rebelmetrocop.mdl", price = 500, noBusiness = true, base = "base_armor", armorAmount = 50, damage = {.75, .75, .75, .75, .75, .75, .75}, hitGroups = {HITGROUP_CHEST, HITGROUP_STOMACH}},
		{id = "cp_vest_medic", category = "kevlar", index = 2, model = "models/tnb/items/aphelion/shirt_rebel1.mdl", price = 500, noBusiness = true, base = "base_armor", armorAmount = 50, damage = {.75, .75, .75, .75, .75, .75, .75}, hitGroups = {HITGROUP_CHEST, HITGROUP_STOMACH}},
		{id = "cp_vest_rebel", category = "kevlar", index = 3, model = "models/tnb/items/aphelion/shirt_rebel1.mdl", price = 500, noBusiness = true, base = "base_armor", armorAmount = 50, damage = {.75, .75, .75, .75, .75, .75, .75}, hitGroups = {HITGROUP_CHEST, HITGROUP_STOMACH}},
		{id = "combat_vest", category = "kevlar", index = 4, model = "models/props_junk/cardboard_box004a.mdl", price = 500, noBusiness = true, base = "base_armor", armorAmount = 50, damage = {.75, .75, .75, .75, .75, .75, .75}, hitGroups = {HITGROUP_CHEST, HITGROUP_STOMACH}},
		{id = "molle_vest", category = "kevlar", index = 5, model = "models/tnb/items/aphelion/shirt_rebel_molle.mdl", price = 500, noBusiness = true, base = "base_armor", armorAmount = 50, damage = {.75, .75, .75, .75, .75, .75, .75}, hitGroups = {HITGROUP_CHEST, HITGROUP_STOMACH}},
		{id = "overwatch_vest", category = "kevlar", index = 6, model = "models/tnb/items/aphelion/shirt_rebeloverwatch.mdl", price = 600, noBusiness = true, base = "base_armor", armorAmount = 60, damage = {.7, .7, .7, .7, .7, .7, .7}, hitGroups = {HITGROUP_CHEST, HITGROUP_STOMACH}},
		{id = "flak_jacket", category = "kevlar", index = 7, model = "models/props_junk/cardboard_box004a.mdl", price = 500, noBusiness = true, base = "base_armor", armorAmount = 40, damage = {.8, .8, .8, .8, .8, .8, .8}, hitGroups = {HITGROUP_CHEST, HITGROUP_STOMACH}},

		-- Belt
		{id = "cp_belt", category = "belt", index = 1, model = "models/props_junk/cardboard_box004a.mdl", price = 50, noBusiness = true},
		{id = "pistol_belt", category = "belt", index = 2, model = "models/props_junk/cardboard_box004a.mdl", price = 50, noBusiness = true},

		-- Armband
		{id = "armpad_lambda", category = "armband", index = 1, model = "models/props_junk/cardboard_box004a.mdl", price = 100, noBusiness = true},
		{id = "armpad", category = "armband", index = 2, model = "models/props_junk/cardboard_box004a.mdl", price = 100, noBusiness = true}
	}

	for _, v in ipairs(items) do
		local oldITEM = ITEM
		local ITEM = ix.item.Register(v.id, v.base or "base_houtfit", false, nil, true)
		ITEM.base = v.base or "base_houtfit"
		ITEM.name = v.id
		ITEM.description = v.id .. "_desc"
		ITEM.model = v.model
		ITEM.skin = v.skin or 0
		ITEM.width = 1
		ITEM.height = 1
		ITEM.price = v.price or 50
		ITEM.outfitCategory = v.category
		ITEM.bodyGroups = {
			[v.category] = v.index
		}
		ITEM.allowedModels = citizenModels

		ITEM.isBag = v.isBag or false
		ITEM.invWidth = v.invWidth or 2
		ITEM.invHeight = v.invHeight or 2

		if (ITEM.isBag) then
			ITEM:OnRegistered()
		end
		
		if (v.noBusiness) then
			ITEM.noBusiness = true
		end

		ITEM.noResetBodyGroups = true
		
		if (v.base == "base_armor") then
			ITEM.armorAmount = v.armorAmount or 0
			ITEM.damage = v.damage or {1, 1, 1, 1, 1, 1, 1}
			ITEM.gasmask = v.gasmask or false
			if (v.gasmask or v.damage) then
				ITEM.resistance = true
			end
			ITEM.hitGroups = v.hitGroups
		end

		if (CLIENT) then
			function ITEM:PopulateTooltip(tooltip)
				local labelColor = nil
				local labelText = nil

				if (string.find(self.uniqueID, "cp_") and !string.find(self.uniqueID, "rebel")) or string.find(self.uniqueID, "overwatch") or string.find(self.uniqueID, "cmb") or (string.find(self.uniqueID, "armpad") and !string.find(self.uniqueID, "lambda")) then
					labelColor = Color(85, 127, 242)
					labelText = "securitizedItemTooltip"
				elseif string.find(self.uniqueID, "rebel") or string.find(self.uniqueID, "lambda") or string.find(self.uniqueID, "combat") or string.find(self.uniqueID, "molle") or string.find(self.uniqueID, "flak") or string.find(self.uniqueID, "shemagh") or string.find(self.uniqueID, "gasmask") then
					labelColor = Color(218, 24, 24)
					labelText = "sociocidalItemTooltip"
				end

				if (labelColor and labelText) then
					local data = tooltip:AddRow("data")
					data:SetBackgroundColor(labelColor)
					data:SetText(L(labelText))
					data:SetExpensiveShadow(0.5)
					data:SizeToContents()
				end
			end
		end

		_G.ITEM = oldITEM
	end
end

DefineCitizenClothing()
