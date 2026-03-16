ITEM.name = "Gasmask Filter"
ITEM.description = "itemGasmaskFilterDesc"
ITEM.model = "models/willardnetworks/props/blackfilter.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.category = "Utility"
ITEM.isStackable = true
ITEM.maxDurability = 100

function ITEM:GetDescription()
	return string.format("%s\n \nDurability: %d / %d", L(self.description), math.floor(self:GetData("Durability", self.maxDurability)), self.maxDurability)
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
		local client = item.player
		local character = client:GetCharacter()
		local inventory = character:GetInventory()
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
	end
}

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local durability = tooltip:AddRow("durability")
		durability:SetBackgroundColor(derma.GetColor("Warning", tooltip))
		durability:SetText(string.format("Durability: %d / %d", math.floor(self:GetData("Durability", self.maxDurability)), self.maxDurability))
		durability:SizeToContents()

		ocal data = tooltip:AddRow("data")
		data:SetBackgroundColor(team.GetColor(FACTION_MPF))
		data:SetText(L("securitizedItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end
