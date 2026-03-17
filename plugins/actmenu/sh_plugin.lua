local PLUGIN = PLUGIN

PLUGIN.name = "Quick Acts"
PLUGIN.author = "Frosty"
PLUGIN.description = "Quick menu for act command"

-- Licensed under CC BY-NC-SA 4.0 (https://creativecommons.org/licenses/by-nc-sa/4.0/)

ix.util.Include("cl_plugin.lua")

ix.lang.AddTable("english", {
	actMenuDesc = "Opens the quick act menu.",
	actExit = "Stop Animation",
	actMenuBindUpdated = "Act menu bind set to %s.",
	actMenuBindDisabled = "Act menu bind disabled.",
	actMenuBindInvalid = "Invalid act menu bind. Use values like N, F6, KP_ENTER, or NONE.",
	actMenuBindCurrent = "Current act menu bind: %s.",
	optActMenuBind = "Act menu bind",
	optdActMenuBind = "Key used to open the act menu. Use values like N, F6, KP_ENTER, or NONE to disable it."
})

ix.lang.AddTable("korean", {
	actMenuDesc = "행동(Act) 선택 메뉴를 엽니다.",
	actExit = "동작 그만두기",
	actMenuBindUpdated = "행동 메뉴 바인드를 %s(으)로 설정했습니다.",
	actMenuBindDisabled = "행동 메뉴 바인드를 비활성화했습니다.",
	actMenuBindInvalid = "유효하지 않은 행동 메뉴 바인드입니다. N, F6, KP_ENTER, NONE 같은 값을 사용해 주세요.",
	actMenuBindCurrent = "현재 행동 메뉴 바인드: %s.",
	optActMenuBind = "행동 메뉴 바인드",
	optdActMenuBind = "행동 메뉴를 여는 키입니다. N, F6, KP_ENTER 같은 값을 쓰고, NONE으로 비활성화할 수 있습니다."
})

if (SERVER) then
	util.AddNetworkString("ixActMenuOpen")
else
	net.Receive("ixActMenuOpen", function()
		PLUGIN:OpenActMenu()
	end)
end

ix.command.Add("Act", {
	description = "@actMenuDesc",
	alias = {"ActMenu"},
	OnRun = function(self, client)
		net.Start("ixActMenuOpen")
		net.Send(client)
	end
})
