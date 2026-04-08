--[[
This work is licensed under a Creative Commons
Attribution-ShareAlike 4.0 International License.
Created by LiGyH.
--]]

PLUGIN.name = "Hunger+++ (merged with Survival System)"
PLUGIN.author = "LiGyH, ZeMysticalTaco | Modified by Frosty"
PLUGIN.description = "A survival system consisting of hunger and thirst."

ix.config.Add("hungerDecaySpeed", 6048, "How long it takes for hunger to decay by 1.", nil, {
	data = {min = 1, max = 10000},
	category = "Survival"
})

ix.config.Add("thirstDecaySpeed", 2592, "How long it takes for thirst to decay by 1.", nil, {
	data = {min = 1, max = 10000},
	category = "Survival"
})

ix.config.Add("syncSurvivalWithTime", true, "Whether or not to synchronize survival decay with time scale.", nil, {
	category = "Survival"
})

local entityMeta = FindMetaTable("Entity")
local cookingEntityClasses = {
	"ix_stove",
	"ix_bucket",
	"ix_bonfire"
}
local cookingCraftCategory = "Food"
local cookingEntityLookup = {
	ix_stove = true,
	ix_bucket = true,
	ix_bonfire = true
}
local stoveMenuSuppressDuration = 0.35

local function GetCookingEntityTable(className)
	local stored = scripted_ents.GetStored(className)

	if (stored and stored.t) then
		return stored.t
	end

	return scripted_ents.Get(className)
end

local function GetCookingTogglePhrase(entity)
	return entity:GetNetVar("active", false) and "stoveTurnOff" or "stoveTurnOn"
end

function entityMeta:IsStove()
	return cookingEntityLookup[self:GetClass()] == true
end

local playerMeta = FindMetaTable("Player")

function PLUGIN:HasRemainingFireStarter(client)
	local character = client:GetCharacter()
	if (!character) then return nil end

	local inventory = character:GetInventory()
	local items = inventory:GetItems()
	local bestItem
	local minUses = 999 

	-- Find the item with the smallest usage count
	for _, v in pairs(items) do
		if (v.uniqueID == "match" or v.uniqueID == "lighter") then
			local uses = v:GetData("uses", v.usenum or 10)
			if (uses > 0 and uses < minUses) then
				minUses = uses
				bestItem = v
			end
		end
	end

	return bestItem
end

function PLUGIN:ConsumeFireStarter(item)
	local uses = item:GetData("uses", item.usenum or 10)
	item:SetData("uses", math.max(0, uses - 1))
end

function PLUGIN:HasIXCraft()
	return ix.plugin.list["ixcraft"] != nil
end

if (CLIENT) then
	function PLUGIN:OpenCookingCraftingMenu(entity)
		local craftPlugin = ix.plugin.list["ixcraft"]

		if (!craftPlugin or !vgui.GetControlTable("ixCrafting")) then
			return false
		end

		if (!IsValid(entity) or !entity:GetNetVar("active", false)) then
			return false
		end

		if (IsValid(ix.gui.stationCrafting)) then
			ix.gui.stationCrafting:Remove()
		end

		LocalPlayer().ixCurrentStation = nil
		LocalPlayer().ixCurrentStationEnt = entity

		local frame = vgui.Create("DFrame")
		frame:SetSize(ScrW() * 0.6, ScrH() * 0.6)
		frame:Center()
		frame:MakePopup()
		frame:SetTitle(L("crafting") .. " - " .. L(entity:GetClass()))

		local craftPanel = frame:Add("ixCrafting")
		craftPanel:SetCategoryFilter({
			[cookingCraftCategory] = true
		}, cookingCraftCategory)
		craftPanel:Dock(FILL)

		frame.OnRemove = function()
			LocalPlayer().ixCurrentStation = nil

			if (LocalPlayer().ixCurrentStationEnt == entity) then
				LocalPlayer().ixCurrentStationEnt = nil
			end
		end

		ix.gui.stationCrafting = frame
		return true
	end
end

