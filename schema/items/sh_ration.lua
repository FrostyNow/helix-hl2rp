
ITEM.name = "Ration"
ITEM.model = Model("models/hls/alyxports/ration_package.mdl")
ITEM.description = "rationDesc"
ITEM.category = "Utility"
ITEM.items = {"supplements", "supplements_bar"}
ITEM.price = 100
ITEM.exRender = true
ITEM.iconCam = {
	pos = Vector(11.14, -6.38, 129.97),
	ang = Angle(86.81, -181.38, 0),
	fov = 8.58
}

ITEM.functions.Open = {
	icon = "icon16/email_open.png",
	OnRun = function(itemTable)
		local client = itemTable.player
		local character = client:GetCharacter()
		local inv = character:GetInventory()

		for k, v in ipairs(itemTable.items) do
			if (!inv:Add(v)) then
				ix.item.Spawn(v, client)
			end
		end

		local luck = character:GetAttribute("lck", 0)
		local luckMult = ix.config.Get("luckMultiplier", 1)
		character:GiveMoney(ix.config.Get("rationTokens", 20) + luck * luckMult)

		if (!inv:HasItem("request_device")) then
			local maxAttr = ix.config.Get("maxAttributes", 100)
			local chance = (maxAttr > 0) and (luck / maxAttr) or 0

			if (math.random() < chance) then
				if (!inv:Add("request_device")) then
					ix.item.Spawn("request_device", client)
				end
			end
		end

		client:EmitSound("ambient/fire/mtov_flame2.wav", 75, math.random(160, 180), 0.35)
	end
}
