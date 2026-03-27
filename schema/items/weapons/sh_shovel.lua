ITEM.name = "Shovel"
ITEM.description = "shovelDesc"
ITEM.class = "weapon_hl2shovel"
ITEM.category = "Utility"
ITEM.weaponCategory = "melee"
ITEM.price = 40
ITEM.model = "models/props_junk/shovel01a.mdl"
ITEM.width = 1
ITEM.height = 3
ITEM.iconCam = {
	pos = Vector(509.64, 427.61, 310.24),
	ang = Angle(25.06, 219.99, 0),
	fov = 1.65
}
ITEM.exRender = true
ITEM.isjunk = true

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(Color(218, 24, 24))
		data:SetText(L("sociocidalItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
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

		if (item:GetData("equip", false)) then
			return false
		end

		return !IsValid(item.entity)
	end
}