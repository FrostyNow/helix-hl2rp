
ITEM.name = "Ration"
ITEM.model = Model("models/hls/alyxports/ration_package.mdl")
ITEM.skin = 4
ITEM.category = "Utility"
ITEM.description = "metropoliceRationDesc"
ITEM.items = {"metropolice_supplements", "metropolice_rationbar"}
ITEM.price = 200
ITEM.exRender = true
ITEM.iconCam = {
	pos = Vector(356.67, 303.02, 565.94),
	ang = Angle(50.52, 221.21, 0),
	fov = 1.88
}

ITEM.functions.Open = {
	OnRun = function(itemTable)
		local client = itemTable.player
		local character = client:GetCharacter()

		for k, v in ipairs(itemTable.items) do
			if (!character:GetInventory():Add(v)) then
				ix.item.Spawn(v, client)
			end
		end

		client:EmitSound("ambient/fire/mtov_flame2.wav", 75, math.random(160, 180), 0.35)
	end
}
