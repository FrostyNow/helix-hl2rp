include('shared.lua')

function ENT:Draw()
  self:DrawModel()
  local position = self:GetPos()
  local angles = self:GetAngles()
end																																																																																												

function ENT:OnPopulateEntityInfo(container)
		local name = container:AddRow("name")
		
		name:SetImportant()
		-- NOTE :: Need Add More Description Text
		name:SetText(L("writing_Table"))
		name:SizeToContents()

		-- NOTE :: Need Add More Description Text
		local desc = container:AddRow("desc")
		desc:SetText(L("writing_Table"))
		desc:SizeToContents()
end


net.Receive("ix_book_open_ui", function()
    if (IsValid(ix.gui.bookEditor)) then ix.gui.bookEditor:Remove() end

    local frame = vgui.Create("DFrame")
    frame:SetSize(500, 600)
    frame:SetTitle("원고 작성 및 제본")
    frame:MakePopup()
    frame:Center()
    ix.gui.bookEditor = frame

    -- 안내 문구
    local help = frame:Add("DLabel")
    help:SetText("종이에 내용을 정성껏 기록하세요.")
    help:Dock(TOP)
    help:SetContentAlignment(5)
    help:DockMargin(0, 5, 0, 5)

    -- [입력창 설정]
    local title = frame:Add("DTextEntry")
    title:Dock(TOP)
    title:SetPlaceholderText("제목을 입력하세요...")
    title:DockMargin(20, 10, 20, 10)

    local content = frame:Add("DTextEntry")
    content:Dock(FILL)
    content:SetMultiline(true)
    content:SetPlaceholderText("이곳에 내용을 작성하세요...")
    content:DockMargin(20, 0, 20, 20)
    content:SetVerticalScrollbarEnabled(true)

    -- [제본 버튼]
    local craftBtn = frame:Add("DButton")
    craftBtn:Dock(BOTTOM)
    craftBtn:SetText("원고 제본하기 (아이템 생성)")
    craftBtn:SetTall(40)
    craftBtn:DockMargin(20, 0, 20, 20)

    craftBtn.DoClick = function()
        -- 서버로 최종 데이터를 보냄 (아까 만든 로직 연결)
        net.Start("ix_book_finish")
            net.WriteString(title:GetText())
            net.WriteString(content:GetText())
        net.SendToServer()

        frame:Close()
    end
end)

net.Receive("ix_book_read", function()
    local title = net.ReadString()
    local content = net.ReadString()

    local frame = vgui.Create("DFrame")
    frame:SetSize(400, 500)
    frame:SetTitle(title) -- 책 제목을 창 제목으로
    frame:Center()
    frame:MakePopup()

    local scroll = frame:Add("DScrollPanel")
    scroll:Dock(FILL)

    local text = scroll:Add("DLabel")
    text:SetText(content)
    text:SetFont("ixChatFont") -- Helix 기본 폰트
    text:SetWrap(true) -- 자동 줄바꿈
    text:SetAutoStretchVertical(true)
    text:Dock(TOP)
    text:DockMargin(10, 10, 10, 10)
    text:SetTextColor(Color(255, 255, 255))
end)