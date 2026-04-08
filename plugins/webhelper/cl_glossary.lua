local glossaryStyles = [[
<style>
	body {
		background-color: #0c0d10;
		color: #e0e0e0;
		font-family: 'NanumBarunGothic', 'NanumGothic', 'Malgun Gothic', 'Inter', 'Segoe UI', sans-serif;
		line-height: 1.6;
		padding: 40px 60px;
		margin: 0;
		-webkit-font-smoothing: antialiased;
		overflow-y: auto;
		box-sizing: border-box;
	}
	* { box-sizing: inherit; }

	::-webkit-scrollbar { width: 8px; }
	::-webkit-scrollbar-track { background: transparent; }
	::-webkit-scrollbar-thumb { background: rgba(255, 255, 255, 0.1); border-radius: 4px; }
	::-webkit-scrollbar-thumb:hover { background: rgba(255, 255, 255, 0.2); }

	.content {
		max-width: 1400px;
		margin: 0 auto;
		animation: fadeIn 0.8s cubic-bezier(0.22, 1, 0.36, 1);
	}
	@keyframes fadeIn {
		from { opacity: 0; transform: translateY(15px); }
		to { opacity: 1; transform: translateY(0); }
	}
	h1 {
		color: #fff;
		font-size: 32px;
		font-weight: 800;
		margin-top: 0;
		margin-bottom: 30px;
		letter-spacing: -0.5px;
		border-left: 4px solid #ff4d61;
		padding-left: 20px;
		text-transform: uppercase;
	}
	.divider {
		height: 1px;
		background: linear-gradient(90deg, rgba(255, 255, 255, 0.1), transparent);
		margin: 50px 0;
	}
	h2 {
		color: rgba(255, 255, 255, 0.9);
		font-size: 18px;
		font-weight: 600;
		margin-top: 40px;
		margin-bottom: 20px;
		text-transform: uppercase;
		letter-spacing: 1.5px;
		display: flex;
		align-items: center;
		gap: 15px;
	}
	h2::after {
		content: '';
		flex: 1;
		height: 1px;
		background: rgba(255, 255, 255, 0.05);
	}
	.term-list {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(min(100%, 400px), 1fr));
		gap: 15px;
	}
	.term-item {
		padding: 18px 24px;
		background: rgba(255, 255, 255, 0.02);
		border: 1px solid rgba(255, 255, 255, 0.05);
		border-radius: 10px;
		transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
		display: flex;
		align-items: flex-start;
		gap: 20px;
		position: relative;
		overflow: hidden;
	}
	.term-item:hover {
		background: rgba(255, 255, 255, 0.04);
		border-color: rgba(255, 255, 255, 0.15);
		transform: translateY(-2px);
		box-shadow: 0 10px 20px rgba(0, 0, 0, 0.2);
	}
	.term-name {
		color: #ff4d61;
		font-weight: 800;
		font-size: 16px;
		min-width: 100px;
		flex-shrink: 0;
		letter-spacing: 0.5px;
	}
	.term-content {
		color: #b0b0b0;
		font-size: 14px;
		line-height: 1.5;
		border-left: 1px solid rgba(255, 255, 255, 0.1);
		padding-left: 20px;
		flex: 1;
	}
	.term-content:empty {
		display: none;
	}

	.term-content:empty {
		display: none;
	}
</style>
]]

