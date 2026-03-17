local PLUGIN = PLUGIN

PLUGIN.name = "Ragdoll Harvest"
PLUGIN.author = "Frosty"
PLUGIN.description = "Lets players harvest usable meat from specific NPC ragdolls."

PLUGIN.license = [[
Copyright © 2026 Frosty

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/
]]

local HARVEST_OPTION_KEY = "harvestCorpse"
local HARVEST_ACTION_KEY = "@harvestingCorpse"
local DEFAULT_HARVEST_TIME = 6
local DEFAULT_HARVEST_SOUND = "physics/body/body_medium_break3.wav"
local HUMAN_BREAK_DAMAGE = 500
local HUMAN_BREAK_SOUND = "physics/body/body_medium_break2.wav"

local humanNPCClasses = {
	npc_alyx = true,
	npc_barney = true,
	npc_breen = true,
	npc_citizen = true,
	-- npc_combine_s = true,
	npc_eli = true,
	npc_gman = true,
	npc_kleiner = true,
	npc_metropolice = true,
	npc_monk = true,
	npc_mossman = true,
	npc_odessa = true,
	npc_zombie = true,
	npc_zombie_torso = true,
	npc_fastzombie = true,
	npc_fastzombie_torso = true,
	npc_poisonzombie = true,
}

local humanModelPrefixes = {
	"models/barney.mdl",
	"models/breen.mdl",
	-- "models/combine_",
	"models/eli.mdl",
	"models/gman_high.mdl",
	"models/humans/",
	"models/kleiner.mdl",
	"models/monk.mdl",
	"models/mossman.mdl",
	"models/odessa.mdl",
	"models/police.mdl",
	"models/zombie/",
}

PLUGIN.harvestables = {
	headcrab = {
		item = "headcrab",
		amount = {1, 1},
		time = DEFAULT_HARVEST_TIME,
		sound = DEFAULT_HARVEST_SOUND,
		effect = "blood_impact_yellow_01",
		decal = "YellowBlood",
		models = {
			["models/headcrabclassic.mdl"] = true,
			["models/headcrab.mdl"] = true,
			["models/headcrabblack.mdl"] = true
		}
	},
	antlion = {
		item = "antlion_meat",
		amount = {1, 2},
		time = DEFAULT_HARVEST_TIME,
		sound = DEFAULT_HARVEST_SOUND,
		effect = "blood_impact_yellow_01",
		decal = "YellowBlood",
		models = {
			["models/antlion.mdl"] = true,
			["models/antlion_worker.mdl"] = true,
		}
	},
	antlion_grub = {
		item = "antlion_grub",
		amount = {1, 1},
		time = DEFAULT_HARVEST_TIME,
		sound = DEFAULT_HARVEST_SOUND,
		effect = "blood_impact_yellow_01",
		decal = "YellowBlood",
		models = {
			["models/antlion_grub.mdl"] = true,
		}
	}
}

PLUGIN.breakables = {
	human = {
		damage = HUMAN_BREAK_DAMAGE,
		sound = HUMAN_BREAK_SOUND,
		effect = "blood_advisor_puncture_withdraw",
		decal = "Blood",
		drops = {
			{
				item = "flesh",
				amount = {2, 3}
			},
			{
				item = "bloody_skull",
				amount = {1, 1}
			},
			{
				item = "spine",
				amount = {1, 1}
			},
			{
				item = "rib",
				amount = {1, 2}
			},
		}
	}
}

ix.lang.AddTable("english", {
	harvestCorpse = "Butcher",
	harvestingCorpse = "Butchering...",
	itemFleshDesc = "A ragged strip of flesh hacked from a ruined human corpse.",
	itemBloodySkullDesc = "A blood-soaked human skull cracked loose from a shattered corpse.",
	itemRibDesc = "A rib bone from a shattered corpse.",
	itemSpineDesc = "A spine from a shattered corpse.",
})

ix.lang.AddTable("korean", {
	harvestCorpse = "도축하기",
	harvestingCorpse = "도축 중...",
	["Flesh Chunk"] = "살점",
	itemFleshDesc = "심하게 훼손된 사람 시체에서 뜯겨 나온 살점입니다.",
	["Bloody Skull"] = "피투성이 두개골",
	itemBloodySkullDesc = "산산조각 난 시체에서 떨어져 나온 피투성이 인간 두개골입니다.",
	["Rib"] = "갈비뼈",
	itemRibDesc = "산산조각 시체에서 나온 갈비뼈입니다.",
	["Spine"] = "척추",
	itemSpineDesc = "산산조각 시체에서 나온 척추입니다.",
})

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
	if (!IsValid(npc)) then
		return false
	end

	if (npc:IsNPC() and humanNPCClasses[npc:GetClass()]) then
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
		or entity:GetNetVar("ixPlayerOwner") != nil
		or entity:GetNetVar("ixInventory") != nil
		or entity:GetNetVar("ixPlayerName") != nil
	)