function PLUGIN:PatchCookingEntityMenus()
	if (!self:HasIXCraft()) then
		return
	end

	local hungerPlugin = self

	for _, className in ipairs(cookingEntityClasses) do
		local entityTable = GetCookingEntityTable(className)

		if (!entityTable or entityTable.ixHungerCraftMenuPatched) then
			continue
		end

		entityTable.ixHungerCraftMenuPatched = true
		entityTable.ixHungerOriginalUse = entityTable.ixHungerOriginalUse or entityTable.Use
		entityTable.ixHungerOriginalOnOptionSelected = entityTable.ixHungerOriginalOnOptionSelected or entityTable.OnOptionSelected

		function entityTable:GetEntityMenu(client)
			local craftPlugin = ix.plugin.list["ixcraft"]
			local categories = craftPlugin and craftPlugin.craft.GetCategories(client)
			local isActive = self:GetNetVar("active", false)
			local options = {}

			if (!isActive) then
				return options
			end

			if (categories and categories[cookingCraftCategory] and !table.IsEmpty(categories[cookingCraftCategory])) then
				if (CLIENT) then
					options[L("stoveOpenCrafting", client)] = function()
						hungerPlugin:OpenCookingCraftingMenu(self)
						return false
					end
				else
					options["stoveOpenCrafting"] = true
				end
			end

			options[L(GetCookingTogglePhrase(self), client)] = true

			return options
		end

		function entityTable:OnOptionSelected(client, option, data)
			if (option == L(GetCookingTogglePhrase(self), client)) then
				if (isfunction(self.ixHungerOriginalUse)) then
					self:ixHungerOriginalUse(client)
				end

				return
			end

			if (isfunction(self.ixHungerOriginalOnOptionSelected)) then
				return self:ixHungerOriginalOnOptionSelected(client, option, data)
			end
		end
	end
end

function PLUGIN:InitializedPlugins()
	self:PatchCookingEntityMenus()
end

function PLUGIN:PlayerUse(client, entity)
	if (IsValid(entity) and entity:GetClass() == "ix_stove" and !entity:GetNetVar("active", false)) then
		client:SetLocalVar("ixSuppressCookingMenuEnt", entity:EntIndex())
		client:SetLocalVar("ixSuppressCookingMenuUntil", CurTime() + stoveMenuSuppressDuration)
		return true
	end

	if (IsValid(entity) and entity.IsStove and entity:IsStove() and !entity:GetNetVar("active", false)) then
		return true
	end
end

if (CLIENT) then
	function PLUGIN:ShowEntityMenu(entity)
		local suppressUntil = LocalPlayer():GetLocalVar("ixSuppressCookingMenuUntil", 0)
		local suppressEnt = LocalPlayer():GetLocalVar("ixSuppressCookingMenuEnt", 0)

		if (IsValid(entity) and entity:GetClass() == "ix_stove" and suppressEnt == entity:EntIndex() and suppressUntil > CurTime()) then
			return false
		end

		if (IsValid(entity) and entity.IsStove and entity:IsStove() and !entity:GetNetVar("active", false)) then
			return false
		end
	end
end

function playerMeta:GetHunger()
	local char = self:GetCharacter()

	if (char) then
		return char:GetData("hunger", 100)
	end
	
	return 100
end

function playerMeta:GetThirst()
	local char = self:GetCharacter()

	if (char) then
		return char:GetData("thirst", 100)
	end
	
	return 100
end

