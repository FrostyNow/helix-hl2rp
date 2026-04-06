ITEM.name = "Filter Base"
ITEM.description = "A base for gasmask filters."
ITEM.category = "Utility"
ITEM.model = "models/props_junk/garbage_metalcan002a.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.isGasmaskFilter = true
ITEM.maxDurability = 100
ITEM.badAirProtection = true
ITEM.isStackable = true
ITEM.maxStack = 2
ITEM.factions = {FACTION_MPF, FACTION_OTA, FACTION_CONSCRIPT}

if (CLIENT) then
	function ITEM:PaintOver(item, w, h)
		if (item:GetData("equip")) then
			surface.SetDrawColor(110, 255, 110, 100)
			surface.DrawRect(w - 14, h - 14, 8, 8)
		end
	end
end

function ITEM:OnInstanced()
	if (self:GetData("Durability") == nil) then
		self:SetData("Durability", self.maxDurability)
	end
end

ITEM.functions.Use = {
	name = "installFilter",
	tip = "useTip",
	icon = "icon16/wrench.png",
	OnRun = function(item)
		local client = item.player or item:GetOwner()
		if (!IsValid(client)) then return false end

		local character = client:GetCharacter()
		local badair = ix.plugin.Get("badair")

		if (!badair) then
			client:NotifyLocalized("filterNoCompatibleMask")
			return false
		end

		local targetMask = badair:GetFilterInstallTarget(character)

		if (targetMask) then
			if (!badair:InstallFilterOnItem(targetMask, item)) then
				client:NotifyLocalized("filterAlreadyInstalled")
				return false
			end
			
			if (targetMask.UpdateResistance) then
				targetMask:UpdateResistance(client)
			end

			client:EmitSound("weapons/usp/usp_silencer_on.wav")
			client:NotifyLocalized("filterInstalledNotify")
			
			return true
		else
			client:NotifyLocalized("filterNoCompatibleMask")
			return false
		end
	end,
	OnCanRun = function(item)
		local client = item.player or item:GetOwner()
		if (!IsValid(client)) then return false end

		local char = client:GetCharacter()
		local invID = char:GetInventory():GetID()
		local gearInvID = char:GetData("gearInvID")
		local badair = ix.plugin.Get("badair")

		return !item:GetData("equip") and (!IsValid(item.entity) and (item.invID == invID or (gearInvID and item.invID == gearInvID))) and not badair:CanEquipInternalFilter(client)
	end
}

ITEM.functions.Equip = {
	name = "installFilter",
	tip = "useTip",
	icon = "icon16/wrench.png",
	OnRun = function(item)
		local client = item.player or item:GetOwner()
		item:SetData("equip", true)
		client:EmitSound("weapons/usp/usp_silencer_on.wav")

		hook.Run("OnItemEquipped", item, client)

		return false
	end,
	OnCanRun = function(item)
		local client = item.player or item:GetOwner()
		local badair = ix.plugin.Get("badair")
		return badair and !IsValid(item.entity) and !item:GetData("equip") and badair:CanEquipInternalFilter(client)
	end
}

ITEM.functions.EquipUn = {
	name = "removeFilter",
	tip = "useTip",
	icon = "icon16/delete.png",
	OnRun = function(item)
		local client = item.player or item:GetOwner()
		item:SetData("equip", false)
		client:EmitSound("weapons/usp/usp_silencer_off.wav")

		hook.Run("OnItemUnequipped", item, client)

		return false
	end,
	OnCanRun = function(item)
		local client = item.player or item:GetOwner()
		local badair = ix.plugin.Get("badair")
		return badair and !IsValid(item.entity) and item:GetData("equip") == true and badair:CanEquipInternalFilter(client)
	end
}

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local durability = tooltip:AddRow("durability")
		durability:SetBackgroundColor(derma.GetColor("Warning", tooltip))
		durability:SetText(string.format("%s: %d / %d", L("Filter Durability"), math.floor(self:GetData("Durability", self.maxDurability)), self.maxDurability))
		durability:SizeToContents()

		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(team.GetColor(FACTION_MPF))
		data:SetText(L("securitizedItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end
