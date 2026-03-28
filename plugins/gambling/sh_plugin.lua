local PLUGIN = PLUGIN

PLUGIN.name = "Gambling Slots"
PLUGIN.description = "Add gambling slot machine to Helix."
PLUGIN.author = "Reagent (CW), ported by mxd (IX)"
PLUGIN.schema = "Any"
PLUGIN.license = [[
Copyright (c) 2025 mxd (mixvd)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

ix.util.Include("sv_hooks.lua")

ix.config.Add("gamblingPrice", 50, "How many tokens should it cost to spin the slot machine?", nil, {
	category = "Slot Machine",
	data = {min = 1, max = 500},
})

ix.config.Add("jackpotChance", 150, "The chance of a jackpot occurring, where 1 in N spins results in a win.", nil, {
	category = "Slot Machine",
	data = {min = 1, max = 500},
})

ix.config.Add("singleBarDollarSign", 350, "Tokens earned for Single Bar or Dollar Sign jackpot.", nil, {
	category = "Slot Machine",
	data = {min = 1, max = 2000},
})

ix.config.Add("horseShoeDoubleBar", 400, "Tokens earned for Horse Shoe or Double Bar jackpot.", nil, {
	category = "Slot Machine",
	data = {min = 1, max = 3000},
})

ix.config.Add("tripleBarClover", 1000, "Tokens earned for Triple Bar or Clover jackpot.", nil, {
	category = "Slot Machine",
	data = {min = 1, max = 5000},
})

ix.config.Add("lucky7Diamond", 5000, "Tokens earned for Lucky 7 or Diamond jackpot.", nil, {
	category = "Slot Machine",
	data = {min = 1, max = 10000},
})

ix.config.Add("gamblingSymbolPayout", 20, "Tokens earned per matching symbol for non-jackpot wins.", nil, {
	category = "Slot Machine",
	data = {min = 1, max = 100},
})

ix.lang.AddTable("english", {
	notEnoughMoney = "You don't have enough money!",
	gamblePayout = "Your payout is %s",
	slotMachineDesc = "A slot machine that can be used for gambling.",
	price = "Price",
	gamblingStarted = "You spent %s as the cost of the game.",
})

ix.lang.AddTable("korean", {
	notEnoughMoney = "돈이 부족합니다!",
	gamblePayout = "당신의 페이아웃은 %s 입니다.",
	["Slot Machine"] = "슬롯머신",
	slotMachineDesc = "도박을 할 수 있는 슬롯머신입니다.",
	price = "비용",
	gamblingStarted = "%s(을)를 게임 비용으로 썼습니다.",
})

ix.command.Add("SlotMachineAdd", {
	adminOnly = true,
	description = "Add a slot machine at your target position.",
	OnRun = function(self, client)
		local trace = client:GetEyeTraceNoCursor()
		local entity = scripted_ents.Get("ix_slot_machine"):SpawnFunction(client, trace)
	
		if ( IsValid(entity) ) then
			-- client:NotifyLocalized("You have added a slot machine.")
		end
	end
})