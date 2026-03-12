
local PLUGIN = PLUGIN

PLUGIN.name = "Admin PlayerInfo"
PLUGIN.author = "Frosty"
PLUGIN.description = "Allows admins to view player inventories and information."

ix.lang.AddTable("english", {
	cmdAdminSearch = "Search and manipulate a character's inventory.",
	adminSearchNoChar = "This character does not have a valid inventory.",
	searchingCharacter = "Searching the inventory of %s...",
	targetSelf = "You cannot target yourself.",
})

ix.lang.AddTable("korean", {
	cmdPlySearch = "캐릭터의 소지품을 검사하고 조작합니다.",
	adminSearchNoChar = "이 캐릭터는 유효한 소지품을 가지고 있지 않습니다.",
	searchingCharacter = "%s의 소지품을 검사하는 중...",
	targetSelf = "스스로를 대상으로 할 수 없습니다.",
})

ix.command.Add("PlySearch", {
	description = "@cmdPlySearch",
	adminOnly = true,
	arguments = {
		bit.bor(ix.type.character, ix.type.optional)
	},
	OnRun = function(self, client, target)
		if (!target) then
			local data = {}
			data.start = client:GetShootPos()
			data.endpos = data.start + client:GetAimVector() * 96
			data.filter = client
			
			local trace = util.TraceLine(data)
			local entity = trace.Entity

			if (IsValid(entity) and entity:IsPlayer()) then
				target = entity:GetCharacter()
			else
				return "@invalidArg", 1
			end
		elseif (target == client) then
			return "@targetSelf"
		end

		local inventory = target:GetInventory()

		if (!inventory) then
			return "@adminSearchNoChar"
		end

		-- Use ix.storage.Open to allow manipulation (moving items)
		-- We pass the target's player entity if they are online, so the UI can show their model/info
		local targetPlayer = target:GetPlayer()
		local name = target:GetName()

		ix.storage.Open(client, inventory, {
			entity = IsValid(targetPlayer) and targetPlayer or client,
			name = name,
			searchText = "@searching",
			bMultipleUsers = true
		})

		client:NotifyLocalized("searchingCharacter", name)
	end
})