if SERVER then
	function PLUGIN:OnCharacterCreated(client, character)
		character:SetData("hunger", 100)
		character:SetData("thirst", 100)
	end

	function PLUGIN:PlayerLoadedCharacter(client, character)
		timer.Simple(0.25, function()
			local hunger = character:GetData("hunger", 100)
			local thirst = character:GetData("thirst", 100)

			client:SetLocalVar("hunger", hunger)
			client:SetLocalVar("thirst", thirst)

			client.ixLastHungerState = self:GetHungerState(hunger)
			client.ixLastHungerValue = hunger
			client.ixLastThirstState = self:GetThirstState(thirst)
			client.ixLastThirstValue = thirst

			client.ixNextHungerMessage = CurTime() + 300
			client.ixNextThirstMessage = CurTime() + 300
		end)
	end

	function PLUGIN:CharacterPreSave(character)
		local client = character:GetPlayer()

		if (IsValid(client)) then
			character:SetData("hunger", client:GetLocalVar("hunger", 0))
			character:SetData("thirst", client:GetLocalVar("thirst", 0))
		end
	end
	
	function PLUGIN:PlayerDeath(client)
		client.resetHunger = true
		client.resetThirst = true
	end

	function PLUGIN:PlayerSpawn(client)
		local char = client:GetCharacter()
		
		if (char and client.resetHunger) then
			char:SetData("hunger", 100)
			client:SetLocalVar("hunger", 100)
			client.resetHunger = false
		end
		
		if (char and client.resetThirst) then
			char:SetData("thirst", 100)
			client:SetLocalVar("thirst", 100)
			client.resetThirst = false
		end

		if (char) then
			local bIsCombine = false
			
			if (bIsCombine) then
				char:SetData("hunger", 100)
				client:SetLocalVar("hunger", 100)
				char:SetData("thirst", 100)
				client:SetLocalVar("thirst", 100)
				client.resetThirst = false
				client.resetHunger = false
			end
		end
	end

	local playerMeta = FindMetaTable("Player")

	function playerMeta:SetHunger(amount)
		local char = self:GetCharacter()

		if (char) then
			char:SetData("hunger", amount)
			self:SetLocalVar("hunger", amount)
		end
	end

	function playerMeta:SetThirst(amount)
		local char = self:GetCharacter()

		if (char) then
			char:SetData("thirst", amount)
			self:SetLocalVar("thirst", amount)
		end
	end

	function playerMeta:TickThirst(amount)
		local char = self:GetCharacter()

		if (char) then
			char:SetData("thirst", char:GetData("thirst", 100) - amount)
			self:SetLocalVar("thirst", char:GetData("thirst", 100) - amount)

			if char:GetData("thirst", 100) < 0 then
				char:SetData("thirst", 0)
				self:SetLocalVar("thirst", 0)
			end
		end
	end

	function playerMeta:TickHunger(amount)
		local char = self:GetCharacter()

		if (char) then
			char:SetData("hunger", char:GetData("hunger", 100) - amount)
			self:SetLocalVar("hunger", char:GetData("hunger", 100) - amount)

			if char:GetData("hunger", 100) < 0 then
				char:SetData("hunger", 0)
				self:SetLocalVar("hunger", 0)
			end
		end
	end

	function PLUGIN:GetHungerState(val)
		if (val < 20) then return "starving" end
		if (val < 40) then return "hungry" end
		if (val < 60) then return "grumbling" end
		return "normal"
	end

	function PLUGIN:GetThirstState(val)
		if (val < 20) then return "dehydrated" end
		if (val < 40) then return "lightlyDehydrated" end
		if (val < 60) then return "thirsty" end
		if (val < 80) then return "parched" end
		return "normal"
	end

	function PLUGIN:PlayerTick(ply)
		local scale = 1

		if (ix.config.Get("syncSurvivalWithTime", false)) then
			scale = math.max(0.01, ix.config.Get("secondsPerMinute", 60) / 60)
		end

		if ply:GetNetVar("hungertick", 0) <= CurTime() then
			ply:SetNetVar("hungertick", (ix.config.Get("hungerDecaySpeed", 300) * scale) + CurTime())
			ply:TickHunger(1, 1)
		end

		if ply:GetNetVar("thirsttick", 0) <= CurTime() then
			ply:SetNetVar("thirsttick", (ix.config.Get("thirstDecaySpeed", 2592) * scale) + CurTime())
			ply:TickThirst(1, 1)
		end
	end
	
	local checkTime = CurTime()

	function PLUGIN:Think()
		if (checkTime < CurTime()) then
			for _, v in ipairs(player.GetAll()) do
				local char = v:GetCharacter()
				if (!char) then continue end

				local hunger = v:GetLocalVar("hunger", 100)
				local thirst = v:GetLocalVar("thirst", 100)

				-- Damage logic
				if (hunger <= 0) then
					v:TakeDamage(1, v, v:GetActiveWeapon())
				end

				if (thirst <= 0) then
					v:TakeDamage(2, v, v:GetActiveWeapon())
				end

				-- Notification logic
				local hungerState = self:GetHungerState(hunger)
				local lastHungerState = v.ixLastHungerState or "normal"

				-- Notification logic
				local hungerState = self:GetHungerState(hunger)
				local lastHungerState = v.ixLastHungerState or "normal"

				if (hungerState != "normal") then
					-- Enter message (only if state worsened)
					if (hungerState != lastHungerState and hunger < (v.ixLastHungerValue or 100)) then
						ix.chat.Send(v, "it", L(hungerState .. "Enter", v), false, {v})
						v.ixNextHungerMessage = CurTime() + 300
					-- Periodic message
					elseif ((v.ixNextHungerMessage or 0) < CurTime()) then
						local key = hungerState .. "Periodic"
						if (L(key, v) != key) then
							ix.chat.Send(v, "it", L(key, v), false, {v})
						end
						v.ixNextHungerMessage = CurTime() + 300
					end
				end
				v.ixLastHungerState = hungerState
				v.ixLastHungerValue = hunger

				local thirstState = self:GetThirstState(thirst)
				local lastThirstState = v.ixLastThirstState or "normal"

				if (thirstState != "normal") then
					-- Enter message
					if (thirstState != lastThirstState and thirst < (v.ixLastThirstValue or 100)) then
						ix.chat.Send(v, "it", L(thirstState .. "Enter", v), false, {v})
						v.ixNextThirstMessage = CurTime() + 300
					-- Periodic message
					elseif ((v.ixNextThirstMessage or 0) < CurTime()) then
						local key = thirstState .. "Periodic"
						if (L(key, v) != key) then
							ix.chat.Send(v, "it", L(key, v), false, {v})
						end
						v.ixNextThirstMessage = CurTime() + 300
					end
				end
				v.ixLastThirstState = thirstState
				v.ixLastThirstValue = thirst
			end

			checkTime = CurTime() + 15
		end
	end

	function PLUGIN:SaveData()
		local data = {}
		local stoveClasses = {"ix_stove", "ix_bonfire", "ix_bucket"}

		for _, class in ipairs(stoveClasses) do
			for _, v in ipairs(ents.FindByClass(class)) do
				data[#data + 1] = {
					class = class,
					pos = v:GetPos(),
					angles = v:GetAngles(),
					active = v:GetNetVar("active"),
					broken = v:GetNetVar("broken"),
					igniter = v:GetNetVar("igniter"),
					fuelList = v.fuelList or {}
				}
			end
		end

		self:SetData(data)
	end

	function PLUGIN:LoadData()
		local data = self:GetData()

		if (data) then
			for _, v in ipairs(data) do
				local entity = ents.Create(v.class)
				entity:SetPos(v.pos)
				entity:SetAngles(v.angles)
				entity:Spawn()
				entity:Activate()
				entity:SetNetVar("active", v.active)
				entity:SetNetVar("broken", v.broken or false)
				if (v.broken) then
					entity:SetColor(Color(100, 100, 100))
				end
				entity:SetNetVar("igniter", v.igniter or 0)
				entity.fuelList = v.fuelList or {}
				if (entity.UpdateFuelNetVars) then
					entity:UpdateFuelNetVars()
				end

				local phys = entity:GetPhysicsObject()
				if (IsValid(phys)) then
					phys:EnableMotion(false)
				end
			end
		end
	end
	
