PLUGIN.name = "Alcohol"
PLUGIN.author = "AleXXX_007 | Modified by Frosty"
PLUGIN.description = "Adds alcohol with effects."

ix.lang.AddTable("english", {
	itemBeerDesc = "An alcoholic drink brewed from cereal grains—most commonly from malted barley, though wheat, maize (corn), and rice are also used.",
	itemBourbonDesc = "A bottle of American whiskey, a barrel-aged distilled spirit made primarily from corn.",
	itemMoonshineDesc = "A bottle of illegally distilled liquor that is so named because its manufacture may be conducted without artificial light at night-time.",
	itemNukaColaDarkDesc = 'A ready to drink bottle of Nuka-Cola and rum boasting an alcohol-by-volume content of 35%, the beverage was touted as "the most thirst-quenching way to unwind."',
	itemRumDesc = "A distilled spirit derived from fermented cane sugar and molasses.",
	itemVodkaDesc = "A clear distilled alcoholic liquor made from grain mash.",
	itemWhiskeyDesc = "A liquor distilled from the fermented mash of grain (as rye, corn, or barley).",
	itemWineDesc = "An alcoholic beverage made by fermenting the juice of grapes.",
	itemGinDesc = "A distilled liquor with a strong aroma, frequently used in making cocktails.",
	drunkTipsy = "You feel a bit tipsy.",
	drunkSpinning = "The world seems to be spinning a bit.",
	drunkNauseous = "You feel quite nauseous.",
	drunkBlackout = "You feel dangerously dizzy and your vision starts to fade...",
})
ix.lang.AddTable("korean", {
	["Alcohol"] = "주류",
	Drink = "마시기",
	["Beer"] = "맥주",
	itemBeerDesc = "보리와 같은 곡물을 발효시키고 향신료인 홉을 첨가시켜 맛을 낸 술입니다.",
	["Bourbon"] = "버본",
	itemBourbonDesc = "미국 켄터키를 중심으로 생산되는 위스키입니다.",
	["Moonshine"] = "밀주",
	itemMoonshineDesc = "가정에서 양조해서 가끔씩 마시는 술로, 보통 옥수수를 주 원료로 사용한 콘 위스키의 형태를 가지고 있으며 거기에 맥아와 이스트 등을 사용해 발효한 밑술을 위의 제조 공정에 따라 증류하여 만듭니다.",
	["Nuka-Cola Dark"] = "누카 콜라 다크",
	itemNukaColaDarkDesc = "비쩍 타들어가는 듯한 갈증을 풀어주는 어른들의 누카 콜라입니다.",
	["Rum"] = "럼",
	itemRumDesc = "사탕수수를 착즙해서 설탕을 만들고 남은 찌꺼기인 당밀이나 사탕수수 즙을 발효시킨 뒤 증류한 술로, 옛날 뱃사람들이 주로 마셨다고 합니다.",
	["Vodka"] = "보드카",
	itemVodkaDesc = "수수, 옥수수, 감자, 밀, 호밀 등 탄수화물 함량이 높은 식물로 빚은 러시아 원산의 증류주입니다.",
	["Whiskey"] = "위스키",
	itemWhiskeyDesc = "스코틀랜드에서 유래한 술로 가장 유명한 증류주입니다.",
	["Wine"] = "포도주",
	itemWineDesc = "포도를 으깨서 나온 즙을 발효시킨 과실주로, 상류층이 주로 즐깁니다.",
	["Canned Beer"] = "캔맥주",
	["Ale"] = "에일",
	itemAleDesc = "과일향이 강한 방식으로 양조된 맥주입니다.",
	["Gin"] = "진",
	itemGinDesc = "향이 강하고 칵테일을 만드는 데 많이 쓰였던 증류주입니다.",
	drunkTipsy = "약간 알딸딸한 기분이 듭니다.",
	drunkSpinning = "세상이 약간 도는 것 같습니다.",
	drunkNauseous = "속이 별로 좋지 않습니다.",
	drunkBlackout = "머리가 너무 어지러워 눈앞이 가물가물합니다...",
})

function PLUGIN:GetDrunkState(val)
	if (val > 90) then return "drunkNauseous" end
	if (val > 60) then return "drunkSpinning" end
	if (val > 30) then return "drunkTipsy" end
	return "normal"
end

