local PLUGIN = PLUGIN

PLUGIN.name = "Quick Acts"
PLUGIN.author = "Frosty"
PLUGIN.description = "Quick menu for act command"

ix.util.Include("cl_plugin.lua")

ix.lang.AddTable("english", {
	actMenuDesc = "Opens the quick act menu.",
	actExit = "Stop Animation",
})

ix.lang.AddTable("korean", {
	actMenuDesc = "행동(Act) 선택 메뉴를 엽니다.",
	actExit = "동작 그만두기",
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
