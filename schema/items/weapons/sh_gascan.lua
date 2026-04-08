ITEM.name = "Gas Canister"
ITEM.description = "itemGasCanisterDesc"
ITEM.class = "weapon_vfire_gascan"
ITEM.category = "Utility"
ITEM.weaponCategory = "special"
ITEM.price = 200
ITEM.model = "models/props_junk/gascan001a.mdl"
ITEM.width = 2
ITEM.height = 2

ITEM.fuel = 100

function ITEM:OnInstanced()
	if (!self:GetData("fuel")) then
		self:SetData("fuel", self.fuel)
	end
end

ITEM.functions.Fuel = {
	name = "Fill Fuel",
	icon = "icon16/fire.png",
	OnCanRun = function(item)
		local client = item.player or (CLIENT and LocalPlayer())

		if (!IsValid(client)) then
			return false
		end

		local ent = client:GetEyeTrace().Entity
		local allowed = {ix_bucket = true, ix_bonfire = true, ix_stove = true}
		return IsValid(ent) and allowed[ent:GetClass()] and client:GetPos():DistToSqr(ent:GetPos()) < 10000 and ix.plugin.list["hunger"] != nil and ent:GetNetVar("fuelCount", 0) < ent:GetNetVar("fuelMax", 5)
	end,
	OnRun = function(item)
		local client = item.player
		local ent = client:GetEyeTrace().Entity
		local allowed = {ix_bucket = true, ix_bonfire = true, ix_stove = true}

		if (IsValid(ent) and allowed[ent:GetClass()]) then
			if (ent:AddFuel(600)) then
				local fuel = item:GetData("fuel", item.fuel)
				fuel = fuel - 10

				if (fuel <= 0) then
					local inventory = ix.item.inventories[item.invID]

					if (item:GetData("equip")) then
						if (item.Unequip) then
							item:Unequip(client)
						end
					end

					if (item:Remove()) then
						if (inventory) then
							inventory:Add("misc_canister", 1)
						end

						if (IsValid(client)) then
							client:NotifyLocalized("gasCanEmpty")
						end
					end
				else
					item:SetData("fuel", fuel)
					client:NotifyLocalized("fuelAdded", item.name, 10)
				end
			else
				client:NotifyLocalized("fuelFull", ent:GetNetVar("fuelMax", 5))
			end
		end

		return false
	end
}

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local fuel = tooltip:AddRow("fuel")
		fuel:SetBackgroundColor(Color(255, 128, 0))
		fuel:SetText(string.format("%s: %d%%", L("fuel"), self:GetData("fuel", 100)))
		fuel:SetExpensiveShadow(0.5)
		fuel:SizeToContents()

		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(team.GetColor(FACTION_MPF))
		data:SetText(L("securitizedItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end