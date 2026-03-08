
ITEM.name = "Empty Bottle"
ITEM.description = "itemEmptyBottleDesc"
ITEM.price = 4
ITEM.model = "models/props_junk/garbage_glassbottle003a.mdl"
ITEM.isjunk = true
ITEM.isStackable = true

-- obsolete
-- ITEM.functions.Use = {
-- 	name = "Break",
-- 	icon = "icon16/arrow_inout.png",
-- 	OnRun = function(item)
-- 		local client = item.player
-- 		local character = client:GetCharacter()

-- 		if (!character:GetInventory():Add("bottle_shard")) then
-- 			ix.item.Spawn("bottle_shard", client)
-- 		end
-- 		client:EmitSound("physics/glass/glass_bottle_break1.wav")
-- 	end
-- }