PLUGIN.glossaryTranslations = {
	english = [[
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
]] .. glossaryStyles .. [[
</head>
<body>
	<div class="content">
		<h1>Miscellaneous codes</h1>
		<div class="term-list">
			<div class="term-item"><span class="term-name">Extractor</span><div class="term-content">Grenade</div></div>
			<div class="term-item"><span class="term-name">Bouncer</span><div class="term-content">Grenade</div></div>
			<div class="term-item"><span class="term-name">Viscerator</span><div class="term-content">Manhack</div></div>
			<div class="term-item"><span class="term-name">Sterilizer</span><div class="term-content">Combine Sentry Gun</div></div>
			<div class="term-item"><span class="term-name">Restrictor</span><div class="term-content">Thumper</div></div>
			<div class="term-item"><span class="term-name">Containment field</span><div class="term-content">Force Field</div></div>
			<div class="term-item"><span class="term-name">Stimdose/Stimboost</span><div class="term-content">A stimulant substance that soldiers consume.</div></div>
			<div class="term-item"><span class="term-name">Bodypack</span><div class="term-content">A soldier's body or armor.</div></div>
			<div class="term-item"><span class="term-name">Viscon</span><div class="term-content">Visual Contact</div></div>
			<div class="term-item"><span class="term-name">Helix vector tango/HVT</span><div class="term-content">High-value target</div></div>
			<div class="term-item"><span class="term-name">Skyshield</span><div class="term-content">Air support</div></div>
			<div class="term-item"><span class="term-name">C&C</span><div class="term-content">Command and control</div></div>
			<div class="term-item"><span class="term-name">ETA</span><div class="term-content">Estimated time of arrival</div></div>
			<div class="term-item"><span class="term-name">Hardpoint</span><div class="term-content">Combine Bunker/Emplacement Gun</div></div>
			<div class="term-item"><span class="term-name">Ripcord</span><div class="term-content">Retreat</div></div>
		</div>

		<div class="divider"></div>

		<h1>Civil Protection</h1>
		
		<h2>Basic codes</h2>
		<div class="term-list">
			<div class="term-item">
				<span class="term-name">Code 2</span>
				<div class="term-content">Proceed immediately with lights/without sirens</div>
			</div>
			<div class="term-item">
				<span class="term-name">Code 3</span>
				<div class="term-content">Proceed immediately with lights and sirens</div>
			</div>
			<div class="term-item">
				<span class="term-name">Code 4</span>
				<div class="term-content">No further assistance required</div>
			</div>
			<div class="term-item">
				<span class="term-name">Code 7</span>
				<div class="term-content">Out of service to eat</div>
			</div>
			<div class="term-item">
				<span class="term-name">Code 12</span>
				<div class="term-content">Patrol your district and report extent of damage</div>
			</div>
			<div class="term-item">
				<span class="term-name">Code 30</span>
				<div class="term-content">Officer needs assistance — emergency</div>
			</div>
			<div class="term-item">
				<span class="term-name">Code 100</span>
				<div class="term-content">In position to intercept suspect</div>
			</div>
		</div>

		<h2>Abbreviations</h2>
		<div class="term-list">
			<div class="term-item">
				<span class="term-name">ADW</span>
				<div class="term-content">Assault with a deadly weapon</div>
			</div>
			<div class="term-item">
				<span class="term-name">APB</span>
				<div class="term-content">All points bulletin</div>
			</div>
			<div class="term-item">
				<span class="term-name">BOL</span>
				<div class="term-content">Be on the lookout</div>
			</div>
			<div class="term-item">
				<span class="term-name">CP</span>
				<div class="term-content">Command point</div>
			</div>
			<div class="term-item">
				<span class="term-name">CPT/PT</span>
				<div class="term-content">Civil Protection team/Protection team</div>
			</div>
			<div class="term-item">
				<span class="term-name">DB</span>
				<div class="term-content">Dead body</div>
			</div>
			<div class="term-item">
				<span class="term-name">Disp</span>
				<div class="term-content">Dispatch</div>
			</div>
			<div class="term-item">
				<span class="term-name">GOA</span>
				<div class="term-content">Gone on arrival</div>
			</div>
			<div class="term-item">
				<span class="term-name">Incap</span>
				<div class="term-content">Incapacitated</div>
			</div>
			<div class="term-item">
				<span class="term-name">OC</span>
				<div class="term-content">Off course</div>
			</div>
			<div class="term-item">
				<span class="term-name">Tac</span>
				<div class="term-content">Tactical</div>
			</div>
			<div class="term-item">
				<span class="term-name">UPI</span>
				<div class="term-content">Unidentified person of interest</div>
			</div>
			<div class="term-item">
				<span class="term-name">UTL</span>
				<div class="term-content">Unable to locate</div>
			</div>
		</div>

		<h2>10 codes</h2>
		<div class="term-list">
			<div class="term-item">
				<span class="term-name">0-0</span>
				<div class="term-content">Use caution</div>
			</div>
			<div class="term-item">
				<span class="term-name">10-2</span>
				<div class="term-content">You are being received clearly</div>
			</div>
			<div class="term-item">
				<span class="term-name">10-3</span>
				<div class="term-content">Stop transmitting</div>
			</div>
			<div class="term-item">
				<span class="term-name">10-4</span>
				<div class="term-content">OK</div>
			</div>
			<div class="term-item">
				<span class="term-name">10-8</span>
				<div class="term-content">In service</div>
			</div>
			<div class="term-item">
				<span class="term-name">10-14</span>
				<div class="term-content">Convoy or escort detail</div>
			</div>
			<div class="term-item">
				<span class="term-name">10-15</span>
				<div class="term-content">Prisoner in custody</div>
			</div>
			<div class="term-item">
				<span class="term-name">10-20</span>
				<div class="term-content">Your location</div>
			</div>
			<div class="term-item">
				<span class="term-name">10-22</span>
				<div class="term-content">Disregard/Cancel last message</div>
			</div>
			<div class="term-item">
				<span class="term-name">10-25</span>
				<div class="term-content">Do you have contact with [person]</div>
			</div>
			<div class="term-item">
				<span class="term-name">10-27</span>
				<div class="term-content">Check for wants or warrants</div>
			</div>
			<div class="term-item">
				<span class="term-name">10-30</span>
				<div class="term-content">Does not conform to rules or regulations</div>
			</div>
			<div class="term-item">
				<span class="term-name">10-33</span>
				<div class="term-content">Alarm (type: audible, silent)</div>
			</div>
			<div class="term-item">
				<span class="term-name">10-38</span>
				<div class="term-content">Your destination</div>
			</div>
			<div class="term-item">
				<span class="term-name">10-54d</span>
				<div class="term-content">Possible dead body</div>
			</div>
			<div class="term-item">
				<span class="term-name">10-55d</span>
				<div class="term-content">Send coroner</div>
			</div>
			<div class="term-item">
				<span class="term-name">10-65</span>
				<div class="term-content">Clear for assignment</div>
			</div>
			<div class="term-item">
				<span class="term-name">10-78</span>
				<div class="term-content">Send ambulance</div>
			</div>
			<div class="term-item">
				<span class="term-name">10-91d</span>
				<div class="term-content">Dead animal</div>
			</div>
			<div class="term-item">
				<span class="term-name">10-97</span>
				<div class="term-content">Arrived at scene</div>
			</div>
			<div class="term-item">
				<span class="term-name">10-99</span>
				<div class="term-content">Unable to receive your last message (or in trouble)</div>
			</div>
			<div class="term-item">
				<span class="term-name">10-103f</span>
				<div class="term-content">Disturbance by fight</div>
			</div>
			<div class="term-item">
				<span class="term-name">10-103m</span>
				<div class="term-content">Disturbance by mentally unfit (Mental person)</div>
			</div>
			<div class="term-item">
				<span class="term-name">10-107</span>
				<div class="term-content">Suspicious person</div>
			</div>
			<div class="term-item">
				<span class="term-name">10-108</span>
				<div class="term-content">Officer down or officer needs assistance</div>
			</div>
		</div>

		<h2>11 codes</h2>
		<div class="term-list">
			<div class="term-item">
				<span class="term-name">11-6</span>
				<div class="term-content">Illegal discharge of firearms</div>
			</div>
			<div class="term-item">
				<span class="term-name">11-7</span>
				<div class="term-content">Prowler</div>
			</div>
			<div class="term-item">
				<span class="term-name">11-8</span>
				<div class="term-content">Person down</div>
			</div>
			<div class="term-item">
				<span class="term-name">11-12</span>
				<div class="term-content">Dead animal</div>
			</div>
			<div class="term-item">
				<span class="term-name">11-29</span>
				<div class="term-content">Subject has no record</div>
			</div>
			<div class="term-item">
				<span class="term-name">11-41</span>
				<div class="term-content">Request ambulance</div>
			</div>
			<div class="term-item">
				<span class="term-name">11-42</span>
				<div class="term-content">Ambulance not required</div>
			</div>
			<div class="term-item">
				<span class="term-name">11-43</span>
				<div class="term-content">Doctor required</div>
			</div>
			<div class="term-item">
				<span class="term-name">11-44</span>
				<div class="term-content">Coroner required</div>
			</div>
			<div class="term-item">
				<span class="term-name">11-47</span>
				<div class="term-content">Injured person</div>
			</div>
			<div class="term-item">
				<span class="term-name">11-99</span>
				<div class="term-content">Officer needs help/emergency</div>
			</div>
		</div>

		<h2>Penal codes</h2>
		<div class="term-list">
			<div class="term-item">
				<span class="term-name">17f</span>
				<div class="term-content">Fugitive detachment</div>
			</div>
			<div class="term-item">
				<span class="term-name">24</span>
				<div class="term-content">Medical emergency</div>
			</div>
			<div class="term-item">
				<span class="term-name">27</span>
				<div class="term-content">Attempted crime</div>
			</div>
			<div class="term-item">
				<span class="term-name">34s</span>
				<div class="term-content">Shooting</div>
			</div>
			<div class="term-item">
				<span class="term-name">51</span>
				<div class="term-content">Non-sanctioned arson</div>
			</div>
			<div class="term-item">
				<span class="term-name">51b</span>
				<div class="term-content">Threat to property (Bomb threat)</div>
			</div>
			<div class="term-item">
				<span class="term-name">52</span>
				<div class="term-content">Simple arson</div>
			</div>
			<div class="term-item">
				<span class="term-name">56</span>
				<div class="term-content">Criminal damage</div>
			</div>
			<div class="term-item">
				<span class="term-name">62</span>
				<div class="term-content">Alarms</div>
			</div>
			<div class="term-item">
				<span class="term-name">63</span>
				<div class="term-content">Criminal trespass</div>
			</div>
			<div class="term-item">
				<span class="term-name">63s</span>
				<div class="term-content">Illegal in operation (Sit-in)</div>
			</div>
			<div class="term-item">
				<span class="term-name">69</span>
				<div class="term-content">Possession of resources (Possession of stolen goods)</div>
			</div>
			<div class="term-item">
				<span class="term-name">94</span>
				<div class="term-content">Weapon (Illegal use of weapon)</div>
			</div>
			<div class="term-item">
				<span class="term-name">95</span>
				<div class="term-content">Illegal carrying (Illegal carrying of gun)</div>
			</div>
			<div class="term-item">
				<span class="term-name">99</span>
				<div class="term-content">Reckless operation</div>
			</div>
			<div class="term-item">
				<span class="term-name">148</span>
				<div class="term-content">Resisting arrest</div>
			</div>
			<div class="term-item">
				<span class="term-name">187</span>
				<div class="term-content">Homicide</div>
			</div>
			<div class="term-item">
				<span class="term-name">211</span>
				<div class="term-content">Armed robbery</div>
			</div>
			<div class="term-item">
				<span class="term-name">243</span>
				<div class="term-content">Assault on Protection Team</div>
			</div>
			<div class="term-item">
				<span class="term-name">245</span>
				<div class="term-content">Assault with a deadly weapon</div>
			</div>
			<div class="term-item">
				<span class="term-name">404</span>
				<div class="term-content">Riot</div>
			</div>
			<div class="term-item">
				<span class="term-name">407</span>
				<div class="term-content">Unlawful assembly</div>
			</div>
			<div class="term-item">
				<span class="term-name">415</span>
				<div class="term-content">Civic disunity (Disturbing the peace)</div>
			</div>
			<div class="term-item">
				<span class="term-name">415b</span>
				<div class="term-content">Investigate the trouble</div>
			</div>
			<div class="term-item">
				<span class="term-name">447</span>
				<div class="term-content">Arson</div>
			</div>
			<div class="term-item">
				<span class="term-name">459</span>
				<div class="term-content">Burglary</div>
			</div>
			<div class="term-item">
				<span class="term-name">505</span>
				<div class="term-content">Reckless driving</div>
			</div>
			<div class="term-item">
				<span class="term-name">507</span>
				<div class="term-content">Public non-compliance</div>
			</div>
			<div class="term-item">
				<span class="term-name">603</span>
				<div class="term-content">Unlawful entry</div>
			</div>
			<div class="term-item">
				<span class="term-name">647e</span>
				<div class="term-content">Disengaged from workforce (Loitering place to place)</div>
			</div>
		</div>

		<h2>Action codes</h2>
		<div class="term-list">
			<div class="term-item"><span class="term-name">Pressure</span></div>
			<div class="term-item"><span class="term-name">Document</span></div>
			<div class="term-item"><span class="term-name">Restrict</span></div>
			<div class="term-item"><span class="term-name">Intercede</span></div>
			<div class="term-item"><span class="term-name">Preserve</span></div>
			<div class="term-item"><span class="term-name">Search</span></div>
			<div class="term-item"><span class="term-name">Suspend</span></div>
			<div class="term-item"><span class="term-name">Investigate</span></div>
			<div class="term-item"><span class="term-name">Interlock</span></div>
			<div class="term-item"><span class="term-name">Isolate</span></div>
			<div class="term-item"><span class="term-name">Administer</span></div>
			<div class="term-item"><span class="term-name">Cauterize</span></div>
			<div class="term-item"><span class="term-name">Inject</span></div>
			<div class="term-item"><span class="term-name">Inoculate</span></div>
			<div class="term-item"><span class="term-name">Examine</span></div>
			<div class="term-item"><span class="term-name">Apply</span></div>
			<div class="term-item"><span class="term-name">Prosecute</span></div>
			<div class="term-item"><span class="term-name">Serve</span></div>
			<div class="term-item"><span class="term-name">Sterilize</span></div>
			<div class="term-item"><span class="term-name">Amputate</span></div>
			<div class="term-item"><span class="term-name">Lock</span></div>
		</div>

		<h2>Suspect names</h2>
		<div class="term-list">
			<div class="term-item"><span class="term-name">Subject</span></div>
			<div class="term-item"><span class="term-name">Citizen</span></div>
			<div class="term-item"><span class="term-name">UPI</span><div class="term-content">Unidentified person of interest</div></div>
			<div class="term-item"><span class="term-name">Noncitizen</span></div>
			<div class="term-item"><span class="term-name">Sociocide</span></div>
			<div class="term-item"><span class="term-name">Anticitizen</span></div>
			<div class="term-item"><span class="term-name">Freeman</span></div>
			<div class="term-item"><span class="term-name">Infection</span></div>
		</div>

		<h2>Charges</h2>
		<div class="term-list">
			<div class="term-item"><span class="term-name">Capital malcompliance</span></div>
			<div class="term-item"><span class="term-name">Violation of civic trust</span></div>
			<div class="term-item"><span class="term-name">Promoting communal unrest</span></div>
			<div class="term-item"><span class="term-name">Failure to comply with the civil will</span></div>
			<div class="term-item"><span class="term-name">Level 5 anti-civil activity</span></div>
			<div class="term-item"><span class="term-name">Destruction of Units</span><div class="term-content">Destruction of Corporal Social Protection Units</div></div>
			<div class="term-item"><span class="term-name">Counter-obeyance</span><div class="term-content">Divisive sociocidal counter-obeyance</div></div>
			<div class="term-item"><span class="term-name">Inciting popucide</span></div>
		</div>

		<h2>Judgments</h2>
		<div class="term-list">
			<div class="term-item"><span class="term-name">Immediate amputation</span></div>
			<div class="term-item"><span class="term-name">Terminal prosecution</span></div>
			<div class="term-item"><span class="term-name">Disassociation</span><div class="term-content">Disassociation from the civic populace</div></div>
		</div>
	</div>
</body>
</html>
]],
	korean = [[
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
]] .. glossaryStyles .. [[
</head>
<body>
	<div class="content">
		<h1>공통 용어</h1>
		<div class="term-list">
			<div class="term-item"><span class="term-name">익스트랙터</span><div class="term-content">수류탄</div></div>
			<div class="term-item"><span class="term-name">바운서</span><div class="term-content">수류탄</div></div>
			<div class="term-item"><span class="term-name">비저레이터</span><div class="term-content">맨핵</div></div>
			<div class="term-item"><span class="term-name">스테릴라이저</span><div class="term-content">콤바인 센트리 건</div></div>
			<div class="term-item"><span class="term-name">레스트릭터</span><div class="term-content">썸퍼</div></div>
			<div class="term-item"><span class="term-name">억제장</span><div class="term-content">역장</div></div>
			<div class="term-item"><span class="term-name">자극제</span><div class="term-content">병력이 처방받는 자극 물질.</div></div>
			<div class="term-item"><span class="term-name">바디팩</span><div class="term-content">병력의 방탄복 또는 신체</div></div>
			<div class="term-item"><span class="term-name">포착</span><div class="term-content">시야에 들어옴</div></div>
			<div class="term-item"><span class="term-name">헬릭스 벡터 탱고/HVT</span><div class="term-content">고가치 목표</div></div>
			<div class="term-item"><span class="term-name">스카이쉴드</span><div class="term-content">공중 지원</div></div>
			<div class="term-item"><span class="term-name">C&C</span><div class="term-content">지시 및 통제</div></div>
			<div class="term-item"><span class="term-name">ETA</span><div class="term-content">도착 예정 시간</div></div>
			<div class="term-item"><span class="term-name">접전지</span><div class="term-content">콤바인 벙커/거치 기관총</div></div>
			<div class="term-item"><span class="term-name">립코드</span><div class="term-content">후퇴</div></div>
		</div>

		<div class="divider"></div>

		<h1>시민 보호 기동대 용어집</h1>
		
		<h2>기본 코드</h2>
		<div class="term-list">
			<div class="term-item">
				<span class="term-name">코드 2</span>
				<div class="term-content">경광등을 켜고 사이렌 없이 즉시 진행</div>
			</div>
			<div class="term-item">
				<span class="term-name">코드 3</span>
				<div class="term-content">경광등과 사이렌을 모두 켜고 즉시 진행</div>
			</div>
			<div class="term-item">
				<span class="term-name">코드 4</span>
				<div class="term-content">추가 지원 필요 없음</div>
			</div>
			<div class="term-item">
				<span class="term-name">코드 7</span>
				<div class="term-content">식사를 위한 비번</div>
			</div>
			<div class="term-item">
				<span class="term-name">코드 12</span>
				<div class="term-content">담당 구역 순찰 및 피해 규모 보고</div>
			</div>
			<div class="term-item">
				<span class="term-name">코드 30</span>
				<div class="term-content">대원 지원 필요 — 비상 상황</div>
			</div>
			<div class="term-item">
				<span class="term-name">코드 100</span>
				<div class="term-content">용의자 차단 위치 확보</div>
			</div>
		</div>

		<h2>약어</h2>
		<div class="term-list">
			<div class="term-item">
				<span class="term-name">ADW</span>
				<div class="term-content">치명적인 무기를 이용한 공격</div>
			</div>
			<div class="term-item">
				<span class="term-name">APB</span>
				<div class="term-content">전 지점 수배령</div>
			</div>
			<div class="term-item">
				<span class="term-name">BOL</span>
				<div class="term-content">감시 및 수색 요망</div>
			</div>
			<div class="term-item">
				<span class="term-name">CP</span>
				<div class="term-content">지휘 지점</div>
			</div>
			<div class="term-item">
				<span class="term-name">CPT/PT</span>
				<div class="term-content">시민 보호 기동대</div>
			</div>
			<div class="term-item">
				<span class="term-name">DB</span>
				<div class="term-content">시체</div>
			</div>
			<div class="term-item">
				<span class="term-name">DISP</span>
				<div class="term-content">디스패치</div>
			</div>
			<div class="term-item">
				<span class="term-name">GOA</span>
				<div class="term-content">현장 도착했으나 보이지 않음</div>
			</div>
			<div class="term-item">
				<span class="term-name">Incap</span>
				<div class="term-content">무력화됨</div>
			</div>
			<div class="term-item">
				<span class="term-name">OC</span>
				<div class="term-content">경로 이탈</div>
			</div>
			<div class="term-item">
				<span class="term-name">Tac</span>
				<div class="term-content">전술/택티컬</div>
			</div>
			<div class="term-item">
				<span class="term-name">UPI</span>
				<div class="term-content">미식별 요주의 인물 (용의자)</div>
			</div>
			<div class="term-item">
				<span class="term-name">UTL</span>
				<div class="term-content">위치 파악 불가</div>
			</div>
		</div>

		<h2>10 코드</h2>
		<div class="term-list">
			<div class="term-item">
				<span class="term-name">0-0</span>
				<div class="term-content">주의 요망</div>
			</div>
			<div class="term-item">
				<span class="term-name">10-2</span>
				<div class="term-content">수신 상태 양호</div>
			</div>
			<div class="term-item">
				<span class="term-name">10-3</span>
				<div class="term-content">송신 중단</div>
			</div>
			<div class="term-item">
				<span class="term-name">10-4</span>
				<div class="term-content">알겠음 (OK)</div>
			</div>
			<div class="term-item">
				<span class="term-name">10-8</span>
				<div class="term-content">근무 중</div>
			</div>
			<div class="term-item">
				<span class="term-name">10-14</span>
				<div class="term-content">호송 또는 호위 세부 사항</div>
			</div>
			<div class="term-item">
				<span class="term-name">10-15</span>
				<div class="term-content">구금된 죄수</div>
			</div>
			<div class="term-item">
				<span class="term-name">10-20</span>
				<div class="term-content">현재 위치</div>
			</div>
			<div class="term-item">
				<span class="term-name">10-22</span>
				<div class="term-content">마지막 메시지 무시/취소</div>
			</div>
			<div class="term-item">
				<span class="term-name">10-25</span>
				<div class="term-content">대상과의 접촉 여부</div>
			</div>
			<div class="term-item">
				<span class="term-name">10-27</span>
				<div class="term-content">수배 여부 확인</div>
			</div>
			<div class="term-item">
				<span class="term-name">10-30</span>
				<div class="term-content">규칙 또는 규정에 불일치</div>
			</div>
			<div class="term-item">
				<span class="term-name">10-33</span>
				<div class="term-content">경보 (유형: 가청, 무음)</div>
			</div>
			<div class="term-item">
				<span class="term-name">10-38</span>
				<div class="term-content">목적지</div>
			</div>
			<div class="term-item">
				<span class="term-name">10-54d</span>
				<div class="term-content">시체 가능성</div>
			</div>
			<div class="term-item">
				<span class="term-name">10-55d</span>
				<div class="term-content">검안사 파견 요망</div>
			</div>
			<div class="term-item">
				<span class="term-name">10-65</span>
				<div class="term-content">임무 할당 대기</div>
			</div>
			<div class="term-item">
				<span class="term-name">10-78</span>
				<div class="term-content">의료 지원 파견 요망</div>
			</div>
			<div class="term-item">
				<span class="term-name">10-91d</span>
				<div class="term-content">동물 사체</div>
			</div>
			<div class="term-item">
				<span class="term-name">10-97</span>
				<div class="term-content">현장 도착</div>
			</div>
			<div class="term-item">
				<span class="term-name">10-99</span>
				<div class="term-content">마지막 메시지 수신 불가 (또는 곤경에 처함)</div>
			</div>
			<div class="term-item">
				<span class="term-name">10-103f</span>
				<div class="term-content">싸움으로 인한 소란</div>
			</div>
			<div class="term-item">
				<span class="term-name">10-103m</span>
				<div class="term-content">정신적 부적격자에 의한 소란</div>
			</div>
			<div class="term-item">
				<span class="term-name">10-107</span>
				<div class="term-content">의심스러운 인물</div>
			</div>
			<div class="term-item">
				<span class="term-name">10-108</span>
				<div class="term-content">대원 쓰러짐 또는 지원 필요</div>
			</div>
		</div>

		<h2>11 코드</h2>
		<div class="term-list">
			<div class="term-item">
				<span class="term-name">11-6</span>
				<div class="term-content">불법 총기 발포</div>
			</div>
			<div class="term-item">
				<span class="term-name">11-7</span>
				<div class="term-content">배회자</div>
			</div>
			<div class="term-item">
				<span class="term-name">11-8</span>
				<div class="term-content">쓰러진 사람</div>
			</div>
			<div class="term-item">
				<span class="term-name">11-12</span>
				<div class="term-content">동물 사체</div>
			</div>
			<div class="term-item">
				<span class="term-name">11-29</span>
				<div class="term-content">전과 없음</div>
			</div>
			<div class="term-item">
				<span class="term-name">11-41</span>
				<div class="term-content">의료 지원 요청</div>
			</div>
			<div class="term-item">
				<span class="term-name">11-42</span>
				<div class="term-content">의료 지원 필요 없음</div>
			</div>
			<div class="term-item">
				<span class="term-name">11-43</span>
				<div class="term-content">의사 필요함</div>
			</div>
			<div class="term-item">
				<span class="term-name">11-44</span>
				<div class="term-content">검안사 필요함</div>
			</div>
			<div class="term-item">
				<span class="term-name">11-47</span>
				<div class="term-content">부상자</div>
			</div>
			<div class="term-item">
				<span class="term-name">11-99</span>
				<div class="term-content">대원 도움 필요/비상 상황</div>
			</div>
		</div>

		<h2>형사 코드</h2>
		<div class="term-list">
			<div class="term-item">
				<span class="term-name">17f</span>
				<div class="term-content">도주자 분리</div>
			</div>
			<div class="term-item">
				<span class="term-name">24</span>
				<div class="term-content">의료 비상 사태</div>
			</div>
			<div class="term-item">
				<span class="term-name">27</span>
				<div class="term-content">범죄 시도</div>
			</div>
			<div class="term-item">
				<span class="term-name">34s</span>
				<div class="term-content">총격</div>
			</div>
			<div class="term-item">
				<span class="term-name">51</span>
				<div class="term-content">허가되지 않은 방화</div>
			</div>
			<div class="term-item">
				<span class="term-name">51b</span>
				<div class="term-content">재산 위협 (폭발물 위협)</div>
			</div>
			<div class="term-item">
				<span class="term-name">52</span>
				<div class="term-content">단순 방화</div>
			</div>
			<div class="term-item">
				<span class="term-name">56</span>
				<div class="term-content">파손 범죄</div>
			</div>
			<div class="term-item">
				<span class="term-name">62</span>
				<div class="term-content">경보</div>
			</div>
			<div class="term-item">
				<span class="term-name">63</span>
				<div class="term-content">무단 침입 범죄</div>
			</div>
			<div class="term-item">
				<span class="term-name">63s</span>
				<div class="term-content">집단 점거 및 농성</div>
			</div>
			<div class="term-item">
				<span class="term-name">69</span>
				<div class="term-content">자원 소지 (장물 소지)</div>
			</div>
			<div class="term-item">
				<span class="term-name">94</span>
				<div class="term-content">무기 (불법 무기 사용)</div>
			</div>
			<div class="term-item">
				<span class="term-name">95</span>
				<div class="term-content">불법 휴대 (불법 총기 소지)</div>
			</div>
			<div class="term-item">
				<span class="term-name">99</span>
				<div class="term-content">부주의한 운행</div>
			</div>
			<div class="term-item">
				<span class="term-name">148</span>
				<div class="term-content">체포 거부</div>
			</div>
			<div class="term-item">
				<span class="term-name">187</span>
				<div class="term-content">살인</div>
			</div>
			<div class="term-item">
				<span class="term-name">211</span>
				<div class="term-content">무장 강도</div>
			</div>
			<div class="term-item">
				<span class="term-name">243</span>
				<div class="term-content">보호 기동대에 대한 공격</div>
			</div>
			<div class="term-item">
				<span class="term-name">245</span>
				<div class="term-content">치명적인 무기를 이용한 공격</div>
			</div>
			<div class="term-item">
				<span class="term-name">404</span>
				<div class="term-content">폭동</div>
			</div>
			<div class="term-item">
				<span class="term-name">407</span>
				<div class="term-content">불법 집회</div>
			</div>
			<div class="term-item">
				<span class="term-name">415</span>
				<div class="term-content">시민 불화 (평화 방해)</div>
			</div>
			<div class="term-item">
				<span class="term-name">415b</span>
				<div class="term-content">문제 조사</div>
			</div>
			<div class="term-item">
				<span class="term-name">447</span>
				<div class="term-content">방화</div>
			</div>
			<div class="term-item">
				<span class="term-name">459</span>
				<div class="term-content">절도</div>
			</div>
			<div class="term-item">
				<span class="term-name">505</span>
				<div class="term-content">난폭 운전</div>
			</div>
			<div class="term-item">
				<span class="term-name">507</span>
				<div class="term-content">공공 불복종</div>
			</div>
			<div class="term-item">
				<span class="term-name">603</span>
				<div class="term-content">불법 진입</div>
			</div>
			<div class="term-item">
				<span class="term-name">647e</span>
				<div class="term-content">노동력 이탈 (배회)</div>
			</div>
		</div>

		<h2>행동 코드</h2>
		<div class="term-list">
			<div class="term-item"><span class="term-name">압력</span></div>
			<div class="term-item"><span class="term-name">증거</span></div>
			<div class="term-item"><span class="term-name">제한</span></div>
			<div class="term-item"><span class="term-name">차단</span></div>
			<div class="term-item"><span class="term-name">보존</span></div>
			<div class="term-item"><span class="term-name">수색</span></div>
			<div class="term-item"><span class="term-name">중지</span></div>
			<div class="term-item"><span class="term-name">조사</span></div>
			<div class="term-item"><span class="term-name">결합</span></div>
			<div class="term-item"><span class="term-name">격리</span></div>
			<div class="term-item"><span class="term-name">지급</span></div>
			<div class="term-item"><span class="term-name">제거</span></div>
			<div class="term-item"><span class="term-name">주입</span></div>
			<div class="term-item"><span class="term-name">접목</span></div>
			<div class="term-item"><span class="term-name">검사</span></div>
			<div class="term-item"><span class="term-name">적용</span></div>
			<div class="term-item"><span class="term-name">집행</span></div>
			<div class="term-item"><span class="term-name">복무</span></div>
			<div class="term-item"><span class="term-name">살균</span></div>
			<div class="term-item"><span class="term-name">절단</span></div>
			<div class="term-item"><span class="term-name">감금</span></div>
		</div>

		<h2>용의자 명칭</h2>
		<div class="term-list">
			<div class="term-item"><span class="term-name">대상</span></div>
			<div class="term-item"><span class="term-name">시민</span></div>
			<div class="term-item"><span class="term-name">용의자</span></div>
			<div class="term-item"><span class="term-name">비시민</span></div>
			<div class="term-item"><span class="term-name">반사회</span></div>
			<div class="term-item"><span class="term-name">반시민</span></div>
			<div class="term-item"><span class="term-name">프리맨</span></div>
			<div class="term-item"><span class="term-name">감염</span></div>
		</div>

		<h2>혐의</h2>
		<div class="term-list">
			<div class="term-item"><span class="term-name">중대 불순종</span></div>
			<div class="term-item"><span class="term-name">시민 신뢰 침해</span></div>
			<div class="term-item"><span class="term-name">공동체 불안 조성</span></div>
			<div class="term-item"><span class="term-name">시민의 의지 순응 실패</span></div>
			<div class="term-item"><span class="term-name">레벨 5 반동 세력 활동</span></div>
			<div class="term-item"><span class="term-name">신체적 파괴</span></div>
			<div class="term-item"><span class="term-name">반사회 불복종</span></div>
			<div class="term-item"><span class="term-name">대량학살 선동</span></div>
		</div>

		<h2>판결</h2>
		<div class="term-list">
			<div class="term-item"><span class="term-name">즉시 절단</span></div>
			<div class="term-item"><span class="term-name">사형 집행</span></div>
			<div class="term-item"><span class="term-name">시민 분열</span></div>
		</div>
	</div>
</body>
</html>
]]
}
