
local PLUGIN = PLUGIN

PLUGIN.name = "Clear Redundant Items"
PLUGIN.author = "Frosty"
PLUGIN.description = "Add a concommand to remove non-existent items from character database."

PLUGIN.license = [[
Copyright © 2026 Frosty

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/
]]

if (SERVER) then
	concommand.Add("ix_clear_redundant_items", function(ply, cmd, args)
		if (IsValid(ply) and !ply:IsSuperAdmin()) then
			ply:ChatPrint("You do not have permission to run this command.")
			return
		end

		local validItems = {}
		for k, v in pairs(ix.item.list) do
			validItems[k] = true
		end

		if (IsValid(ply)) then
			ply:ChatPrint("Checking database for redundant items...")
		else
			print("Checking database for redundant items...")
		end

		-- Query all items from the database to find those with unknown uniqueIDs
		local selectQuery = mysql:Select("ix_items")
		selectQuery:Select("item_id")
		selectQuery:Select("unique_id")
		selectQuery:Callback(function(result)
			if (istable(result) and #result > 0) then
				local toDeleteCount = 0
				local toDeleteIds = {}

				for _, v in ipairs(result) do
					if (!validItems[v.unique_id]) then
						toDeleteCount = toDeleteCount + 1
						toDeleteIds[#toDeleteIds + 1] = v.item_id
					end
				end

				if (toDeleteCount > 0) then
					-- Delete redundant items in chunks if necessary (to evitar long queries)
					-- But for most cases, a single WhereIn is fine.
					local deleteQuery = mysql:Delete("ix_items")
					deleteQuery:WhereIn("item_id", toDeleteIds)
					deleteQuery:Callback(function()
						local msg = "Successfully deleted " .. toDeleteCount .. " redundant items from the database."
						if (IsValid(ply)) then
							ply:ChatPrint(msg)
						else
							print(msg)
						end
						
						-- Log the deleted uniqueIDs for reference
						if (toDeleteCount < 100) then
							-- Just for debugging purposes
						end
					end)
					deleteQuery:Execute()
				else
					local msg = "No redundant items found in the database."
					if (IsValid(ply)) then
						ply:ChatPrint(msg)
					else
						print(msg)
					end
				end
			else
				local msg = "No items found in the database."
				if (IsValid(ply)) then
					ply:ChatPrint(msg)
				else
					print(msg)
				end
			end
		end)
		selectQuery:Execute()

		-- Also clear redundant items from currently loaded inventories
		local liveCount = 0
		for _, inventory in pairs(ix.item.inventories) do
			if (inventory.slots) then
				for x, row in pairs(inventory.slots) do
					for y, item in pairs(row) do
						-- If item is a table (object) and uniqueID is missing from list
						if (item and item.uniqueID and !validItems[item.uniqueID]) then
							row[y] = nil
							liveCount = liveCount + 1
						end
					end
				end
			end
		end

		if (liveCount > 0) then
			local msg = "Cleared " .. liveCount .. " redundant item instances from active inventories."
			if (IsValid(ply)) then
				ply:ChatPrint(msg)
			else
				print(msg)
			end
		end
	end)
end