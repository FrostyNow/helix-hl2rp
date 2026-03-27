include('shared.lua')

function ENT:Draw()
  self:DrawModel()
  local position = self:GetPos()
  local angles = self:GetAngles()
end																																																																																												

function ENT:OnPopulateEntityInfo(container)
		local name = container:AddRow("name")

        -- Entity
		name:SetImportant()
		name:SetText(L("writing_Table"))
		name:SizeToContents()

		local desc = container:AddRow("desc")
		desc:SetText(L("writing_Table"))
		desc:SizeToContents()
end

ix.gui.bookCache = ix.gui.bookCache or {}

net.Receive("ix_book_open_ui", function()
    local attributes = net.ReadTable()
    local tableEnt = net.ReadEntity()
    local savedDrafts = net.ReadTable() 

    if (IsValid(ix.gui.bookEditor)) then ix.gui.bookEditor:Remove() end

    local frame = vgui.Create("DFrame")
    frame:SetSize(850, 550)
    frame:SetTitle("중단된 책(최대 5개 저장 가능)")
    frame:MakePopup()
    frame:Center()
    ix.gui.bookEditor = frame

    -- [Left] Stat
    local attrList = frame:Add("DListView")
    attrList:Dock(LEFT)
    attrList:SetWidth(150)
    attrList:AddColumn("Write New Book")
    attrList:SetMultiSelect(false)

    -- [Right] book not ready
    local draftList = frame:Add("DListView")
    draftList:Dock(RIGHT)
    draftList:SetWidth(200)
    draftList:AddColumn("작업을 멈춘 책들")
    draftList:SetMultiSelect(false)

    -- [Center] Write Panel
    local p = frame:Add("DPanel")
    p:Dock(FILL)
    p:DockPadding(10, 10, 10, 10)

    local titleEntry = p:Add("DTextEntry")
    titleEntry:Dock(TOP)
    titleEntry:SetPlaceholderText("책 제목...")
    titleEntry:SetTall(30)

    local contentEntry = p:Add("DTextEntry")
    contentEntry:Dock(FILL)
    contentEntry:SetMultiline(true)
    contentEntry:DockMargin(0, 10, 0, 10)

    local craftBtn = p:Add("DButton")
    craftBtn:Dock(BOTTOM)
    craftBtn:SetTall(40)
    craftBtn:SetText("능력치를 선택하세요")
    craftBtn:SetEnabled(false)

    local currentAttrID = ""
    local isResuming = false

    local function RefreshDrafts()
        draftList:Clear()
        if (savedDrafts and #savedDrafts > 0) then
            for i, data in ipairs(savedDrafts) do
                local attrName = (ix.attributes.list[data.attrID] and ix.attributes.list[data.attrID].name) or data.attrID
                local displayTitle = string.utf8sub(data.title, 1, 8)
                local line = draftList:AddLine(attrName .. " (" .. displayTitle .. "...)")
                line.isServerDraft = true
                line.data = data
            end
        end
    end

    -- [왼쪽] 능력치
    attrList.OnRowSelected = function(_, _, row)
        currentAttrID = row.attrID
        isResuming = false
        
        local localSaved = ix.gui.bookCache[currentAttrID]
        titleEntry:SetText(localSaved and localSaved.title or "")
        contentEntry:SetText(localSaved and localSaved.content or "")
        
        craftBtn:SetEnabled(true)
        craftBtn:SetText(row:GetValue(1) .. "책 제작시작 (10초)")
    end

    -- [오른쪽 ]
    draftList.OnRowSelected = function(_, _, row)
        if (row.isServerDraft) then
            local data = row.data
            titleEntry:SetText(data.title)
            contentEntry:SetText(data.content)
            currentAttrID = data.attrID
            isResuming = true 
            
            craftBtn:SetEnabled(true)
            craftBtn:SetText("다시 작업 (" .. data.remaining .. "초 남음)")
            LocalPlayer():Notify("'" .. data.title .. "' 작업중이던 책을 꺼냈습니다.")
        end
    end

    local function SaveToCache()
        if (currentAttrID == "" or isResuming) then return end
        ix.gui.bookCache[currentAttrID] = {
            title = titleEntry:GetText(),
            content = contentEntry:GetText()
        }
    end
    titleEntry.OnValueChange = SaveToCache
    contentEntry.OnValueChange = SaveToCache

    for id, _ in pairs(attributes) do
        local name = (ix.attributes.list[id] and ix.attributes.list[id].name) or id
        local row = attrList:AddLine(name)
        row.attrID = id
    end
    
    RefreshDrafts()

    craftBtn.DoClick = function()
        local finalTitle = titleEntry:GetText() or ""
        local finalContent = contentEntry:GetText() or "" 
        
        if (finalTitle == "" or finalContent == "") then
            LocalPlayer():Notify("제목과 내용을 모두 입력해야 합니다.")
            return
        end
        
        net.Start("ix_book_finish")
            net.WriteString(tostring(finalTitle))
            net.WriteString(tostring(finalContent))
            net.WriteString(tostring(currentAttrID))
            net.WriteEntity(tableEnt)
        net.SendToServer()

        frame:Close()
    end
end)