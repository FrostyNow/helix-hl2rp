
ITEM.name = "Ration"
ITEM.model = Model("models/hls/alyxports/ration_package.mdl")
ITEM.description = "rationGr3Desc"
ITEM.category = "Utility"
ITEM.items = {"supplements_poultry", "supplements_bar_citrus"}
ITEM.price = 120
ITEM.skin = 3
ITEM.exRender = true
ITEM.iconCam = {
	pos = Vector(356.67, 303.02, 565.94),
	ang = Angle(50.52, 221.21, 0),
	fov = 1.88
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
		character:GiveMoney(ix.config.Get("rationTokens", 20) * 1.3 + luck * luckMult)

		client:EmitSound("ambient/fire/mtov_flame2.wav", 75, math.random(160, 180), 0.35)
	end
}
