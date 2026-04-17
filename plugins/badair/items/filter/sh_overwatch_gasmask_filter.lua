ITEM.name = "Overwatch Gasmask Filter"
ITEM.description = "itemOverwatchGasmaskFilterDesc"
ITEM.model = "models/willardnetworks/props/cpfilter.mdl"
ITEM.price = 80
ITEM.maxDurability = 200

if (SERVER) then
	local function SetFilterBodygroup(client, bEquipped)
		if (!IsValid(client)) then return end

		local index = client:FindBodygroupByName("Filter")

		if (index != -1) then
			client:SetBodygroup(index, bEquipped and 0 or 1)
		end
	end

	local function IsOTAFilterUser(client)
		local badair = ix.plugin.Get("badair")
		return badair and IsValid(client) and badair:CanEquipInternalFilter(client)
	end

	local function SyncFilterBodygroup(client)
		if (!IsOTAFilterUser(client)) then return end

		local char = client:GetCharacter()
		if (!char) then return end

		local badair = ix.plugin.Get("badair")
		local activeFilter = badair:GetEquippedBadAirProtectionItem(char, function(item)
			return item.isGasmaskFilter == true
		end)

		SetFilterBodygroup(client, activeFilter != nil)
	end

	hook.Add("OnItemEquipped", "ixOWFilterBodygroup", function(item, client)
		if (!item.isGasmaskFilter or !IsOTAFilterUser(client)) then return end
		SetFilterBodygroup(client, true)
	end)

	hook.Add("OnItemUnequipped", "ixOWFilterBodygroup", function(item, client)
		if (!item.isGasmaskFilter or !IsOTAFilterUser(client)) then return end
		SetFilterBodygroup(client, false)
	end)

	hook.Add("CharacterLoaded", "ixOWFilterBodygroupLoad", function(character)
		local player = character:GetPlayer()

		timer.Simple(0.1, function()
			if (IsValid(player)) then
				SyncFilterBodygroup(player)
			end
		end)
	end)
end
