PLUGIN.quiz = {}

-- Questions for the quiz plugin.
PLUGIN.quiz.questions = {
	{ -- 1. IC/OOC
		question = "quizQ1",
		options = {
			"quizQ1_A1",
			"quizQ1_A2",
			"quizQ1_A3"
		},
		correct = 1
	},
	{ -- 2. Metagaming
		question = "quizQ2",
		options = {
			"quizQ2_A1",
			"quizQ2_A2",
			"quizQ2_A3"
		},
		correct = 1
	},
	{ -- 3. Powergaming
		question = "quizQ3",
		options = {
			"quizQ3_A1",
			"quizQ3_A2",
			"quizQ3_A3"
		},
		correct = 1
	},
	{ -- 4. RDM
		question = "quizQ4",
		options = {
			"quizQ4_A1",
			"quizQ4_A2",
			"quizQ4_A3"
		},
		correct = 1
	},
	{ -- 5. NLR
		question = "quizQ5",
		options = {
			"quizQ5_A1",
			"quizQ5_A2",
			"quizQ5_A3"
		},
		correct = 1
	},
	{ -- 6. FearRP
		question = "quizQ6",
		options = {
			"quizQ6_A1",
			"quizQ6_A2",
			"quizQ6_A3"
		},
		correct = 1
	},
	{ -- 7. /me usage
		question = "quizQ7",
		options = {
			"quizQ7_A1",
			"quizQ7_A2",
			"quizQ7_A3"
		},
		correct = 1
	},
	{ -- 8. Prop Abuse
		question = "quizQ8",
		options = {
			"quizQ8_A1",
			"quizQ8_A2",
			"quizQ8_A3"
		},
		correct = 1
	},
	{ -- 9. Character Name
		question = "quizQ9",
		options = {
			"quizQ9_A1",
			"quizQ9_A2",
			"quizQ9_A3"
		},
		correct = 1
	},
	{ -- 10. Serious RP Goal
		question = "quizQ10",
		options = {
			"quizQ10_A1",
			"quizQ10_A2",
			"quizQ10_A3"
		},
		correct = 1
	}
}

-- The default text to be shown for questions which a player have not yet selected an answer for.
PLUGIN.quiz.defaultText = "quizSelectOption"

-- How wide the quiz menu is. This is a ratio for the screen's width. (0.5 = half of the screen's width)
PLUGIN.quiz.menuWidth = 0.5

-- How tall the quiz menu is. This is a ratio for the screen's height. (0.5 = half the screen's height)
PLUGIN.quiz.menuHeight = 0.75

-- The kick message a player should recieve if they have any incorrect answers.
PLUGIN.quiz.kickMessage = "quizFailKick"
