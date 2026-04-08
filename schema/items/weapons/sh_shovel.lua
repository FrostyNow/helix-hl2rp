ITEM.name = "Shovel"
ITEM.description = "shovelDesc"
ITEM.class = "weapon_hl2shovel"
ITEM.category = "Utility"
ITEM.weaponCategory = "melee"
ITEM.price = 40
ITEM.model = "models/props_junk/shovel01a.mdl"
ITEM.width = 1
ITEM.height = 2
ITEM.iconCam = {
	pos = Vector(509.64, 427.61, 310.24),
	ang = Angle(25.06, 219.99, 0),
	fov = 1.65
}
ITEM.exRender = true
ITEM.isjunk = true

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local durability = self:GetData("durability", 50)
		local durabilityRow = tooltip:AddRow("durability")
		durabilityRow:SetBackgroundColor(durability <= 0 and Color(200, 0, 0) or Color(100, 100, 100))
		durabilityRow:SetText(L("shovelDurability")..": "..durability .. (durability <= 0 and " [BROKEN]" or ""))
		durabilityRow:SetExpensiveShadow(0.5)
		durabilityRow:SizeToContents()

		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(Color(218, 24, 24))
		data:SetText(L("sociocidalItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end

function ITEM:ReduceDurability(amount)
	local durability = self:GetData("durability", 50)
	durability = math.max(0, durability - (amount or 1))
	self:SetData("durability", durability)

	if (durability <= 0) then
		local client = self.player
		if (IsValid(client)) then
			client:NotifyLocalized("shovelBroken")
			
			if (self:GetData("equip")) then
				self.functions.Unequip.OnRun(self)
			end
		end
	end
end

ITEM.functions.MakeFarmbox = {
	name = "Make Farmbox",
	tip = "makeFarmboxTip",
	icon = "icon16/box.png",
	OnRun = function(item)
		local client = item.player
		local nextTime = client:GetCharacter():GetData("nextFarmboxTime", 0)
		
		if (nextTime > os.time()) then
			local timeLeft = string.FormattedTime(nextTime - os.time())
			client:NotifyLocalized("farmboxCooldown", string.format("%02d:%02d", timeLeft.m, timeLeft.s))
			return false
		end
		
		net.Start("ixFarmboxStartPlace")
		net.Send(client)
		return false
	end,
	OnCanRun = function(item)
		if (!ix.plugin.Get("ixfarming")) then
			return false
		end

		if (item:GetData("durability", 50) <= 0) then
			return false
		end

		if (item:GetData("equip", false)) then
			return false
		end

		return !IsValid(item.entity)
	end
}

ITEM.functions.Equip.OnCanRun = function(item)
	if (item.baseTable.functions.Equip.OnCanRun(item) == false) then
		return false
	end

	return item:GetData("durability", 50) > 0
end


ITEM.functions.Repair = {
	icon = "icon16/wrench.png",
	OnRun = function(item)
		local client = item.player
		local char = client:GetCharacter()
		local inventory = char:GetInventory()
		local repairTools = inventory:HasItem("repair_tools")
		
		if (repairTools) then
			item:SetData("durability", 50)
			repairTools:Remove()
			
			client:EmitSound("interface/inv_repair_kit.ogg")
			client:NotifyLocalized("shovelRepaired")
		else
			client:NotifyLocalized("itemNoRepairKit")
			return false
		end
		
		return false
	end,
	OnCanRun = function(item)
		local client = item.player
		return !IsValid(item.entity) and item:GetData("durability", 50) < 50
	end
}
