local PLUGIN = PLUGIN
PLUGIN.name = "Helios Outfits"
PLUGIN.author = "Helios"
PLUGIN.desc = "Fixes some issues with Helix's builtin outfit system."

function PLUGIN:CharacterVarChanged(character, key, oldValue, value)
	if (key == "model") then
		local client = character:GetPlayer()

		if (IsValid(client)) then
			local inventory = character:GetInventory()

			if (inventory) then
				local items = inventory:GetItems()

				-- Check if any equipped item is currently overriding the model.
				-- If so, we skip the allowedModels check because the player is "disguised" or in a suit.
				for _, item in pairs(items) do
					if (item:GetData("equip") and item.outfitCategory) then
						if (character:GetData("oldModel" .. item.outfitCategory)) then
							return
						end
					end
				end

				for _, item in pairs(items) do
					if (item:GetData("equip") and item.outfitCategory and item.allowedModels) then
						if (!table.HasValue(item.allowedModels, value)) then
							item:RemoveOutfit(client)
						end
					end
				end
			end
		end
	end
end