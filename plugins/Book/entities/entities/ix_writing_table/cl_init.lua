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
    local attributes = net.ReadTable()
    -- Debug Only
    -- print("[BookSystem] :")
    -- PrintTable(attributes)

    if (IsValid(ix.gui.bookEditor)) then ix.gui.bookEditor:Remove() end

    local frame = vgui.Create("DFrame")
    frame:SetSize(500, 600)
    frame:SetTitle("Wrting Book")
    frame:MakePopup()
    frame:Center()
    ix.gui.bookEditor = frame

    local sheet = frame:Add("DPropertySheet")
    sheet:Dock(FILL)

    for id, value in pairs(attributes) do
        local attributeInfo = ix.attributes.list[id]
        local attrName = attributeInfo and attributeInfo.name or id

        if (value >= 0) then
            local p = vgui.Create("DPanel", sheet)
            p:Dock(FILL)
            p:DockPadding(10, 10, 10, 10)

            local info = p:Add("DLabel")
            info:SetText(attrName .. " 숙련도 (" .. value .. ") 기반 서적")
            info:SetFont("ixMediumFont")
            info:Dock(TOP)
            info:SetContentAlignment(5)
            info:SetTall(30)

            local title = p:Add("DTextEntry")
            title:Dock(TOP)
            title:SetPlaceholderText("책 제목을 입력하세요...")
            title:DockMargin(0, 10, 0, 10)

            local content = p:Add("DTextEntry")
            content:Dock(FILL)
            content:SetMultiline(true)
            content:SetPlaceholderText(attrName .. "에 관한 지식을 기록하세요...")

            local btn = p:Add("DButton")
            btn:Dock(BOTTOM)
            btn:SetTall(35)
            btn:SetText(attrName .. " 교본 제작하기")
            btn:DockMargin(0, 10, 0, 0)

            btn.DoClick = function()
                net.Start("ix_book_finish")
                    net.WriteString(title:GetText())
                    net.WriteString(content:GetText())
                    net.WriteString(id) -- 능력치 ID를 같이 보냄
                net.SendToServer()
                frame:Close()
            end

            -- 탭 추가
            sheet:AddSheet(attrName, p, "icon16/book_edit.png")
        end
    end
end)
