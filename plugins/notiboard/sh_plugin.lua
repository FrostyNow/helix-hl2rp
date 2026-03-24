PLUGIN.name = "Noti-Board"
PLUGIN.author = "Black Tea | Ported by Frosty"
PLUGIN.description = "This is a noti-board for notifications!"

ix.lang.AddTable("english", {
	cmdNotiSetGroup = "Set the group of the noti-board",
	cmdNotiSetGroupText = "Set the text of the noti-board",
	cmdNotiSetGroupTitle = "Set the title of the noti-board",
	notiSetGroupText = "You changed %s Noti-Board's text.",
	notiSetGroupTitle = "You changed %s Noti-Board's title.",
	noNotiGroup = "There is no noti-board with this group.",
	notiSetGroup = "You have set this noti-board's group to %s.",
	notiNoTarget = "You must be looking at a noti-board.",
	notiSetTitle = "Set Title",
	notiSetText = "Set Text",
	notiEnterTitle = "Enter the title for the Noti-Board.",
	notiEnterText = "Enter the text for the Noti-Board.",
	notiSetGroupMenu = "Set Group",
	notiEnterGroup = "Enter the group ID for the Noti-Board."
})

ix.lang.AddTable("korean", {
	cmdNotiSetGroup = "알림판의 그룹을 설정합니다.",
	cmdNotiSetGroupText = "알림판의 텍스트를 설정합니다.",
	cmdNotiSetGroupTitle = "알림판의 제목을 설정합니다.",
	notiSetGroupText = "알림판 %s개의 텍스트를 변경했습니다.",
	notiSetGroupTitle = "알림판 %s개의 제목을 변경했습니다.",
	noNotiGroup = "이 그룹의 알림판이 없습니다.",
	notiSetGroup = "알림판의 그룹을 %s로 설정했습니다.",
	notiNoTarget = "알림판을 바라봐야 합니다.",
	notiSetTitle = "제목 설정",
	notiSetText = "텍스트 설정",
	notiEnterTitle = "알림판의 제목을 입력하십시오.",
	notiEnterText = "알림판의 텍스트를 입력하십시오.",
	notiSetGroupMenu = "그룹 설정",
	notiEnterGroup = "알림판의 그룹 ID를 입력하십시오."
})

if SERVER then
	function PLUGIN:LoadData()
		local data = self:GetData()

		if data then
			for k, v in pairs(data) do
				local position = v.position
				local angles = v.angles
				local title  = v.title
				local text = v.text
				local group = v.group

				local entity = ents.Create("ix_notiboard")
				entity:SetPos(position)
				entity:SetAngles(angles)
				entity:Spawn()
				entity:Activate()
				entity:SetNetVar("title", title)
				entity:SetNetVar("text", text)
				entity:SetNetVar("group", group)

				local physicsObject = entity:GetPhysicsObject();
				if (IsValid(physicsObject)) then
					physicsObject:EnableMotion(false);
					physicsObject:Sleep();
				end
			end
		end
	end

	function PLUGIN:SaveData()
		local data = {}

		for k, v in pairs(ents.FindByClass("ix_notiboard")) do
			data[#data + 1] = {
				position = v:GetPos(),
				angles = v:GetAngles(),
				title = v:GetNetVar("title"),
				text = v:GetNetVar("text"),
				group = v:GetNetVar("group")
			}
		end

		self:SetData(data)
	end
end

ix.command.Add("NotiSetGroup", {
	description = "@cmdNotiSetGroup",
	arguments = {
		ix.type.number
	},
	adminOnly = true,
	OnRun = function(self, client, group)
		local data = {}
			data.start = client:GetShootPos()
			data.endpos = data.start + client:GetAimVector() * 450
			data.filter = client
		local trace = util.TraceLine(data)
		local entity = trace.Entity

		if (IsValid(entity) and entity:GetClass() == "ix_notiboard") then
			entity:SetNetVar("group", group)

			for _, v in ipairs(ents.FindByClass("ix_notiboard")) do
				if (v != entity and v:GetNetVar("group") == group) then
					entity:SetNetVar("title", v:GetNetVar("title"))
					entity:SetNetVar("text", v:GetNetVar("text"))
					break
				end
			end

			client:NotifyLocalized("notiSetGroup", group)
		else
			client:NotifyLocalized("notiNoTarget")
		end
	end
})

ix.command.Add("NotiSetGroupTitle", {
	description = "@cmdNotiSetGroupTitle",
	arguments = {
		ix.type.number,
		ix.type.string
	},
	adminOnly = true,
	OnRun = function(self, client, group, text)
		local count = 0
		for k, v in pairs(ents.FindByClass("ix_notiboard")) do
			if v:GetNetVar("group") == group then
				v:SetNetVar("title", text)
				count = count + 1
			end
		end

		if (count > 0) then
			client:NotifyLocalized("notiSetGroupTitle", count)
		else
			client:NotifyLocalized("noNotiGroup")
		end
	end
})

ix.command.Add("NotiSetGroupText", {
	description = "@cmdNotiSetGroupText",
	arguments = {
		ix.type.number,
		ix.type.string
	},
	adminOnly = true,
	OnRun = function(self, client, group, text)
		local count = 0
		for k, v in pairs(ents.FindByClass("ix_notiboard")) do
			if v:GetNetVar("group") == group then
				v:SetNetVar("text", text)
				count = count + 1
			end
		end

		if (count > 0) then
			client:NotifyLocalized("notiSetGroupText", count)
		else
			client:NotifyLocalized("noNotiGroup")
		end
	end
})