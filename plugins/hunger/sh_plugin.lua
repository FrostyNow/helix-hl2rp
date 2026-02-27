--[[
This work is licensed under a Creative Commons
Attribution-ShareAlike 4.0 International License.
Created by LiGyH.
--]]

PLUGIN.name = "Hunger+++ (merged with Survival System)"
PLUGIN.author = "LiGyH, ZeMysticalTaco | Modified by Frosty"
PLUGIN.description = "A survival system consisting of hunger and thirst."

ix.lang.AddTable("english", {
	starving = "Starving",
	hungry = "Hungry",
	grumbling = "Grumbling",
	dehydrated = "Dehydrated",
	lightlyDehydrated = "Lightly Dehydrated",
	thirsty = "Thirsty",
	parched = "Parched",
	charSetHunger01 = "You've set your hunger amount as %s.",
	charSetHunger02 = "You've set %s's hunger amount as %s.",
	charSetHunger02 = "%s have set your hunger amount as %s.",
	charSetThirst01 = "You've set your thirst amount as %s.",
	charSetThirst02 = "You've set %s's thirst amount as %s.",
	charSetThirst02 = "%s have set your thirst amount as %s.",
	cook_it = "%s cooks the %s",
	food_uncook = "Not cooked.",
	food_worst = "Utter shit.",
	food_reallybad = "Black garbage.",
	food_bad = "Visually burnt.",
	food_notgood = "Over cooked.",
	food_normal = "Cooked.",
	food_good = "Cooked well.",
	food_sogood = "Delicious.",
	food_reallygood = "Unbelievable.",
	food_best = "God-likely cooked.",
	stove_desc = "Allows you to cook some food.",
	notice_cooked = "You cooked %s.",
	notice_turnonstove = "Failed Cooking: Stove must be active to cook %s.",
	notice_notcookable = "Failed Cooking: %s Is not cookable.",
	notice_alreadycooked = "Failed Cooking: %s is already cooked.",
	notice_havetofacestove = "Failed Cooking: You have to face stove to cook %s.",
	usesLabel = "%s times left.",
	statusLabel = "%s",
	ix_stove = "Cooking Stove",
	ix_barrel = "Barrel Stove",
	ix_bucket = "Bucket Stove",
})
ix.lang.AddTable("korean", {
	starving = "굶주림",
	hungry = "배고픔",
	grumbling = "출출함",
	dehydrated = "탈수",
	lightlyDehydrated = "가벼운 탈수",
	thirsty = "목마름",
	parched = "약간 목마름",
	charSetHunger01 = "당신의 배고픔 수치를 %s으로 설정했습니다.",
	charSetHunger02 = "당신은 %s님의 배고픔 수치를 %s으로 설정했습니다.",
	charSetHunger02 = "%s님이 당신의 배고픔 수치를 %s으로 설정했습니다.",
	charSetThirst01 = "당신의 목마름 수치를 %s으로 설정했습니다.",
	charSetThirst02 = "당신은 %s님의 목마름 수치를 %s으로 설정했습니다.",
	charSetThirst02 = "%s님이 당신의 목마름 수치를 %s으로 설정했습니다.",
	["Cook"] = "조리하기",
	cook_it = "%s님이 %s을(를) 조리합니다.",
	food_uncook = "조리되지 않음.",
	food_worst = "석탄 덩어리.",
	food_reallybad = "검게 탄 쓰레기.",
	food_bad = "겉보기에 탄 듯함.",
	food_notgood = "너무 익음.",
	food_normal = "익음.",
	food_good = "잘 익음.",
	food_sogood = "맛있음.",
	food_reallygood = "정말 맛있음.",
	food_best = "믿을 수 없이 맛있음.",
	stove_desc = "음식을 조리할 수 있습니다.",
	notice_cooked = "%s을(를) 조리했습니다.",
	notice_turnonstove = "조리 실패: %s을(를) 조리하려면 조리대를 켜야 합니다.",
	notice_notcookable = "조리 실패: %s은(를) 조리할 수 없습니다.",
	notice_alreadycooked = "조리 실패: %s은(를) 이미 조리되었습니다.",
	notice_havetofacestove = "조리 실패: %s을(를) 조리하려면 조리대를 바라봐야 합니다.",
	usesLabel = "%s번 먹을 수 있습니다.",
	statusLabel = "%s",
	ix_stove = "조리대",
	ix_barrel = "조리용 드럼통",
	ix_bucket = "조리용 양동이",
})


