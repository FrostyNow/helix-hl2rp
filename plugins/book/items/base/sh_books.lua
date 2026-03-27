ITEM.name = "books"
ITEM.description = "Simple."
ITEM.category = "education"
ITEM.model = "models/props_lab/bindergraylabel01b.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.empty = false

function ITEM:GetName()
    return self:GetData("name", "제목 없는 책")
end

if (CLIENT) then
    function ITEM:PopulateTooltip(tooltip)
        local nameData = self:GetData("name", "제목 없는 책")
        local contentData = self:GetData("content", "내용이 없습니다.")
        local attrID = self:GetData("attr", "없음")
        local bookLevel = self:GetData("level", 0)

        -- 1. 권장 숙련도
        local levelRow = tooltip:AddRow("book_level")
        levelRow:SetText("권장 숙련도: " .. math.floor(math.max(0, bookLevel - 2)) .. " ~ " .. math.floor(bookLevel))
        levelRow:SetTextColor(Color(100, 255, 100))
        levelRow:SetWide(500)
        levelRow:SizeToContents()

        -- 2. 적용 스킬
        local SkillRow = tooltip:AddRow("Skill_title")
        local skillName = (ix.attributes.list[attrID] and ix.attributes.list[attrID].name) or attrID
        SkillRow:SetText("적용 스킬: " .. skillName)
        SkillRow:SetTextColor(Color(100, 255, 100))
        SkillRow:SetWide(500)
        SkillRow:SizeToContents()

        -- 3. 내용
        local contentRow = tooltip:AddRow("book_content")
        contentRow:SetText(contentData)
        contentRow:SetTextColor(Color(200, 155 , 200))
        contentRow:SetWide(500)
        contentRow:SizeToContents()
    end
end
ITEM.functions.ReadBook = {
    name = "읽기",
    icon = "icon16/book_open.png",
    OnRun = function(item)
        local client = item.player
        local char = client:GetCharacter()
        
        if (!char) then return false end

        local title = item:GetData("name", "제목 없음")
        local content = item:GetData("content", "내용이 비어있습니다.")
        local attrID = item:GetData("attr") 
        local bookLevel = tonumber(item:GetData("level", 0)) or 0
        local playerLevel = char:GetAttribute(attrID, 0) 

        if (attrID and (bookLevel - 2) > playerLevel) then
            client:Notify("이 서적의 내용을 이해하기에는 지식이 너무 부족합니다. (최소 " .. math.floor(bookLevel - 2) .. " 필요)")
            return false
        end

        if (attrID and playerLevel >= bookLevel) then
            client:Notify("이미 이 서적 이상의 지식을 갖추고 있어 배울 것이 없습니다.")
            return false
        end

        net.Start("ix_book_read_ui")
            net.WriteString(title)
            net.WriteString(content)
        net.Send(client)

        if (attrID and ix.attributes.list[attrID]) then
            char:SetAttrib(attrID, bookLevel)
            client:Notify(ix.attributes.list[attrID].name .. " 숙련도가 " .. math.floor(bookLevel) .. " 레벨로 상승했습니다!")
            client:EmitSound("ambient/levels/citadel/skill_increase.wav", 60, 100)
        end

        return true 
    end,
    OnCanRun = function(item)
        return !IsValid(item.entity)
    end
}