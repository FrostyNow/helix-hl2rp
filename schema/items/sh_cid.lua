
ITEM.name = "Citizen ID"
ITEM.model = Model("models/dorado/tarjeta1.mdl")
ITEM.description = "cidDesc"
ITEM.price = 50
ITEM.noDeathDrop = true
ITEM.functions.Use = {
	name = "Assign",
	OnRun = function(itemTable)
		local client = itemTable.player
		local data = {}
			data.start = client:GetShootPos()
			data.endpos = data.start + client:GetAimVector() * 96
			data.filter = client
		local target = util.TraceLine(data).Entity

		if (IsValid(target) and target:IsPlayer() and target:GetCharacter() and target:Team() == FACTION_CITIZEN) then
			char = target:GetCharacter()
			id = Schema:ZeroNumber(math.random(1, 99999), 5)
			
			if (char:GetData("cid", 00000)) then
				id = char:GetData("cid", 00000)
			end
				
			char:SetData("cid", id)
			itemTable:SetData("id", id)
			itemTable:SetData("name", char:GetName())

			if char:GetClass() == CLASS_CWU then
				itemTable:SetData("class", "Civil Worker's Union")
			elseif char:GetClass() == CLASS_ELITE_CITIZEN then
				itemTable:SetData("class", "First Class Citizen")
			else
				itemTable:SetData("class", "Second Class Citizen")
			end
				
			client:EmitSound("items/battery_pickup.wav")
		end

		return false
	end,
	OnCanRun = function(itemTable)
		local client = itemTable.player

		return !IsValid(itemTable.entity) and IsValid(client) and itemTable.invID == client:GetCharacter():GetInventory():GetID() and (client:IsCombine() or client:Team() == FACTION_ADMIN or client:Team() == FACTION_CONSCRIPT)
	end
}
ITEM.functions.Upgrade = {
	name = "Upgrade",
	OnRun = function(itemTable)
		local client = itemTable.player
		local data = {}
			data.start = client:GetShootPos()
			data.endpos = data.start + client:GetAimVector() * 96
			data.filter = client
		local target = util.TraceLine(data).Entity

		if (IsValid(target) and target:IsPlayer() and target:GetCharacter()) then
			local char = target:GetCharacter()

			if (target:Team() == FACTION_CITIZEN) then
				if (itemTable:GetData("name") == target:GetCharacter():GetName()) then
					id = Schema:ZeroNumber(math.random(1, 99999), 5)
					
					if (target:GetCharacter():GetData("cid", 00000)) then
						id = target:GetCharacter():GetData("cid", 00000)
					end
					
					target:GetCharacter():SetData("cid", id)
					itemTable:SetData("id", id)
					itemTable:SetData("name", target:GetCharacter():GetName())

					if (char:GetClass() == CLASS_CITIZEN) then

						char:SetClass(CLASS_CWU)
						itemTable:SetData("class", "Civil Worker's Union")
						
						client:EmitSound("items/battery_pickup.wav")
						client:NotifyLocalized("cidClassUpgraded", client:GetName(), target:GetName(), "Civil Worker's Union")
						target:NotifyLocalized("cidClassUpgraded", client:GetName(), target:GetName(), "Civil Worker's Union")
					elseif (char:GetClass() == CLASS_CWU) then
						char:SetClass(CLASS_ELITE_CITIZEN)
						itemTable:SetData("class", "First Class Citizen")
						
						client:EmitSound("items/battery_pickup.wav")
						client:NotifyLocalized("cidClassUpgraded", client:GetName(), target:GetName(), "First Class Citizen")
						target:NotifyLocalized("cidClassUpgraded", client:GetName(), target:GetName(), "First Class Citizen")
					else
						client:NotifyLocalized("cidClassUpgradedFailed", target:GetName())
					end
				else
					client:NotifyLocalized("cidInvalidTarget")
				end
			else
				client:NotifyLocalized("notCitizen")
			end
		end

		return false
	end,
	OnCanRun = function(itemTable)
		local client = itemTable.player

		return !IsValid(itemTable.entity) and IsValid(client) and itemTable.invID == client:GetCharacter():GetInventory():GetID() and (client:IsCombine() or client:Team() == FACTION_ADMIN or client:Team() == FACTION_CONSCRIPT)
	end
}
ITEM.functions.Degrade = {
	name = "Degrade",
	OnRun = function(itemTable)
		local client = itemTable.player
		local data = {}
			data.start = client:GetShootPos()
			data.endpos = data.start + client:GetAimVector() * 96
			data.filter = client
		local target = util.TraceLine(data).Entity

		if (IsValid(target) and target:IsPlayer() and target:GetCharacter()) then
			local char = target:GetCharacter()

			if (target:Team() == FACTION_CITIZEN) then
				if (itemTable:GetData("name") == target:GetCharacter():GetName()) then
					id = Schema:ZeroNumber(math.random(1, 99999), 5)
				
					if (target:GetCharacter():GetData("cid", 00000)) then
						id = target:GetCharacter():GetData("cid", 00000)
					end
					
					target:GetCharacter():SetData("cid", id)
					itemTable:SetData("id", id)
					itemTable:SetData("name", target:GetCharacter():GetName())

					if (char:GetClass() != CLASS_CITIZEN) then
						char:SetClass(CLASS_CITIZEN)
						itemTable:SetData("class", "Second Class Citizen")
						
						client:EmitSound("items/battery_pickup.wav")
						client:NotifyLocalized("cidClassDegraded", client:GetName(), target:GetName(), "Second Class Citizen")
						target:NotifyLocalized("cidClassDegraded", client:GetName(), target:GetName(), "Second Class Citizen")
					end
				else
					client:NotifyLocalized("cidInvalidTarget")
				end
			else
				client:NotifyLocalized("notCitizen")
			end
		end

		return false
	end,
	OnCanRun = function(itemTable)
		local client = itemTable.player

		return !IsValid(itemTable.entity) and IsValid(client) and itemTable.invID == client:GetCharacter():GetInventory():GetID() and (client:IsCombine() or client:Team() == FACTION_ADMIN or client:Team() == FACTION_CONSCRIPT)
	end
}

function ITEM:GetDescription()
	if (!IsValid(self.entity)) then
		return (L(self.description) .. L("cidDescID") .. self:GetData("id", "00000") .. L("cidDescName") .. self:GetData("name", L("unknown")))
	else
		return L(self.description)
	end
end

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local class = tooltip:AddRow("class")
		
		if (self:GetData("class") == "Civil Worker's Union") then
			class:SetText(L("Civil Worker's Union") .. L("cidDescClass"))
			class:SetBackgroundColor(Color(224, 208, 117, 255))
		elseif (self:GetData("class") == "First Class Citizen") then
			class:SetText(L("First Class Citizen") .. L("cidDescClass"))
			class:SetBackgroundColor(Color(191, 57, 75, 255))
		else
			class:SetText(L("Second Class Citizen") .. L("cidDescClass"))
			class:SetBackgroundColor(Color(53, 156, 56, 255))
		end
		class:SetExpensiveShadow(0.5)
		class:SizeToContents()
	end
end