end

function PLUGIN:IsBreakablePlayerCorpse(entity)
	if (!self:IsMarkedPlayerCorpse(entity)) then
		return false
	end

	-- 도축 중인 시체는 보호합니다.
	if (entity:GetNetVar("ixHarvestBusy", false)) then
		return false
	end

	-- 1. 우리 플러그인이 관리하는 최신 시체 소유권 확인
	local owner = entity:GetNetVar("ixPlayerOwner")
	if (IsValid(owner)) then
		return false -- 보호함
	end

	-- 2. (백업용) 다른 플러그인이 설정한 player 넷바 확인
	local altOwner = entity:GetNetVar("player")
	if (IsValid(altOwner)) then
		-- 만약 Persistent Corpses가 넷바를 안 지웠더라도, 엔진 레벨 체크로 이중 보호
		if (altOwner:GetRagdollEntity() == entity or altOwner.ixRagdoll == entity) then
			return false
		end
	end

	-- 주인이 없거나 서버를 나갔거나, 더 이상 최신 시체가 아니면 터짐
	return true
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
	function PLUGIN:MarkHarvestableRagdoll(owner, ragdoll)
		if (!IsValid(owner) or !IsValid(ragdoll) or ragdoll:GetClass() != "prop_ragdoll") then
			return
		end

		local isPlayer = owner:IsPlayer()
		local isNPC = owner:IsNPC()

		if (!isPlayer and !isNPC) then
			return
		end

		-- 플레이어 시체인 경우 최신 시체 관리
		if (isPlayer) then
			-- 이 플레이어의 기존 시체들에서 소유권(보호권)을 제거합니다.
			for _, v in ipairs(ents.FindByClass("prop_ragdoll")) do
				if (v:GetNetVar("ixPlayerOwner") == owner) then
					v:SetNetVar("ixPlayerOwner", nil)
				end
			end

			-- 새 시체에 소유권을 부여합니다.
			ragdoll:SetNetVar("ixPlayerOwner", owner)
		end

		local harvestID = self:GetHarvestID(owner, ragdoll)
		local breakID = self:GetBreakID(owner, ragdoll)

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

	function PLUGIN:OnPlayerCorpseCreated(client, ragdoll)
		self:MarkHarvestableRagdoll(client, ragdoll)
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

		if (breakData.effect) then
			ParticleEffect(breakData.effect, dropPos, Angle(0, 0, 0))
		else
			util.Effect("BloodImpact", effectData, true, true)
		end

		if (breakData.decal) then
			local trace = util.TraceLine({
				start = dropPos + Vector(0, 0, 32),
				endpos = dropPos - Vector(0, 0, 128),
				filter = entity
			})

			if (trace.Hit) then
				util.Decal(breakData.decal, trace.HitPos + trace.HitNormal, trace.HitPos - trace.HitNormal, entity)
			end
		end

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

		-- 도축 중(로딩바)인 시체는 데미지로 터지지 않도록 보호합니다.
		if (entity:GetNetVar("ixHarvestBusy", false)) then
			return
		end

		local breakData = self:GetBreakData(entity)

		if (!breakData) then
			if (self:IsBreakablePlayerCorpse(entity)) then
				breakData = self.breakables.human
			elseif (self:IsMarkedPlayerCorpse(entity)) then
				return
			end
		elseif (self:IsMarkedPlayerCorpse(entity) and !self:IsBreakablePlayerCorpse(entity)) then
			-- 플레이어 시체이면서 최신/보호 대상인 경우, breakData가 있더라도 터지지 않게 보호
			return
		end

		if (!breakData or entity:GetNetVar("ixCorpseDestroyed", false)) then
			return
		end

		entity.ixCorpseDamage = (entity.ixCorpseDamage or 0) + math.max(dmgInfo:GetDamage(), 0)

		if (entity.ixCorpseDamage >= (breakData.damage or HUMAN_BREAK_DAMAGE)) then
			timer.Simple(0, function()
				if (IsValid(entity)) then
					self:ShatterCorpse(entity, breakData)
				end
			end)
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

			if (liveData.effect) then
				ParticleEffect(liveData.effect, dropPos, Angle(0, 0, 0))
			end

			if (liveData.decal) then
				local trace = util.TraceLine({
					start = dropPos + Vector(0, 0, 32),
					endpos = dropPos - Vector(0, 0, 128),
					filter = entity
				})

				if (trace.Hit) then
					util.Decal(liveData.decal, trace.HitPos + trace.HitNormal, trace.HitPos - trace.HitNormal, entity)
				end
			end

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