local entityMeta = FindMetaTable("Entity")

function entityMeta:IsStove()
	local class = self:GetClass()
	return ( class == "ix_stove" or class == "ix_bucket" or class == "ix_barrel" )
end

local playerMeta = FindMetaTable("Player")

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
			client:SetLocalVar("hunger", character:GetData("hunger", 100))
			client:SetLocalVar("thirst", character:GetData("thirst", 100))
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
		local enabled = client:GetCharacter() and client:Team() != FACTION_OTA and !Schema:IsCombineRank(client:Name(), "SCN")
		
		if (client.resetHunger) then
			char:SetData("hunger", 100)
			client:SetLocalVar("hunger", 100)
			client.resetHunger = false
		end
		
		if (client.resetThirst) then
			char:SetData("thirst", 100)
			client:SetLocalVar("thirst", 100)
			client.resetThirst = false
		end

		if (enabled) then
			char:SetData("hunger", 100)
			client:SetLocalVar("hunger", 100)
			char:SetData("thirst", 100)
			client:SetLocalVar("thirst", 100)
			client.resetThirst = false
			client.resetHunger = false
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
		local enabled = self:Team() != FACTION_OTA and !Schema:IsCombineRank(self:Name(), "SCN")

		if (char and enabled) then
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
		local enabled = self:Team() != FACTION_OTA and !Schema:IsCombineRank(self:Name(), "SCN")

		if (char and enabled) then
			char:SetData("hunger", char:GetData("hunger", 100) - amount)
			self:SetLocalVar("hunger", char:GetData("hunger", 100) - amount)

			if char:GetData("hunger", 100) < 0 then
				char:SetData("hunger", 0)
				self:SetLocalVar("hunger", 0)
			end
		end
	end

	function PLUGIN:PlayerTick(ply)
		if ply:GetNetVar("hungertick", 0) <= CurTime() then
			ply:SetNetVar("hungertick", ix.config.Get("hunger_decay_speed", 300) + CurTime())
			ply:TickHunger(1, 1)
		end

		if ply:GetNetVar("thirsttick", 0) <= CurTime() then
			ply:SetNetVar("thirsttick", ix.config.Get("thirst_decay_speed", 300) + CurTime())
			ply:TickThirst(2, 1)
		end
	end
	
	local damageTime = CurTime()
	
	function PLUGIN:Think()
		if (damageTime < CurTime()) then
			for k, v in ipairs(player.GetAll()) do
				if (v:GetCharacter()) then
					if (v:GetCharacter():GetData("hunger", 0) < 20) then
						v:TakeDamage(1,v,v:GetActiveWeapon())
					end
				
					if (v:GetCharacter():GetData("thirst", 0) < 20) then
						v:TakeDamage(1.5,v,v:GetActiveWeapon())
					end
				end
			end
			
			damageTime = CurTime() + 15
		end
	end

	function PLUGIN:SaveData()
		local data = {}

		for _, v in ipairs(ents.GetAll()) do
			local class = v:GetClass()
			if (class == "ix_stove" or class == "ix_barrel" or class == "ix_bucket") then
				data[#data + 1] = {
					class = class,
					pos = v:GetPos(),
					angles = v:GetAngles(),
					active = v:GetNetVar("active")
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

		if var < 0.2 then
			status = L"starving"
		elseif var < 0.4 then
			status = L"hungry"
		elseif var < 0.6 then
			status = L"grumbling"
		elseif var < 0.8 then
			status = ""
		end

		return var, status
	end, Color(40, 100, 40), nil, "hunger")

	ix.bar.Add(function()
		local status = ""
		local var = LocalPlayer():GetLocalVar("thirst", 0) / 100

		if var < 0.2 then
			status = L"dehydrated"
		elseif var < 0.4 then
			status = L"lightlyDehydrated"
		elseif var < 0.6 then
			status = L"thirsty"
		elseif var < 0.8 then
			status = L"parched"
		end

		return var, status
	end, Color(40, 40, 200), nil, "thirst")
end

function PLUGIN:AdjustStaminaOffset(client, offset)
	if client:GetHunger() < 15 or client:GetThirst() < 20 then
		return -1
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