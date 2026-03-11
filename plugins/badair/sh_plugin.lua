local PLUGIN = PLUGIN
PLUGIN.name = "Bad Air"
PLUGIN.author = "Black Tea and Subleader"
PLUGIN.desc = "Remastered Bad Air"

ix.lang.AddTable("korean", {
	toxicity = "오염도",
	badairEnter1 = "갑자기 숨 쉬기가 답답하고 쓰라린 듯 따갑습니다.",
	badairEnter2 = "뭔가 매캐한 냄새가 나는 것 같습니다.",
	badairEnter3 = "공기 중에 무거운 입자가 깔리는 듯한 느낌이 듭니다.",
	badairExit1 = "숨 쉬기가 한결 편안해졌습니다.",
	badairExit2 = "불쾌한 냄새가 사라지는 것 같습니다.",
	badairExit3 = "뭔가 상쾌해진 것 같습니다.",
	badairMaskDepleted = "방독면의 정화통이 다 되어 숨이 막혀옵니다."
})

ix.lang.AddTable("english", {
	toxicity = "Toxicity",
	badairEnter1 = "It suddenly feels stuffy and your breathing stings.",
	badairEnter2 = "It smells as if there's something acrid here.",
	badairEnter3 = "It feels as though heavy particles are settling in the air.",
	badairExit1 = "Breathing has become much easier.",
	badairExit2 = "The unpleasant smell seems to have disappeared.",
	badairExit3 = "It feels somehow refreshing.",
	badairMaskDepleted = "The filter in your gasmask runs out, making it hard to breathe."
})

local badairEnterMessages = {
	"badairEnter1",
	"badairEnter2",
	"badairEnter3"
}

local badairExitMessages = {
	"badairExit1",
	"badairExit2",
	"badairExit3"
}

function PLUGIN:SetupAreaProperties()
	ix.area.AddProperty("badair", ix.type.bool, false)
end

if (!CLIENT) then
	-- This timer does the effect of bad air.
	timer.Create("badairTick", 1, 0, function()
		for _, client in ipairs(player.GetAll()) do
			local char = client:GetCharacter()

			if (client:Alive() and char) then
				local isInGas = false

				if (client:IsInArea()) then
					local areaID = client:GetArea()
					
					if (areaID and areaID != "") then
						local areaMeta = ix.area.stored[areaID]
						
						if (areaMeta and areaMeta.properties and areaMeta.properties.badair) then
							local bIsProtected = client:GetMoveType() == MOVETYPE_NOCLIP
							local bCombineProtected = false

							if (!bIsProtected and client:IsCombine()) then
								if (Schema:IsConceptCombine(client)) then
									local index = client:FindBodygroupByName("mask")

									if (index != -1 and client:GetBodygroup(index) >= 1) then
										bIsProtected = true
										bCombineProtected = true
									end
								else
									bIsProtected = true
									bCombineProtected = true
								end
							end

							if (!bCombineProtected and client:GetNetVar("gasmask") and client:GetMoveType() != MOVETYPE_NOCLIP) then
								local inv = char:GetInventory()
								local activeMask

								if (inv) then
									for _, item in pairs(inv:GetItems()) do
										if (item.base == "base_armor" and item:GetData("equip") and item.gasmask) then
											activeMask = item
											break
										end
									end
								end

								if (activeMask) then
									local dur = activeMask:GetData("Durability", activeMask.maxDurability)
									if (dur > 0) then
										-- 10 minutes (600 seconds) to deplete full durability. 
										-- Calculate deduction based on max durability so any gasmask lasts ~10 mins.
										activeMask:SetData("Durability", math.max(0, dur - (activeMask.maxDurability / 600)))
										
										if (activeMask:GetData("Durability") <= 0) then
											ix.chat.Send(client, "it", L("badairMaskDepleted", client), false, {client})
											bIsProtected = false
										end
									else
										bIsProtected = false
									end
								end
								
								if (activeMask and activeMask:GetData("Durability", activeMask.maxDurability) > 0) then
									bIsProtected = true
								end
							end

							if (!bIsProtected) then
								isInGas = true
							end
						end
					end
				end

				local wasInGas = client.ixInBadAir or false

				if (isInGas and !wasInGas) then
					client.ixInBadAir = true

					if ((client.ixNextBadAirEnterMessage or 0) < CurTime()) then
						local msg = table.Random(badairEnterMessages)
						ix.chat.Send(client, "it", L(msg, client), false, {client})

						client.ixNextBadAirEnterMessage = CurTime() + 5
					end
				elseif (!isInGas and wasInGas) then
					client.ixInBadAir = false

					if ((client.ixNextBadAirExitMessage or 0) < CurTime()) then
						local msg = table.Random(badairExitMessages)
						ix.chat.Send(client, "it", L(msg, client), false, {client})

						client.ixNextBadAirExitMessage = CurTime() + 5
					end
				end

				local toxicity = client:GetLocalVar("toxicity", 0)

				if (isInGas) then
					toxicity = math.Clamp(toxicity + 3, 0, 100)
					client:SetLocalVar("toxicity", toxicity)

					if (toxicity >= 100) then
						local dmg = math.max(1, client:GetMaxHealth() / 33)
						client:TakeDamage(dmg)
						client:ScreenFade(1, ColorAlpha(color_white, 150), .5, 0)
					end

					if ((client.ixNextCough or 0) < CurTime()) then
						client.ixNextCough = CurTime() + math.Rand(3, 5)
						
						local pitch = client:IsFemale() and math.random(115, 125) or math.random(95, 105)
						client:EmitSound("ambient/voices/cough" .. math.random(1, 4) .. ".wav", 75, pitch)
						client:ViewPunch(Angle(math.Rand(-3, 3), math.Rand(-2, 2), math.Rand(-1, 1)))
					end
				else
					if (toxicity > 0) then
						toxicity = math.Clamp(toxicity - 2, 0, 100)
						client:SetLocalVar("toxicity", toxicity)
					end
				end
			end
		end
	end)
else
	ix.bar.Add(function()
		return math.max(LocalPlayer():GetLocalVar("toxicity", 0) / 100, 0)
	end, Color(34, 139, 34), nil, "toxicity")
end

ix.command.Add("AreaBadAir", {
	description = "@cmdAreaBadAir",
	adminOnly = true,
	OnRun = function(self, client, arguments)
		local areaID = client:GetArea()

		if (!client:IsInArea() or !areaID or areaID == "") then
			return "@areaBadAirReq"
		end

		local areaInfo = ix.area.stored[areaID]
		if (!areaInfo) then
			return "@areaBadAirInvalid"
		end

		areaInfo.properties.badair = not areaInfo.properties.badair

		-- Network the change to all clients
		net.Start("ixAreaAdd")
			net.WriteString(areaID)
			net.WriteString(areaInfo.type)
			net.WriteVector(areaInfo.startPosition)
			net.WriteVector(areaInfo.endPosition)
			net.WriteTable(areaInfo.properties)
		net.Broadcast()

		-- Save the area plugin data
		local areaPlugin = ix.plugin.list["area"]
		if (areaPlugin) then
			areaPlugin:SaveData()
		end

		if (areaInfo.properties.badair) then
			return "@areaBadAirEnabled", areaID
		else
			return "@areaBadAirDisabled", areaID
		end
	end
})
