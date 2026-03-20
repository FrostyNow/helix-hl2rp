local PLUGIN = PLUGIN

PLUGIN.name = "User Interface Rework (Tab Menu)"
PLUGIN.description = ""
PLUGIN.author = "Riggs | Modified by Frosty"
PLUGIN.schema = "Any"
PLUGIN.license = [[
Copyright 2022 Riggs Mackay

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

ix.lang.AddTable("english", {
	["dateFormat12"] = "%A, %B %d, %Y. %I:%M %p",
	["dateFormat24"] = "%A, %B %d, %Y. %H:%M",
})
ix.lang.AddTable("korean", {
	["dateFormat12"] = "%Y년 %m월 %d일 %A %p %I:%M",
	["dateFormat24"] = "%Y년 %m월 %d일 %A %H:%M",
	["January"] = "1월",
	["February"] = "2월",
	["March"] = "3월",
	["April"] = "4월",
	["May"] = "5월",
	["June"] = "6월",
	["July"] = "7월",
	["August"] = "8월",
	["September"] = "9월",
	["October"] = "10월",
	["November"] = "11월",
	["December"] = "12월",
	["Monday"] = "월요일",
	["Tuesday"] = "화요일",
	["Wednesday"] = "수요일",
	["Thursday"] = "목요일",
	["Friday"] = "금요일",
	["Saturday"] = "토요일",
	["Sunday"] = "일요일",
	["AM"] = "오전",
	["PM"] = "오후",
})

ix.config.Add("tabMenuTitle", false, "Wether or not there should be titles on tabs within the tab menu. (NOTE: THIS CAN BE BUGGY ON PLUGINS THAT ADD CUSTOM TABS)", function()
	if ( CLIENT ) then
		ix.util.Notify("Reopen the tab menu!")
	end
end, {
	category = "Appearance",
})