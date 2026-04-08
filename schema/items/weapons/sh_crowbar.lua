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

	return char:GetAttribute("str", 0) >= strReq and item:GetData("durability", 5) > 0
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
		
		local bPrying = true
		local lastSound
		local function PlayPrySound()
			if (!bPrying or !IsValid(client)) then return end

			local soundIndex = math.random(1, 4)
			while (soundIndex == lastSound) do
				soundIndex = math.random(1, 4)
			end
			lastSound = soundIndex

			local soundName = "physics/metal/metal_box_strain" .. soundIndex .. ".wav"
			client:EmitSound(soundName)

			local duration = SoundDuration(soundName)
			if (duration == 0) then duration = 0.7 end -- fallback if SoundDuration fails

			timer.Simple(duration + 0.05, function()
				PlayPrySound()
			end)
		end

		PlayPrySound()

		client:DoStaredAction(target, function()
			bPrying = false

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
			
			-- remove -> unequip
			if (durability <= 0) then
				client:NotifyLocalized("crowbarBroken")
				
				if (itemTable:GetData("equip")) then
					itemTable.functions.Unequip.OnRun(itemTable)
				end
			end
		end, 5, function()
			bPrying = false

			if (IsValid(client)) then
				client:SetAction()
			end
		end)

		return false
	end,
	OnCanRun = function(itemTable)
		return !IsValid(itemTable.entity) and itemTable:GetData("durability", 5) > 0
	end
}

ITEM.functions.Repair = {
	icon = "icon16/wrench.png",
	OnRun = function(item)
		local client = item.player
		local char = client:GetCharacter()
		local inventory = char:GetInventory()
		local repairTools = inventory:HasItem("repair_tools")
		
		if (repairTools) then
			item:SetData("durability", 5)
			repairTools:Remove()
			
			client:EmitSound("interface/inv_repair_kit.ogg")
			client:NotifyLocalized("crowbarRepaired")
		else
			client:NotifyLocalized("itemNoRepairKit")
			return false
		end
		
		return false
	end,
	OnCanRun = function(item)
		local client = item.player
		return !IsValid(item.entity) and item:GetData("durability", 5) < 5
	end
}

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local durability = self:GetData("durability", 5)
		local durabilityRow = tooltip:AddRow("durability")
		durabilityRow:SetBackgroundColor(durability <= 0 and Color(200, 0, 0) or Color(100, 100, 100))
		durabilityRow:SetText(L("crowbarDurability")..": "..durability .. (durability <= 0 and " [BROKEN]" or ""))
		durabilityRow:SetExpensiveShadow(0.5)
		durabilityRow:SizeToContents()

		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(Color(218, 24, 24))
		data:SetText(L("sociocidalItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end