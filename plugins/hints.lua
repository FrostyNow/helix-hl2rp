local PLUGIN = PLUGIN

PLUGIN.name = "Hint System"
PLUGIN.description = "Adds hints which might help you every now and then."
PLUGIN.author = "Riggs Mackay"
PLUGIN.schema = "Any"
PLUGIN.license = [[
Copyright 2022 Riggs Mackay

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

ix.lang.AddTable("english", {
	optHints = "Toggle hints",
	optHintsSound = "Toggle hints Sound",
	optHintsDelay = "Hints delay",
	optdHints = "Wether or not hints should be shown.",
	optdHintsSound = "Wether or not hints should play a sound.",
	optdHintsDelay = "The delay between hints.",
	hintWater = "Don't drink the water; they put something in it, to make you forget.",
	hintConversation = "Bored? Try striking up a conversation with someone or creating a plot!",
	hintStaff = "The staff are here to help you. Show respect and cooperate with them and everyone will benefit from it.",
	hintUncivilized = "Running, jumping, and other uncivil actions can result in re-education by Civil Protection.",
	hintWhisper = "The Combine don't like it when you talk, so whisper.",
	hintFriends = "Life is bleak in the city without companions. Go make some friends.",
	hintIC = "Remember: This is a roleplay server. You are playing as a character- not as yourself.",
	hintSurveillance = "The city is under constant surveillance. Be careful.",
	hintCombine = "Don't mess with the Combine, they took over Earth in 7 hours.",
	hintTrouble = "Cause too much trouble and you may find yourself without a ration, or worse.",
	hintPlace = "Your designated inspection position is your room. Don't forget!",
	hintAsk = "If you're looking for a way to get to a certain location, it's not a bad idea to ask for help.",
	hintLoyalty = "Report crimes to Civil Protection to gain loyalty points on your record.",
	hintOOC = "Type .// before your message to talk out of character locally.",
	hintObey = "Obey the Combine, you'll be glad that you did.",
	hintCP = "Civil Protection is protecting civilized society, not you.",
	hintCook = "Why don't you try cooking something every now and then? All you need is a stove and the right ingredients.",
	hintPiss = "Don't piss off Civil Protection, or you'll find yourself being re-educated, or worse..",
})

ix.lang.AddTable("korean", {
	optHints = "도움말 켜기/끄기",
	optHintsSound = "도움말 효과음 켜기/끄기",
	optHintsDelay = "도움말 재출력 시간",
	optdHints = "도움말 표시 여부.",
	optdHintsSound = "도움말 효과음 재생 여부.",
	optdHintsDelay = "도움말 재출력 시간.",
	hintWater = "물을 마시지 마십시오. 저들이 물에 기억을 잃게 만드는 뭔가를 탔습니다.",
	hintConversation = "지루하십니까? 다른 사람과 대화하거나 일거리를 찾아 보십시오!",
	hintStaff = "도움이 필요하시면 관리자를 호출하십시오. 상호존중과 협력을 통해 모두가 혜택을 받을 수 있습니다.",
	hintUncivilized = "달리기, 뛰기와 같은 반사회적 행동 때문에 시민 보호 기동대에게 재교육을 받을 수 있습니다.",
	hintWhisper = "콤바인은 수다쟁이를 싫어합니다. 조곤조곤 속삭이십시오.",
	hintFriends = "친구가 없이는 사는 의미가 없습니다. 가서 사람들을 만나보십시오.",
	hintIC = "기억하십시오. 이곳은 롤플레이 서버입니다. 현실의 나 자신이 아닌 캐릭터로 연기하셔야 합니다.",
	hintSurveillance = "도시는 감시당하고 있습니다. 조심하십시오.",
	hintCombine = "콤바인의 눈밖에 나지 마십시오. 저들은 지구를 단 7시간 만에 정복했습니다.",
	hintTrouble = "문제를 일으키면 배급을 받지 못하거나 더 나쁜 상황에 처할 수 있습니다.",
	hintPlace = "지정된 검사 위치는 거주 구역입니다. 잊지 마십시오!",
	hintAsk = "어떤 곳으로 가는 길을 모른다면 다른 사람들에게 물어보는 것도 나쁘지 않습니다.",
	hintLoyalty = "시민 보호 기동대에게 범죄를 신고하면 개인 기록에 좋은 평가를 남길 수 있습니다.",
	hintOOC = "캐릭터가 아닌 플레이어로서 대화하려면 할 말 앞에 //를 입력하십시오.",
	hintObey = "좋지 않은 결말을 피하려면 콤바인에 복종하십시오.",
	hintCP = "시민 보호 기동대는 문명사회를 보호합니다. 당신이 아니라.",
	hintCook = "요리를 해보는 건 어떻습니까? 가스레인지와 적절한 재료만 있으면 됩니다.",
	hintPiss = "시민 보호 기동대의 눈밖에 나지 마십시오. 재교육을 받거나 더 나쁜 일에 처할 수 있습니다..",
})

ix.config.Add("hints", true, "Whether or not player hint is enabled.", nil, {
	category = "Hint System",
	default = true,
})

ix.config.Add("hintsDelay", 300, "The delay between hints in seconds.", nil, {
	category = "Hint System",
	data = {min = 30, max = 1800, decimals = 0},
	default = 300,
})

ix.option.Add("hints", ix.type.bool, true, {
	category = "Hint System",
	default = true,
})

ix.option.Add("hintsSound", ix.type.bool, true, {
	category = "Hint System",
	default = true,
})

ix.hints = ix.hints or {}
ix.hints.stored = ix.hints.stored or {}

function ix.hints.Register(message)
	table.insert(ix.hints.stored, message)
end

ix.hints.Register("hintWater")
ix.hints.Register("hintConversation")
ix.hints.Register("hintStaff")
ix.hints.Register("hintUncivilized")
ix.hints.Register("hintWhisper")
ix.hints.Register("hintFriends")
ix.hints.Register("hintIC")
ix.hints.Register("hintSurveillance")
ix.hints.Register("hintCombine")
ix.hints.Register("hintTrouble")
ix.hints.Register("hintPlace")
ix.hints.Register("hintAsk")
ix.hints.Register("hintLoyalty")
ix.hints.Register("hintOOC")
ix.hints.Register("hintObey")
ix.hints.Register("hintCP")
ix.hints.Register("hintCook")
ix.hints.Register("hintPiss")

if ( CLIENT ) then
	function PLUGIN:LoadFonts(font, genericFont)
		surface.CreateFont("HintFont", {
			font = font,
			size = 20,
			extended = true,
			weight = 500,
			blursize = 0.5,
			shadow = true,
		})
	end
	
	local nextHint = 0
	local hintEndRender = 0
	local bInHint = false
	local hint = nil
	local hintShow = false
	local hintAlpha = 0
	function PLUGIN:HUDPaint()
		if not ( ix.config.Get("hints", true) ) then return end
		if not ( ix.option.Get("hints", true) ) then return end

		if ( nextHint < CurTime() ) then
			hint = ix.hints.stored[math.random(#ix.hints.stored)]
			nextHint = CurTime() + math.max(30, tonumber(ix.config.Get("hintsDelay", 300)) or 300)
			hintShow = true
			hintEndRender = CurTime() + 15

			if ( ix.option.Get("hintsSound", true) ) then
				LocalPlayer():EmitSound("ui/hint.wav", 40, 100, 0.1)
			end
		end
		
		if not ( hint ) then return end
		
		if ( hintEndRender < CurTime() ) then
			hintShow = false
		end
		
		if ( hintShow == true ) then
			hintAlpha = Lerp(0.01, hintAlpha, 255)
		else
			hintAlpha = Lerp(0.01, hintAlpha, 0)
		end
		
		draw.DrawText(L(hint), "HintFont", ScrW() - 24, 24, ColorAlpha(color_white, hintAlpha), TEXT_ALIGN_RIGHT)
	end
end
