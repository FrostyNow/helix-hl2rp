ITEM.name = "Crowbar"
ITEM.description = "crowbarDesc"
ITEM.model = "models/weapons/w_crowbar.mdl"
ITEM.class = "weapon_crowbar"
ITEM.weaponCategory = "melee"
ITEM.width = 2
ITEM.height = 1
ITEM.price = 25
ITEM.iconCam = {
	ang	= Angle(-0.23955784738064, 270.44906616211, 0),
	fov	= 10.780103254469,
	pos	= Vector(0, 200, 0)
}

// Prevent random person smashing heavy stuff
ITEM.functions.Equip.OnCanRun = function(item)
	if (item.baseTable.functions.Equip.OnCanRun(item) == false) then
		return false
	end

	local char = item.player:GetCharacter()
	local maxAttributes = math.max(ix.config.Get("maxAttributes", 100), 1)
	local strReq = maxAttributes * 2 / 3

	return char:GetAttribute("str", 0) >= strReq
end

ITEM.functions.Pry = {
	name = "Pry",
	tip = "crowbarPryTip",
	icon = "icon16/door_out.png",
	OnRun = function(itemTable)
		local client = itemTable.player
		local char = client:GetCharacter()
		
		-- attribute check
		local maxAttributes = math.max(ix.config.Get("maxAttributes", 100), 1)
		local strReq = maxAttributes / 2

		if (char:GetAttribute("str", 0) < strReq) then
			client:NotifyLocalized("crowbarLowStr")
			return false
		end

		local data = {}
		data.start = client:GetShootPos()
		data.endpos = data.start + client:GetAimVector() * 96
		data.filter = client
		local target = util.TraceLine(data).Entity

		if (!IsValid(target) or !target:IsDoor()) then
			client:NotifyLocalized("dNotValid")
			return false
		end

		client:EmitSound("physics/metal/metal_box_impact_hard3.wav")
		client:SetAction("@crowbarPrying", 5)
		
		local sound = CreateSound(client, "physics/metal/metal_box_scrape_rough_loop1.wav")
		sound:Play()

		client:DoStaredAction(target, function()
			if (sound) then
				sound:Stop()
				sound = nil
			end

			-- chance
			local luck = char:GetAttribute("lck", 0)
			local maxAttributes = math.max(ix.config.Get("maxAttributes", 100), 1)
			local luckMultiplier = ix.config.Get("luckMultiplier", 1)
			
			local luckBonus = (luck / maxAttributes) * 35 * luckMultiplier
			local successChance = 35 + luckBonus
			
			-- if door has lock, increase difficulty
			local lock = target.ixLock
			if (IsValid(lock)) then
				successChance = successChance * 0.5
			end
			
			local roll = math.Rand(0, 100)
			local bSuccess = roll <= successChance
			
			-- durability
			local durability = itemTable:GetData("durability", 5)
			durability = durability - 1
			itemTable:SetData("durability", durability)
			
			if (bSuccess) then
				target:Fire("unlock")
				target:Fire("open")
				client:EmitSound("physics/metal/metal_box_break3.wav")
				client:NotifyLocalized("crowbarPrySuccess")
				
				if (IsValid(lock)) then
					if (lock.SetLocked) then lock:SetLocked(false) end
					if (lock.SetDisabledUntil) then lock:SetDisabledUntil(CurTime() + 300) end
				end
			else
				client:EmitSound("physics/metal/metal_box_impact_hard2.wav")
				client:NotifyLocalized("crowbarPryFailed")
			end
			
			-- remove
			if (durability <= 0) then
				client:NotifyLocalized("crowbarBroken")
				
				if (itemTable:GetData("equip")) then
					client:StripWeapon(itemTable.class)
					itemTable:SetData("equip", false)
				end
				itemTable:Remove()
			end
		end, 5, function()
			if (sound) then
				sound:Stop()
				sound = nil
			end

			if (IsValid(client)) then
				client:SetAction()
			end
		end)

		return false
	end,
	OnCanRun = function(itemTable)
		return !IsValid(itemTable.entity)
	end
}

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local durability = tooltip:AddRow("durability")
		durability:SetBackgroundColor(Color(100, 100, 100))
		durability:SetText(L("crowbarDurability")..": "..self:GetData("durability", 5))
		durability:SetExpensiveShadow(0.5)
		durability:SizeToContents()

		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(Color(218, 24, 24))
		data:SetText(L("sociocidalItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end