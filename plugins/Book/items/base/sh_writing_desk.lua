ITEM.name = "writing_desk"
ITEM.description = "Simple."
ITEM.category = "writing_desk_Base"
ITEM.model = "models/props_lab/bindergraylabel01b.mdl"
ITEM.width = 10
ITEM.height = 1
ITEM.empty = false

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

ITEM.functions.Writing = {
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
		
		if (str) then
			char:SetAttrib("str", str + 1)

			timer.Simple(120, function()
				if (IsValid(client) and client:GetCharacter()) then
					local currentStr = client:GetCharacter():GetAttribute("str", 0)
					client:GetCharacter():SetAttrib("str", math.max(0, currentStr - 1))
				end
			end)
		end

		if (int) then
			char:SetAttrib("int", math.max(0, int - 1))

			timer.Simple(120, function()
				if (IsValid(client) and client:GetCharacter()) then
					local currentInt = client:GetCharacter():GetAttribute("int", 0)
					client:GetCharacter():SetAttrib("int", currentInt + 1)
				end
			end)
		end

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
		local character = client:GetCharacter()
		local enabled = !Schema:IsCombineRank(client:Name(), "SCN")
		if (FACTION_OTA and client:Team() == FACTION_OTA) then enabled = false end

		return enabled
	end
}