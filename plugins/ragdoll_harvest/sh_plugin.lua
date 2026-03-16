local PLUGIN = PLUGIN

PLUGIN.name = "Ragdoll Harvest"
PLUGIN.author = "Frosty"
PLUGIN.description = "Lets players harvest usable meat from specific NPC ragdolls."

local HARVEST_OPTION_KEY = "harvestCorpse"
local HARVEST_ACTION_KEY = "@harvestingCorpse"
local DEFAULT_HARVEST_TIME = 6
local DEFAULT_HARVEST_SOUND = "physics/body/body_medium_break3.wav"
local HUMAN_BREAK_DAMAGE = 200
local HUMAN_BREAK_SOUND = "physics/body/body_medium_break2.wav"

local humanNPCClasses = {
	npc_alyx = true,
	npc_barney = true,
	npc_breen = true,
	npc_citizen = true,
	npc_combine_s = true,
	npc_eli = true,
	npc_gman = true,
	npc_kleiner = true,
	npc_metropolice = true,
	npc_monk = true,
	npc_mossman = true,
	npc_odessa = true
}

local humanModelPrefixes = {
	"models/barney.mdl",
	"models/breen.mdl",
	"models/combine_",
	"models/eli.mdl",
	"models/gman_high.mdl",
	"models/humans/",
	"models/kleiner.mdl",
	"models/monk.mdl",
	"models/mossman.mdl",
	"models/odessa.mdl",
	"models/police.mdl"
}

PLUGIN.harvestables = {
	headcrab = {
		item = "headcrab",
		amount = {1, 1},
		time = DEFAULT_HARVEST_TIME,
		sound = DEFAULT_HARVEST_SOUND,
		models = {
			["models/headcrabclassic.mdl"] = true,
			["models/headcrab.mdl"] = true,
			["models/headcrabblack.mdl"] = true
		}
	}
}

PLUGIN.breakables = {
	human = {
		damage = HUMAN_BREAK_DAMAGE,
		sound = HUMAN_BREAK_SOUND,
		drops = {
			{
				item = "flesh_chunk",
				amount = {2, 3}
			},
			{
				item = "bloody_skull",
				amount = {1, 1}
			},
			{
				item = "comp_bone",
				amount = {1, 2}
			}
		}
	}
}

do
	ix.lang.AddTable("english", {
		harvestCorpse = "Butcher",
		harvestingCorpse = "Butchering...",
		itemFleshChunk = "Flesh Chunk",
		itemHumanMeatDesc = "A ragged strip of flesh hacked from a ruined human corpse."
	})

	ix.lang.AddTable("korean", {
		harvestCorpse = "도축하기",
		harvestingCorpse = "도축 중...",
		itemFleshChunk = "살점",
		itemHumanMeatDesc = "심하게 훼손된 사람 시체에서 뜯겨 나온 살점입니다."
	})

	ix.lang.AddTable("english", {
		itemBloodySkull = "Bloody Skull",
		itemBloodySkullDesc = "A blood-soaked human skull cracked loose from a shattered corpse."
	})

	ix.lang.AddTable("korean", {
		itemBloodySkull = "피투성이 두개골",
		itemBloodySkullDesc = "산산조각 난 시체에서 떨어져 나온 피투성이 인간 두개골입니다."
	})
end

local function CopyOptions(source)
	local options = {}

	if (istable(source)) then
		for key, value in pairs(source) do
			options[key] = value
		end
	end

	return options
end

function PLUGIN:GetHarvestID(npc, ragdoll)
	local model = string.lower((IsValid(ragdoll) and ragdoll:GetModel()) or (IsValid(npc) and npc:GetModel()) or "")

	if (model == "") then
		return nil
	end

	for harvestID, data in pairs(self.harvestables) do
		if (data.models and data.models[model]) then
			return harvestID
		end
	end

	return nil
end

function PLUGIN:IsHumanCorpse(npc, ragdoll)
	if (!IsValid(npc) or !npc:IsNPC()) then
		return false
	end

	if (humanNPCClasses[npc:GetClass()]) then
		return true
	end

	local model = string.lower((IsValid(ragdoll) and ragdoll:GetModel()) or npc:GetModel() or "")

	for _, prefix in ipairs(humanModelPrefixes) do
		if (string.StartWith(model, prefix)) then
			return true
		end
	end

	return false