end

if (CLIENT) then
	function PLUGIN:RenderScreenspaceEffects()
		if (LocalPlayer():GetCharacter()) then
			if (LocalPlayer():GetHunger() < 20) then
				DrawMotionBlur(0.1, 0.3, 0.01)
			end
			
			if (LocalPlayer():GetThirst() < 20) then
				DrawMotionBlur(0.1, 0.3, 0.01)
			end
		end
    end

	ix_Fire_sprite = ix_Fire_sprite or {}
	ix_Fire_sprite.fire = Material("particles/fire1") 
	ix_Fire_sprite.nextFrame = CurTime()
	ix_Fire_sprite.curFrame = 0

	function PLUGIN:Think()
		if ix_Fire_sprite.nextFrame < CurTime() then
			ix_Fire_sprite.nextFrame = CurTime() + 0.05 * (1 - FrameTime())
			ix_Fire_sprite.curFrame = (ix_Fire_sprite.curFrame or 0) + 1
			ix_Fire_sprite.fire:SetFloat("$frame", ix_Fire_sprite.curFrame % 22 )
		end
	end

	ix.bar.Add(function()
		local status = ""
		local var = LocalPlayer():GetLocalVar("hunger", 0) / 100
		local bShowLabels = ix.option.Get("showBarLabels", false)

		if var < 0.2 then
			status = L"starving"
		elseif var < 0.4 then
			status = L"hungry"
		elseif var < 0.6 then
			status = L"grumbling"
		else
			status = bShowLabels and L"notHungry"
		end

		return var, status
	end, Color(40, 100, 40), nil, "hunger")

	ix.bar.Add(function()
		local status = ""
		local var = LocalPlayer():GetLocalVar("thirst", 0) / 100
		local bShowLabels = ix.option.Get("showBarLabels", false)

		if var < 0.2 then
			status = L"dehydrated"
		elseif var < 0.4 then
			status = L"lightlyDehydrated"
		elseif var < 0.6 then
			status = L"thirsty"
		elseif var < 0.8 then
			status = L"parched"
		else
			status = bShowLabels and L"notThirsty"
		end

		return var, status
	end, Color(40, 40, 200), nil, "thirst")
end

