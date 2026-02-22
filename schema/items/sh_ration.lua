
ITEM.name = "Ration"
ITEM.model = Model("models/weapons/w_package.mdl")
ITEM.description = "rationDesc"
ITEM.items = {"supplements", "crackers", "water"}
ITEM.price = 100

ITEM.functions.Open = {
	OnRun = function(itemTable)
		local client = itemTable.player
		local character = client:GetCharacter()

		for k, v in ipairs(itemTable.items) do
			if (!character:GetInventory():Add(v)) then
				ix.item.Spawn(v, client)
			end
		end
		local luck = character:GetAttribute("lck", 0)
		local luckMult = ix.config.Get("luckMultiplier", 1)
		character:GiveMoney(ix.config.Get("rationTokens", 20) + luck * luckMult)
		client:EmitSound("ambient/fire/mtov_flame2.wav", 75, math.random(160, 180), 0.35)
	end
}
