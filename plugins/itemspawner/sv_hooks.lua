
local PLUGIN = PLUGIN

PLUGIN.spawner = PLUGIN.spawner or {}
PLUGIN.items = PLUGIN.items or {}
PLUGIN.spawner.positions = PLUGIN.spawner.positions or {}

PLUGIN.items.common = {
	"pistol"
}

PLUGIN.items.rare = {
	"shotgun"
}

function PLUGIN:InitializedPlugins()
	local ixloot = ix.plugin.list["ixloot"]
	
	if (ixloot and ixloot.randomLoot) then
		PLUGIN.items.common = {}
		PLUGIN.items.rare = {}

		local function ProcessLootTable(src, dest)
			for k, v in pairs(src) do
				local itemID
				local weight

				if (type(v) == "number") then
					itemID = k
					weight = v
				elseif (type(v) == "string") then
					itemID = v
					local itemTable = ix.item.list[itemID]
					local price = (itemTable and itemTable.price) or 10
					weight = math.Clamp(math.floor(100 / math.max(1, price)), 1, 100)
				end

				if (itemID and weight) then
					for i = 1, weight do
						table.insert(dest, itemID)
					end
				end
			end
		end

		if (ixloot.randomLoot.common) then
			ProcessLootTable(ixloot.randomLoot.common, PLUGIN.items.common)
		end

		if (ixloot.randomLoot.rare) then
			ProcessLootTable(ixloot.randomLoot.rare, PLUGIN.items.rare)
		end
	end
end

util.AddNetworkString("ixItemSpawnerManager")
util.AddNetworkString("ixItemSpawnerDelete")
util.AddNetworkString("ixItemSpawnerEdit")
util.AddNetworkString("ixItemSpawnerGoto")
util.AddNetworkString("ixItemSpawnerSpawn")
util.AddNetworkString("ixItemSpawnerChanges")
util.AddNetworkString("ixItemSpawnerESP")

function PLUGIN:SyncSpawners()
	local recipients = {}
	for _, v in ipairs(player.GetAll()) do
		if (CAMI.PlayerHasAccess(v, "Helix - Item Spawner", nil)) then
			table.insert(recipients, v)
		end
	end
	
	if (#recipients > 0) then
		net.Start("ixItemSpawnerESP")
			net.WriteTable(PLUGIN.spawner.positions)
		net.Send(recipients)
	end
end

function PLUGIN:LoadData()
	PLUGIN.spawner.positions = self:GetData() or {}
end

function PLUGIN:PlayerLoadedCharacter(client, character, currentChar)
	if (CAMI.PlayerHasAccess(client, "Helix - Item Spawner", nil)) then
		net.Start("ixItemSpawnerESP")
			net.WriteTable(PLUGIN.spawner.positions)
		net.Send(client)
	end
end

function PLUGIN:SaveData()
	self:SetData(PLUGIN.spawner.positions)
end

function PLUGIN:AddSpawner(client, position, title)
	if !(CAMI.PlayerHasAccess(client, "Helix - Item Spawner", nil)) then return end

	local respawnTime = ix.config.Get("spawnerRespawnTime", 600)
	local offsetTime  = ix.config.Get("spawnerOffsetTime", 100)
	if (respawnTime < offsetTime) then
		offsetTime = respawnTime - 60
	end

	table.insert(PLUGIN.spawner.positions, {
		["ID"] = os.time(),
		["title"] = title,
		["delay"] = math.random(respawnTime - offsetTime, respawnTime + offsetTime),
		["lastSpawned"] = os.time(),
		["author"] = client:SteamID64(),
		["position"] = position,
		["rarity"] = ix.config.Get("spawnerRareItemChance", 0)
	})

	PLUGIN:SaveData()
	PLUGIN:SyncSpawners()
end

function PLUGIN:RemoveSpawner(client, title)
	if !(CAMI.PlayerHasAccess(client, "Helix - Item Spawner", nil)) then return end

	for k, v in ipairs(PLUGIN.spawner.positions) do
		if (v.title:lower() == title:lower()) then
			table.remove(PLUGIN.spawner.positions, k)
			PLUGIN:SaveData()
			PLUGIN:SyncSpawners()
			return true
		end
	end
	return false
end

function PLUGIN:ForceSpawn(client, spawner)
	if !(CAMI.PlayerHasAccess(client, "Helix - Item Spawner", nil)) then return end
	if !(ix.config.Get("spawnerActive")) then return end

	spawner.lastSpawned = os.time()
	local rareChance = math.random(100)
	if (rareChance > tonumber(spawner.rarity)) then
		ix.item.Spawn(table.Random(PLUGIN.items.common), spawner.position)
	else
		ix.item.Spawn(table.Random(PLUGIN.items.rare), spawner.position)
	end
end

function PLUGIN:Think()
	if ((self.nextSpawnerCheck or 0) > CurTime()) then return end
	self.nextSpawnerCheck = CurTime() + 2

	if (table.IsEmpty(PLUGIN.spawner.positions) or !(ix.config.Get("spawnerActive", false))) then return end

	for k, v in pairs(PLUGIN.spawner.positions) do
		if (v.lastSpawned + (v.delay * 60) < os.time()) then
			v.lastSpawned = os.time()
			
			local maxItems = ix.config.Get("spawnerMaxItems", 10)
			local itemsAround = 0
			
			for _, ent in ipairs(ents.FindInSphere(v.position, 100)) do
				if (ent:GetClass() == "ix_item") then
					itemsAround = itemsAround + 1
				end
			end
			
			if (itemsAround >= maxItems) then
				continue
			end

			local rareChance = math.random(100)
			if (rareChance <= ix.config.Get("spawnerRareItemChance", 0)) then
				ix.item.Spawn(table.Random(PLUGIN.items.rare), v.position)
			else
				ix.item.Spawn(table.Random(PLUGIN.items.common), v.position)
			end
		end
	end
end

net.Receive("ixItemSpawnerDelete", function(length, client)
	if !(CAMI.PlayerHasAccess(client, "Helix - Item Spawner", nil)) then return end

	local item = net.ReadString()
	PLUGIN:RemoveSpawner(client, item)
end)

net.Receive("ixItemSpawnerGoto", function(length, client)
	if !(CAMI.PlayerHasAccess(client, "Helix - Item Spawner", nil)) then return end

	local position = net.ReadVector()
	client:SetPos(position)
end)

net.Receive("ixItemSpawnerSpawn", function(length, client)
	if !(CAMI.PlayerHasAccess(client, "Helix - Item Spawner", nil)) then return end

	local item = net.ReadTable()
	PLUGIN:ForceSpawn(client, item)
end)

net.Receive("ixItemSpawnerChanges", function(length, client)
	if !(CAMI.PlayerHasAccess(client, "Helix - Item Spawner", nil)) then return end

	local changes = net.ReadTable()

	for k, v in ipairs(PLUGIN.spawner.positions) do
		if (v.ID == changes[1]) then
			v.title = changes[2]
			v.delay = math.Clamp(tonumber(changes[3]) or 1, 1, 10000)
			v.rarity  = math.Clamp(tonumber(changes[4]) or 0, 0, 100)
			PLUGIN:SaveData()
			PLUGIN:SyncSpawners()
		end
	end
end)
