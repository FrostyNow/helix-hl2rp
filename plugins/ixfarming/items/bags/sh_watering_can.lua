
ITEM.name = "Watering Can"
ITEM.description = "itemWateringCanDesc"
ITEM.model = "models/noble/limelight/watering_can.mdl"
ITEM.category = "Utility"
ITEM.width = 1
ITEM.height = 1
ITEM.price = 40

ITEM.invWidth = 1
ITEM.invHeight = 1
ITEM.waterItems = {
	["water"] = {isClean = false},
	["water_purified"] = {isClean = true},
	["water_purified_bottle"] = {isClean = true},
	["mineral_water"] = {isClean = true},
	["water_dirty"] = {isClean = false},
	["water_dirty_bottle"] = {isClean = false},
	["water_dirty_can"] = {isClean = false},
}

ITEM.functions.Water = {
	name = "Apply water",
	icon = "icon16/water.png",
	OnRun = function(item)
		local client = item.player
		local trace = client:GetEyeTraceNoCursor()
		local entity = trace.Entity

		if (IsValid(entity) and entity:GetClass() == "ix_farmbox" and entity:GetPos():DistToSqr(client:GetPos()) <= 20000) then
			local inv = item:GetInventory()
			if (inv) then
				local waterItems = inv:GetItems()
				local waterItem = nil
				
				for _, v in pairs(waterItems) do
					if (item.waterItems[v.uniqueID]) then
						waterItem = v
						break
					end
				end

				if (waterItem) then
					local waterInfo = item.waterItems[waterItem.uniqueID]
					local isClean = waterInfo.isClean

					client:EmitSound("ambient/water/water_spray1.wav", 60)
					
					entity:SetWaterAmount(entity:GetWaterAmount() + ix.config.Get("waterDrainTime", 6))
					if (isClean) then
						entity:SetWaterQuality(entity:GetWaterQuality() + 1)
					end
					
					client:NotifyLocalized("farmWaterGiven", L(waterItem.name))
					waterItem:Remove()
					return false
				else
					client:NotifyLocalized("farmNoWaterItem")
					return false
				end
			else
				client:NotifyLocalized("farmNoWaterInventory")
			end
		else
			client:NotifyLocalized("farmLookAtBox")
		end
		return false
	end,
	OnCanRun = function(item)
		return !IsValid(item.entity)
	end
}
