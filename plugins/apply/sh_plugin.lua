PLUGIN.name = "Apply"
PLUGIN.author = "FatherSquirrel | Heavily modified by Frosty"
PLUGIN.description = "Adds the functionality to show your CID or just say your name."

ix.util.Include("sh_commands.lua")

if (SERVER) then
	util.AddNetworkString("ixApplyCID")
end

ix.lang.AddTable("english", {
	cmdApply = "Says your name and CID to a CP.",
	cmdName = "Says your name.",
	dontHaveCID = "You don't own a CID!",
	applyCooldown = "You must wait %s second(s) before using /Apply again.",
	cidTitle = "<:: CITY 17 CITIZEN ID ::>",
	cidName = "Name",
	cidID = "ID",
	cidGrade = "Grade",
	["Civil Worker's Union"] = "Civil Worker's Union",
	["First Class Citizen"] = "First Class Citizen",
	["Second Class Citizen"] = "Second Class Citizen",
})

ix.lang.AddTable("korean", {
	cmdApply = "이름과 시민 ID를 기동대에게 말합니다.",
	cmdName = "이름을 말합니다.",
	dontHaveCID = "당신은 신분증이 없습니다!",
	applyCooldown = "/Apply를 다시 사용하려면 %s초 더 기다려야 합니다.",
	cidTitle = "<:: 17번 지구 시민증 ::>",
	cidName = "이름",
	cidID = "ID",
	cidGrade = "등급",
	["Civil Worker's Union"] = "시민 노동 조합",
	["First Class Citizen"] = "일등 시민",
	["Second Class Citizen"] = "이등 시민",
})

if (CLIENT) then
	net.Receive("ixApplyCID", function()
		local data = net.ReadTable()
		local name = data.name
		local id = data.id
		local class = data.class
		local owner = data.owner

		if (IsValid(ix.gui.cidPanel)) then
			ix.gui.cidPanel:Remove()
		end

		local color = team.GetColor(FACTION_CITIZEN) or Color(200, 100, 0)

		if (class == "Civil Worker's Union") then
			color = (ix.class.list[CLASS_CWU] and ix.class.list[CLASS_CWU].color) or Color(50, 150, 50)
		elseif (class == "First Class Citizen") then
			color = (ix.class.list[CLASS_ELITE_CITIZEN] and ix.class.list[CLASS_ELITE_CITIZEN].color) or Color(50, 100, 200)
		end

		local panel = vgui.Create("DFrame")
		panel:SetSize(400, 260)
		panel:Center()
		panel:SetTitle("")
		panel:MakePopup()
		panel:SetDraggable(true)
		panel:ShowCloseButton(true)
		ix.gui.cidPanel = panel

		function panel:Think()
			if (!IsValid(owner) or owner:GetPos():DistToSqr(LocalPlayer():GetPos()) > 16384) then -- 128^2
				self:Remove()
			end
		end

		function panel:Paint(w, h)
			ix.util.DrawBlur(self, 5)

			surface.SetDrawColor(0, 0, 0, 180)
			surface.DrawRect(0, 0, w, h)

			surface.SetDrawColor(30, 30, 30, 200)
			surface.DrawOutlinedRect(0, 0, w, h)

			-- Header
			surface.SetDrawColor(color.r, color.g, color.b, 200)
			surface.DrawRect(0, 0, w, 40)

			surface.SetDrawColor(255, 255, 255, 20)
			surface.DrawOutlinedRect(0, 0, w, 40)

			draw.SimpleText(L("cidTitle"), "ixMediumFont", w / 2, 20, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end

		local content = panel:Add("Panel")
		content:Dock(FILL)
		content:DockMargin(20, 10, 20, 20)

		local function AddInfo(label, value)
			local row = content:Add("Panel")
			row:Dock(TOP)
			row:SetTall(45)
			row:DockMargin(0, 5, 0, 2)

			local lbl = row:Add("DLabel")
			lbl:SetText(L(label):upper())
			lbl:SetFont("ixSmallFont")
			lbl:SetTextColor(color_white)
			lbl:Dock(TOP)
			lbl:SetTall(15)

			local val = row:Add("DLabel")
			val:SetText(value)
			val:SetFont("ixMediumFont")
			val:SetTextColor(color_white)
			val:Dock(FILL)
		end

		AddInfo("cidName", name)
		AddInfo("cidID", "#" .. id)
		AddInfo("cidGrade", L(class or "Second Class Citizen"))
	end)
end
