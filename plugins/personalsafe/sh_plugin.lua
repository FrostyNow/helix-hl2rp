local PLUGIN = PLUGIN

PLUGIN.name = "Personal Safe"
PLUGIN.author = "Mixed"
PLUGIN.desc = "Add a items to set the name and the password of a containers on the map to get a personal safe. (Can works on all containers of the map)."

ix.container.Register("models/Items/ammoCrate_Rockets.mdl", {
	name = "Personal Safe",
	description = "A personal safe.",
	width = 6,
	height = 4,
})

ix.lang.AddTable("english", {
	notPersonalSafe = "You must use this on a personal safe!",
	itemSafePasswordDesc = "A safe password to secure your own container.",
	itemSafeNameDesc = "A safe name to rename your own container.",
	safeAlreadySecured = "You cannot put a password on an already secured container!",
	safeAlreadyNamed = "You cannot put a name on an already named container!",
	containerPasswordTitle = "Container Password",
	containerPasswordDesc = "What password do you want for your personal safe?",
	containerNameTitle = "Container Name",
	containerNameDesc = "What name do you want for your personal safe?",
})

ix.lang.AddTable("korean", {
	["Set Password"] = "비밀번호 설정",
	["Set Name"] = "이름 설정",
	itemSafePasswordDesc = "개인 보관함을 비밀번호로 잠글 수 있습니다.",
	itemSafeNameDesc = "개인 보관함의 이름을 설정할 수 있습니다.",
	notPersonalSafe = "개인 보관함에 사용해야 합니다!",
	safeAlreadySecured = "이미 잠긴 보관함에는 비밀번호를 설정할 수 없습니다!",
	safeAlreadyNamed = "이미 이름을 정한 보관함에는 이름을 설정할 수 없습니다!",
	containerPasswordTitle = "보관함 비밀번호",
	containerPasswordDesc = "보관함에 설정할 비밀번호를 입력하세요.",
	containerNameTitle = "보관함 이름",
	containerNameDesc = "보관함에 설정할 이름을 입력하세요.",
})