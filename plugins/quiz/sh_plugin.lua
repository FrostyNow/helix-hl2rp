local PLUGIN = PLUGIN
PLUGIN.name = "Quiz"
PLUGIN.author = "Qemist (Ported)"
PLUGIN.description = "A quiz which will be shown the first time a player joins your server."

ix.util.Include("sh_config.lua")
ix.util.Include("cl_quiz.lua")

if (SERVER) then
	function PLUGIN:PlayerInitialSpawn(client)
		timer.Simple(3, function()
			if (IsValid(client) and !client:IsBot() and !client:GetData("passedQuiz", false)) then
				netstream.Start(client, "ixQuizOpen")
			end
		end)
	end

	netstream.Hook("ixQuizResult", function(client, result)
		if (result) then
			client:SetData("passedQuiz", true)
			client:NotifyLocalized("quizPassed")
		else
			client:Kick("One or more of your answers were incorrect, you may rejoin to try again.")
		end
	end)
else
	ix.lang.AddTable("english", {
		quizTitle = "Quiz",
		quizNotification = "If any answers are incorrect, you may be kicked from the server.",
		quizSubmit = "Submit answers",
		quizPassed = "You have passed the quiz.",
		quizLearnRules = "Learn Rules",
		cmdPlyForceQuizDesc = "Forcefully shows the quiz to a specific player.",
		cmdPlyForceQuizNotice = "Opened the quiz for %s.",
		
		-- General
		quizSelectOption = "Select an option",
		
		-- Q1 IC/OOC
		quizQ1 = "What is the difference between IC (In-Character) and OOC (Out-Of-Character)?",
		quizQ1_A1 = "IC is for roleplay, OOC is for real world talk.", -- Correct
		quizQ1_A2 = "They are the same thing.",
		quizQ1_A3 = "IC is for admins only.",

		-- Q2 Metagaming
		quizQ2 = "What is Metagaming?",
		quizQ2_A1 = "Using OOC information for IC advantage.", -- Correct
		quizQ2_A2 = "Playing the game with friends.",
		quizQ2_A3 = "Using the best weapons in the game.",

		-- Q3 Powergaming
		quizQ3 = "Which of the following is an example of Powergaming?",
		quizQ3_A1 = "/me shoots the person in the head and killing them instantly.", -- Correct
		quizQ3_A2 = "/me attempts to punch the person.",
		quizQ3_A3 = "/me ties their shoelaces.",
		
		-- Q4 RDM
		quizQ4 = "What is RDM (Random Deathmatch)?",
		quizQ4_A1 = "Killing another player without a valid roleplay reason.", -- Correct
		quizQ4_A2 = "Killing a player during a war.",
		quizQ4_A3 = "Killing a zombie.",

		-- Q5 NLR
		quizQ5 = "What applies when your character dies (NLR - New Life Rule)?",
		quizQ5_A1 = "You forget everything leading up to your death and cannot return immediately.", -- Correct
		quizQ5_A2 = "You can go back and get revenge.",
		quizQ5_A3 = "You keep all your items and memory.",

		-- Q6 FearRP
		quizQ6 = "If two heavily armed Civil Protection officers aim at you, what should you do (FearRP)?",
		quizQ6_A1 = "Roleplay fear and follow their orders.", -- Correct
		quizQ6_A2 = "Pull out a weapon and fight them.",
		quizQ6_A3 = "Run away immediately.",

		-- Q7 /me
		quizQ7 = "Which command is used to describe a physical action your character is doing?",
		quizQ7_A1 = "/me", -- Correct
		quizQ7_A2 = "/ooc",
		quizQ7_A3 = "/y",

		-- Q8 Prop Abuse
		quizQ8 = "Is it allowed to use props to climb into unreachable areas (Prop Climbing)?",
		quizQ8_A1 = "No, it is forbidden.", -- Correct
		quizQ8_A2 = "Yes, if no one sees it.",
		quizQ8_A3 = "Yes, always.",

		-- Q9 Name
		quizQ9 = "What is a proper roleplay name?",
		quizQ9_A1 = "John Doe", -- Correct
		quizQ9_A2 = "xX_Killa_Xx",
		quizQ9_A3 = "Admin User",

		-- Q10 Goal
		quizQ10 = "What is the goal of a Serious RP server?",
		quizQ10_A1 = "To create immersive stories and develop characters.", -- Correct
		quizQ10_A2 = "To kill as many people as possible.",
		quizQ10_A3 = "To become the richest player."
	})

	ix.lang.AddTable("korean", {
		quizTitle = "퀴즈",
		quizNotification = "오답이 있을 경우 서버에서 추방될 수 있습니다.",
		quizSubmit = "제출",
		quizPassed = "퀴즈를 통과했습니다.",
		quizLearnRules = "규칙 배우기",
		cmdPlyForceQuizDesc = "특정 플레이어에게 강제로 퀴즈 창을 표시합니다.",
		cmdPlyForceQuizNotice = "%s에게 퀴즈 창을 띄웠습니다.",
		
		-- General
		quizSelectOption = "하나를 선택하세요",
		
		-- Q1 IC/OOC
		quizQ1 = "IC(In-Character)와 OOC(Out-Of-Character)의 차이점은 무엇입니까?",
		quizQ1_A1 = "IC는 역할극을 위한 것이고, OOC는 현실 세계 대화를 위한 것입니다.", -- Correct
		quizQ1_A2 = "둘은 같은 것입니다.",
		quizQ1_A3 = "IC는 관리자만 사용할 수 있습니다.",

		-- Q2 Metagaming
		quizQ2 = "메타게이밍(Metagaming)이란 무엇입니까?",
		quizQ2_A1 = "OOC 정보를 사용하여 IC에서 이득을 취하는 행위입니다.", -- Correct
		quizQ2_A2 = "친구들과 함께 게임을 하는 것입니다.",
		quizQ2_A3 = "게임 내에서 가장 좋은 무기를 사용하는 것입니다.",

		-- Q3 Powergaming
		quizQ3 = "다음 중 파워게이밍(Powergaming/먼치킨)의 예시는 무엇입니까?",
		quizQ3_A1 = "/me 상대를 머리에 쏴서 즉사시킵니다.", -- Correct
		quizQ3_A2 = "/me 상대를 주먹으로 때리려 시도합니다.",
		quizQ3_A3 = "/me 신발끈을 묶습니다.",
		
		-- Q4 RDM
		quizQ4 = "RDM(Random Deathmatch/묻지마 살인)이란 무엇입니까?",
		quizQ4_A1 = "타당한 역할극적 이유 없이 다른 플레이어를 살해하는 것입니다.", -- Correct
		quizQ4_A2 = "전쟁 중에 플레이어를 죽이는 것입니다.",
		quizQ4_A3 = "좀비를 죽이는 것입니다.",

		-- Q5 NLR
		quizQ5 = "캐릭터가 사망했을 때 적용되는 규칙(NLR - New Life Rule)은 무엇입니까?",
		quizQ5_A1 = "사망 직전의 기억을 모두 잊으며, 즉시 사망 장소로 돌아올 수 없습니다.", -- Correct
		quizQ5_A2 = "돌아가서 복수할 수 있습니다.",
		quizQ5_A3 = "모든 아이템과 기억을 유지합니다.",

		-- Q6 FearRP
		quizQ6 = "중무장한 시민 보호 기동대(CP) 두 명이 당신을 겨누고 있다면 어떻게 해야 합니까(FearRP)?",
		quizQ6_A1 = "공포를 연기하며 그들의 명령에 따릅니다.", -- Correct
		quizQ6_A2 = "무기를 꺼내서 그들과 싸웁니다.",
		quizQ6_A3 = "즉시 도망칩니다.",

		-- Q7 /me
		quizQ7 = "캐릭터의 신체적 행동을 묘사하는 데 사용되는 명령어는 무엇입니까?",
		quizQ7_A1 = "/me", -- Correct
		quizQ7_A2 = "/ooc",
		quizQ7_A3 = "/y",

		-- Q8 Prop Abuse
		quizQ8 = "프롭을 사용하여 갈 수 없는 곳으로 올라가는 행위(Prop Climbing)는 허용됩니까?",
		quizQ8_A1 = "아니요, 금지되어 있습니다.", -- Correct
		quizQ8_A2 = "아무도 보지 않는다면 가능합니다.",
		quizQ8_A3 = "네, 항상 가능합니다.",

		-- Q9 Name
		quizQ9 = "적절한 역할극 이름은 무엇입니까?",
		quizQ9_A1 = "John Doe", -- Correct
		quizQ9_A2 = "xX_Killa_Xx",
		quizQ9_A3 = "Admin User",

		-- Q10 Goal
		quizQ10 = "시리어스 RP(Serious RP) 서버의 목표는 무엇입니까?",
		quizQ10_A1 = "몰입감 있는 이야기를 만들고 캐릭터를 발전시키는 것입니다.", -- Correct
		quizQ10_A2 = "가능한 한 많은 사람을 죽이는 것입니다.",
		quizQ10_A3 = "가장 부자가 되는 것입니다."
	})

	netstream.Hook("ixQuizOpen", function()
		if (IsValid(ix.gui.characterMenu)) then
			ix.gui.characterMenu:SetVisible(false)
		end
		
		vgui.Create("ixQuiz")
	end)
end

ix.command.Add("PlyForceQuiz", {
	description = "@cmdPlyForceQuizDesc",
	adminOnly = true,
	arguments = {
		ix.type.player
	},
	OnRun = function(self, client, target)
		target:SetData("passedQuiz", false)
		netstream.Start(target, "ixQuizOpen")
		
		if (client) then
			return "@cmdPlyForceQuizNotice", target:Name()
		end
	end
})
