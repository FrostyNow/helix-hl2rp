local PLUGIN = PLUGIN

PLUGIN.Title = "Gear Menu"
PLUGIN.Author = "Ronald and Frosty"
PLUGIN.Description = "Make menu for store equipment gear so it doesn't have slot in inventory."
PLUGIN.Version = "2.0.0"

PLUGIN.GearInvWidth = 50
PLUGIN.GearInvHeight = 50

ix.lang.AddTable("english", {
	["gear"] = "Inventory",
	gearTooltip = "Drag and drop\nto equip or unequip.",
	moveUp = "Move Up",
	moveDown = "Move Down",
	noFitDropped = "The item was dropped to the ground because there was no space in your inventory.",
	gearDumpContainerName = "Inventory Storage (%s)",
	gearDumpNotify = "Stored %d items for %s in a container.",
	noItemsToStore = "No items to store.",
	gearDumpNotOwner = "You are not the owner of this container."
})
ix.lang.AddTable("korean", {
	["gear"] = "소지품 및 장비",
	["Inventory"] = "소지품",
	["Equipment"] = "장비",
	gearTooltip = "장비를 드래그 드랍하여\n장착하거나 해제하실 수 있습니다.",
	moveUp = "위로 이동",
	moveDown = "아래로 이동",
	noFitDropped = "인벤토리가 가득 차 아이템이 바닥에 떨어졌습니다.",
	gearDumpContainerName = "소지품 보관함 (%s)",
	gearDumpNotify = "%s의 아이템 %d개를 전용 보관함에 보관했습니다.",
	noItemsToStore = "정리할 아이템이 없습니다.",
	gearDumpNotOwner = "이 보관함의 주인이 아닙니다."
})

ix.inventory.Register("ixGearInv", PLUGIN.GearInvWidth, PLUGIN.GearInvHeight, false)

-- Helper: check if an inventory is a gear inventory.
function PLUGIN:IsGearInventory(invID)
	local inv = ix.item.inventories[invID]
	return inv and inv.vars and inv.vars.isGear
end

