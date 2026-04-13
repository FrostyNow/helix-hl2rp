
ITEM.name = "Metal Bucket"
ITEM.description = "itemMetalBucketDesc"
ITEM.price = 10
ITEM.model = "models/mosi/fallout4/props/junk/bucket.mdl"
ITEM.isjunk = true
ITEM.isStackable = true

ITEM.functions.Deploy = {
	icon = "icon16/anchor.png",
	OnRun = function(item)
		local client = item.player
		
		-- Check Count Limit
		local count = 0
		for _, v in ipairs(ents.FindByClass("ix_bucket")) do
			if (v.GetOwnerCID and v:GetOwnerCID() == client:GetCharacter():GetID()) then
				count = count + 1
			end
		end

		if (count >= 1) then
			client:NotifyLocalized("bucketLimitReached", 1)
			return false
		end

		net.Start("ixBucketPlaceStart")
		net.Send(client)

		return false
	end,
	OnCanRun = function(item)
		return !IsValid(item.entity) and ix.plugin.Get("hunger")
	end
}