function PLUGIN:AdjustStaminaOffset(client, offset)
	local char = client:GetCharacter()
	local enabled = client:Team() != FACTION_OTA

	if (!char or !enabled) then
		return
	end

	local hunger = client:GetHunger()
	local thirst = client:GetThirst()
	local penalty = 0

	-- Hunger Penalties
	if (hunger < 20) then
		penalty = penalty - 0.3 -- Starving (was -0.5)
	elseif (hunger < 40) then
		penalty = penalty - 0.15 -- Hungry (was -0.2)
	elseif (hunger < 60) then
		penalty = penalty - 0.05 -- Grumbling
	end

	-- Thirst Penalties
	if (thirst < 20) then
		penalty = penalty - 0.5 -- Dehydrated (was -0.7)
	elseif (thirst < 40) then
		penalty = penalty - 0.25 -- Lightly Dehydrated (was -0.3)
	elseif (thirst < 60) then
		-- Only apply if they are also somewhat hungry
		if (hunger < 60) then
			penalty = penalty - 0.1 -- Thirsty
		end
	elseif (thirst < 80) then
		if (hunger < 60) then
			penalty = penalty - 0.05 -- Parched
		end
	end

	if (penalty != 0) then
		return offset + penalty
	end
end

ix.command.Add("CharSetHunger", {
	adminOnly = true,
	arguments = {
		ix.type.player,
		ix.type.number
	},
	OnRun = function(self, client, target, hunger)
		target:SetHunger(hunger)

		if client == target then
			client:NotifyLocalized("charSetHunger01", hunger)
		else
			client:NotifyLocalized("charSetHunger02", target:GetName(), hunger)
			target:NotifyLocalized("charSetHunger03", client:GetName(), hunger)
		end
	end
})

ix.command.Add("CharSetThirst", {
	adminOnly = true,
	arguments = {
		ix.type.player,
		ix.type.number
	},
	OnRun = function(self, client, target, thirst)
		target:SetThirst(thirst)

		if client == target then
			client:NotifyLocalized("charSetThirst01", thirst)
		else
			client:NotifyLocalized("charSetThirst02", target:GetName(), thirst)
			target:NotifyLocalized("charSetThirst03", client:GetName(), thirst)
		end
	end
})

properties.Add("ixHungerFuelOverride", {
	MenuLabel = "Override Fuel",
	Order = 999,
	MenuIcon = "icon16/clock_edit.png",
	Filter = function(self, ent, ply)
		if (!IsValid(ent)) then return false end
		local classes = {["ix_bucket"] = true, ["ix_bonfire"] = true, ["ix_stove"] = true}
		return classes[ent:GetClass()] and ply:IsAdmin()
	end,
	Action = function(self, ent)
		Derma_StringRequest("Override Fuel", "Enter fuel duration in minutes:", "60", function(text)
			local minutes = tonumber(text)
			if (minutes) then
				self:MsgStart()
					net.WriteEntity(ent)
					net.WriteUInt(minutes * 60, 32)
				self:MsgEnd()
			end
		end)
	end,
	Receive = function(self, length, ply)
		local ent = net.ReadEntity()
		local seconds = net.ReadUInt(32)
		if (!IsValid(ent) or !ply:IsAdmin()) then return end
		
		ent.fuelList = {seconds}
		if (ent.UpdateFuelNetVars) then
			ent:UpdateFuelNetVars()
		end
	end
})

properties.Add("ixHungerBatterySet", {
	MenuLabel = "Install Battery",
	Order = 1000,
	MenuIcon = "icon16/lightning.png",
	Filter = function(self, ent, ply)
		return IsValid(ent) and ent:GetClass() == "ix_stove" and ply:IsAdmin()
	end,
	Action = function(self, ent)
		self:MsgStart()
			net.WriteEntity(ent)
		self:MsgEnd()
	end,
	Receive = function(self, length, ply)
		local ent = net.ReadEntity()
		if (!IsValid(ent) or !ply:IsAdmin() or ent:GetClass() != "ix_stove") then return end
		ent:SetNetVar("igniter", 100)
	end
})

properties.Add("ixHungerRepair", {
	MenuLabel = "Repair Stove",
	Order = 1001,
	MenuIcon = "icon16/wrench.png",
	Filter = function(self, ent, ply)
		return IsValid(ent) and ent:GetClass() == "ix_stove" and ent:GetNetVar("broken", false) and ply:IsAdmin()
	end,
	Action = function(self, ent)
		self:MsgStart()
			net.WriteEntity(ent)
		self:MsgEnd()
	end,
	Receive = function(self, length, ply)
		local ent = net.ReadEntity()
		if (!IsValid(ent) or !ply:IsAdmin() or ent:GetClass() != "ix_stove") then return end
		ent:SetNetVar("broken", false)
		ent:SetColor(Color(255, 255, 255))
	end
})
