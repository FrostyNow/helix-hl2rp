ITEM.name = "Alcohol"
ITEM.description = "Simple."
ITEM.category = "Alcohol"
ITEM.model = "models/props_lab/bindergraylabel01b.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.strength = 1
ITEM.usenum = 4
ITEM.thirst = 0
ITEM.radiation = 0
ITEM.empty = false
ITEM.classes = {CLASS_CWU}

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local usenum = self:GetData("usenum", self.usenum)
		if (usenum) then
			local row = tooltip:AddRow("usenum")
			row:SetText(L("usesLabel", usenum))
			row:SetBackgroundColor(ix.config.Get("color"))
		end
	end
end

ITEM.functions.Drink = {
	icon = "icon16/drink.png",
	OnRun = function(item)
		local client = item.player
		local char = client:GetCharacter()
		local thirst = char:GetData("thirst", 100)
		local str = char:GetAttribute("str", 0)
		local int = char:GetAttribute("int", 0)
		local endurance = char:GetAttribute("end", 1)
		
		local usenum = item:GetData("usenum", item.usenum or 4)
		usenum = usenum - 1

		local thirstGain = (item.thirst or 0) / (item.usenum or 1)
		if thirst and thirstGain > 0 then
			client:SetThirst(math.Clamp(thirst + thirstGain, 0, 100))
		end
		
		local increase = (item.strength or 1) * 10 / math.max(1, endurance)
		char:SetData("drunk", char:GetData("drunk", 0) + increase)
		
		client:EmitSound("npc/barnacle/barnacle_gulp2.wav")
		hook.Run("Drunk", client)
		
		local boostID = "alcohol_" .. item:GetID()
		char:AddBoost(boostID, "str", 1)
		char:AddBoost(boostID, "int", -1)

		timer.Simple(120, function()
			if (char) then
				char:RemoveBoost(boostID, "str")
				char:RemoveBoost(boostID, "int")
			end
		end)

		if (usenum > 0) then
			item:SetData("usenum", usenum)
			return false
		else
			if (item.empty) then
				local inv = char:GetInventory()
				inv:Add(item.empty)
			end
			return true
		end
	end,
	OnCanRun = function(item)
		local client = item.player

		return client:GetCharacter() and client:Team() != FACTION_OTA
	end
}