end

function PLUGIN:GetBreakID(npc, ragdoll)
	if (self:IsHumanCorpse(npc, ragdoll)) then
		return "human"
	end

	return nil
end

function PLUGIN:GetHarvestData(entity)
	if (!IsValid(entity) or entity:GetClass() != "prop_ragdoll") then
		return nil
	end

	local harvestID = entity:GetNetVar("ixHarvestCorpseType")

	if (!harvestID) then
		return nil
	end

	return self.harvestables[harvestID], harvestID
end

function PLUGIN:GetBreakData(entity)
	if (!IsValid(entity) or entity:GetClass() != "prop_ragdoll") then
		return nil
	end

	local breakID = entity:GetNetVar("ixCorpseBreakType")

	if (!breakID) then
		return nil
	end

	return self.breakables[breakID], breakID
end

function PLUGIN:IsMarkedPlayerCorpse(entity)
	return IsValid(entity) and entity:GetClass() == "prop_ragdoll" and (
		entity:GetNetVar("player") != nil
		or entity:GetNetVar("ixInventory") != nil
		or entity:GetNetVar("ixPlayerName") != nil
	)
end

function PLUGIN:IsDisconnectedPlayerCorpse(entity)
	if (!self:IsMarkedPlayerCorpse(entity)) then
		return false
	end

	local owner = entity:GetNetVar("player")

	return !IsValid(owner)
end

function PLUGIN:CanHarvestEntity(entity)
	local data = self:GetHarvestData(entity)

	return data != nil and !entity:GetNetVar("ixHarvested", false)
end

if (CLIENT) then
	function PLUGIN:PatchRagdollMenu(entity)
		if (!IsValid(entity) or entity:GetClass() != "prop_ragdoll" or entity.ixHarvestMenuPatched) then
			return
		end

		entity.ixHarvestMenuPatched = true

		local originalGetEntityMenu = entity.GetEntityMenu

		entity.GetEntityMenu = function(this, client)
			local options = CopyOptions(isfunction(originalGetEntityMenu) and originalGetEntityMenu(this, client) or nil)

			if (PLUGIN:CanHarvestEntity(this) and !this:GetNetVar("ixHarvestBusy", false)) then
				options[L(HARVEST_OPTION_KEY, client)] = true
			end

			return options
		end
	end

	function PLUGIN:OnEntityCreated(entity)
		if (entity:GetClass() != "prop_ragdoll") then
			return
		end

		timer.Simple(0, function()
			if (IsValid(entity)) then
				self:PatchRagdollMenu(entity)
			end
		end)
	end
end

