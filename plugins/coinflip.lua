local PLUGIN = PLUGIN

PLUGIN.name = "Coinflip"
PLUGIN.author = "Frosty"
PLUGIN.description = "Adds a command to flip a coin."

ix.lang.AddTable("english", {
	cmdCoinFlip = "Flips a coin to land heads/tails.",
	coinHeads = "flipped a coin and it landed on heads.",
	coinTails = "flipped a coin and it landed on tails.",
	coinNoMoney = "You do not have enough money to flip a coin!",
})

ix.lang.AddTable("korean", {
	cmdCoinFlip = "동전을 던져 앞뒷면을 가립니다.",
	coinHeads = "동전을 던졌더니 앞면이 나왔다.",
	coinTails = "동전을 던졌더니 뒷면이 나왔다.",
	coinNoMoney = "동전을 던질 돈이 부족합니다!",
})

ix.command.Add("CoinFlip", {
	description = "@cmdCoinFlip",
	adminOnly = false,
	alias = "Coin",
	OnRun = function(self, client, arguments)
		local character = client:GetCharacter()

		if (!character or !character:HasMoney(1)) then
			return "@coinNoMoney"
		end
		
		local bHeads = math.random(0, 1) == 1
		local phrase = bHeads and "coinHeads" or "coinTails"
		
		local meChat = ix.chat.classes.me
		
		for _, v in player.Iterator() do
			if (v:GetCharacter() and meChat:CanHear(client, v)) then
				ix.chat.Send(client, "me", L(phrase, v), false, {v})
			end
		end
	end
})