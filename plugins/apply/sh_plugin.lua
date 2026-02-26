PLUGIN.name = "Apply"
PLUGIN.author = "FatherSquirrel | Modified by Frosty"
PLUGIN.description = "Adds the functionality to say ur name and CID or just ur name."

ix.util.Include("sh_commands.lua")

ix.lang.AddTable("english", {
	cmdApply = "Says your name and CID to a CP.",
	cmdName = "Says your name.",
	dontHaveCID = "You don´t own a CID!",
})

ix.lang.AddTable("korean", {
	cmdApply = "이름과 시민 ID를 기동대에게 말합니다.",
	cmdName = "이름을 말합니다.",
	dontHaveCID = "당신은 신분증이 없습니다!",
})