function PLUGIN:Drunk(client)
	local character = client:GetCharacter()
	local endurance = character:GetAttribute("end", 0)
	local luck = character:GetAttribute("lck", 0)
	local strength = character:GetAttribute("str", 0)
	local maxAttributes = ix.config.Get("maxAttributes", 30)
	local timerID = "ixDrunk_" .. client:SteamID64()

	if strength then
		character:SetAttrib("str", strength + 3)
	end
	
	local lastDrunk = client:GetLocalVar("drunk", 0)
	local addDrunk = character:GetData("drunk", 0)
	client:SetLocalVar("drunk", addDrunk)
	
	-- Notify state change
	local oldState = self:GetDrunkState(lastDrunk)
	local newState = self:GetDrunkState(addDrunk)
	
	if (oldState != newState and newState != "normal" and addDrunk > lastDrunk) then
		ix.chat.Send(client, "it", L(newState, client), false, {client})
	end
	
	-- Calculate threshold and pass-out chance
	local threshold = 100 + (endurance / maxAttributes) * 50
	
	if client:GetLocalVar("drunk") > threshold then
		local unctime = (client:GetLocalVar("drunk") - threshold) * 7.5
		client:ConCommand("say /fallover ".. unctime .."")
	elseif (client:GetLocalVar("drunk") > 50) then
		-- Random pass-out chance based on luck and endurance
		-- Higher luck and endurance reduce the chance
		local chance = (client:GetLocalVar("drunk") - 50) * 0.2
		local resistance = (luck * 0.5) + (endurance * 0.3)
		
		if (math.random(1, 100) < (chance - resistance)) then
			ix.chat.Send(client, "it", L("drunkBlackout", client), false, {client})
			client:ConCommand("say /fallover ".. math.random(5, 15) .."")
		end
	end
	
	if (!timer.Exists(timerID)) then
		timer.Create(timerID, 5, 0, function()
			if (!IsValid(client) or !client:GetCharacter()) then
				timer.Remove(timerID)
				return
			end

			local drunk = client:GetLocalVar("drunk", 0)
			if (drunk > 0) then
				client:SetLocalVar("drunk", drunk - 1)
				client:GetCharacter():SetData("drunk", client:GetLocalVar("drunk"))
			else
				if (strength) then
					client:GetCharacter():SetAttrib("str", strength)
				end
				timer.Remove(timerID)
			end
		end)
	end
end

if (SERVER) then
	function PLUGIN:PostPlayerLoadout(client)
		if not client:GetCharacter() then return end
		client:SetLocalVar("drunk", 0)
		client:GetCharacter():SetData("drunk", 0)
	end
	
	function PLUGIN:PlayerDeath(client)
		if not client:GetCharacter() then return end
		client:SetLocalVar("drunk", 0)
		client:GetCharacter():SetData("drunk", 0)
		timer.Remove("ixDrunk_" .. client:SteamID64())
	end
end

if (CLIENT) then
	function PLUGIN:RenderScreenspaceEffects()
		local a = LocalPlayer():GetLocalVar("drunk", 0)
		
		if (a > 60) then
			-- Stage 3: Extreme blurring, oversaturation, and red heat
			local intensity = a * 0.015
			local spinIntensity = (a - 60) * 0.1
			DrawMotionBlur(0.1, intensity, 0.05)
			DrawSharpen(spinIntensity * 0.5, intensity)
			
			local default = {}
			default["$pp_colour_addr"] = (spinIntensity * 0.02)
			default["$pp_colour_addg"] = 0
			default["$pp_colour_addb"] = 0
			default["$pp_colour_brightness"] = (spinIntensity * 0.005)
			default["$pp_colour_contrast"] = 1 + (spinIntensity * 0.01)
			-- Colors become extremely vivid and distorted
			default["$pp_colour_colour"] = 1 + (a * 0.025)
			default["$pp_colour_mulr"] = (spinIntensity * 0.1)
			default["$pp_colour_mulg"] = 0
			default["$pp_colour_mulb"] = 0
			DrawColorModify(default)
		elseif (a > 20) then
			-- Stage 2: Motion blur and increased saturation
			local value = a * 0.01
			DrawMotionBlur(0.2, value, 0.05)
			
			local default = {}
			default["$pp_colour_addr"] = 0
			default["$pp_colour_addg"] = 0
			default["$pp_colour_addb"] = 0
			default["$pp_colour_brightness"] = 0
			default["$pp_colour_contrast"] = 1 + (a * 0.002)
			default["$pp_colour_colour"] = 1 + (a * 0.015)
			default["$pp_colour_mulr"] = 0
			default["$pp_colour_mulg"] = 0
			default["$pp_colour_mulb"] = 0
			DrawColorModify(default)
		elseif (a > 0) then
			-- Stage 1: Subtle color enhancement
			local default = {}
			default["$pp_colour_addr"] = 0
			default["$pp_colour_addg"] = 0
			default["$pp_colour_addb"] = 0
			default["$pp_colour_brightness"] = 0
			default["$pp_colour_contrast"] = 1
			default["$pp_colour_colour"] = 1 + (a * 0.01)
			default["$pp_colour_mulr"] = 0
			default["$pp_colour_mulg"] = 0
			default["$pp_colour_mulb"] = 0
			DrawColorModify(default)
		end
	end
end