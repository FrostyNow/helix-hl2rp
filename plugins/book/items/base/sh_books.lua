ITEM.name = "Book"
ITEM.description = "skillBookDesc"
ITEM.category = "Utility"
ITEM.model = "models/props_lab/bindergraylabel01b.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.empty = false

function ITEM:GetName()
    return self:GetData("name", "Book")
end

if (CLIENT) then
    function ITEM:PopulateTooltip(tooltip)
        local nameData = self:GetData("name", L("Book"))
        local contentData = self:GetData("content", L("bookEmptyContent"))
        local attrID = self:GetData("attr", L("bookNone"))
        local bookLevel = self:GetData("level", 0)

        -- 1. Recommended Level
        local levelRow = tooltip:AddRow("book_level")
        levelRow:SetText(L("bookRecommendedLevel", math.floor(math.max(0, bookLevel - 2)), math.floor(bookLevel)))
        levelRow:SetTextColor(Color(100, 255, 100))
        levelRow:SetWide(500)
        levelRow:SizeToContents()

        -- 2. Target Skill
        local SkillRow = tooltip:AddRow("Skill_title")
        local skillName = (ix.attributes.list[attrID] and ix.attributes.list[attrID].name) or attrID
        SkillRow:SetText(L("bookSkillLabel", skillName))
        SkillRow:SetTextColor(Color(100, 255, 100))
        SkillRow:SetWide(500)
        SkillRow:SizeToContents()

        -- 3. Contents
        local contentRow = tooltip:AddRow("book_content")
        contentRow:SetText(contentData)
        contentRow:SetTextColor(Color(200, 155 , 200))
        contentRow:SetWide(500)
        contentRow:SizeToContents()
    end
end
ITEM.functions.ReadBook = {
    name = "bookReadBook",
    icon = "icon16/book_open.png",
    OnRun = function(item)
        local client = item.player
        local char = client:GetCharacter()
        
        if (!char) then return false end

        local title = item:GetData("name", "Book")
        local content = item:GetData("content", "bookEmptyContent")
        local attrID = item:GetData("attr") 
        local bookLevel = tonumber(item:GetData("level", 0)) or 0
        local playerLevel = char:GetAttribute(attrID, 0) 

        if (attrID and (bookLevel - 2) > playerLevel) then
            client:NotifyLocalized("bookIdiot", math.floor(bookLevel - 2))
            return false
        end

        if (attrID and playerLevel >= bookLevel) then
            client:NotifyLocalized("bookDontNeed")
            return false
        end

        net.Start("ix_book_read_ui")
            net.WriteString(title)
            net.WriteString(content)
        net.Send(client)

        if (attrID and ix.attributes.list[attrID]) then
            char:SetAttrib(attrID, bookLevel)
            client:NotifyLocalized("bookSkillIncreased", ix.attributes.list[attrID].name, math.floor(bookLevel))
            client:EmitSound("ambient/levels/citadel/skill_increase.wav", 60, 100)
        end

        return true 
    end,
    OnCanRun = function(item)
        return !IsValid(item.entity)
    end
}