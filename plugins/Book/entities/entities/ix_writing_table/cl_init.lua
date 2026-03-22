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
ix.gui.bookCache = ix.gui.bookCache or {}

net.Receive("ix_book_open_ui", function()
    local attributes = net.ReadTable()

    if (IsValid(ix.gui.bookEditor)) then ix.gui.bookEditor:Remove() end

    local frame = vgui.Create("DFrame")
    frame:SetSize(900, 600) -- 가로 폭을 넓혀서 오른쪽 공간 확보
    frame:SetTitle("전문 서적 집필 및 임시 저장소")
    frame:MakePopup()
    frame:Center()
    ix.gui.bookEditor = frame

    -- [1] 왼쪽: 능력치 리스트
    local attrList = frame:Add("DListView")
    attrList:Dock(LEFT)
    attrList:SetWidth(150)
    attrList:AddColumn("능력치")
    attrList:SetMultiSelect(false)

    -- [2] 오른쪽: 임시 저장된 원고 리스트
    local saveList = frame:Add("DListView")
    saveList:Dock(RIGHT)
    saveList:SetWidth(180)
    saveList:AddColumn("임시 저장된 원고")
    saveList:SetMultiSelect(false)

    -- [3] 중앙: 입력 패널
    local centerPanel = frame:Add("DPanel")
    centerPanel:Dock(FILL)
    centerPanel:DockPadding(10, 10, 10, 10)

    local titleEntry = centerPanel:Add("DTextEntry")
    titleEntry:Dock(TOP)
    titleEntry:SetPlaceholderText("제목...")
    titleEntry:SetTall(30)

    local bodyEntry = centerPanel:Add("DTextEntry")
    bodyEntry:Dock(FILL)
    bodyEntry:SetMultiline(true)
    bodyEntry:DockMargin(0, 10, 0, 10)

    local craftBtn = centerPanel:Add("DButton")
    craftBtn:Dock(BOTTOM)
    craftBtn:SetTall(40)
    craftBtn:SetText("제본 시작")

    local selectedID = "none"
    local selectedID_Skill = 0

    -- [함수] 오른쪽 저장 목록 갱신
    local function RefreshSaveList()
        saveList:Clear()
        for id, data in pairs(ix.gui.bookCache) do
            local attrName = (ix.attributes.list[id] and ix.attributes.list[id].name) or id
            local line = saveList:AddLine(attrName .. " 원고")
            line.attrID = id
        end
    end

    -- 왼쪽 능력치 클릭 시
    attrList.OnRowSelected = function(_, _, row)
        selectedID = row.attrID
        selectedID_Skill = row.attr_Skill
        local saved = ix.gui.bookCache[selectedID]
        
        -- 해당 능력치로 저장된게 있으면 불러오고, 없으면 비움
        titleEntry:SetText(saved and saved.title or "")
        bodyEntry:SetText(saved and saved.content or "")
        
        craftBtn:SetText(row:GetValue(1) .. " 기반 서적 제작")
    end

    -- 오른쪽 임시 저장 클릭 시 바로 불러오기
    saveList.OnRowSelected = function(_, _, row)
        selectedID = row.attrID
        local saved = ix.gui.bookCache[selectedID]
        titleEntry:SetText(saved.title)
        bodyEntry:SetText(saved.content)
    end

    -- 실시간 임시 저장 (글을 쓸 때마다 캐시에 저장)
    local function AutoSave()
        if selectedID == "none" then return end
        ix.gui.bookCache[selectedID] = {
            title = titleEntry:GetText(),
            content = bodyEntry:GetText()
        }
        RefreshSaveList() -- 목록 이름 갱신
    end

    titleEntry.OnValueChange = AutoSave
    bodyEntry.OnValueChange = AutoSave

    -- 초기 데이터 채우기
    for id, value in pairs(attributes) do
        local name = (ix.attributes.list[id] and ix.attributes.list[id].name) or id
        local row = attrList:AddLine(name)
        row.attrID = id
    end
    RefreshSaveList()

    -- 제작 버튼
    craftBtn.DoClick = function()
        net.Start("ix_book_Wrting_Start")
            net.WriteString(titleEntry:GetText())
            net.WriteString(bodyEntry:GetText())
            net.WriteString(selectedID)
            net.WriteString(selectedID)
        net.SendToServer()
        
        ix.gui.bookCache[selectedID] = nil -- 제작 완료 후 삭제
        frame:Close()
    end
end)

net.Receive("ix_book_Wrting_Start", function(len, client)
    -- [중요] 클라이언트가 보낸 순서대로 읽기!
    local title = net.ReadString()        -- 첫 번째: 제목
    local content = net.ReadString()      -- 두 번째: 내용
    local attrID = net.ReadString()       -- 세 번째: 능력치 ID (예: "str")
    local attrValue = net.ReadString()    -- 네 번째: 능력치 수치 (String으로 보냈을 경우)

    local character = client:GetCharacter()
    if (!character) then return end

    -- 아이템 생성 로직
    -- 'testbook'은 실제 등록된 아이템 ID여야 합니다.
    local inventory = character:GetInventory()
    
    if (inventory) then
        -- 아이템을 추가하면서 작성한 데이터를 'Data' 테이블에 삽입
        inventory:Add("testbook", 1, {
            name = title,           -- 아이템의 이름 데이터
            content = content,      -- 아이템의 내용 데이터
            author = client:Name(), -- 작성자 이름 기록
            originAttr = attrID,    -- 기반이 된 능력치 ID
            originValue = attrValue -- 당시 능력치 수치
        })

        client:Notify(attrID .. " 지식을 바탕으로 '" .. title .. "' 서적을 제본했습니다.")
    end
end)

