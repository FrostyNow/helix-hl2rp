local PANEL = {}

local function GetQuizText(key)
	local lang = GetConVar("gmod_language"):GetString()
	if (lang == "ko") then
		if (ix.lang.stored["korean"] and ix.lang.stored["korean"][key]) then
			return ix.lang.stored["korean"][key]
		end
	end
	
	if (ix.lang.stored["english"] and ix.lang.stored["english"][key]) then
		return ix.lang.stored["english"][key]
	end

	return L(key)
end

function PANEL:Init()
	self:SetPos(ScrW() * 0.250, ScrH() * 0.125)
	self:SetSize(ScrW() * (ix.plugin.list["quiz"].quiz.menuWidth or 0.5), ScrH() * (ix.plugin.list["quiz"].quiz.menuHeight or 0.75))
	self:MakePopup()
	self:ShowCloseButton(false)
	self:SetDraggable(false)
	self:SetDrawOnTop(true)
	self:SetTitle(GetQuizText("quizTitle"))
	self:SetBackgroundBlur(true)

	local noticePanel = self:Add("DLabel")
	noticePanel:Dock(TOP)
	noticePanel:DockMargin(0, 0, 0, 5)
	noticePanel:SetText(GetQuizText("quizNotification"))
	noticePanel:SetTextColor(Color(255, 100, 100))
	noticePanel:SetContentAlignment(5)
	noticePanel:SizeToContents()
	
	local panel = self:Add("DScrollPanel")
	panel:Dock(FILL)
	panel:SetDrawBackground(true)

	local answers = {}
	local quizConfig = ix.plugin.list["quiz"].quiz

	local questionIndices = {}
	for i = 1, #quizConfig.questions do
		table.insert(questionIndices, i)
	end
	
	for i = #questionIndices, 2, -1 do
		local j = math.random(i)
		questionIndices[i], questionIndices[j] = questionIndices[j], questionIndices[i]
	end

	for _, k in ipairs(questionIndices) do
		local question = quizConfig.questions[k]
		answers[k] = {}

		local text = panel:Add("DLabel")
		text:Dock(TOP)
		text:DockMargin(4, 10, 4, 0)
		text:SetDark(false) 
		text:SetText(GetQuizText(question.question))
		text:SizeToContents()

		local options = panel:Add("DComboBox")
		options:Dock(TOP)
		options:DockMargin(4, 5, 4, 10)
		options:SetValue(GetQuizText(question.text or quizConfig.defaultText))		
		options.OnSelect = function(panel, index, value)
			answers[k].correct = (question.correct == index)
			answers[k].selected = true
		end

		for _, option in ipairs(question.options) do
			options:AddChoice(GetQuizText(option))
		end
	end

	local learn = self:Add("DButton")
	learn:Dock(BOTTOM)
	learn:DockMargin(0, 5, 0, 0)
	learn:SetText(GetQuizText("quizLearnRules"))
	learn.DoClick = function()
		self:SetDrawOnTop(false)
		gui.OpenURL("https://steamcommunity.com/sharedfiles/filedetails/?id=268714411")
	end

	local submit = self:Add("DButton")
	submit:Dock(BOTTOM)
	submit:DockMargin(0, 5, 0, 0)
	submit:SetText(GetQuizText("quizSubmit"))
	submit.DoClick = function()
		for k, question in ipairs(quizConfig.questions) do
			local answer = answers[k]
			if (not answer) then
				netstream.Start("ixQuizResult", false)
				return
			end
			
			answer.correct = answer.correct or false
			answer.selected = answer.selected or false

			if (!answer.correct or !answer.selected) then
				netstream.Start("ixQuizResult", false)
				return
			end		    		
		end

		netstream.Start("ixQuizResult", true)
		self:Close()
		
		if (IsValid(ix.gui.characterMenu)) then
			ix.gui.characterMenu:SetVisible(true)
		end
	end
end

vgui.Register("ixQuiz", PANEL, "DFrame")
