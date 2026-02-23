local PLUGIN = PLUGIN

PLUGIN.name = "Flags for Vendors"
PLUGIN.author = "Ron"
PLUGIN.description = "Makes vendors perform a flag check on buying an item if it has a flag requirement."

if(SERVER) then

	net.Receive("ixVendorTrade", function(length, client)
		if ((client.ixVendorTry or 0) < CurTime()) then
			client.ixVendorTry = CurTime() + 0.33
		else
			return
		end

		local entity = client.ixVendor

		if (!IsValid(entity) or client:GetPos():Distance(entity:GetPos()) > 192) then
			return
		end

		local uniqueID = net.ReadString()
		local isSellingToVendor = net.ReadBool()

		if (entity.items[uniqueID] and
			hook.Run("CanPlayerTradeWithVendor", client, entity, uniqueID, isSellingToVendor) != false) then
			local price = entity:GetPrice(uniqueID, isSellingToVendor)

			if (isSellingToVendor) then
				local found = false
				local name

				if (!entity:HasMoney(price)) then
					return client:NotifyLocalized("vendorNoMoney")
				end

				local stock, max = entity:GetStock(uniqueID)

				if (stock and stock >= max) then
					return client:NotifyLocalized("vendorMaxStock")
				end

				local invOkay = true

				for _, v in pairs(client:GetCharacter():GetInventory():GetItems()) do
					if (v.uniqueID == uniqueID and v:GetID() != 0 and ix.item.instances[v:GetID()] and v:GetData("equip", false) == false) then
						invOkay = v:Remove()
						found = true
						name = L(v.name, client)

						break
					end
				end

				if (!found) then
					return
				end

				if (!invOkay) then
					client:GetCharacter():GetInventory():Sync(client, true)
					return client:NotifyLocalized("tellAdmin", "trd!iid")
				end

				client:GetCharacter():GiveMoney(price, price == 0)
				client:NotifyLocalized("businessSell", name, ix.currency.Get(price, client))
				entity:TakeMoney(price)
				entity:AddStock(uniqueID)

				ix.log.Add(client, "vendorSell", name, entity:GetDisplayName(), ix.currency.Get(price))
			else
				local stock = entity:GetStock(uniqueID)

				local flag = ix.item.list[uniqueID].flag

				if (flag and !client:GetCharacter():HasFlags(flag)) then
					return client:NotifyLocalized("flagNoMatch", flag)
				end

				if (stock and stock < 1) then
					return client:NotifyLocalized("vendorNoStock")
				end

				if (!client:GetCharacter():HasMoney(price)) then
					return client:NotifyLocalized("canNotAfford")
				end

				local name = L(ix.item.list[uniqueID].name, client)

				client:GetCharacter():TakeMoney(price, price == 0)
				client:NotifyLocalized("businessPurchase", name, ix.currency.Get(price, client))

				entity:GiveMoney(price)

				if (!client:GetCharacter():GetInventory():Add(uniqueID)) then
					ix.item.Spawn(uniqueID, client)
				else
					net.Start("ixVendorAddItem")
						net.WriteString(uniqueID)
					net.Send(client)
				end

				entity:TakeStock(uniqueID)

				ix.log.Add(client, "vendorBuy", name, entity:GetDisplayName(), ix.currency.Get(price))
			end

			hook.Run("SaveData")
			hook.Run("CharacterVendorTraded", client, entity, uniqueID, isSellingToVendor)
		else
			client:NotifyLocalized("vendorNoTrade")
		end
	end)
end
