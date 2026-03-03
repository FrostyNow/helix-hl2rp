
local PLUGIN = PLUGIN

PLUGIN.name = "Bodygroup Manager"
PLUGIN.author = "Gary Tate | Modified by Frosty"
PLUGIN.description = "Allows players and administration to have an easier time customising bodygroups."

ix.lang.AddTable("english", {
	cmdEditBodygroup = "Customise the bodygroups of a target.",
	cmdBodygroup = "Customise your own bodygroups (requires the b flag).",
	cmdSkin = "Customise your own skin (requires the s flag).",
	bodygroupManager = "Bodygroup Manager",
	saveChanges = "Save Changes",
	skin = "Skin",
	next = "Next",
	previous = "Previous",
	cmdCharResetBodygroups = "Reset the bodygroups of a target character and unequip related items.",
	resetBodygroupsTarget = "Your bodygroups have been reset by an administrator.",
	resetBodygroupsClient = "You have reset the bodygroups of %s."
})

ix.lang.AddTable("korean", {
	cmdEditBodygroup = "대상의 바디그룹/스킨을 수정합니다.",
	cmdBodygroup = "자신의 바디그룹을 수정합니다. (b 플래그 필요)",
	cmdSkin = "자신의 스킨을 수정합니다. (s 플래그 필요)",
	bodygroupManager = "바디그룹 매니저",
	saveChanges = "변경사항 저장",
	skin = "스킨",
	next = "다음",
	previous = "이전",
	cmdCharResetBodygroups = "대상의 바디그룹을 초기화하고 관련 아이템을 장착 해제합니다.",
	resetBodygroupsTarget = "관리자에 의해 바디그룹이 초기화되었습니다.",
	resetBodygroupsClient = "%s의 바디그룹을 초기화했습니다."
})

ix.command.Add("CharEditBodygroup", {
	description = "@cmdEditBodygroup",
	adminOnly = true,
	arguments = {
		bit.bor(ix.type.player, ix.type.optional)
	},
	OnRun = function(self, client, target)
		net.Start("ixBodygroupView")
			net.WriteEntity(target or client)
		net.Send(client)
	end
})

ix.command.Add("CharResetBodygroups", {
	description = "@cmdCharResetBodygroups",
	adminOnly = true,
	arguments = {
		ix.type.character
	},
	OnRun = function(self, client, target)
		local player = target:GetPlayer()

		-- Clear character data
		target:SetData("groups", {})
		
		-- Also clear 'oldGroups' from various categories if they exist
		-- This is tricky since we don't know all categories, but 'model' is common.
		-- A more robust way is to iterate through data keys if possible, but Helix doesn't expose that easily.
		-- Let's hit the common ones.
		target:SetData("oldGroupsmodel", nil)
		target:SetData("oldGroupskevlar", nil)

		-- Unequip items that modify bodygroups
		local inventory = target:GetInventory()
		if (inventory) then
			for _, item in pairs(inventory:GetItems()) do
				if (item:GetData("equip") and (item.eqBodyGroups or item.bodyGroups)) then
					-- If the item has a RemoveOutfit function, use it.
					if (item.RemoveOutfit) then
						item:RemoveOutfit(player or target:GetPlayer())
					else
						-- Fallback: just set equip to false
						item:SetData("equip", false)
					end
				end
			end
		end

		if (IsValid(player)) then
			-- Reset all actual bodygroups
			player:ResetBodygroups()
			player:NotifyLocalized("resetBodygroupsTarget")
		end

		client:NotifyLocalized("resetBodygroupsClient", target:GetName())
	end
})

ix.command.Add("Bodygroup", {
	description = "@cmdBodygroup",
	OnRun = function(self, client)
		local character = client:GetCharacter()

		if (!character or !character:HasFlags("b")) then
			return "@flagNoMatch", "b"
		end

		net.Start("ixBodygroupView")
			net.WriteEntity(client)
		net.Send(client)
	end
})

ix.command.Add("Skin", {
	description = "@cmdSkin",
	OnRun = function(self, client)
		local character = client:GetCharacter()

		if (!character or !character:HasFlags("s")) then
			return "@flagNoMatch", "s"
		end

		net.Start("ixBodygroupView")
			net.WriteEntity(client)
		net.Send(client)
	end
})

properties.Add("ixEditBodygroups", {
	MenuLabel = "#Edit Bodygroups",
	Order = 10,
	MenuIcon = "icon16/user_edit.png",

	Filter = function(self, entity, client)
		if (!entity:IsPlayer() or !entity:GetCharacter()) then return false end

		if (ix.command.HasAccess(client, "CharEditBodygroup")) then
			return true
		end

		if (entity == client) then
			local character = client:GetCharacter()
			return character:HasFlags("b") or character:HasFlags("s")
		end

		return false
	end,

	Action = function(self, entity)
		local panel = vgui.Create("ixBodygroupView")
		panel:Display(entity)
	end
})

ix.util.Include("sv_hooks.lua")
ix.util.Include("cl_hooks.lua")