if (SERVER) then
	function PLUGIN:MarkHarvestableRagdoll(npc, ragdoll)
		if (!IsValid(npc) or !npc:IsNPC() or !IsValid(ragdoll) or ragdoll:GetClass() != "prop_ragdoll") then
			return
		end

		local harvestID = self:GetHarvestID(npc, ragdoll)
		local breakID = self:GetBreakID(npc, ragdoll)

		if (!harvestID and !breakID) then
			return
		end

		if (harvestID) then
			ragdoll:SetNetVar("ixHarvestCorpseType", harvestID)
			ragdoll:SetNetVar("ixHarvested", false)
			ragdoll:SetNetVar("ixHarvestBusy", false)
			ragdoll.GetEntityMenu = ragdoll.GetEntityMenu or function()
				return {}
			end
		end

		if (breakID) then
			ragdoll:SetNetVar("ixCorpseBreakType", breakID)
			ragdoll.ixCorpseDamage = 0
		end

		local originalOnOptionSelected = ragdoll.OnOptionSelected

		function ragdoll:OnOptionSelected(client, option, data)
			if (harvestID and option == L(HARVEST_OPTION_KEY, client)) then
				PLUGIN:BeginHarvest(client, self)
				return
			end

			if (isfunction(originalOnOptionSelected)) then
				return originalOnOptionSelected(self, client, option, data)
			end
		end
	end

	function PLUGIN:CreateEntityRagdoll(npc, ragdoll)
		self:MarkHarvestableRagdoll(npc, ragdoll)
	end

	function PLUGIN:ShatterCorpse(entity, breakData)
		if (!IsValid(entity) or !breakData or entity:GetNetVar("ixCorpseDestroyed", false)) then
			return
		end

		entity:SetNetVar("ixCorpseDestroyed", true)
		entity:SetNetVar("ixHarvested", true)
		entity:SetNetVar("ixHarvestBusy", false)
		entity.ixHarvestBusyBy = nil

		local dropPos = entity:GetPos() + Vector(0, 0, 12)
		local effectData = EffectData()
		effectData:SetOrigin(dropPos)
		effectData:SetScale(1)

		entity:EmitSound(breakData.sound or HUMAN_BREAK_SOUND)
		util.Effect("BloodImpact", effectData, true, true)

		for _, dropInfo in ipairs(breakData.drops or {}) do
			if (ix.item.Get(dropInfo.item)) then
				local minAmount = (dropInfo.amount and dropInfo.amount[1]) or 1
				local maxAmount = (dropInfo.amount and dropInfo.amount[2]) or minAmount
				local amount = math.max(1, math.random(minAmount, maxAmount))

				for i = 1, amount do
					ix.item.Spawn(dropInfo.item, dropPos + VectorRand() * 12)
				end
			end
		end

		entity:Remove()
	end

	function PLUGIN:EntityTakeDamage(entity, dmgInfo)
		if (!IsValid(entity) or entity:GetClass() != "prop_ragdoll") then
			return
		end

		local breakData = self:GetBreakData(entity)

		if (!breakData) then
			if (self:IsDisconnectedPlayerCorpse(entity)) then
				breakData = self.breakables.human
			elseif (self:IsMarkedPlayerCorpse(entity)) then
				return
			end
		end

		if (!breakData or entity:GetNetVar("ixCorpseDestroyed", false)) then
			return
		end

		entity.ixCorpseDamage = (entity.ixCorpseDamage or 0) + math.max(dmgInfo:GetDamage(), 0)

		if (entity.ixCorpseDamage >= (breakData.damage or HUMAN_BREAK_DAMAGE)) then
			self:ShatterCorpse(entity, breakData)
		end
	end

	function PLUGIN:BeginHarvest(client, entity)
		if (!IsValid(client) or !client:Alive() or !IsValid(entity)) then
			return
		end

		local data = self:GetHarvestData(entity)

		if (!data or entity:GetNetVar("ixHarvested", false)) then
			return
		end

		if (client:GetPos():DistToSqr(entity:GetPos()) > 96 ^ 2) then
			client:NotifyLocalized("tooFar")
			return
		end

		if (entity:GetNetVar("ixHarvestBusy", false) and entity.ixHarvestBusyBy != client) then
			return
		end

		if (!ix.item.Get(data.item)) then
			client:Notify("Missing harvest drop item: " .. data.item)
			return
		end

		entity.ixHarvestBusyBy = client
		entity:SetNetVar("ixHarvestBusy", true)
		client:SetAction(HARVEST_ACTION_KEY, data.time or DEFAULT_HARVEST_TIME)

		client:DoStaredAction(entity, function()
			if (!IsValid(client) or !client:Alive() or !IsValid(entity)) then
				return
			end

			local liveData = self:GetHarvestData(entity)

			if (!liveData or entity:GetNetVar("ixHarvested", false)) then
				client:SetAction()
				return
			end

			entity:SetNetVar("ixHarvested", true)
			entity:SetNetVar("ixHarvestBusy", false)
			entity.ixHarvestBusyBy = nil

			client:SetAction()
			client:EmitSound(liveData.sound or DEFAULT_HARVEST_SOUND)

			local minAmount = (liveData.amount and liveData.amount[1]) or 1
			local maxAmount = (liveData.amount and liveData.amount[2]) or minAmount
			local amount = math.max(1, math.random(minAmount, maxAmount))
			local dropPos = entity:GetPos() + Vector(0, 0, 12)

			for i = 1, amount do
				ix.item.Spawn(liveData.item, dropPos + VectorRand() * 10)
			end

			entity:Remove()
		end, data.time or DEFAULT_HARVEST_TIME, function()
			if (IsValid(client)) then
				client:SetAction()
			end

			if (IsValid(entity)) then
				entity:SetNetVar("ixHarvestBusy", false)
				entity.ixHarvestBusyBy = nil
			end
		end)
	end
end
