ITEM.name = "Food base"
ITEM.description = "A food."
ITEM.model = "models/props_lab/bindergraylabel01b.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.category = "Food"
ITEM.hunger = 0
ITEM.thirst = 0
ITEM.radiation = 0
ITEM.empty = false
ITEM.cookable = false
ITEM.heal = 0
ITEM.sound = "npc/barnacle/barnacle_gulp2.wav"
ITEM.isDrink = false

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local usenum = self:GetData("usenum", self.usenum)
		if (usenum) then
			local row = tooltip:AddRow("usenum")
			row:SetText(L("usesLabel", usenum))
			row:SetBackgroundColor(ix.config.Get("color"))
		end

		if (self.cookable) then
			local cooklevel = self:GetData("cooklevel", 0)
			local cookTable = {
				[0] = L"food_uncook",
				[1] = L"food_worst",
				[2] = L"food_reallybad",
				[3] = L"food_bad",
				[4] = L"food_notgood",
				[5] = L"food_normal",
				[6] = L"food_good",
				[7] = L"food_sogood",
				[8] = L"food_reallygood",
				[9] = L"food_best",
			}
			local row = tooltip:AddRow("cooklevel")
			row:SetText(L("statusLabel", cookTable[cooklevel] or cookTable[0]))
			row:SetBackgroundColor(Color(200, 100, 0))
		end
	end
end

ITEM.functions = ITEM.functions or {}
ITEM.functions.Eat = {
	name = "Eat",
	OnRun = function(item)
		local client = item.player
		local character = client:GetCharacter()
		local hunger = character:GetData("hunger", 100)
		local thirst = character:GetData("thirst", 100)
		local cooklevel = item:GetData("cooklevel", 0)
		
		if (item.sound) then
			client:EmitSound(item.sound, item.soundLevel, item.soundPitch, item.soundVolume)
		end

		if (hunger) then
			local amount = item.hunger or 0
			if (item.cookable) then
				amount = amount + (item.hungermultp or 1) * (cooklevel - 4)
			end
			client:SetHunger(math.Clamp(hunger + amount, 0, 100))
		end

		if (thirst) then
			local amount = item.thirst or 0
			if (item.cookable) then
				amount = amount + (item.thirstmultp or 1) * (cooklevel - 4)
			end
			client:SetThirst(math.Clamp(thirst + amount, 0, 100))
		end

		local luck = character:GetAttribute("lck", 0)
		local baseHeal = item.heal or 0

		if (baseHeal != 0) then
			-- Luck reflects base scale (increase/decrease)
			-- Range: -2 (at 0 lck) to +2 (at max lck)
			local maxAttrib = ix.config.Get("maxAttributes", 10)
			local luckBonus = math.floor((luck - (maxAttrib / 2)) / (maxAttrib / 4))
			local cookBonus = 0

			-- Cooking quality bonus/penalty
			if (item.cookable) then
				local cooklevel = item:GetData("cooklevel", 0)
				-- Results in -2 (uncooked) to +2 (best quality) bonus
				cookBonus = math.floor((cooklevel - 4) / 2)
			end

			local heal = baseHeal + luckBonus + cookBonus

			-- Maintain polarity: medicine stays medicine or becomes neutral, poison stays poison or becomes neutral
			if (baseHeal > 0) then
				heal = math.max(0, heal)
			else
				heal = math.min(0, heal)
			end

			local absHeal = math.abs(math.floor(heal))
			if (absHeal > 0) then
				for i = 1, absHeal do
				timer.Simple(i, function()
					if (IsValid(client) and client:Alive()) then
						if (heal > 0) then
							client:SetHealth(math.Clamp(client:Health() + 1, 0, client:GetMaxHealth()))
						else
							client:TakeDamage(1)
						end
					end
				end)
			end
		end -- end if (absHeal > 0)
	end -- end if (baseHeal != 0)

		local usenum = item:GetData("usenum", item.usenum)
		if (usenum) then
			usenum = usenum - 1
			if (usenum <= 0) then
				if (item.empty) then
					local inv = character:GetInventory()
					inv:Add(item.empty)
				end
				return true
			end
			item:SetData("usenum", usenum)
			return false
		elseif (item.empty) then
			local inv = character:GetInventory()
			inv:Add(item.empty)
		end

		return true
	end,
	icon = "icon16/cup.png"
}

ITEM.functions.Cook = {
	name = "Cook",
	icon = "icon16/bomb.png",
	OnRun = function(item)
		local client = item.player
		local data = {}
		data.start = client:GetShootPos()
		data.endpos = data.start + client:GetAimVector() * 96
		data.filter = client
		
		local trace = util.TraceLine(data)
		local entity = trace.Entity
		local cooklevel = item:GetData("cooklevel", 0)

		if (cooklevel == 0) then
			if (IsValid(entity) and entity:IsStove()) then
				if (entity:GetNetVar("active")) then
					local character = client:GetCharacter()
					local cookingSkill = character:GetAttribute("cooking", 0)
					local luck = character:GetAttribute("lck", 0)

					local maxAttrib = ix.config.Get("maxAttributes", 10)
					-- Cooking skill is the primary factor, luck is secondary
					-- Weighted: 80% cooking, 20% luck (More skill reliant, less erratic)
					local weightedSkill = (cookingSkill * 0.8 + luck * 0.2) / maxAttrib

					-- Shifted floor: even skill 0 shouldn't burn everything.
					-- Skill 0 starts at 3 (Bad/Not Good territory), Skill 10 reaches 9 (Best)
					local baseQuality = 3 + weightedSkill * 6

					-- Random variance: narrowed down slightly for better consistency.
					-- Base variance ±1.2, reduced by skill.
					local consistency = math.Clamp(cookingSkill / maxAttrib, 0, 1)
					local variance = (math.random() * 2 - 1) * (1.2 - consistency * 0.4)

					local f_quality = math.Clamp(math.Round(baseQuality + variance), 1, 9)

					-- Experience: lower quality results give more experience (you learn from mistakes)
					local expboost = 0.15
					local exp = (1 - (f_quality / 9)) * expboost

					item:SetData("cooklevel", f_quality)
					character:UpdateAttrib("cooking", exp)

					client:EmitSound("player/pl_burnpain" .. math.random(1, 3) .. ".wav", 75, 140)
					client:NotifyLocalized("notice_cooked", L(item.name, client))
				else
					client:NotifyLocalized("notice_turnonstove", L(item.name, client))
				end
			else
				client:NotifyLocalized("notice_havetofacestove", L(item.name, client))
			end
		else
			client:NotifyLocalized("notice_alreadycooked", L(item.name, client))
		end

		return false
	end,
	OnCanRun = function(item)
		return !IsValid(item.entity) and item.cookable and item:GetData("cooklevel", 0) == 0
	end
}