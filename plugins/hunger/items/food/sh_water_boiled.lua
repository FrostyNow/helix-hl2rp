ITEM.name = "Boiled Water"
ITEM.model = "models/mosi/fallout4/props/drink/dirtywater.mdl"
ITEM.description = "itemBoiledWaterDesc"
ITEM.thirst = 25
ITEM.price = 15
ITEM.classes = nil

ITEM.functions.Drink = {
	name = "Drink",
	tip = "drinkTip",
	icon = "icon16/cup.png",
	OnRun = function(item)
		local client = item.player
		local character = client:GetCharacter()

		character:SetData("thirst", math.min(character:GetData("thirst", 0) + item.thirst, 100))
		client:EmitSound("npc/barnacle/barnacle_gulp1.wav", 60, math.random(70, 130))
		
		return true
	end
}