-- ============================================================
-- GLOBAL OVERRIDE: ix.meta.inventory
-- Make GetItems() universally return Gear Items for compatibility
-- ============================================================
local ix_inv = ix.meta.inventory
if (ix_inv) then
	ix_inv.GearOriginalGetItems = ix_inv.GearOriginalGetItems or ix_inv.GetItems
	ix_inv.GearOriginalGetBags = ix_inv.GearOriginalGetBags or ix_inv.GetBags

	function ix_inv:GetItems(onlyMain)
		local items = self:GearOriginalGetItems(onlyMain)

		-- Only inject gear items when directly querying a character's primary main inventory.
		-- onlyMain = false natively allows bags via base GetItems. Here we extend it to gear.
		if (onlyMain != true and !self.vars.isBag and !self.vars.isGear and self.owner) then
			local character = ix.char.loaded and ix.char.loaded[self.owner]
			
			if (character and character:GetInventory() == self) then
				local gearID = character:GetData("gearInvID")
				local gearInv = gearID and ix.item.inventories[gearID]

				if (gearInv and gearInv != self) then
					for itemID, itemInst in pairs(gearInv:GearOriginalGetItems(true)) do
						items[itemID] = itemInst
					end
				end
			end
		end

		return items
	end

	function ix_inv:GetBags()
		local bags = self:GearOriginalGetBags()

		-- Treat equipped bags in the gear inventory as part of the character's carried storage.
		-- Helix's empty-slot search calls GetBags(), so without this world pickup and auto-placement
		-- won't see bag space once the bag item is moved out of the main inventory.
		if (!self.vars.isBag and !self.vars.isGear and self.owner) then
			local character = ix.char.loaded and ix.char.loaded[self.owner]

			if (character and character:GetInventory() == self) then
				local gearID = character:GetData("gearInvID")
				local gearInv = gearID and ix.item.inventories[gearID]

				if (gearInv and gearInv != self) then
					for _, itemInst in pairs(gearInv:GearOriginalGetItems(true)) do
						if (itemInst.isBag and itemInst:GetData("equip") == true) then
							local bagInvID = itemInst:GetData("id")

							if (bagInvID and bagInvID != self:GetID() and !table.HasValue(bags, bagInvID)) then
								bags[#bags + 1] = bagInvID
							end
						end
					end
				end
			end
		end

		return bags
	end
end

ix.util.Include("sv_plugin.lua")
ix.util.Include("cl_plugin.lua")

-- ============================================================
-- Commands
-- ============================================================

if (SERVER) then
	local function ForceUnequipForDump(item, owner)
		if (!item or item:GetData("equip") != true or !IsValid(owner)) then
			return
		end

		item.player = owner
		item.bGearDump = true

		if (isfunction(item.Unequip)) then
			item:Unequip(owner, false)
		elseif (isfunction(item.RemoveOutfit)) then
			item:RemoveOutfit(owner)
		elseif (isfunction(item.RemovePart)) then
			item:RemovePart(owner)
		elseif (item.functions and item.functions.EquipUn and item.functions.EquipUn.OnRun) then
			item.functions.EquipUn.OnRun(item)
		else
			item:SetData("equip", false)

			if (item.OnUnequipped) then
				item:OnUnequipped()
			end
		end

		item.player = nil
		item.bGearDump = nil
		item:SetData("equipTime", nil)

		-- Track if it was already dropped during unequip
		if (item.invID <= 0) then
			item.bRecentlyDroppedByDump = true
		end
	end

	ix.inventory.Register("container:gear_dump", 20, 20)

	local function DoGearDump(ply, cmd, args)
		if (!IsValid(ply)) then return end

		local targetPly = ply
		local char = targetPly:GetCharacter()
		if (!char) then return end

		local charID = char:GetID()
		local mainInv = char:GetInventory()
		local mainInvID = mainInv and mainInv:GetID() or 0
		local gearInvID = char:GetData("gearInvID")
		local count = 0

		-- 1. Collect ALL items belonging to this character
		local itemsToDump = {}
		local itemMap = {}

		local function AddItem(item)
			if (item and !itemMap[item:GetID()]) then
				itemsToDump[#itemsToDump + 1] = item
				itemMap[item:GetID()] = true
			end
		end

		if (mainInv) then
			for _, item in pairs(mainInv:GetItems(true)) do AddItem(item) end
		end

		local gearInv = gearInvID and ix.item.inventories[gearInvID]
		if (gearInv) then
			for _, item in pairs(gearInv:GetItems(true)) do AddItem(item) end
		end

		for _, item in pairs(ix.item.instances) do
			local bIsOurs = (item.characterID == charID) or (gearInvID and item.invID == gearInvID) or (item.player == targetPly)
			if (bIsOurs and (item.invID > 0 or item:GetData("equip") == true)) then
				AddItem(item)
			end
		end

		if (#itemsToDump == 0) then
			ply:NotifyLocalized("noItemsToStore")
			return
		end

		-- 2. Sort items (Accessories -> Suits last)
		table.sort(itemsToDump, function(a, b)
			local aEquipped = a:GetData("equip") == true
			local bEquipped = b:GetData("equip") == true
			if (aEquipped != bEquipped) then return aEquipped end
			if (aEquipped) then
				local categoryA = a.outfitCategory or ""
				local categoryB = b.outfitCategory or ""
				if ((categoryA == "suit") ~= (categoryB == "suit")) then return categoryA != "suit" end
			end
			return (a.id or 0) < (b.id or 0)
		end)

		-- 3. Phase 1: Force Unequip (Synchronous)
		for _, item in ipairs(itemsToDump) do
			if (item:GetData("equip") == true) then
				ForceUnequipForDump(item, targetPly)
			end
		end

		-- 4. Create Container and Transfer (Async)
		local model = "models/props_junk/cardboard_box003b.mdl"
		local container = ents.Create("ix_container")
		container:SetPos(targetPly:GetPos() + targetPly:GetForward() * 48 + Vector(0, 0, 32))
		container:SetAngles(Angle(0, targetPly:GetAngles().y + 180, 0))
		container:SetModel(model)
		
		-- Prevent ID 0 from returning the default ground inventory table before DB assigns real ID
		container:SetID(-1)
		
		container:Spawn()
		container:SetDisplayName(L("gearDumpContainerName", targetPly, targetPly:Nick()))

		local targetCharID = charID
		local oldUse = container.Use
		container.Use = function(self, activator)
			local actChar = activator:GetCharacter()
			if (!actChar or actChar:GetID() != targetCharID) then
				activator:NotifyLocalized("gearDumpNotOwner")
				return
			end
			if (oldUse) then oldUse(self, activator) end
		end

		local containerEntID = container:EntIndex()
		timer.Create("ixGearDump_" .. containerEntID, 2, 0, function()
			if (!IsValid(container)) then
				timer.Remove("ixGearDump_" .. containerEntID)
				return
			end
			local inv = container:GetInventory()
			if (inv) then
				if (!ix.storage.InUse(inv) and table.IsEmpty(inv:GetItems())) then
					container:Remove()
				end
			end
		end)

		ix.inventory.New(0, "container:gear_dump", function(inv)
			inv.vars.isBag = true
			inv.vars.isContainer = true

			if (IsValid(container)) then
				container:SetInventory(inv)
			end

			local dumpCount = 0
			for _, item in ipairs(itemsToDump) do
				local x, y = inv:FindEmptySlot(item.width, item.height)
				
				item.bGearTransfer = true
				local oldCanTransfer = item.CanTransfer
				item.CanTransfer = function() return true end

				if (x and y) then
					if (item:Transfer(inv:GetID(), x, y)) then
						dumpCount = dumpCount + 1
					end
				else
					-- Fallback to ground if container fills up
					item:Transfer(0)
					dumpCount = dumpCount + 1
				end

				item.CanTransfer = oldCanTransfer
				item.bGearTransfer = nil
			end

			-- Cleanup original slots
			if (gearInvID) then
				local gInv = ix.item.inventories[gearInvID]
				if (gInv) then gInv.slots = {} if (gInv.Sync) then gInv:Sync(targetPly) end end
			end
			if (mainInv) then
				mainInv.slots = {} if (mainInv.Sync) then mainInv:Sync(targetPly) end
			end

			ply:NotifyLocalized("gearDumpNotify", targetPly:Nick(), dumpCount)
		end)
	end

	-- Internal server command that does the actual work
	concommand.Add("ix_gear_dump_sv", DoGearDump)
end

-- Universal command registration for autocomplete
concommand.Add("ix_gear_dump", function(ply, cmd, args)
	if (CLIENT) then
		-- Proxy to server command
		local argStr = table.concat(args, " ")
		LocalPlayer():ConCommand("ix_gear_dump_sv " .. argStr)
	else
		-- Server logic (concommand doesn't forward from client if registered on both, so we handle it)
		if (SERVER and IsValid(ply) and ply:IsAdmin()) then
			-- Using the internal function directly
			-- Wait! In GMod, this block only runs if the call was local to the server.
			-- Calls from client console for shared commands only run the client's version.
			-- So we rely on ix_gear_dump_sv for client->server calls.
		end
	end
end)
