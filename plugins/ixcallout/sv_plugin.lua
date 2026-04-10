local PLUGIN = PLUGIN

local GRENADE_CLASS = "npc_grenade_frag"
local GRENADE_SCAN_INTERVAL = 0.2
local GRENADE_REACTION_RADIUS = 220
local GRENADE_REST_SPEED = 80
local GRENADE_WORLD_CONTACT_DISTANCE = 20
local DEATH_REACTION_RADIUS = 700
local SQUAD_RADIUS = 900
local PLAYER_COOLDOWN = 2.5
local DEATH_EVENT_COOLDOWN = 0.4
local IC_RANGE = 280

local PHYSICS_COLLIDE_MIN_SPEED = 140 -- Minimum impact speed to trigger a reaction

local COMBAT_SCAN_INTERVAL = 1.0
local COMBAT_REACTION_COOLDOWN = 15
local COMBAT_SIGHT_RADIUS = 1000

local DANGER_CLASSES = {
	"combine_mine",
	"rpg_missile",
	"prop_combine_ball",
	"npc_satchel",
	"npc_tripmine",
	"grenade_ar2",
	"prop_explosive_barrel",
	"gmod_dynamite",
	"npc_manhack",
	"prop_vehicle_jeep",
	"prop_vehicle_airboat"
}

local EXCLUDED_WEAPONS = {
	["ix_hands"] = true,
	["ix_keys"] = true,
	["weapon_physgun"] = true,
	["gmod_physgun"] = true,
	["gmod_tool"] = true,
	["ix_suitcase"] = true,
	["swep_vortigaunt_sweep"] = true
}

local COMBINE_TEMPLATE_SETS = {
	-- [callsign] [text] [target/radial/zone] [suffix]
	throwGrenade = {
		{
			-- THROW0: on1 V_MYNAMES V_MYNUMS extractoraway off1
			sounds = {"npc/combine_soldier/vo/extractoraway.wav"},
			text = "수류탄 준비.",
			useDesignation = true,
			useNumber = true,
			-- "리더 1. 수류탄 준비."
		},
		{
			-- THROW1: on1 V_MYNAMES V_MYNUMS extractorislive off1
			sounds = {"npc/combine_soldier/vo/extractorislive.wav"},
			text = "수류탄 투척!",
			useDesignation = true,
			useNumber = true,
			-- "리더 1. 수류탄 투척!"
		},
		{
			-- THROW2: on1 V_MYNAMES V_MYNUMS flush sharpzone off1
			sounds = {
				"npc/combine_soldier/vo/flush.wav",
				"npc/combine_soldier/vo/sharpzone.wav"
			},
			text = "플러시, 이동 구역.",
			useDesignation = true,
			useNumber = true,
			-- "리더 1. 플러시, 이동 구역."
		},
		{
			-- THROW3: on1 V_MYNAMES V_MYNUMS extractoraway sharpzone off1
			sounds = {
				"npc/combine_soldier/vo/extractoraway.wav",
				"npc/combine_soldier/vo/sharpzone.wav"
			},
			text = "수류탄 준비, 이동 구역.",
			useDesignation = true,
			useNumber = true,
			-- "리더 1. 수류탄 준비, 이동 구역."
		},
		{
			-- THROW4: on1. six, five, four, three, two, one, flash flash(p105) flash(p110) off1
			sounds = {
				"npc/combine_soldier/vo/six.wav",
				"npc/combine_soldier/vo/five.wav",
				"npc/combine_soldier/vo/four.wav",
				"npc/combine_soldier/vo/three.wav",
				"npc/combine_soldier/vo/two.wav",
				"npc/combine_soldier/vo/one.wav",
				"npc/combine_soldier/vo/flash.wav",
				"npc/combine_soldier/vo/flash.wav",
				"npc/combine_soldier/vo/flash.wav"
			},
			text = "6, 5, 4, 3, 2, 1. 플래시, 플래시, 플래시!",
		}
	},
	grenade_danger = {
		{
			sounds = {"npc/combine_soldier/vo/bouncerbouncer.wav"},
			text = "수류탄, 피해라!",
		},
		{
			sounds = {"npc/combine_soldier/vo/flaredown.wav"},
			text = "수류탄!",
		},
		{
			sounds = {"npc/metropolice/vo/shit.wav"},
			text = "젠장!",
		}
	},
	danger = {
		{
			sounds = {
				"npc/combine_soldier/vo/displace.wav"
			},
			text = "흩어져라!"
		},
		{
			sounds = {
				"npc/combine_soldier/vo/displace2.wav"
			},
			text = "분산하라!"
		},
		{
			sounds = {
				"npc/combine_soldier/vo/ripcordripcord.wav"
			},
			text = "분산! 분산해라!"
		}
	},
	lastSquad = {
		{
			-- SQUAD0: on2 overwatchrequestreserveactivation off1
			sounds = {"npc/combine_soldier/vo/overwatchrequestreserveactivation.wav"},
			text = "지원군 출동 요청한다!"
		},
		{
			-- SQUAD1: on1 overwatch, sectorisnotsecure off3
			sounds = {
				"npc/combine_soldier/vo/overwatch.wav",
				"npc/combine_soldier/vo/sectorisnotsecure.wav"
			},
			text = "보고한다, 구역 미확보."
		},
		{
			-- SQUAD2: on1 sector V_SECTORS, outbreak x3 off1
			sounds = {
				"npc/combine_soldier/vo/sector.wav",
				"npc/combine_soldier/vo/outbreak.wav",
				"npc/combine_soldier/vo/outbreak.wav",
				"npc/combine_soldier/vo/outbreak.wav"
			},
			layout = {"sectorLabel", "sectorNumber", "suffix"},
			usesSector = true,
			suffix = ", 확산. 확산. 확산.",
			-- "구역 5, 확산. 확산. 확산."
		},
		{
			-- SQUAD3: on1 V_MYNAMES V_MYNUMS isfinalteamunitbackup off1
			sounds = {"npc/combine_soldier/vo/isfinalteamunitbackup.wav"},
			text = "최종 팀이다. 증원 바란다.",
			useDesignation = true,
			useNumber = true,
		},
		{
			-- SQUAD4: on1 overwatchteamisdown off1
			sounds = {"npc/combine_soldier/vo/overwatchteamisdown.wav"},
			text = "팀은 전멸됐다. 구역이 통제권 밖이다.",
		},
		{
			-- SQUAD5: on2 overwatchsectoroverrun off2
			sounds = {"npc/combine_soldier/vo/overwatchsectoroverrun.wav"},
			text = "구역이 넘어갔다! 반복한다, 구역이 넘어갔다!",
		},
		{
			-- SQUAD6: on1 overwatchrequestskyshield off1
			sounds = {"npc/combine_soldier/vo/overwatchrequestskyshield.wav"},
			text = "스카이쉴드 요청한다.",
		},
		{
			-- SQUAD7: on1 overwatchrequestwinder off1
			sounds = {"npc/combine_soldier/vo/overwatchrequestwinder.wav"},
			text = "와인더 출동 요청한다.",
		}
	},
	combatCallout = {
		{
			-- ANNOUNCE0: on1 V_MYNAMES V_MYNUMS suppressing off1
			sounds = {"npc/combine_soldier/vo/suppressing.wav"},
			text = "진압.",
			useDesignation = true,
			useNumber = true,
			-- "리더 1. 진압."
		},
		{
			-- ANNOUNCE1: on1 V_MYNAMES V_MYNUMS gosharp off2
			sounds = {"npc/combine_soldier/vo/gosharp.wav"},
			text = "이동하라!",
			useDesignation = true,
			useNumber = true,
			-- "리더 1. 이동하라!"
		},
		{
			-- ANNOUNCE2: on2 V_MYNAMES V_MYNUMS prosecuting off1
			sounds = {"npc/combine_soldier/vo/prosecuting.wav"},
			text = "수행 중.",
			useDesignation = true,
			useNumber = true,
			-- "리더 1. 수행 중."
		},
		{
			-- ANNOUNCE3: on2 V_MYNAMES V_MYNUMS engaging off1
			sounds = {"npc/combine_soldier/vo/engaging.wav"},
			text = "수행 중!",
			useDesignation = true,
			useNumber = true,
			-- "리더 1. 수행 중!"
		},
		{
			-- ANNOUNCE4: on2 cover off1
			sounds = {"npc/combine_soldier/vo/cover.wav"},
			text = "엄폐하라!",
		}
	},
	assault = {
		{
			-- ASSAULT0: on1 contact V_G0_PLAYERS off1
			sounds = {"npc/combine_soldier/vo/contact.wav"},
			layout = {"text", "target", "suffix"},
			usesTarget = true,
			text = "포착,",
			-- "포착, 반시민 1."
		},
		{
			-- ASSAULT1: on1 contactconfirmprosecuting off1
			sounds = {"npc/combine_soldier/vo/contactconfirmprosecuting.wav"},
			layout = {"text"},
			text = "포착 확인, 임무 수행 중.",
		},
		{
			-- ASSAULT2: on2 contactconfim off1
			sounds = {"npc/combine_soldier/vo/contactconfim.wav"},
			layout = {"text"},
			text = "포착 확인.",
		},
		{
			-- ASSAULT3: on2 targetmyradial V_DIRS degrees off3
			sounds = {"npc/combine_soldier/vo/targetmyradial.wav"},
			layout = {"text", "bearing"},
			usesBearing = true,
			bearingSuffix = "도.",
			text = "목표 대상 포착,",
			-- "목표 대상 포착, 180도."
		},
	},
	flank = {
		{
			-- FLANK0: on1 V_MYNAMES V_MYNUMS closing off1
			sounds = {"npc/combine_soldier/vo/closing.wav"},
			text = "접근 중.",
			useDesignation = true,
			useNumber = true,
			-- "리더 1. 접근 중."
		},
		{
			-- FLANK1: on2 V_MYNAMES V_MYNUMS inbound off1
			sounds = {"npc/combine_soldier/vo/inbound.wav"},
			text = "진입 중.",
			useDesignation = true,
			useNumber = true,
			-- "리더 1. 진입 중."
		},
		{
			-- FLANK2: on1 movein off2
			sounds = {"npc/combine_soldier/vo/movein.wav"},
			text = "진입하라!",
			-- "진입하라!"
		},
		{
			-- FLANK3: on2 V_MYNAMES V_MYNUMS sweepingin off1
			sounds = {"npc/combine_soldier/vo/sweepingin.wav"},
			text = "정찰 중.",
			useDesignation = true,
			useNumber = true,
			-- "리더 1. 정찰 중."
		},
		{
			-- FLANK4: on1 coverme off1
			sounds = {"npc/combine_soldier/vo/coverme.wav"},
			text = "엄호하라!",
		},
		{
			-- FLANK5: on1 V_MYNAMES unitisclosing off1
			sounds = {"npc/combine_soldier/vo/unitisclosing.wav"},
			text = "병력 접근 중.",
			useDesignation = true,
			useNumber = false,
			-- "리더, 병력 접근 중."
		},
		{
			-- FLANK6: on1 V_MYNAMES unitisinbound off1
			sounds = {"npc/combine_soldier/vo/unitisinbound.wav"},
			text = "병력 진입 중.",
			useDesignation = true,
			useNumber = false,
			-- "리더, 병력 진입 중."
		},
		{
			-- FLANK7: on1 V_MYNAMES unitismovingin off1
			sounds = {"npc/combine_soldier/vo/unitismovingin.wav"},
			text = "병력 이동 중.",
			useDesignation = true,
			useNumber = false,
			-- "리더, 병력 이동 중."
		}
	},
	go_alert = {
		{
			sounds = {
				"npc/combine_soldier/vo/alert1.wav"
			},
			text = "경고 1."
		},
		{
			sounds = {
				"npc/combine_soldier/vo/executingfullresponse.wav"
			},
			text = "전체 상황 수행!",
			useDesignation = true,
			-- "리더 1. 전체 상황 수행!"
		},
		{
			sounds = {"npc/combine_soldier/vo/readyweaponshostilesinbound.wav"},
			text = "무기 준비하라, 적 접근 중.",
		},
		{
			sounds = {"npc/combine_soldier/vo/prepforcontact.wav"},
			text = "전투 준비, 보고하라.",
		},
		{
			sounds = {"npc/combine_soldier/vo/stayalert.wav"},
			text = "경계하라.",
		},
		{
			sounds = {"npc/combine_soldier/vo/weaponsoffsafeprepforcontact.wav"},
			text = "무기 안전 해제, 전투 준비.",
		},
		{
			-- QUEST5: overwatch isatcode V_RNDCODES V_RNDNUMS
			sounds = {"npc/combine_soldier/vo/overwatch.wav", "npc/combine_soldier/vo/isatcode.wav"},
			layout = {"text", "rndCodes", "rndNums"},
			text = "보고한다, 코드:",
			-- 보고한다, 코드: 에코 5.
		},
		{
			-- IDLE1: on1 overwatchreportspossiblehostiles off1
			sounds = {"npc/combine_soldier/vo/overwatchreportspossiblehostiles.wav"},
			text = "적으로 의심되는 단체가 접근하고 있다.",
			filter = function(speaker, target)
				local count = 0
				local radiusSqr = (600 * 1.5) ^ 2 -- SQUAD_RADIUS * 1.5
				local origin = speaker:GetPos()

				-- Count nearby hostile humanoids (players/NPCs)
				for _, ent in ipairs(ents.FindInSphere(origin, 900)) do
					if (ent:IsPlayer() or ent:IsNPC()) then
						if (ent != speaker and (ent.Alive and ent:Alive()) and PLUGIN:IsHostileToCombine(ent, speaker)) then
							count = count + 1
							if (count >= 2) then return true end
						end
					end
				end
				return false
			end
		},
	},
	lost_long = {
		{
			sounds = {"npc/combine_soldier/vo/targetblackout.wav"},
			text = "목표 대상을 놓쳤다. 정찰 재개하라."
		},
		{
			sounds = {"npc/combine_soldier/vo/lostcontact.wav"},
			text = "추적 실패.",
			useDesignation = true,
			-- "리더 1. 추적 실패."
		},
		{
			sounds = {"npc/combine_soldier/vo/motioncheckallradials.wav"},
			text = "목표 이동을 추적하라."
		},
		{
			sounds = {"npc/combine_soldier/vo/stayalertreportsightlines.wav"},
			text = "경계하라, 상황 보고하라."
		},
		{
			sounds = {"npc/combine_soldier/vo/overwatch.wav", "npc/combine_soldier/vo/teamdeployedandscanning.wav"},
			text = "팀 배치 및 수색 중.",
		},
		{
			sounds = {"npc/combine_soldier/vo/overwatch.wav", "npc/combine_soldier/vo/engagedincleanup.wav"},
			text = "소탕 임무 수행 중.",
			useDesignation = true,
			-- "리더 1. 소탕 임무 수행 중."
		},
		{
			sounds = {"npc/combine_soldier/vo/readyweapons.wav", "npc/combine_soldier/vo/stayalert.wav"},
			text = "무기 준비, 경비하라."
		}
	},
	lost_short = {
		{
			sounds = {
				"npc/combine_soldier/vo/targetisat.wav",
				"npc/combine_soldier/vo/shadow.wav",
				"npc/combine_soldier/vo/four.wav"
			},
			text = "목표 대상 발견. 섀도 4.",
		},
		-- {
		-- 	sounds = {"npc/combine_soldier/vo/readyextractors.wav"},
		-- 	text = "수류탄 준비.",
		-- 	-- "수류탄 준비."
		-- },
		-- {
		-- 	sounds = {"npc/combine_soldier/vo/readycharges.wav"},
		-- 	text = "폭약 준비.",
		-- 	-- "폭약 준비."
		-- },
		{
			sounds = {"npc/combine_soldier/vo/fixsightlinesmovein.wav"},
			text = "고정 시선 이동.",
		},
		{
			sounds = {"npc/combine_soldier/vo/containmentproceeding.wav"},
			text = "진압 진행 중이다.",
		}
	},
	refind_enemy = {
		{
			sounds = {"npc/combine_soldier/vo/target.wav"},
			layout = {"text", "target", "suffix"},
			usesTarget = true,
			suffixSounds = {"npc/combine_soldier/vo/goactiveintercept.wav"},
			text = "목표,",
			suffix = "차단하라.",
			-- "목표, 반시민 1. 차단하라."
		},
		{
			sounds = {"npc/combine_soldier/vo/gosharp.wav"},
			layout = {"text", "distance"},
			usesDistance = true,
			distancePrefix = "범위:",
			distancePrefixSounds = {"npc/combine_soldier/vo/range.wav"},
			distanceSuffix = "미터.",
			text = "이동하라,",
			-- "이동하라, 범위: 12미터."
		},
		{
			sounds = {"npc/combine_soldier/vo/targetcontactat.wav"},
			layout = {"text", "grid", "suffix"},
			usesGrid = true,
			text = "목표 대상 포착,",
			suffix = ".",
			-- "목표 대상 포착, 5-3."
		},
		{
			sounds = {
				"npc/combine_soldier/vo/viscon.wav",
				"npc/combine_soldier/vo/viscon.wav"
			},
			layout = {"text", "distance", "bearing"},
			usesDistance = true,
			distancePrefix = "범위:",
			distancePrefixSounds = {"npc/combine_soldier/vo/range.wav"},
			distanceSuffix = "미터,",
			usesBearing = true,
			bearingPrefix = "방향:",
			bearingPrefixSounds = {"npc/combine_soldier/vo/bearing.wav"},
			bearingSuffix = "도.",
			text = "포착 확인, 포착 확인.",
			-- "포착 확인, 포착 확인. 범위: 15미터, 방향: 180도."
		}
	},
	leader_alert = {
		{
			-- ALERT0: contactconfim V_G0_PLAYERS, range V_DISTS meters, bearing V_DIRS degrees
			sounds = {"npc/combine_soldier/vo/contactconfim.wav"},
			layout = {"text", "target", "distance", "bearing"},
			usesTarget = true,
			usesDistance = true,
			distancePrefix = "범위:",
			distancePrefixSounds = {"npc/combine_soldier/vo/range.wav"},
			distanceSuffix = "미터,",
			usesBearing = true,
			bearingPrefix = "방향:",
			bearingPrefixSounds = {"npc/combine_soldier/vo/bearing.wav"},
			bearingSuffix = "도.",
			text = "포착 확인.",
			-- "포착 확인. 반시민 1. 범위: 12미터, 방향: 180도."
		},
		{
			-- ALERT1: gosharpgosharp, V_DISTS meters
			sounds = {"npc/combine_soldier/vo/gosharpgosharp.wav"},
			layout = {"text", "distance"},
			usesDistance = true,
			distanceSuffix = "미터.",
			text = "이동하라, 이동하라.",
			-- "이동하라, 이동하라. 12미터."
		},
		{
			-- ALERT2: callcontacttarget1, grid V_GRIDXS dash V_GRIDYS
			sounds = {"npc/combine_soldier/vo/callcontacttarget1.wav"},
			layout = {"text", "grid"},
			usesGrid = true,
			text = "용의자 1 확인, 그리드:",
			-- "용의자 1 확인, 그리드: 5-3."
		},
		{
			-- ALERT3: targetisat V_DISTS meters bearing V_DIRS degrees
			sounds = {"npc/combine_soldier/vo/targetisat.wav"},
			layout = {"text", "distance", "bearing"},
			usesDistance = true,
			distanceSuffix = "미터,",
			usesBearing = true,
			bearingPrefix = "방향:",
			bearingPrefixSounds = {"npc/combine_soldier/vo/bearing.wav"},
			bearingSuffix = "도.",
			text = "목표 대상 발견.",
			-- "목표 대상 발견. 12미터, 방향: 180도."
		},
		{
			-- ALERT4: targetmyradial V_DIRS degrees
			sounds = {"npc/combine_soldier/vo/targetmyradial.wav"},
			layout = {"text", "bearing"},
			usesBearing = true,
			bearingSuffix = "도.",
			text = "목표 대상 포착,",
			-- "목표 대상 포착, 180도."
		},
		{
			-- ALERT5: contact V_G0_PLAYERS
			sounds = {"npc/combine_soldier/vo/contact.wav"},
			layout = {"text", "target", "suffix"},
			usesTarget = true,
			text = "포착,",
			-- "포착, 반시민 1."
		},
		{
			-- ALERT6: targetcontactat V_DISTS meters, bearing V_DIRS degrees
			sounds = {"npc/combine_soldier/vo/targetcontactat.wav"},
			layout = {"text", "distance", "bearing"},
			usesDistance = true,
			distanceSuffix = "미터,",
			usesBearing = true,
			bearingPrefix = "방향:",
			bearingPrefixSounds = {"npc/combine_soldier/vo/bearing.wav"},
			bearingSuffix = "도.",
			text = "목표 대상 포착,",
			-- "목표 대상 포착, 12미터, 방향: 180도."
		},
		{
			-- ALERT7: designatetargetas V_G0_PLAYERS
			sounds = {"npc/combine_soldier/vo/designatetargetas.wav"},
			layout = {"text", "target", "suffix"},
			usesTarget = true,
			text = "지명 목표:",
			-- "지명 목표: 반시민 1."
		},
		{
			-- ALERT8: contactconfirmprosecuting
			sounds = {"npc/combine_soldier/vo/contactconfirmprosecuting.wav"},
			layout = {"text"},
			text = "포착 확인, 임무 수행 중.",
		},
		{
			-- ALERT9: contactconfim, designatetargetas V_G0_PLAYERS
			sounds = {
				"npc/combine_soldier/vo/contactconfim.wav",
				"npc/combine_soldier/vo/designatetargetas.wav"
			},
			layout = {"text", "target", "suffix"},
			usesTarget = true,
			text = "포착 확인. 지명 목표:",
			-- "포착 확인. 지명 목표: 반시민 1."
		}
	},
	man_down = {
		{
			-- MAN_DOWN0: on1 V_WHODIEDS onedown onedown off1
			sounds = {
				"npc/combine_soldier/vo/onedown.wav",
				"npc/combine_soldier/vo/onedown.wav"
			},
			layout = {"victimDesignation", "text"},
			usesVictim = true,
			text = "사상자 발생, 사상자 발생!",
			-- "소드 3. 사상자 발생, 사상자 발생!"
		},
		{
			-- MAN_DOWN1: on1 V_WHODIEDS onedutyvacated off1
			sounds = {"npc/combine_soldier/vo/onedutyvacated.wav"},
			layout = {"victimDesignation", "text"},
			usesVictim = true,
			text = "한 자리 비었다.",
			-- "소드 3. 한 자리 비었다."
		},
		{
			-- MAN_DOWN2: on2 heavyresistance off3
			sounds = {"npc/combine_soldier/vo/heavyresistance.wav"},
			layout = {"text"},
			text = "저항이 거세다. 지시사항 바란다.",
		},
		{
			-- MAN_DOWN3: on1 overwatchrequestreinforcement off3
			sounds = {"npc/combine_soldier/vo/overwatchrequestreinforcement.wav"},
			layout = {"text"},
			text = "증원 병력 요청한다.",
		},
		{
			-- MAN_DOWN4: on1 V_WHODIEDS onedown, hardenthatposition off3
			sounds = {
				"npc/combine_soldier/vo/onedown.wav",
				"npc/combine_soldier/vo/hardenthatposition.wav"
			},
			layout = {"victimDesignation", "text"},
			usesVictim = true,
			text = "사상자 발생! 위치 사수하라!",
			-- "소드 3. 사상자 발생! 위치 사수하라!"
		}
	},
	player_hit = {
		{
			-- HIT0: targetcompromisedmovein
			sounds = {"npc/combine_soldier/vo/targetcompromisedmovein.wav"},
			text = "목표 대상 전투력 저하, 접근하라.",
		},
		{
			-- HIT1: affirmativewegothimnow
			sounds = {"npc/combine_soldier/vo/affirmativewegothimnow.wav"},
			text = "알았다. 그를 잡았다.",
		},
		{
			-- HIT2: thatsitwrapitup
			sounds = {"npc/combine_soldier/vo/thatsitwrapitup.wav"},
			text = "됐어, 마무리 해.",
		}
	},
	monster_alert = {
		{
			-- MONST0: confirmsectornotsterile
			sounds = {"npc/combine_soldier/vo/confirmsectornotsterile.wav"},
			text = "미살균 구역인지 확인하라.",
		},
		{
			-- MONST1: visualonexogens
			sounds = {"npc/combine_soldier/vo/visualonexogens.wav"},
			text = "엑소젠 발견했다.",
		},
		{
			-- MONST2: overwatch sector V_SECTORS infected
			sounds = {"npc/combine_soldier/vo/overwatch.wav", "npc/combine_soldier/vo/infected.wav"},
			layout = {"text", "sectorLabel", "sectorNumber", "suffix"},
			usesSector = true,
			text = "보고한다,",
			suffix = "감염 확인.",
			-- "보고한다, 구역 5 감염 확인."
		}
	},
	monster_bugs = {
		{
			-- BUGS0: confirmsectornotsterile
			sounds = {"npc/combine_soldier/vo/confirmsectornotsterile.wav"},
			text = "미살균 구역인지 확인하라.",
		},
		{
			-- BUGS1: swarmoutbreakinsector V_SECTORS
			sounds = {"npc/combine_soldier/vo/swarmoutbreakinsector.wav"},
			layout = {"text", "sectorNumber", "suffix"},
			usesSector = true,
			text = "새 보금 확산 확인.",
			suffix = ".",
			-- "새 보금 확산 확인. 5."
		},
		{
			-- BUGS2: overwatch, weareinaninfestationzone, sector V_SECTORS
			sounds = {
				"npc/combine_soldier/vo/overwatch.wav",
				"npc/combine_soldier/vo/weareinaninfestationzone.wav",
				"npc/combine_soldier/vo/sector.wav"
			},
			layout = {"text", "sectorLabel", "sectorNumber", "suffix"},
			usesSector = true,
			text = "보고한다, 출몰 구역에 있다.",
			suffix = ".",
			-- "보고한다, 출몰 구역에 있다. 구역 5."
		},
		{
			-- BUGS3: overwatch, wehavenontaggedviromes, grid V_GRIDXS dash V_GRIDYS
			sounds = {
				"npc/combine_soldier/vo/overwatch.wav",
				"npc/combine_soldier/vo/wehavenontaggedviromes.wav",
				"npc/combine_soldier/vo/grid.wav"
			},
			layout = {"text", "gridX", "dash", "gridY", "suffix"},
			usesGrid = true,
			text = "보고한다, 태그 없는 바이롬을 발견했다. 그리드:",
			suffix = ".",
			-- "보고한다, 태그 없는 바이롬을 발견했다. 그리드: 5-3."
		}
	},
	monster_citizens = {
		{
			-- CITIZENS0: outbreak
			sounds = {"npc/combine_soldier/vo/outbreak.wav"},
			text = "확산.",
		}
	},
	monster_character = {
		{
			-- CHARACTER0: target, prioritytwoescapee
			sounds = {
				"npc/combine_soldier/vo/target.wav",
				"npc/combine_soldier/vo/prioritytwoescapee.wav"
			},
			text = "목표, 2번 임무 도망자 처리.",
		},
		{
			-- CHARACTER1: outbreakstatusiscode hurricane
			sounds = {"npc/combine_soldier/vo/outbreakstatusiscode.wav", "npc/combine_soldier/vo/hurricane.wav"},
			text = "확산 상태 코드: 허리케인.",
		}
	},
	monster_zombies = {
		{
			-- ZOMBIES0: necrotics
			sounds = {"npc/combine_soldier/vo/necrotics.wav"},
			text = "변종.",
		},
		{
			-- ZOMBIES1: necroticsinbound
			sounds = {"npc/combine_soldier/vo/necroticsinbound.wav"},
			text = "변종 접근.",
		},
		{
			-- ZOMBIES2: overwatch, weareinaninfestationzone, sector V_SECTORS
			sounds = {
				"npc/combine_soldier/vo/overwatch.wav",
				"npc/combine_soldier/vo/weareinaninfestationzone.wav",
				"npc/combine_soldier/vo/sector.wav"
			},
			layout = {"text", "sectorLabel", "sectorNumber", "suffix"},
			usesSector = true,
			text = "보고한다, 출몰 구역에 있다.",
			suffix = ".",
			-- "보고한다, 출몰 구역에 있다. 구역 5."
		}
	},
	monster_parasites = {
		{
			-- PARASITES0: callcontactparasitics
			sounds = {"npc/combine_soldier/vo/callcontactparasitics.wav"},
			text = "기생 생명체 포착.",
		},
		{
			-- PARASITES1: overwatch, wehavefreeparasites, sector V_SECTORS
			sounds = {
				"npc/combine_soldier/vo/overwatch.wav",
				"npc/combine_soldier/vo/wehavefreeparasites.wav",
				"npc/combine_soldier/vo/sector.wav"
			},
			layout = {"text", "sectorLabel", "sectorNumber", "suffix"},
			usesSector = true,
			text = "보고한다, 숙주 없는 기생 발견했다.",
			suffix = ".",
			-- "보고한다, 숙주 없는 기생 발견했다. 구역 5."
		}
	},
	kill_monster = {
		{
			-- MONST0: V_SEQGLOBNBRS cleaned
			sounds = {"npc/combine_soldier/vo/cleaned.wav"},
			layout = {"seqGlobNbrs", "text"},
			usesKills = true,
			text = "처리했다.",
			-- "4 처리했다."
		},
		{
			-- MONST1: V_SEQGLOBNBRS sterilized
			sounds = {"npc/combine_soldier/vo/sterilized.wav"},
			layout = {"seqGlobNbrs", "text"},
			usesKills = true,
			text = "처리됐다.",
			-- "4 처리됐다."
		},
		{
			-- MONST2: V_SEQGLOBNBRS contained
			sounds = {"npc/combine_soldier/vo/contained.wav"},
			layout = {"seqGlobNbrs", "text"},
			usesKills = true,
			text = "격리되었다.",
			-- "4 격리되었다."
		}
	},
	cover = {
		{
			-- COVER0: coverhurt
			sounds = {"npc/combine_soldier/vo/coverhurt.wav"},
			text = "엄호하라!",
		},
		{
			-- COVER1: displace2
			sounds = {"npc/combine_soldier/vo/displace2.wav"},
			text = "분산해라!",
		},
		{
			-- COVER2: V_MYNAMES V_MYNUMS requestmedical
			sounds = {"npc/combine_soldier/vo/requestmedical.wav"},
			text = "의료 요청.",
			useDesignation = true,
			useNumber = true,
			-- "리더 1. 의료 요청."
		},
		{
			-- COVER3: V_MYNAMES V_MYNUMS requeststimdose
			sounds = {"npc/combine_soldier/vo/requeststimdose.wav"},
			text = "스팀팩 요청.",
			useDesignation = true,
			useNumber = true,
			-- "리더 1. 스팀팩 요청."
		}
	},
	ally_hurt = {
		{
			-- IDLE2: ovewatchorders3ccstimboost
			sounds = {"npc/combine_soldier/vo/ovewatchorders3ccstimboost.wav"},
			text = "스팀팩 3CC 투여하라.",
			filter = function(speaker, target)
				return PLUGIN:IsSquadLeader(speaker)
			end
		},
	},
	taunt = {
		{
			-- TAUNT0: targetineffective
			sounds = {"npc/combine_soldier/vo/targetineffective.wav"},
			text = "큰 손상 없음.",
		},
		{
			-- TAUNT1: bodypackholding
			sounds = {"npc/combine_soldier/vo/bodypackholding.wav"},
			text = "방탄복 양호.",
		},
		{
			-- TAUNT2: V_MYNAMES V_MYNUMS fullactive
			sounds = {"npc/combine_soldier/vo/fullactive.wav"},
			text = "이상 무.",
			useDesignation = true,
			useNumber = true,
			-- "리더 1. 이상 무."
		}
	},
	skyshield_lost = {
		{
			-- "skyshieldreportslostcontact, readyweapons"
			sounds = {"npc/combine_soldier/vo/skyshieldreportslostcontact.wav", "npc/combine_soldier/vo/readyweapons.wav"},
			text = "스카이쉴드, 교신 실패. 무기 준비.",
		},
	},
	player_dead = {
		{
			-- PLAYER_DEAD0: overwatchconfirmhvtcontained
			sounds = {"npc/combine_soldier/vo/overwatchconfirmhvtcontained.wav"},
			text = "목표 대상 처리 임무가 완수됐다.",
		},
		{
			-- PLAYER_DEAD2: overwatchtargetcontained
			sounds = {"npc/combine_soldier/vo/overwatchtargetcontained.wav"},
			text = "목표 대상은 처리됐다.",
		},
		{
			-- PLAYER_DEAD3: overwatch, stabilizationteamhassector
			sounds = {"npc/combine_soldier/vo/overwatch.wav", "npc/combine_soldier/vo/stabilizationteamhassector.wav"},
			text = "진압 팀, 구역 통제 임무 완수됐다.",
		},
		{
			-- PLAYER_DEAD4: overwatch, V_G0_PLAYERS secure
			sounds = {"npc/combine_soldier/vo/overwatch.wav", "npc/combine_soldier/vo/secure.wav"},
			layout = {"text", "target", "suffix"},
			usesTarget = true,
			text = "보고한다,",
			targetSuffix = "",
			suffix = "처리 완수.",
			-- "보고한다, 확산 처리 완수."
		},
		{
			-- PLAYER_DEAD5: overwatch, V_G0_PLAYERS delivered
			sounds = {"npc/combine_soldier/vo/overwatch.wav", "npc/combine_soldier/vo/delivered.wav"},
			layout = {"text", "target", "suffix"},
			usesTarget = true,
			text = "보고한다,",
			targetSuffix = "",
			suffix = "처리 완료.",
			-- "보고한다, 확산 처리 완료."
		},
		{
			-- PLAYER_DEAD6: overwatch, antiseptic administer
			sounds = {"npc/combine_soldier/vo/overwatch.wav", "npc/combine_soldier/vo/antiseptic.wav", "npc/combine_soldier/vo/administer.wav"},
			text = "보고한다, 소독제 지급하라.",
		}
	},
	idle = {
		{
			-- IDLE0: on1 V_RNDNAMES V_RNDCODES V_RNDNUMS dash V_RNDNUMS off1
			layout = {"rndNames", "rndCodes", "rndNums", "dash", "rndNums"},
			-- 고스트 에코 1-5.
		},
		{
			-- IDLE3: stabilizationteamholding
			sounds = {"npc/combine_soldier/vo/stabilizationteamholding.wav"},
			text = "진압 팀, 현 위치에서 대기 중이다.",
		},
		{
			-- IDLE4: V_MYNAMES V_MYNUMS standingby
			sounds = {"npc/combine_soldier/vo/standingby].wav"},
			text = "대기 중.",
			useDesignation = true,
			useNumber = true,
		}
	},
	answer = {
		{
			sounds = {"npc/combine_soldier/vo/affirmative.wav"},
			text = "알았다.",
		},
		{
			sounds = {"npc/combine_soldier/vo/copy.wav"},
			text = "알았다.",
		},
		{
			sounds = {"npc/combine_soldier/vo/copythat.wav"},
			text = "알았다.",
		},
		{
			sounds = {"npc/combine_soldier/vo/affirmative2.wav"},
			text = "알았다.",
		},
		{
			-- ANSWER4: copythat, V_RNDNAMES V_RNDCODES V_RNDNUMS dash V_RNDNUMS
			sounds = {"npc/combine_soldier/vo/copythat.wav"},
			layout = {"text", "rndNames", "rndCodes", "rndNums", "dash", "rndNums"},
			text = "알았다.",
			-- 알았다. 고스트 에코 1-5.
		}
	},
	clear = {
		{
			-- CLEAR0: V_MYNAMES V_MYNUMS hasnegativemovement grid V_GRIDXS dash V_GRIDYS
			sounds = {"npc/combine_soldier/vo/hasnegativemovement.wav"},
			layout = {"designation", "text", "grid"},
			useDesignation = true,
			useNumber = true,
			usesGrid = true,
			text = "이동이 감지되지 않는다. 그리드:",
			-- 이동이 감지되지 않는다. 그리드: 5-3.
		},
		{
			-- CLEAR1: V_MYNAMES V_MYNUMS isholdingatcode V_RNDCODES
			sounds = {"npc/combine_soldier/vo/isholdingatcode.wav"},
			layout = {"designation", "text", "rndCodes"},
			useDesignation = true,
			useNumber = true,
			text = "대기 중, 코드:",
			-- 리더 1. 대기 중, 코드: 에코.
		},
		{
			-- CLEAR2: V_MYNAMES V_MYNUMS hasnegativemovement
			sounds = {"npc/combine_soldier/vo/hasnegativemovement.wav"},
			text = "이동이 감지되지 않는다.",
			useDesignation = true,
			useNumber = true,
			-- 리더 1. 이동이 감지되지 않는다.
		},
		{
			-- CLEAR3: affirmative, noviscon
			sounds = {"npc/combine_soldier/vo/affirmative.wav", "npc/combine_soldier/vo/noviscon.wav"},
			text = "알았다, 추적 실패.",
		},
		{
			-- CLEAR4: sightlineisclear
			sounds = {"npc/combine_soldier/vo/sightlineisclear.wav"},
			text = "가시거리 이상 없음.",
		},
		{
			-- CLEAR5: V_MYNAMES reportingclear
			sounds = {"npc/combine_soldier/vo/reportingclear.wav"},
			text = "이상 없음.",
			useDesignation = true,
			-- 리더, 이상 없음.
		},
		{
			-- CLEAR6: sectorissecurenovison
			sounds = {"npc/combine_soldier/vo/sectorissecurenovison.wav"},
			text = "구역 확보, 포착 없음.",
		}
	},
	check = {
		{
			sounds = {"npc/combine_soldier/vo/stayalertreportsightlines.wav"},
			text = "경계하라, 상황 보고하라.",
		},
		{
			sounds = {"npc/combine_soldier/vo/reportallpositionsclear.wav"},
			text = "모든 위치는 보고하라.",
		},
		{
			sounds = {"npc/combine_soldier/vo/reportallradialsfree.wav"},
			text = "모든 구역은 보고하라.",
		}
	},
}

-- Metropolice sentences components (suspects and locations) expanded
-- Mapping based on original HL2 map numbers/themes
local MPF_MAP_THEMES = {
	-- map 0 default
	[0] = {
		locations = {
			{sound = "npc/metropolice/vo/block.wav", text = "구역"},
			{sound = "npc/metropolice/vo/zone.wav", text = "구역"},
			{sound = "npc/metropolice/vo/sector.wav", text = "섹터"}
		},
		suspects = {
			{sound = "npc/metropolice/vo/subject.wav", text = "대상"}
		}
	},
	-- map 1 trainstation
	[1] = {
		locations = {
			{sound = "npc/metropolice/vo/stationblock.wav", text = "스테이션 구역"},
			{sound = "npc/metropolice/vo/transitblock.wav", text = "통과 구역"},
			{sound = "npc/metropolice/vo/workforceintake.wav", text = "인력 증원"}
		},
		suspects = {
			{sound = "npc/metropolice/vo/citizen.wav", text = "시민"},
			{sound = "npc/metropolice/vo/upi.wav", text = "용의자"},
			{sound = "npc/metropolice/vo/subject.wav", text = "대상"}
		}
	},
	-- map 2 canals
	[2] = {
		locations = {
			{sound = "npc/metropolice/vo/canalblock.wav", text = "운하 구역"},
			{sound = "npc/metropolice/vo/stormsystem.wav", text = "스톰 시스템"},
			{sound = "npc/metropolice/vo/wasteriver.wav", text = "오염된 강"},
			{sound = "npc/metropolice/vo/deservicedarea.wav", text = "관할 구역"}
		},
		suspects = {
			{sound = "npc/metropolice/vo/subject.wav", text = "대상"},
			{sound = "npc/metropolice/vo/noncitizen.wav", text = "비시민"},
			{sound = "npc/metropolice/vo/sociocide.wav", text = "반사회"},
			{sound = "npc/metropolice/vo/anticitizen.wav", text = "반시민"}
		}
	},
	-- map 3 black mesa east, eli's lab
	[3] = {
		locations = {
			{sound = "npc/metropolice/vo/industrialzone.wav", text = "산업 구역"},
			{sound = "npc/metropolice/vo/restrictedblock.wav", text = "제한 구역"},
			{sound = "npc/metropolice/vo/repurposedarea.wav", text = "용도 변경 지역"}
		},
		suspects = {
			{sound = "npc/metropolice/vo/anticitizen.wav", text = "반시민"},
			{sound = "npc/metropolice/vo/subject.wav", text = "대상"}
		}
	},
	-- map 4 ravenholm
	[4] = {
		locations = {
			{sound = "npc/metropolice/vo/condemnedzone.wav", text = "저주받은 구역"},
			{sound = "npc/metropolice/vo/infestedzone.wav", text = "감염된 구역"},
			{sound = "npc/metropolice/vo/nonpatrolregion.wav", text = "비감시 영역"}
		},
		suspects = {
			{sound = "npc/metropolice/vo/subject.wav", text = "대상"},
			{sound = "npc/metropolice/vo/anticitizen.wav", text = "반시민"}
		}
	},
	-- map 5 highway 17 coast
	[5] = {
		locations = {
			{sound = "npc/metropolice/vo/externaljurisdiction.wav", text = "외부 관할권"},
			{sound = "npc/metropolice/vo/stabilizationjurisdiction.wav", text = "진압 관할권"},
			{sound = "npc/metropolice/vo/outlandzone.wav", text = "외지 구역"}
		},
		suspects = {
			{sound = "npc/metropolice/vo/sociocide.wav", text = "반사회"}
		}
	},
	-- map 6 nova prospekt prison
	[6] = {
		locations = {
			{sound = "npc/metropolice/vo/externaljurisdiction.wav", text = "외부 관할권"},
			{sound = "npc/metropolice/vo/stabilizationjurisdiction.wav", text = "진압 관할권"}
		},
		suspects = {
			{sound = "npc/metropolice/vo/infection.wav", text = "감염"}
		}
	},
	-- map 7 city 17 urban
	[7] = {
		locations = {
			{sound = "npc/metropolice/vo/residentialblock.wav", text = "거주 구역"},
			{sound = "npc/metropolice/vo/404zone.wav", text = "404 구역"},
			{sound = "npc/metropolice/vo/distributionblock.wav", text = "유통 구역"},
			{sound = "npc/metropolice/vo/productionblock.wav", text = "생산 구역"}
		},
		suspects = {
			{sound = "npc/metropolice/vo/subject.wav", text = "대상"}
		}
	},
	-- map 8 citadel
	[8] = {
		locations = {
			{sound = "npc/metropolice/vo/highpriorityregion.wav", text = "최우선 지역"},
			{sound = "npc/metropolice/vo/terminalrestrictionzone.wav", text = "최종 제한 구역"},
			{sound = "npc/metropolice/vo/controlsection.wav", text = "구역 통제"}
		},
		suspects = {
			{sound = "npc/metropolice/vo/subject.wav", text = "대상"}
		}
	}
}

local MPF_THEME_MAPPING = {
	["default"] = 0,
	["trainstation"] = 1,
	["canals"] = 2,
	["restricted"] = 3,
	["ravenholm"] = 4,
	["coast"] = 5,
	["prison"] = 6,
	["urban"] = 7,
	["citadel"] = 8
}

function PLUGIN:GetMapThemeIndex()
	local map = game.GetMap():lower()
	
	if (map:find("trainstation") or map:find("terminal") or map:find("transit") or map:find("rp_city17")) then return 1 end
	if (map:find("canal")) then return 2 end
	if (map:find("eli") or map:find("black_mesa_east")) then return 3 end
	if (map:find("ravenholm") or map:find("d1_town")) then return 4 end
	if (map:find("coast") or map:find("highway") or map:find("wasteland") or map:find("outland") or map:find("forest")) then return 5 end
	if (map:find("prison") or map:find("nova_prospekt")) then return 6 end
	if (map:find("citadel")) then return 8 end
	if (map:find("c17") or map:find("c18") or map:find("city") or map:find("indust")) then return 7 end
	
	return 0 -- default
end

local MPF_RANK_WEIGHTS = {
	["CMD"] = 9, ["CmD"] = 9,
	["SEC"] = 9, ["SeC"] = 9,
	["DVL"] = 8,  ["DvL"] = 8,
	["OFC"] = 7,  ["OfC"] = 7,
	["EPU"] = 7,  ["EpU"] = 7,
	["01"] = 6,   ["i1"] = 6,
	["02"] = 5,   ["i2"] = 5,
	["03"] = 4,   ["i3"] = 4,
	["04"] = 3,   ["i4"] = 3,
	["05"] = 2,   ["i5"] = 2,
	["RCT"] = 1,  ["Rct"] = 1
}

function PLUGIN:GetMPFRankWeight(client)
	local char = client:GetCharacter()
	if (!char) then return 0 end
	
	local name = char:GetName()
	for rank, weight in pairs(MPF_RANK_WEIGHTS) do
		if (name:find(rank)) then
			return weight
		end
	end
	
	return 0
end

function PLUGIN:IsHighestRankingMPF(client)
	local mpfs = {}
	for _, v in ipairs(player.GetAll()) do
		if (v:Alive() and v:Team() == FACTION_MPF) then
			table.insert(mpfs, v)
		end
	end

	if (#mpfs <= 1) then return false end

	local maxWeight = -1
	local minWeight = 99
	local weights = {}
	
	for _, v in ipairs(mpfs) do
		local w = self:GetMPFRankWeight(v)
		weights[v] = w
		if (w > maxWeight) then maxWeight = w end
		if (w < minWeight) then minWeight = w end
	end

	-- Allow any top-ranking officer to speak, as long as there is at least one subordinate
	return (weights[client] == maxWeight and maxWeight > minWeight)
end

function PLUGIN:GetMPFThemeName(client)
	local overrideTheme = client and self:GetAreaCalloutTheme(client:GetArea())
	local selected = overrideTheme or ix.config.Get("mpfCalloutTheme", "auto")
	
	if (selected == "auto") then
		local index = self:GetMapThemeIndex()
		for name, idx in pairs(MPF_THEME_MAPPING) do
			if (idx == index) then return name end
		end
		return "default"
	end
	
	return selected
end

function PLUGIN:GetMPFMapChoices(client)
	local overrideTheme = client and self:GetAreaCalloutTheme(client:GetArea())
	local selected = overrideTheme or ix.config.Get("mpfCalloutTheme", "auto")
	local index = 0
	
	if (selected == "auto") then
		index = self:GetMapThemeIndex()
	else
		index = MPF_THEME_MAPPING[selected] or 0
	end
	
	local theme = MPF_MAP_THEMES[index] or MPF_MAP_THEMES[0]
	
	return theme
end

local MPF_TEMPLATE_SETS = {
	pain_light = {
		{
			sounds = {
				"npc/metropolice/vo/minorhitscontinuing.wav",
			},
			text = "경미한 부상이다, 임무 재개 중!",
		}
	},
	pain_medium = {
		{
			-- COVER_HEAVY_DAMAGE0: officerunderfiretakingcover
			sounds = {"npc/metropolice/vo/officerunderfiretakingcover.wav"},
			text = "공격받고 있다, 엄폐한다!",
		},
		{
			-- COVER_HEAVY_DAMAGE1: officerneedsassistance
			sounds = {"npc/metropolice/vo/officerneedsassistance.wav"},
			text = "부상 당한 경찰이 있다, 11-99!",
		},
		{
			-- COVER_HEAVY_DAMAGE2: takecover
			sounds = {"npc/metropolice/vo/takecover.wav"},
			text = "엄폐하라!",
		},
		{
			-- COVER_HEAVY_DAMAGE3: movingtocover
			sounds = {"npc/metropolice/vo/movingtocover.wav"},
			text = "엄호 위치로 이동한다!",
		}
	},
	pain_heavy = {
		{
			sounds = {
				"npc/metropolice/vo/11-99officerneedsassistance.wav",
			},
			text = "11-99, 긴급 지원 바란다!",
		},
		{
			sounds = {
				"npc/metropolice/vo/officerneedshelp.wav",
			},
			text = "경찰이 지원 요청한다!",
		},
		{
			sounds = {
				"npc/metropolice/vo/dispatchIneed10-78.wav",
			},
			text = "10-78 지원, 대원이 위험하다!",
		},
		{
			sounds = {
				"npc/metropolice/vo/officerneedsassistance.wav",
			},
			text = "부상 당한 경찰이 있다, 11-99!",
		}
	},
	go_alert = {
		{
			-- METROPOLICE_CANAL_ALERT0: suspectinstormrunoff V_G1_LOCATION_MAP__P V_G3_NUMBP
			sounds = {"npc/metropolice/vo/suspectinstormrunoff.wav"},
			layout = {"text", "sectorLabel", "sectorNumber", "suffix"},
			usesSector = true,
			requiredTheme = "canals",
			text = "모든 병력, 용의자가 스톰 런오프 시스템에 있다.",
			-- "모든 병력, 용의자가 스톰 런오프 시스템에 있다. 구역 1."
		},
		{
			-- METROPOLICE_WATER_ALERT0: suspectusingrestrictedcanals
			sounds = {"npc/metropolice/vo/suspectusingrestrictedcanals.wav"},
			layout = {"text", "sectorLabel", "sectorNumber", "suffix"},
			usesSector = true,
			requiredTheme = "canals",
			text = "용의자가 제한된 운하를 사용하고 있다.",
			-- "용의자가 제한된 운하를 사용하고 있다. 구역 1."
		},
		{
			-- METROPOLICE_UPTHERE_ALERT0: hesupthere
			sounds = {"npc/metropolice/vo/hesupthere.wav"},
			text = "위쪽에 있다!",
			filter = function(speaker, target)
				if (!IsValid(target)) then return false end
				return (target:GetPos().z - speaker:GetPos().z) > 150
			end
		},
		{
			-- Generic re-finds for non-leaders
			sounds = {"npc/metropolice/vo/thereheis.wav"},
			text = "저기 있다!",
		},
		{
			-- METROPOLICE_IDLE_CR1: suspect11-6my1020is
			sounds = {"npc/metropolice/vo/suspect11-6my1020is.wav"},
			layout = {"text", "sectorLabel", "sectorNumber"},
			usesSector = true,
			text = "용의자 11-6, 여기는 10-20:",
			-- "용의자 11-6, 여기는 10-20: 주거 구역 1."
		},
	},
	leader_alert = {
		{
			-- METROPOLICE_MONST_PLAYER0: V_G2_SUSPECT_MAP__P matchonapblikeness
			layout = {"target", "text"},
			usesTarget = true,
			suffixSounds = {"npc/metropolice/vo/matchonapblikeness.wav"},
			text = "APB 사진과 일치한다.",
			-- "용의자 APB 사진과 일치한다."
		},
		{
			-- METROPOLICE_MONST_PLAYER3: V_G2_SUSPECT_MAP__P location V_G1_LOCATION_MAP__P V_G3_NUMBP
			sounds = { "npc/metropolice/vo/location.wav"},
			layout = {"target", "text", "sectorLabel", "sectorNumber", "suffix"},
			usesTarget = true,
			usesSector = true,
			suffix = ".",
			text = "위치,",
			-- "용의자 위치, 주거 구역 1."
		},
		{
			-- METROPOLICE_MONST_PLAYER4: designatesuspectas V_G2_SUSPECT_MAP__P allunitscode2
			sounds = {"npc/metropolice/vo/designatesuspectas.wav"},
			layout = {"text", "target", "suffix"},
			usesTarget = true,
			suffixSounds = {"npc/metropolice/vo/allunitscode2.wav"},
			text = "용의자 지명:",
			suffix = "모든 병력, 코드 2!",
			-- "용의자 지명: 대상. 모든 병력, 코드 2!"
		},
		{
			-- METROPOLICE_GO_ALERT1: thereheis V_DISTP meters
			sounds = {"npc/metropolice/vo/thereheis.wav"},
			layout = {"text", "distance", "suffix"},
			usesDistance = true,
			text = "저기 있다!",
			-- "저기 있다! 25미터."
		},
		{
			-- METROPOLICE_GO_ALERT2: contactwith243suspect, V_G1_LOCATION_MAP__P V_G3_NUMBP
			sounds = {"npc/metropolice/vo/contactwith243suspect.wav"},
			layout = {"text", "sectorLabel", "sectorNumber", "suffix"},
			usesSector = true,
			text = "243 용의자 포착했다, 10-20:",
			-- "243 용의자 포착했다, 10-20: 구역 1."
		},
		{
			-- METROPOLICE_GO_ALERT3: allunitsrespondcode3
			sounds = {"npc/metropolice/vo/allunitsrespondcode3.wav"},
			text = "현장의 모든 병력, 코드 3 응답하라!",
		},
		{
			-- METROPOLICE_MONST_PLAYER2: allunitsrespondcode3, V_G1_LOCATION_MAP__P V_G3_NUMBP
			sounds = {"npc/metropolice/vo/allunitsrespondcode3.wav"},
			layout = {"text", "sectorLabel", "sectorNumber", "suffix"},
			usesSector = true,
			suffix = ".",
			text = "현장의 모든 병력, 코드 3 응답하라!",
			-- "현장의 모든 병력, 코드 3 응답하라! 주거 구역 1."
		},
		{
			-- "stillgetting647e"
			sounds = {"npc/metropolice/vo/stillgetting647e.wav"},
			text = "로컬 감시조에서 647-E를 포착 중."
		},
		{
			-- METROPOLICE_CANAL_ALERT0 (Leader version)
			sounds = {"npc/metropolice/vo/suspectinstormrunoff.wav"},
			layout = {"text", "sectorLabel", "sectorNumber", "suffix"},
			usesSector = true,
			requiredTheme = "canals",
			text = "용의자가 스톰 런오프 시스템에 있다.",
		},
		{
			-- METROPOLICE_WATER_ALERT0 (Leader version)
			sounds = {"npc/metropolice/vo/suspectusingrestrictedcanals.wav"},
			layout = {"text", "sectorLabel", "sectorNumber", "suffix"},
			usesSector = true,
			requiredTheme = "canals",
			text = "용의자가 제한된 운하를 사용하고 있다.",
		},
		{
			-- METROPOLICE_UPTHERE_ALERT0 (Leader version)
			sounds = {"npc/metropolice/vo/hesupthere.wav"},
			text = "위쪽에 있다!",
			filter = function(speaker, target)
				if (!IsValid(target)) then return false end
				return (target:GetPos().z - speaker:GetPos().z) > 150
			end
		},
	},
	monster_alert = {
		{
			-- METROPOLICE_MONST0: outbreak V_RNDNUMP V_RNDACTP
			sounds = {"npc/metropolice/vo/outbreak.wav"},
			layout = {"text", "rndNums", "sectorLabel", "suffix"},
			usesSector = true,
			suffix = ".",
			text = "확산. 10-20:",
			-- "확산. 10-20: 5 구역."
		},
		{
			-- METROPOLICE_MONST1: V_RNDACTP V_RNDNUMP
			layout = {"sectorLabel", "rndNums", "suffix"},
			usesSector = true,
			suffix = ".",
			-- "구역 5."
		},
		{
			-- METROPOLICE_MONST_CITIZENS1: shotsfiredhostilemalignants
			sounds = {"npc/metropolice/vo/shotsfiredhostilemalignants.wav"},
			text = "무기 발사, 적대적인 생명체 발견!",
			filter = function(speaker, target)
				return IsValid(target) and !target:IsPlayer()
			end
		},
	},
	monster_bugs = {
		{
			-- METROPOLICE_MONST_BUGS0: bugs
			sounds = {"npc/metropolice/vo/bugs.wav"},
			text = "벌레!",
			filter = function(speaker, target)
				return IsValid(target) and target:GetClass():lower():find("antlion")
			end
		},
		{
			-- METROPOLICE_MONST_BUGS1: bugsontheloose
			sounds = {"npc/metropolice/vo/bugsontheloose.wav"},
			text = "벌레들이 활동 중이다!",
			filter = function(speaker, target)
				return IsValid(target) and target:GetClass():lower():find("antlion")
			end
		},
		{
			-- METROPOLICE_MONST_BUGS2: outbreak V_RNDNUMP converging
			sounds = {"npc/metropolice/vo/outbreak.wav"},
			layout = {"text", "rndNums", "suffix"},
			suffixSounds = {"npc/metropolice/vo/converging.wav"},
			text = "확산",
			suffix = "집합 중.",
			-- "확산 5. 집합 중."
		},
		{
			-- METROPOLICE_MONST_BUGS3: outlandbioticinhere
			sounds = {"npc/metropolice/vo/outlandbioticinhere.wav"},
			text = "여기 외지 생물체가 있다!",
			filter = function(speaker, target)
				return IsValid(target) and !target:IsPlayer()
			end
		}
	},
	monster_zombies = {
		{
			-- METROPOLICE_MONST_ZOMBIES0: freenecrotics, converging V_G1_LOCATION_MAP__P V_G3_NUMBP
			sounds = {
				"npc/metropolice/vo/freenecrotics.wav",
				"npc/metropolice/vo/converging.wav"
			},
			layout = {"text", "suffix", "sectorLabel", "sectorNumber"},
			usesSector = true,
			text = "네크로틱이 날뛰고 있다! 접근 중,",
			suffix = ".",
			-- "네크로틱이 날뛰고 있다! 접근 중, 주거 구역 1."
			filter = function(speaker, target)
				local class = IsValid(target) and target:GetClass():lower() or ""
				return class:find("zombie") or class == "npc_zombine"
			end
		},
		{
			-- METROPOLICE_MONST_ZOMBIES1: necrotics malignant location V_G1_LOCATION_MAP__P V_G3_NUMBP
			sounds = {"npc/metropolice/vo/necrotics.wav", "npc/metropolice/vo/malignant.wav"},
			layout = {"text", "sectorLabel", "sectorNumber", "suffix"},
			usesSector = true,
			text = "네크로틱 악성,",
			suffix = ".",
			-- "네크로틱 악성, 주거 구역 1."
			filter = function(speaker, target)
				local class = IsValid(target) and target:GetClass():lower() or ""
				return class:find("zombie") or class == "npc_zombine"
			end
		}
	},
	monster_parasites = {
		{
			-- METROPOLICE_MONST_PARASITES0: non-taggedviromeshere
			sounds = {"npc/metropolice/vo/non-taggedviromeshere.wav"},
			text = "태그 없는 바이롬을 발견했다!",
			filter = function(speaker, target)
				return IsValid(target) and target:GetClass():lower():find("antlion")
			end
		},
		{
			-- METROPOLICE_MONST_PARASITES1: looseparasitics
			sounds = {"npc/metropolice/vo/looseparasitics.wav"},
			text = "기생충 조심하라!",
			filter = function(speaker, target)
				return IsValid(target) and target:GetClass():lower():find("headcrab")
			end
		}
	},
	monster_freeman = {
		{
			sounds = {"npc/metropolice/vo/confirmpriority1sighted.wav"},
			text = "중요도 1 용의자 발견했다.",
		}
	},
	monster_character = {
		{
			-- METROPOLICE_MONST_CHARACTER0: contactwithpriority2
			sounds = {"npc/metropolice/vo/contactwithpriority2.wav"},
			text = "중요도 2 용의자 발견!",
		},
		{
			-- METROPOLICE_MONST_CHARACTER1: priority2anticitizenhere
			sounds = {"npc/metropolice/vo/priority2anticitizenhere.wav"},
			text = "여기에 중요도 2 반시민이 있다!",
		}
	},
	monster_citizens = {
		{
			-- METROPOLICE_MONST_CITIZENS0: noncitizen outbreak
			sounds = {"npc/metropolice/vo/noncitizen.wav", "npc/metropolice/vo/outbreak.wav"},
			text = "반시민, 확산."
		},
		{
			-- METROPOLICE_MONST_CITIZENS2: possible404here V_G1_LOCATION_MAP__P V_G3_NUMBP
			sounds = {"npc/metropolice/vo/possible404here.wav"},
			layout = {"text", "sectorLabel", "sectorNumber", "suffix"},
			usesSector = true,
			text = "여기에 404 발생 예상!",
			suffix = ".",
			-- "여기에 404 발생 예상! 주거 구역 1."
		},
		{
			-- METROPOLICE_MONST_CHARACTER2: gotoneaccomplicehere
			sounds = {"npc/metropolice/vo/gotoneaccomplicehere.wav"},
			text = "여기 공범자 한 명 잡았다!"
		}
	},
	monster_vehicle = {
		{
			-- METROPOLICE_MONST_PLAYER_VEHICLE3: Ivegot408hereatlocation V_G1_LOCATION_MAP__P V_G3_NUMBP
			sounds = {"npc/metropolice/vo/ivegot408hereatlocation.wav"},
			layout = {"text", "sectorLabel", "sectorNumber", "suffix"},
			usesSector = true,
			text = "이곳에 408 사태 발생했다.",
			suffix = ".",
			-- "이곳에 408 사태 발생했다. 주거 구역 1."
		},
		{
			-- METROPOLICE_MONST_PLAYER_VEHICLE0: airwatchsubjectis505
			sounds = {"npc/metropolice/vo/airwatchsubjectis505.wav"},
			text = "공중 추적 지원 바람, 표적 505!"
		},
		{
			-- METROPOLICE_MONST_PLAYER_VEHICLE1: subjectis505
			sounds = {"npc/metropolice/vo/subjectis505.wav"},
			text = "대상은 505!"
		},
		{
			-- METROPOLICE_MONST_PLAYER_VEHICLE2: subjectisnowhighspeed
			sounds = {"npc/metropolice/vo/subjectisnowhighspeed.wav"},
			text = "주목하라, 대상의 이동 속도가 빨라졌다!",
		},
	},
	grenade_danger = {
		{
			sounds = {"npc/metropolice/vo/grenade.wav"},
			text = "수류탄!",
		},
		{
			sounds = {"npc/metropolice/vo/thatsagrenade.wav"},
			text = "수류탄이다!",
		},
		{
			sounds = {"npc/metropolice/vo/getdown.wav"},
			text = "숙여!",
		}
	},
	manhack_danger = {
		{
			sounds = {"npc/metropolice/vo/lookoutrogueviscerator.wav"},
			text = "통제 안 된 비저레이터다!",
		},
		{
			sounds = {"npc/metropolice/vo/visceratorisoc.wav"},
			text = "날뛰고 있다!",
		}
	},
	vehicle_danger = {
		{
			sounds = {"npc/metropolice/vo/shit.wav"},
			text = "젠장!",
		},
		{
			sounds = {"npc/metropolice/vo/watchit.wav"},
			text = "조심해라!",
		},
		{
			sounds = {"npc/metropolice/vo/lookout.wav"},
			text = "조심해!",
		}
	},
	danger = {
		{
			sounds = {"npc/metropolice/vo/moveit.wav"},
			text = "움직여!",
		},
		{
			sounds = {"npc/metropolice/vo/lookout.wav"},
			text = "조심해!",
		}
	},
	activate_baton = {
		{
			-- "issuing malcompliant citation"
			sounds = {"npc/metropolice/vo/issuingmalcompliantcitation.wav"},
			text = "불순종 소환장 발행 중.",
		},
		{
			-- "pacifying"
			sounds = {"npc/metropolice/vo/pacifying.wav"},
			text = "진압 중!",
		}
	},
	on_fire = {
		{
			-- "officerneedshelp"
			sounds = {"npc/metropolice/vo/officerneedshelp.wav"},
			text = "경찰이 지원 요청한다!",
		},
		{
			-- "help"
			sounds = {"npc/metropolice/vo/help.wav"},
			text = "도와줘!",
		}
	},
	harassment = {
		-- Level 1 (A)
		{ sounds = {"npc/metropolice/vo/movealong3.wav"}, text = "움직여라!", forceLocal = true, level = 1, volume = 60 },
		{ sounds = {"npc/metropolice/vo/move.wav"}, text = "움직여!", forceLocal = true, level = 1, volume = 60 },
		{ sounds = {"npc/metropolice/vo/keepmoving.wav"}, text = "계속 움직여라!", forceLocal = true, level = 1, volume = 60 },
		{ sounds = {"npc/metropolice/vo/backup.wav"}, text = "물러서!", forceLocal = true, level = 1, volume = 60 }, -- 오역 대체: "지원!"
		{ sounds = {"npc/metropolice/vo/getoutofhere.wav"}, text = "이제 여기서 나가라.", forceLocal = true, level = 1, volume = 60 },
		{ sounds = {"npc/metropolice/vo/firstwarningmove.wav"}, text = "첫 번째 경고다, 비켜라!", forceLocal = true, level = 1, volume = 60 },

		-- Level 2 (B)
		{ sounds = {"npc/metropolice/vo/isaidmovealong.wav"}, text = "움직이라고 말했다.", forceLocal = true, level = 2, volume = 70 },
		{ sounds = {"npc/metropolice/vo/youwantamalcomplianceverdict.wav"}, text = "불순종 죄로 평결을 원하나?", forceLocal = true, level = 2, volume = 70 },
		{ sounds = {"npc/metropolice/vo/movebackrightnow.wav"}, text = "즉시 물러나라!", forceLocal = true, level = 2, volume = 70 },
		{ sounds = {"npc/metropolice/vo/secondwarning.wav"}, text = "2차 경고 발부!", forceLocal = true, level = 2, volume = 70 },

		-- Level 3 (C)
		{ sounds = {"npc/metropolice/vo/level3civilprivacyviolator.wav"}, text = "여기에 레벨 3 시민 사생활 침해자가 있다!", level = 3, volume = 80 },
		{ sounds = {"npc/metropolice/vo/malcompliant10107my1020.wav"}, text = "10-20에서 10-107의 불순종, 구속 진행.", level = 3, volume = 80 },
		{ sounds = {"npc/metropolice/vo/preparingtojudge10-107.wav"}, text = "10-107, 판결을 준비 중이다.", level = 3, volume = 80 },
		{ sounds = {"npc/metropolice/vo/readytoprosecutefinalwarning.wav"}, text = "불순종 시민, 기소 준비를 마쳤다!", level = 3, volume = 80 },
		{ sounds = {"npc/metropolice/vo/issuingmalcompliantcitation.wav"}, text = "불순종 소환장 발행 중.", level = 3, volume = 80 },
		{ sounds = {"npc/metropolice/vo/possiblelevel3civilprivacyviolator.wav"}, text = "레벨 3 시민 사생활 침해자가 있다!", level = 3, volume = 80 },
		{ sounds = {"npc/metropolice/vo/finalwarning.wav"}, text = "최종 경고!", forceLocal = true, level = 3, volume = 80 },
	},
	idle = {
		{
			-- "unitis10-8standingby"
			sounds = {"npc/metropolice/vo/unitis10-8standingby.wav"},
			text = "병력은 10-8 대기 중.",
		},
		{
			-- "unitisonduty10-8"
			sounds = {"npc/metropolice/vo/unitisonduty10-8.wav"},
			text = "병력은 10-8 수행 중.",
		},
		{
			-- "holdingon10-14duty"
			sounds = {"npc/metropolice/vo/holdingon10-14duty.wav"},
			text = "10-14 근무 중, 코드 4.",
		},
		{
			-- "unitis10-65"
			sounds = {"npc/metropolice/vo/unitis10-65.wav"},
			text = "병력은 10-65 상태.",
		},
		{
			-- "code7"
			sounds = {"npc/metropolice/vo/code7.wav"},
			text = "코드 7.",
		},
		{
			-- METROPOLICE_IDLE_CR2: ten8standingby
			sounds = {"npc/metropolice/vo/ten8standingby.wav"},
			text = "10-8 대기 중.",
		},
		{
			-- METROPOLICE_IDLE_CR3: code100
			sounds = {"npc/metropolice/vo/code100.wav"},
			text = "코드 100.",
		}
	},
	check = {
		{
			-- "V_G1_LOCATION_MAP__P V_G3_NUMBP ptatlocationreport"
			sounds = {"npc/metropolice/vo/ptatlocationreport.wav"},
			layout = {"sectorLabel", "sectorNumber", "text", "suffix"},
			usesSector = true,
			text = "보호 기동대 위치 도착. 보고한다.",
			-- "구역 1. 보호 기동대 위치 도착. 보고한다."
			isCheck = true,
			filter = function(speaker) return PLUGIN:IsHighestRankingMPF(speaker) end
		},
		{
			-- "anyonepickup647e"
			sounds = {"npc/metropolice/vo/anyonepickup647e.wav"},
			text = "647-E 상태를 확인한 사람 또 있나?",
			isCheck = true,
			filter = function(speaker) return PLUGIN:IsHighestRankingMPF(speaker) end
		},
		{
			-- "checkformiscount"
			sounds = {"npc/metropolice/vo/checkformiscount.wav"},
			text = "불일치 없는지 확인하라.",
			isCheck = true,
			filter = function(speaker) return PLUGIN:IsHighestRankingMPF(speaker) end
		},
		{
			sounds = {"npc/metropolice/vo/copy.wav"},
			text = "확인 바람.",
			isCheck = true,
			filter = function(speaker) return PLUGIN:IsHighestRankingMPF(speaker) end
		},
	},
	lost_short = {
		{
			-- LOST_SHORT0: V_G2_SUSPECT_MAP__P hidinglastseenatrange V_DISTP meters
			sounds = {"npc/metropolice/vo/hidinglastseenatrange.wav"},
			layout = {"target", "text", "distance"},
			usesTarget = true,
			usesDistance = true,
			text = "의심 중, 마지막 포착 위치:",
			-- "대상, 의심 중, 마지막 포착 위치: 15미터."
		},
		{
			-- LOST_SHORT1: sweepingforsuspect
			sounds = {"npc/metropolice/vo/sweepingforsuspect.wav"},
			text = "용의자 추적 중!",
		}
	},
	lost_long = {
		{
			-- LOST_LONG0: allunitsreportlocationsuspect
			sounds = {"npc/metropolice/vo/allunitsreportlocationsuspect.wav"},
			text = "모든 병력, 용의자 위치 보고하라!",
			filter = function(speaker) return PLUGIN:IsSquadLeader(speaker) end,
		},
		{
			-- LOST_LONG1: V_MYNAMEP V_MYNUMP nocontact
			sounds = {"npc/metropolice/vo/nocontact.wav"},
			layout = {"designation", "text"},
			useDesignation = true,
			useNumber = true,
			text = "시야 미확보!",
			-- "유니온 3. 시야 미확보!"
		},
		{
			-- LOST_LONG2: cpweneedtoestablishaperimeterat V_G1_LOCATION_MAP__P V_G3_NUMBP
			sounds = {"npc/metropolice/vo/cpweneedtoestablishaperimeterat.wav"},
			layout = {"text", "sectorLabel", "sectorNumber"},
			usesSector = true,
			text = "지역 구축 요청한다, 위치는...",
			-- "지역 구축 요청한다, 위치는... 구역 5."
		},
		{
			-- LOST_LONG3: V_MYNAMEP V_MYNUMP utlsuspect
			sounds = {"npc/metropolice/vo/utlsuspect.wav"},
			layout = {"designation", "text"},
			useDesignation = true,
			useNumber = true,
			text = "용의자 미발견.",
			-- "유니온 3. 용의자 미발견."
		},
		{
			-- METROPOLICE_IDLE_CR0: ten97suspectisgoa
			sounds = {"npc/metropolice/vo/ten97suspectisgoa.wav"},
			text = "10-97, 용의자는 GOA 상태.",
		},
	},
	refind_enemy = {
		{
			-- REFIND_ENEMY0: supsecthasmovednowto V_G1_LOCATION_MAP__P V_GRIDXP
			sounds = {"npc/metropolice/vo/supsecthasmovednowto.wav"},
			layout = {"text", "sectorLabel", "sectorNumber", "grid"},
			usesSector = true,
			usesGrid = true,
			text = "현재 용의자가 이동했다.",
			-- "현재 용의자가 이동했다. 구역 5, 그리드 10-5."
		},
		{
			-- REFIND_ENEMY1: thereheis
			sounds = {"npc/metropolice/vo/thereheis.wav"},
			text = "저기 있다!",
		},
		{
			-- REFIND_ENEMY2: therehegoeshesat V_DISTP meters
			sounds = {"npc/metropolice/vo/therehegoeshesat.wav"},
			layout = {"text", "distance"},
			usesDistance = true,
			text = "저기 있다! 위치:",
			-- "저기 있다! 위치: 25미터."
		}
	},
	deploy_manhack = {
		{
			-- METROPOLICE_DEPLOY_MANHACK0: visceratordeployed
			sounds = {"npc/metropolice/vo/visceratordeployed.wav"},
			text = "비저레이터가 배치되었다!",
		},
		{
			-- METROPOLICE_DEPLOY_MANHACK1: tenzerovisceratorishunting
			sounds = {"npc/metropolice/vo/tenzerovisceratorishunting.wav"},
			text = "10-0, 비저레이터가 수색 중이다!",
		}
	},
	manhack_killed = {
		{
			-- METROPOLICE_MANHACK_KILLED0: visceratorisoffgrid
			sounds = {"npc/metropolice/vo/visceratorisoffgrid.wav"},
			text = "장소를 이탈했다!",
		},
		{
			-- METROPOLICE_MANHACK_KILLED1: requestsecondaryviscerator
			sounds = {"npc/metropolice/vo/requestsecondaryviscerator.wav"},
			text = "추가 비저레이터 요청, 첫 번째는 전투 불능이다!",
		}
	},
	clear = {
		{
			-- "clearno647no10-107"
			sounds = {"npc/metropolice/vo/clearno647no10-107.wav"},
			text = "이상 없음, 10-107 없음.",
		},
		{
			-- "wearesociostablethislocation"
			sounds = {"npc/metropolice/vo/wearesociostablethislocation.wav"},
			text = "이 지역은 안정되어 있다.",
		},
		{
			-- "blockisholdingcohesive"
			sounds = {"npc/metropolice/vo/blockisholdingcohesive.wav"},
			text = "구역 유지 중, 단결.",
		},
		{
			-- "control100percent"
			sounds = {"npc/metropolice/vo/control100percent.wav"},
			text = "이 구역은 아무 이상이 없다, 647-E 보이지 않는다.",
		},
		{
			sounds = {"npc/metropolice/vo/rodgerthat.wav"},
			text = "알았다, 오버.",
		},
		{
			sounds = {"npc/metropolice/vo/ten4.wav"},
			text = "10-4.",
		},
		{
			sounds = {"npc/metropolice/vo/ten2.wav"},
			text = "10-2.",
		},
		{
			sounds = {"npc/metropolice/vo/ten97.wav"},
			text = "10-97.",
		},
		{
			sounds = {"npc/metropolice/vo/affirmative.wav"},
			text = "알았다.",
		},
		{
			sounds = {"npc/metropolice/vo/affirmative2.wav"},
			text = "알았다.",
		}
	},
	cto_discovery = {
		{
			-- "catchthatbliponstabilization"
			sounds = {"npc/metropolice/vo/catchthatbliponstabilization.wav"},
			text = "기기에 포착된 범죄 현장을 소탕하라.",
		},
		{
			-- "pickingupnoncorplexindy"
			sounds = {"npc/metropolice/vo/pickingupnoncorplexindy.wav"},
			text = "비중앙 기지 신호가 잡히고 있다.",
		}
	},
	assault = {
		-- Standoff Begin (Leader)
		{
			sounds = {"npc/metropolice/vo/holdthisposition.wav"},
			text = "보호 기동대, 이 위치를 사수하라.",
			filter = function(speaker) return PLUGIN:IsSquadLeader(speaker) end,
			-- "보호 기동대, 이 위치를 사수하라."
		},
		{
			sounds = {"npc/metropolice/vo/lockyourposition.wav"},
			text = "모든 병력, 위치를 사수하라!",
			filter = function(speaker) return PLUGIN:IsSquadLeader(speaker) end,
			-- "모든 병력, 위치를 사수하라!"
		},
		{
			sounds = {"npc/metropolice/vo/allunitsmaintainthiscp.wav"},
			text = "모든 병력, 이 CP 사수하라!",
			filter = function(speaker) return PLUGIN:IsSquadLeader(speaker) end,
			-- "모든 병력, 이 CP 사수하라!"
		},
	},
	incoming = {
		-- Standoff End (Leader)
		{
			sounds = {"npc/metropolice/vo/cpiscompromised.wav"},
			text = "CP 연루돼 있다, 지원하라!",
			filter = function(speaker) return PLUGIN:IsSquadLeader(speaker) end,
		},
		-- Force Cover (Any)
		{
			sounds = {"npc/metropolice/vo/officerunderfiretakingcover.wav"},
			text = "공격받고 있다, 엄폐한다!",
		},
		{
			sounds = {"npc/metropolice/vo/movingtocover.wav"},
			text = "엄호 위치로 이동한다!",
		},
		{
			sounds = {"npc/metropolice/vo/takecover.wav"},
			text = "엄폐하라!",
		},
	},
	flank = {
		-- Regular unit reports (Rally/Assault points)
		{
			sounds = {"npc/metropolice/vo/inposition.wav"},
			layout = {"designation", "text"},
			useDesignation = true,
			useNumber = true,
			text = "준비됐다.",
			-- "유니온 3. 준비됐다."
		},
		{
			sounds = {"npc/metropolice/vo/atcheckpoint.wav"},
			layout = {"designation", "text"},
			useDesignation = true,
			useNumber = true,
			text = "검문소.",
			-- "유니온 3. 검문소."
		},
		{
			sounds = {"npc/metropolice/vo/isreadytogo.wav"},
			layout = {"designation", "text"},
			useDesignation = true,
			useNumber = true,
			text = "준비가 됐다.",
			-- "유니온 3. 준비가 됐다."
		},
		{
			sounds = {"npc/metropolice/vo/readytojudge.wav"},
			layout = {"designation", "text"},
			useDesignation = true,
			useNumber = true,
			text = "판결 준비 완료.",
			-- "유니온 3. 판결 준비 완료."
		},
		{
			sounds = {"npc/metropolice/vo/inpositiononeready.wav"},
			layout = {"designation", "text"},
			useDesignation = true,
			useNumber = true,
			text = "위치로, 준비 됐다.",
			-- "유니온 3. 위치로, 준비 됐다."
		},
		-- Peek (Any)
		{
			sounds = {"npc/metropolice/vo/goingtotakealook.wav"},
			text = "살펴보고 오겠다!",
		},
		{
			sounds = {"npc/metropolice/vo/acquiringonvisual.wav"},
			text = "용의자 포착됐다!",
		},
		-- Leader commands
		{
			sounds = {"npc/metropolice/vo/isgo.wav"},
			layout = {"designation", "text"},
			useDesignation = true,
			useNumber = true,
			text = "허가한다.",
			filter = function(speaker) return PLUGIN:IsSquadLeader(speaker) end,
			-- "디펜더 1. 허가한다."
		},
		{
			sounds = {"npc/metropolice/vo/proceedtocheckpoints.wav"},
			text = "지명된 검문소로 이동하라.",
			filter = function(speaker) return PLUGIN:IsSquadLeader(speaker) end
		},
		{
			sounds = {"npc/metropolice/vo/allunitscloseonsuspect.wav"},
			text = "모든 병력, 용의자에 접근하라!",
			filter = function(speaker) return PLUGIN:IsSquadLeader(speaker) end
		},
		{
			sounds = {"npc/metropolice/vo/allunitsmovein.wav"},
			text = "모든 병력, 진입하라!",
			filter = function(speaker) return PLUGIN:IsSquadLeader(speaker) end
		},
		{
			sounds = {"npc/metropolice/vo/teaminpositionadvance.wav"},
			text = "팀 위치 도착, 전진!",
			filter = function(speaker) return PLUGIN:IsSquadLeader(speaker) end
		},
		{
			sounds = {"npc/metropolice/vo/ptgoagain.wav"},
			text = "PT, 다시 가라.",
			filter = function(speaker) return PLUGIN:IsSquadLeader(speaker) end
		},
		{
			sounds = {"npc/metropolice/vo/assaultpointsecureadvance.wav"},
			text = "습격 지점 확보, 전진하라!",
			filter = function(speaker) return PLUGIN:IsSquadLeader(speaker) end
		},
		{
			-- METROPOLICE_FLANK0: ismovingin
			sounds = {"npc/metropolice/vo/ismovingin.wav"},
			layout = {"designation", "text"},
			useDesignation = true,
			useNumber = true,
			text = "접근 중이다.",
			-- "유니온 3. 접근 중이다."
		},
		{
			-- METROPOLICE_FLANK1: covermegoingin
			sounds = {"npc/metropolice/vo/covermegoingin.wav"},
			text = "엄호하라, 들어간다!",
		},
		{
			-- METROPOLICE_FLANK2: isclosingonsuspect
			sounds = {"npc/metropolice/vo/isclosingonsuspect.wav"},
			layout = {"designation", "text"},
			useDesignation = true,
			useNumber = true,
			text = "용의자에 접근 중!",
			-- "유니온 3. 용의자에 접근 중!"
		},
		{
			-- METROPOLICE_FLANK3: converging
			sounds = {"npc/metropolice/vo/converging.wav"},
			layout = {"designation", "text"},
			useDesignation = true,
			useNumber = true,
			text = "집합 중.",
			-- "유니온 3. 집합 중."
		}
	},
	man_down = {
		{
			sounds = {"npc/metropolice/vo/wehavea10-108.wav"},
			text = "10-108 상황 발생!",
		},
		{
			sounds = {"npc/metropolice/vo/onedown.wav"},
			layout = {"victimDesignation", "text"},
			usesVictim = true,
			text = "사상자 발생!",
			-- "유니온 3. 사상자 발생."
		},
		{
			sounds = {"npc/metropolice/vo/wehavea10-108.wav"},
			layout = {"victimDesignation", "text"},
			usesVictim = true,
			text = "10-108 상황 발생!",
			-- "유니온 3. 10-108 발생."
		},
		{
			sounds = {"npc/metropolice/vo/establishnewcp.wav"},
			text = "후퇴하라, 새 CP를 구축하라!",
			filter = function(speaker) return PLUGIN:IsSquadLeader(speaker) end,
		},
	},
	lastSquad = {
		{
			sounds = {"npc/metropolice/vo/officerdowncode3tomy10-20.wav"},
			text = "경찰이 쓰러졌다, 모든 병력은 10-20으로!",
		},
		{
			sounds = {"npc/metropolice/vo/officerdownIam10-99.wav"},
			text = "경찰이 쓰러졌다, 여기는 10-99!",
		},
		{
			sounds = {"npc/metropolice/vo/cpisoverrunwehavenocontainment.wav"},
			text = "CP가 침략되었다, 봉쇄가 무너졌다!",
		},
	},
	physics_hit = {
		{
			sounds = {"npc/metropolice/vo/preparingtojudge10-107.wav"},
			text = "10-107, 판결을 준비 중이다.",
		},
		{
			sounds = {"npc/metropolice/vo/movebackrightnow.wav"},
			text = "즉시 물러나라!",
		},
		{
			sounds = {"npc/metropolice/vo/holditrightthere.wav"},
			text = "거기서 멈춰라!",
		},
		{
			sounds = {"npc/metropolice/vo/malcompliant10107my1020.wav"},
			text = "10-20에서 10-107의 불순종, 구속 진행.",
		},
	},
	freeze = {
		{
			sounds = {"npc/metropolice/vo/holditrightthere.wav"},
			text = "거기 정지하라!",
		},
		{
			sounds = {"npc/metropolice/vo/prepareforjudgement.wav"},
			text = "판결을 준비하라.",
		},
	},
	arrest_answer = {
		{
			sounds = {"npc/metropolice/vo/movetoarrestpositions.wav"},
			text = "전원 구속 위치로 이동하라.",
		},
		{
			sounds = {"npc/metropolice/vo/positiontocontain.wav"},
			text = "포위 위치를 사수하라.",
		},
		{
			sounds = {"npc/metropolice/vo/preparefor1015.wav"},
			text = "구속을 준비하라, 10-15.",
		},
	},
	suspect_running = {
		{
			sounds = {"npc/metropolice/vo/hesrunning.wav"},
			text = "대상이 도주하고 있다!",
		},
		{
			sounds = {"npc/metropolice/vo/hesgone148.wav"},
			text = "대상 10-148, 추격을 시작한다.",
		},
	},
	arrest = {
		{
			sounds = {"npc/metropolice/vo/inposition.wav"},
			layout = {"designation", "text"},
			useDesignation = true,
			useNumber = true,
			text = "위치 확보 완료.",
		},
		{
			sounds = {"npc/metropolice/vo/readytoprosecute.wav"},
			layout = {"designation", "text"},
			useDesignation = true,
			useNumber = true,
			text = "기소 준비 완료.",
		},
	},
	player_hit = {
		{
			-- HIT0: wegotadbherecancel10-102
			sounds = {"npc/metropolice/vo/wegotadbherecancel10-102.wav"},
			text = "시체 발견, 11-42 취소하라.",
		},
		{
			-- HIT1: suspectisbleeding
			sounds = {"npc/metropolice/vo/suspectisbleeding.wav"},
			text = "용의자, 상처 입고 피를 흘리고 있다!"
		},
		{
			-- HIT2: V_G2_SUSPECT_MAP__P ispassive
			sounds = {"npc/metropolice/vo/ispassive.wav"},
			layout = {"target", "text"},
			usesTarget = true,
			text = "반응이 없다.",
			-- "대상, 반응이 없다."
		},
		{
			-- HIT3: readytoamputate V_G2_SUSPECT_MAP__P
			sounds = {"npc/metropolice/vo/readytoamputate.wav"},
			layout = {"text", "target", "suffix"},
			usesTarget = true,
			text = "절단 준비 완료,",
			suffix = ".",
			-- "절단 준비 완료, 대상."
		},
		{
			-- HIT4: get11-44inboundcleaningup
			sounds = {"npc/metropolice/vo/get11-44inboundcleaningup.wav"},
			text = "11-44 데려와라, 지금 소탕한다."
		},
	},
	reload = {
		{
			-- COVER_NO_AMMO0: backmeupImout
			sounds = {"npc/metropolice/vo/backmeupImout.wav"},
			text = "엄호하라, 나간다!",
		},
		{
			-- COVER_LOW_AMMO0: runninglowonverdicts
			sounds = {"npc/metropolice/vo/runninglowonverdicts.wav"},
			text = "실탄이 부족하다, 엄폐하겠다!"
		}
	},
	shoot_cover = {
		{
			-- METROPOLICE_SHOOT_COVER0: breakhiscover
			sounds = {"npc/metropolice/vo/breakhiscover.wav"},
			text = "엄폐물 제거하라!",
		},
		{
			-- METROPOLICE_SHOOT_COVER1: destroythatcover
			sounds = {"npc/metropolice/vo/destroythatcover.wav"},
			text = "엄폐물 파괴하라!",
		},
		{
			-- METROPOLICE_SHOOT_COVER2: firingtoexposetarget
			sounds = {"npc/metropolice/vo/firingtoexposetarget.wav"},
			text = "목표를 향해 쏴라!",
		},
		{
			-- METROPOLICE_SHOOT_COVER3: firetodislocateinterpose
			sounds = {"npc/metropolice/vo/firetodislocateinterpose.wav"},
			text = "사이를 쏴서 힘을 분산시켜라!",
		}
	},
}

local TEMPLATE_SETS = {
	combine = COMBINE_TEMPLATE_SETS,
	metropolice = MPF_TEMPLATE_SETS
}

local COMBINE_CALLSIGN_KEYS = {
	-- soldier names:
	LEADER = "리더",
	FLASH = "플래시",
	RANGER = "레인저",
	HUNTER = "헌터",
	BLADE = "블레이드",
	SCAR = "스카",
	HAMMER = "해머",
	SWEEPER = "스위퍼",
	SWIFT = "스위프트",
	FIST = "피스트",
	SWORD = "소드",
	SAVAGE = "새비지",
	TRACKER = "트래커",
	SLASH = "슬래시",
	RAZOR = "레이저",
	STAB = "스탭",
	SPEAR = "스피어",
	STRIKER = "스트라이커",
	DAGGER = "대거",

	-- air support names:
	GHOST = "고스트",
	REAPER = "리퍼",
	NOMAD = "노매드",
	HURRICANE = "허리케인",
	PHANTOM = "팬텀",
	JUDGE = "저지",
	SHADOW = "섀도",
	SLAM = "슬램",
	STINGER = "스팅어",
	STORM = "스톰",
	VAMP = "뱀프",
	WINDER = "와인더",
	STAR = "스타",

	-- phonetic alphabet/codes:
	APEX = "에이펙스",
	ION = "이온",
	JET = "제트",
	KILO = "킬로",
	MACE = "메이스",
	NOVA = "노바",
	PAYBACK = "페이백",
	SUNDOWN = "선다운",
	UNIFORM = "유니폼",
	BOOMER = "부머",
	ECHO = "에코",
	FLATLINE = "플랫라인",
	HELIX = "헬릭스",
	ICE = "아이스",
	QUICKSAND = "퀵샌드",
	RIPCORD = "립코드",

	-- metropolice unit names:
	DEFENDER = "디펜더",
	HERO = "히어로",
	JURY = "주리",
	KING = "킹",
	LINE = "라인",
	PATROL = "패트롤",
	QUICK = "퀵",
	ROLLER = "롤러",
	STICK = "스틱",
	TAP = "탭",
	UNION = "유니온",
	VICTOR = "빅터",
	XRAY = "엑스레이",
	YELLOW = "옐로우",
	VICE = "바이스"
}

-- Faction registration and server initialization is now handled in sh_plugin.lua

function PLUGIN:IsVoicePluginAvailable()
	return self.ixVoicePlugin != nil
end

function PLUGIN:AssignAreaSectors()
	if (!ix.area or !ix.area.stored) then
		return
	end

	local areaIDs = {}

	for areaID in pairs(ix.area.stored) do
		areaIDs[#areaIDs + 1] = areaID
	end

	table.sort(areaIDs, function(a, b)
		return tostring(a) < tostring(b)
	end)

	local usedSectors = {}
	local nameToSector = {}
	local needsSave = false

	for _, areaID in ipairs(areaIDs) do
		local area = ix.area.stored[areaID]
		local properties = area and area.properties or nil
		local areaName = tostring((properties and properties.name) or areaID or "")
		local sector_index = self:GetAreaSectorNumber(areaID)

		if (sector_index) then
			usedSectors[sector_index] = true

			if (areaName != "") then
				nameToSector[areaName] = nameToSector[areaName] or sector_index
			end
		end
	end

	local nextSector = 1

	for _, areaID in ipairs(areaIDs) do
		local area = ix.area.stored[areaID]

		if (!area) then
			continue
		end

		area.properties = area.properties or {}

		if (!self:GetAreaSectorNumber(areaID)) then
			local areaName = tostring(area.properties.name or areaID or "")
			local sharedSector = areaName != "" and nameToSector[areaName] or nil

			if (sharedSector) then
				area.properties.sector_index = sharedSector
			else
				while (usedSectors[nextSector]) do
					nextSector = nextSector + 1
				end

				area.properties.sector_index = nextSector
				usedSectors[nextSector] = true
				nameToSector[areaName] = nextSector
				nextSector = nextSector + 1
			end
			needsSave = true
		end
	end

	if (needsSave) then
		local areaPlugin = ix.plugin.list["area"]

		if (areaPlugin and areaPlugin.SaveData) then
			areaPlugin:SaveData()
		end
	end
end

function PLUGIN:GetVoiceType(client)
	if (!IsValid(client)) then
		return nil
	end

	for uniqueID, data in pairs(self.voiceTypes or {}) do
		if (data.factions and data.factions[client:Team()]) then
			return uniqueID, data
		end
	end
end

-- Efficiently handles a prop colliding with a link-connected unit
function PLUGIN:HandlePropCollision(prop, data)
	local target = data.HitEntity
	if (!IsValid(target) or !target:IsPlayer()) then return end
	if (!self:IsConnectedToLink(target) or !self:CanAutoVoice(target)) then return end

	-- Check for impact speed to avoid reacting to static props/nudges
	if (data.OurOldVelocity:Length() < PHYSICS_COLLIDE_MIN_SPEED) then return end

	-- Hostile check (Optional, but usually we want to react if anyone throws something at us)
	-- To keep it simple as requested, we just look at the impact.
	if (self:CanUsePlayerCooldown(target, "physics_hit", 10)) then
		local event = self:BuildTemplateEvent(target, "physics_hit")
		if (event) then
			self:EmitVoiceEvent(target, event.text, event.sounds, 75, event.forceLocal, event.isCheck)
		end
	end
end

function PLUGIN:IsConnectedToLink(client)
	if (!IsValid(client) or !client:IsPlayer() or !client:Alive()) then return false end
	if (!client:IsCombine() or !Schema:CanPlayerSeeCombineOverlay(client)) then return false end

	-- Ensure character has an active biosignal if CTO plugin is present
	if (ix.plugin.Get("cto") and client:GetNetVar("IsBiosignalGone", false)) then
		return false
	end

	return true
end

function PLUGIN:CanAutoVoice(client)
	if (!self:IsVoicePluginAvailable() or !self:IsConnectedToLink(client)) then
		return false
	end

	if (client:GetMoveType() == MOVETYPE_NOCLIP or client:IsRagdoll()) then
		return false
	end

	if (!client:GetCharacter() or ix.option.Get(client, "ixCalloutClientEnabled", true) == false) then
		return false
	end

	local voiceType = self:GetVoiceType(client)

	if (client.ixVoiceBusy and client.ixVoiceBusy > CurTime()) then
		return false
	end

	return true
end

function PLUGIN:GetPlayerVoicePriority(client)
	if (!self:CanAutoVoice(client)) then
		return 0
	end

	local _, info = Schema:GetCombineUnitID(client)

	if (info and info.callsign == "LEADER") then
		return 2
	end

	return 1
end

function PLUGIN:CanUsePlayerCooldown(client, key, delay)
	self.playerCooldowns[client] = self.playerCooldowns[client] or {}

	local currentTime = CurTime()
	local nextUse = self.playerCooldowns[client][key] or 0

	if (nextUse > currentTime) then
		return false
	end

	self.playerCooldowns[client][key] = currentTime + (delay or PLAYER_COOLDOWN)

	return true
end

function PLUGIN:GetVoiceInfo(className, key)
	local classData = Schema.voices.stored[string.lower(className or "")]

	if (!classData) then
		return nil
	end

	return classData[string.lower(key or "")]
end

function PLUGIN:GetVoiceSound(className, key)
	local info = self:GetVoiceInfo(className, key)

	if (!info) then
		return nil
	end

	if (info.table) then
		local selected = table.Random(info.table)

		return istable(selected) and selected[2] or nil
	end

	if (istable(info.sound)) then
		return table.Random(info.sound)
	end

	return info.sound
end

function PLUGIN:GetVoiceText(className, key)
	local info = self:GetVoiceInfo(className, key)

	if (!info) then
		return nil
	end

	if (info.table) then
		local selected = table.Random(info.table)

		return istable(selected) and selected[1] or nil
	end

	return info.text
end

function PLUGIN:GetGridNumbers(position)
	position = position or vector_origin

	return math.Round(position.x / 100), math.Round(position.y / 100)
end

function PLUGIN:BuildNumberSounds(value)
	local sounds = {}
	local val = math.floor(math.abs(tonumber(value) or 0))

	if (val == 0) then
		local sound = self:GetVoiceSound("Combine", "0")
		if (sound) then sounds[#sounds + 1] = sound end
		return sounds
	end

	-- Hundreds (100, 200, 300)
	if (val >= 100) then
		local hundreds = math.floor(val / 100) * 100
		local sound = self:GetVoiceSound("Combine", tostring(hundreds))

		if (sound) then
			sounds[#sounds + 1] = sound
			val = val % 100
		end
	end

	-- Tens and Units
	if (val > 0) then
		if (val <= 19) then
			-- Direct match for 1-19
			local sound = self:GetVoiceSound("Combine", tostring(val))

			if (sound) then
				sounds[#sounds + 1] = sound
			else
				-- Fallback to individual digits if the specific teen sound is missing
				local sVal = tostring(val)
				for i = 1, #sVal do
					local digit = sVal:sub(i, i)
					local dSound = self:GetVoiceSound("Combine", digit)
					if (dSound) then sounds[#sounds + 1] = dSound end
				end
			end
		else
			-- Handle 20-99
			local tens = math.floor(val / 10) * 10
			local units = val % 10

			local tensSound = self:GetVoiceSound("Combine", tostring(tens))
			if (tensSound) then
				sounds[#sounds + 1] = tensSound
			end

			if (units > 0) then
				local unitsSound = self:GetVoiceSound("Combine", tostring(units))
				if (unitsSound) then
					sounds[#sounds + 1] = unitsSound
				end
			end
		end
	end

	return sounds
end

function PLUGIN:GetCombineDesignationParts(client)
	local _, info = Schema:GetCombineUnitID(client)

	if (!info) then
		return nil, nil, nil
	end

	local callsignKey = COMBINE_CALLSIGN_KEYS[info.callsign]
	local callsignSound = callsignKey and self:GetVoiceSound("Combine", callsignKey) or nil
	local callsignText = callsignKey and self:GetVoiceText("Combine", callsignKey) or info.callsign
	if (callsignText) then callsignText = string.TrimRight(string.Trim(callsignText), ".,") end
	local numberSounds = self:BuildNumberSounds(info.number or 0)

	return {
		sound = callsignSound,
		text = callsignText
	}, numberSounds, info
end

function PLUGIN:FormatCombineDesignation(callsignText, number)
	callsignText = string.Trim(tostring(callsignText or ""))
	callsignText = string.TrimRight(callsignText, ".")

	if (callsignText == "") then
		return number and tostring(number) .. "." or ""
	end

	if (number == nil) then
		return callsignText
	end

	return string.format("%s %s.", callsignText, tostring(number))
end

function PLUGIN:BuildTemplateEvent(client, templateName, context)
	local vType = self:GetVoiceType(client)
	local templateSet = (vType and TEMPLATE_SETS[vType]) or COMBINE_TEMPLATE_SETS
	local templates = templateSet[templateName]

	if (!istable(templates) or #templates == 0) then
		return nil
	end

	local currentTheme = (vType == "metropolice") and self:GetMPFThemeName(client) or nil
	local variant = nil
	local forcedIndex = context and context.forcedIndex

	if (forcedIndex and templates[forcedIndex]) then
		variant = templates[forcedIndex]
	else
		local specificTemplates = {}
		local genericTemplates = {}
		local target = context and context.target

		for _, v in ipairs(templates) do
			-- Theme check first
			if (v.requiredTheme and (!currentTheme or v.requiredTheme != currentTheme)) then
				continue
			end

			if (v.filter) then
				if (v.filter(client, target)) then
					specificTemplates[#specificTemplates + 1] = v
				end
			else
				genericTemplates[#genericTemplates + 1] = v
			end
		end

		-- Priority: Specific (Filtered) > Generic (Unfiltered)
		local eligibleTemplates = {}
		if (#specificTemplates > 0) then
			eligibleTemplates = specificTemplates
		else
			eligibleTemplates = genericTemplates
		end

		variant = table.Random(eligibleTemplates)
	end

	if (!variant) then
		return nil
	end

	local sequence = {}
	local parts = {}

	local handlers
	handlers = {
		designation = function()
			if (variant.useDesignation == true) then
				local name, num, info = self:GetCombineDesignationParts(client)

				if (name) then
					sequence[#sequence + 1] = name.sound
					parts[#parts + 1] = name.text .. (num and "" or ",")

					if (num) then
						for _, soundPath in ipairs(num) do
							sequence[#sequence + 1] = soundPath
						end
						parts[#parts + 1] = tostring(info and info.number or 0) .. "."
					end
				end
			end
		end,
		text = function()
			if (variant.sounds) then
				for _, soundPath in ipairs(variant.sounds) do
					sequence[#sequence + 1] = soundPath
				end
			end

			if (variant.text) then
				parts[#parts + 1] = variant.text
			end
		end,
		V_G0_PLAYERS = function()
			if (variant.usesTarget and context and IsValid(context.target)) then
				local target = context.target

				if (target:IsPlayer()) then
					if (target:IsCombine()) then
						local name, num, targetInfo = self:GetCombineDesignationParts(target)

						if (name) then
							sequence[#sequence + 1] = name.sound
							parts[#parts + 1] = name.text

							if (num) then
								for _, soundPath in ipairs(num) do
									sequence[#sequence + 1] = soundPath
								end
								parts[#parts + 1] = tostring(targetInfo and targetInfo.number or 0)
							end
						end
					else
						local choices = {}
						local enemyType = self:GetEnemyType(target)

						if (enemyType == "freeman") then
							if (vType == "metropolice") then
								choices = {
									{sound = "npc/metropolice/vo/freeman.wav", text = "프리맨"}
								}
							else
								choices = {
									{sound = "npc/combine_soldier/vo/freeman3.wav", text = "프리맨"},
									{sound = "npc/combine_soldier/vo/anticitizenone.wav", text = "반시민 1"},
									{sound = "npc/combine_soldier/vo/priority1objective.wav", text = "1번 임무 목표 완수"}
								}
							end
						elseif (vType == "metropolice") then
							local theme = self:GetMPFMapChoices(client)
							choices = theme.suspects
							
							if (!choices or #choices == 0) then
								choices = MPF_MAP_THEMES[0].suspects
							end
						else
							choices = {
								{sound = "npc/combine_soldier/vo/outbreak.wav", text = "확산"},
								{sound = "npc/metropolice/vo/anticitizen.wav", text = "반시민"},
								{sound = "vj_hlr/src/npc/combine_soldier/noncitizen.wav", text = "비시민"}
							}
						end

						local choice = table.Random(choices)

						sequence[#sequence + 1] = choice.sound
						parts[#parts + 1] = choice.text
					end
				elseif (target:IsNPC()) then
					local class = target:GetClass():lower()

					if (class:find("zombie") or class == "npc_zombine") then
						local choices = {
							{sound = "npc/combine_soldier/vo/necrotics.wav", text = "변종"},
							{sound = "npc/metropolice/vo/infected.wav", text = "감염"}
						}
						local choice = table.Random(choices)

						sequence[#sequence + 1] = choice.sound
						parts[#parts + 1] = choice.text
					elseif (class:find("antlion") or class:find("headcrab")) then
						sequence[#sequence + 1] = "npc/combine_soldier/vo/exogens.wav"
						parts[#parts + 1] = "엑소젠"
					else
						local choices
						if (vType == "metropolice") then
							local theme = self:GetMPFMapChoices(client)
							choices = theme.suspects
							
							if (!choices or #choices == 0) then
								choices = MPF_MAP_THEMES[0].suspects
							end
						else
							choices = {
								{sound = "npc/combine_soldier/vo/outbreak.wav", text = "확산"},
								{sound = "npc/metropolice/vo/anticitizen.wav", text = "반시민"},
								{sound = "vj_hlr/src/npc/combine_soldier/noncitizen.wav", text = "비시민"}
							}
						end

						local choice = table.Random(choices)

						sequence[#sequence + 1] = choice.sound
						parts[#parts + 1] = choice.text
					end
				end

				-- If follow-up information follows, automatically add a period after target if no custom suffix is specified.
				local hasFollowup = (variant.suffix and variant.suffix != "") or variant.usesDistance or variant.usesBearing or variant.usesGrid or variant.usesSector or variant.usesVictim
				local targetSuffix = variant.targetSuffix or (hasFollowup and ".")
				if (targetSuffix) then
					parts[#parts] = parts[#parts] .. targetSuffix
				end
			end
		end,
		target = function()
			-- Alias to V_G0_PLAYERS
			handlers.V_G0_PLAYERS()
		end,
		V_DISTS = function()
			if (variant.usesDistance and context and IsValid(context.target)) then
				local distance = math.Round(client:GetPos():Distance(context.target:GetPos()) / 50)

				if (variant.distancePrefixSounds) then
					for _, soundPath in ipairs(variant.distancePrefixSounds) do
						sequence[#sequence + 1] = soundPath
					end
				end

				for _, soundPath in ipairs(self:BuildNumberSounds(distance)) do
					sequence[#sequence + 1] = soundPath
				end

				if (variant.distanceSuffixSounds) then
					for _, soundPath in ipairs(variant.distanceSuffixSounds) do
						sequence[#sequence + 1] = soundPath
					end
				else
					sequence[#sequence + 1] = "npc/combine_soldier/vo/meters.wav"
				end

				local distStr = tostring(distance) .. (variant.distanceSuffix or "미터")
				if (variant.distancePrefix) then
					parts[#parts + 1] = variant.distancePrefix
				end
				parts[#parts + 1] = distStr
			end
		end,
		distance = function()
			-- Alias to V_DISTS
			handlers.V_DISTS()
		end,
		V_DIRS = function()
			if (variant.usesBearing and context and IsValid(context.target)) then
				local bearing = math.Round((context.target:GetPos() - client:GetPos()):Angle().y)
				if (bearing < 0) then bearing = bearing + 360 end

				if (variant.bearingPrefixSounds) then
					for _, soundPath in ipairs(variant.bearingPrefixSounds) do
						sequence[#sequence + 1] = soundPath
					end
				end

				for _, soundPath in ipairs(self:BuildNumberSounds(bearing)) do
					sequence[#sequence + 1] = soundPath
				end

				if (variant.bearingSuffixSounds) then
					for _, soundPath in ipairs(variant.bearingSuffixSounds) do
						sequence[#sequence + 1] = soundPath
					end
				else
					sequence[#sequence + 1] = "npc/combine_soldier/vo/degrees.wav"
				end

				local bearingStr = tostring(bearing) .. (variant.bearingSuffix or "도")
				if (variant.bearingPrefix) then
					parts[#parts + 1] = variant.bearingPrefix
				end
				parts[#parts + 1] = bearingStr
			end
		end,
		bearing = function()
			-- Alias to V_DIRS
			handlers.V_DIRS()
		end,
		gridX = function()
			if (variant.usesGrid and context and IsValid(context.target)) then
				local pos = context.target:GetPos()
				local x = math.abs(math.Round(pos.x / 1000))

				for _, soundPath in ipairs(self:BuildNumberSounds(x)) do
					sequence[#sequence + 1] = soundPath
				end

				parts[#parts + 1] = tostring(x)
			end
		end,
		gridY = function()
			if (variant.usesGrid and context and IsValid(context.target)) then
				local pos = context.target:GetPos()
				local y = math.abs(math.Round(pos.y / 1000))

				for _, soundPath in ipairs(self:BuildNumberSounds(y)) do
					sequence[#sequence + 1] = soundPath
				end

				parts[#parts + 1] = tostring(y)
			end
		end,
		dash = function()
			sequence[#sequence + 1] = "npc/combine_soldier/vo/dash.wav"
			parts[#parts + 1] = "-"
		end,
		grid = function()
			if (variant.usesGrid and context and IsValid(context.target)) then
				local pos = context.target:GetPos()
				local x = math.abs(math.Round(pos.x / 1000))
				local y = math.abs(math.Round(pos.y / 1000))

				for _, soundPath in ipairs(self:BuildNumberSounds(x)) do
					sequence[#sequence + 1] = soundPath
				end

				sequence[#sequence + 1] = "npc/combine_soldier/vo/dash.wav"

				for _, soundPath in ipairs(self:BuildNumberSounds(y)) do
					sequence[#sequence + 1] = soundPath
				end

				parts[#parts + 1] = string.format("%d-%d", x, y)
			end
		end,
		sectorLabel = function()
			if (variant.usesSector) then
				if (vType == "metropolice") then
					local theme = self:GetMPFMapChoices(client)
					local choice = table.Random(theme.locations)

					if (choice) then
						sequence[#sequence + 1] = choice.sound
						parts[#parts + 1] = choice.text
					else
						parts[#parts + 1] = "구역"
					end
				else
					local label = self:GetAreaSectorLabel(client:GetArea()) or "구역"
					parts[#parts + 1] = label
				end
			end
		end,
		V_SECTORS = function()
			if (variant.usesSector) then
				local num = self:GetAreaSectorNumber(client:GetArea())

				if (num) then
					local sectorSounds = self:BuildNumberSounds(num)

					for _, soundPath in ipairs(sectorSounds) do
						sequence[#sequence + 1] = soundPath
					end

					parts[#parts + 1] = tostring(num)
				end
			end
		end,
		sectorNumber = function()
			-- Alias to V_SECTORS
			handlers.V_SECTORS()
		end,
		victimDesignation = function()
			if (variant.usesVictim and context and IsValid(context.target)) then
				local name, num = self:GetCombineDesignationParts(context.target)

				if (name) then
					sequence[#sequence + 1] = name.sound
					parts[#parts + 1] = name.text
				end
			end
		end,
		seqGlobNbrs = function()
			if (variant.usesKills) then
				local kills = client.ixVoiceKills or 1
				-- Limit to safe range (if somehow more than 9, just say 9)
				if (kills > 9) then kills = 9 end
				
				for _, soundPath in ipairs(self:BuildNumberSounds(kills)) do
					sequence[#sequence + 1] = soundPath
				end
				parts[#parts + 1] = tostring(kills)
				
				-- Reset the counter after we explicitly declare recent kills.
				client.ixVoiceKills = 0
			end
		end,
		rndNames = function()
			local names = {
				{sound = "npc/combine_soldier/vo/ghost.wav", text = "고스트"},
				{sound = "npc/combine_soldier/vo/reaper.wav", text = "리퍼"},
				{sound = "npc/combine_soldier/vo/nomad.wav", text = "노매드"},
				{sound = "npc/combine_soldier/vo/hurricane.wav", text = "허리케인"},
				{sound = "npc/combine_soldier/vo/phantom.wav", text = "팬텀"},
				{sound = "npc/combine_soldier/vo/judge.wav", text = "저지"},
				{sound = "npc/combine_soldier/vo/shadow.wav", text = "섀도"},
				{sound = "npc/combine_soldier/vo/slam.wav", text = "슬램"},
				{sound = "npc/combine_soldier/vo/stinger.wav", text = "스팅어"},
				{sound = "npc/combine_soldier/vo/storm.wav", text = "스톰"},
				{sound = "npc/combine_soldier/vo/vamp.wav", text = "뱀프"},
				{sound = "npc/combine_soldier/vo/winder.wav", text = "와인더"},
				{sound = "npc/combine_soldier/vo/star.wav", text = "스타"}
			}
			local choice = names[math.random(#names)]
			sequence[#sequence + 1] = choice.sound
			parts[#parts + 1] = choice.text
		end,
		rndCodes = function()
			local codes = {
				{sound = "npc/combine_soldier/vo/apex.wav", text = "에이펙스"},
				{sound = "npc/combine_soldier/vo/ion.wav", text = "이온"},
				{sound = "npc/combine_soldier/vo/jet.wav", text = "제트"},
				{sound = "npc/combine_soldier/vo/kilo.wav", text = "킬로"},
				{sound = "npc/combine_soldier/vo/mace.wav", text = "메이스"},
				{sound = "npc/combine_soldier/vo/nova.wav", text = "노바"},
				{sound = "npc/combine_soldier/vo/payback.wav", text = "페이백"},
				{sound = "npc/combine_soldier/vo/sundown.wav", text = "선다운"},
				{sound = "npc/combine_soldier/vo/uniform.wav", text = "유니폼"},
				{sound = "npc/combine_soldier/vo/boomer.wav", text = "부머"},
				{sound = "npc/combine_soldier/vo/echo.wav", text = "에코"},
				{sound = "npc/combine_soldier/vo/flatline.wav", text = "플랫라인"},
				{sound = "npc/combine_soldier/vo/helix.wav", text = "헬릭스"},
				{sound = "npc/combine_soldier/vo/ice.wav", text = "아이스"},
				{sound = "npc/combine_soldier/vo/quicksand.wav", text = "퀵샌드"},
				{sound = "npc/combine_soldier/vo/ripcord.wav", text = "립코드"}
			}
			local choice = codes[math.random(#codes)]
			sequence[#sequence + 1] = choice.sound
			parts[#parts + 1] = choice.text
		end,
		rndNums = function()
			local num = math.random(1, 9)
			for _, soundPath in ipairs(self:BuildNumberSounds(num)) do
				sequence[#sequence + 1] = soundPath
			end
			parts[#parts + 1] = tostring(num)
		end,
		suffix = function()
			if (variant.suffix and variant.suffix != "") then
				parts[#parts + 1] = variant.suffix
			end
		end
	}

	local layout = variant.layout
	
	if (!layout) then
		layout = {}
		if (variant.useDesignation) then layout[#layout + 1] = "designation" end
		layout[#layout + 1] = "text"
		if (variant.usesVictim) then layout[#layout + 1] = "victimDesignation" end
		if (variant.usesTarget) then layout[#layout + 1] = "V_G0_PLAYERS" end
		if (variant.usesDistance) then layout[#layout + 1] = "V_DISTS" end
		if (variant.usesBearing) then layout[#layout + 1] = "V_DIRS" end
		if (variant.usesGrid) then layout[#layout + 1] = "grid" end
		if (variant.usesSector) then 
			layout[#layout + 1] = "sectorLabel"
			layout[#layout + 1] = "V_SECTORS"
		end
		if (variant.usesKills) then layout[#layout + 1] = "seqGlobNbrs" end
		if (variant.suffix) then layout[#layout + 1] = "suffix" end
	end

	for _, key in ipairs(layout) do
		if (handlers[key]) then
			handlers[key]()
		end
	end

	if (#sequence == 0 or #parts == 0) then
		return nil
	end

	local resultText = ""
	local lastPart = ""

	for i, part in ipairs(parts) do
		if (i == 1) then
			resultText = part
		else
			-- If the current part starts with punctuation (including dash/colon), NO space
			-- OR if the PREVIOUS part was a dash, NO space (for formatting like 5-3)
			local noSpace = part:match("^[,%.!%?%-%:]") or lastPart:match("%-$")

			if (noSpace) then
				resultText = resultText .. part
			else
				resultText = resultText .. " " .. part
			end
		end

		lastPart = part
	end

	return {
		sounds = sequence,
		text = resultText,
		forceLocal = variant.forceLocal == true,
		isCheck = variant.isCheck == true
	}
end

function PLUGIN:BuildCombineSpeech(sounds)
	local sequence = {}

	for _, soundPath in ipairs(sounds) do
		if (isstring(soundPath) and soundPath != "") then
			sequence[#sequence + 1] = soundPath
		end
	end

	return sequence
end

function PLUGIN:PlayCombineSequence(client, sounds, volume, isRadioTransmission, receivers)
	if (!self:CanAutoVoice(client) or !istable(sounds) or #sounds == 0) then
		return false
	end

	local sequence = self:BuildCombineSpeech(sounds)
	local totalDuration = 0

	for _, soundPath in ipairs(sequence) do
		local duration = SoundDuration(soundPath)

		if (duration == 0) then
			-- Fallback to a default duration if SoundDuration fails on the server
			duration = 1.5
		end

		totalDuration = totalDuration + duration
	end

	client.ixVoiceBusy = CurTime() + totalDuration + 0.5
	local volume = volume or 75
	local voiceType = "combine"

	-- Primary spatial sound on the speaker
	netstream.Start(nil, "voicePlay", sequence, volume, client:EntIndex(), isRadioTransmission == true, voiceType)

	-- Secondary sounds on receivers for radio transmissions (multi-cast)
	if (isRadioTransmission and receivers) then
		local threshold = (self.ixVoicePlugin and self.ixVoicePlugin.radioNoiseDistanceSqr) or (1200 * 1200)
		local speakerPos = client:GetPos()

		for _, v in ipairs(receivers) do
			if (!IsValid(v) or v == client) then continue end

			local pos = v:GetPos()
			if (pos:DistToSqr(speakerPos) <= threshold) then
				continue -- Already audible spatially
			end

			-- Relay sound through the receiver's entity index (sounds like it's coming from their radio)
			netstream.Start(nil, "voicePlay", sequence, volume * 0.45, v:EntIndex(), true, voiceType)
		end
	end

	return true
end

function PLUGIN:GetActiveRadioState(client)
	local character = client:GetCharacter()

	if (!character) then
		return nil
	end

	local inventory = character:GetInventory()

	if (!inventory) then
		return nil
	end

	local items = inventory:GetItems()
	local enabledRadio

	for _, item in pairs(items) do
		-- Check if the item is a radio (standard handheld or radio_extended based)
		if (item.uniqueID == "handheld_radio" or item.radiotypes or item.isRadio) then
			if (item:GetData("enabled", false)) then
				enabledRadio = enabledRadio or item

				if (item:GetData("active", false)) then
					-- If currently scanning channels, only allow broadcast if specifically enabled
					if (item:GetData("scanning", false) and !item:GetData("broadcast", false)) then
						continue
					end

					local frequency = character:GetData("frequency", item:GetData("frequency", "100.0"))

					if (!frequency or frequency == "") then
						continue
					end

					return {
						freq = frequency,
						chan = character:GetData("channel", item:GetData("channel", "1")),
						broadcast = item:GetData("broadcast", false),
						walkie = item.walkietalkie == true,
						lrange = item.longrange == true,
						quiet = item:GetData("silenced", false),
						callsign = ix.config.Get("enableCallsigns", true) and character:GetData("callsign", client:Name()) or nil
					}
				end
			end
		end
	end

	-- Fallback to the first enabled radio if no active one is found
	if (enabledRadio) then
		local frequency = character:GetData("frequency", enabledRadio:GetData("frequency", "100.0"))

		if (frequency and frequency != "") then
			return {
				freq = frequency,
				chan = character:GetData("channel", enabledRadio:GetData("channel", "1")),
				broadcast = false,
				walkie = enabledRadio.walkietalkie == true,
				lrange = enabledRadio.longrange == true,
				quiet = enabledRadio:GetData("silenced", false),
				callsign = nil
			}
		end
	end

	return nil
end

function PLUGIN:HasNearbyCombineICListener(client)
	local range = ix.config.Get("chatRange", IC_RANGE)
	local rangeSqr = range * range
	local origin = client:GetPos()

	for _, target in ipairs(player.GetAll()) do
		if (target == client or !IsValid(target) or !target:IsPlayer()) then
			continue
		end

		if (!target:Alive() or target:IsRagdoll()) then
			continue
		end

		if (origin:DistToSqr(target:GetPos()) <= rangeSqr) then
			return true
		end
	end

	return false
end

function PLUGIN:SendChatForVoice(client, text, radioData)
	if (!isstring(text) or text == "") then
		return false
	end

	if (radioData) then
		local chatData = {
			freq = radioData.freq,
			chan = radioData.chan,
			broadcast = radioData.broadcast == true,
			walkie = radioData.walkie == true,
			lrange = radioData.lrange == true,
			quiet = radioData.quiet == true,
			callsign = radioData.callsign
		}
		local eavesdropData = {
			quiet = chatData.quiet,
			walkie = chatData.walkie
		}

		local receivers = {}
		local chatClass = ix.chat.classes["radio"]
		if (chatClass) then
			for _, v in ipairs(player.GetAll()) do
				if (v:GetCharacter() and chatClass:CanHear(client, v, chatData)) then
					receivers[#receivers + 1] = v
				end
			end
		end

		local translated = L(text, client)
		ix.chat.Send(client, "radio", translated, false, receivers, chatData)
		ix.chat.Send(client, "radio_eavesdrop", translated, false, nil, eavesdropData)

		return true, true, receivers
	end

	if (self:HasNearbyCombineICListener(client)) then
		ix.chat.Send(client, "ic", L(text, client))

		return true, false
	end

	return false
end

function PLUGIN:EmitVoiceEvent(client, text, sounds, volume, forceLocal, isCheck)
	if (!self:CanAutoVoice(client)) then
		return false
	end

	local radioData = !forceLocal and self:GetActiveRadioState(client) or nil
	local didSend, usedRadio, receivers = self:SendChatForVoice(client, text, radioData)

	if (!didSend) then
		return false
	end

	local success = self:PlayCombineSequence(client, sounds, volume, usedRadio, receivers)

	-- Automated response logic: If this was marked as a check call, trigger responders to clear it
	if (success and isCheck) then
		timer.Simple(math.random(1.5, 3), function()
			if (IsValid(client)) then
				self:TriggerResponders(client, "idle_clear")
			end
		end)
	end

	return success
end

function PLUGIN:IsGrenadeRestingOnWorld(entity)
	if (!IsValid(entity)) then
		return false
	end

	local velocity = entity.GetVelocity and entity:GetVelocity() or vector_origin

	if (velocity:LengthSqr() > (GRENADE_REST_SPEED * GRENADE_REST_SPEED)) then
		return false
	end

	local origin = entity:GetPos()
	local directions = {
		Vector(0, 0, -1),
		Vector(1, 0, 0),
		Vector(-1, 0, 0),
		Vector(0, 1, 0),
		Vector(0, -1, 0)
	}

	for _, direction in ipairs(directions) do
		local trace = util.TraceLine({
			start = origin,
			endpos = origin + direction * GRENADE_WORLD_CONTACT_DISTANCE,
			filter = entity,
			mask = MASK_SOLID_BRUSHONLY
		})

		if (trace.HitWorld) then
			return true
		end
	end

	return false
end

function PLUGIN:TryGrenadeReaction(client, grenade)
	if (!self:CanAutoVoice(client) or !IsValid(grenade) or grenade:GetClass() != GRENADE_CLASS) then
		return false
	end

	if (grenade:GetPos():DistToSqr(client:GetPos()) > (GRENADE_REACTION_RADIUS * GRENADE_REACTION_RADIUS)) then
		return false
	end

	local owner = grenade.GetOwner and grenade:GetOwner() or nil

	if (owner == client) then
		return false
	end

	if (!self:IsGrenadeRestingOnWorld(grenade) or !self:CanUsePlayerCooldown(client, "grenade")) then
		return false
	end

	local reactedPlayers = self.reactedGrenades[grenade] or {}

	if (reactedPlayers[client]) then
		return false
	end

	reactedPlayers[client] = true
	self.reactedGrenades[grenade] = reactedPlayers

	local event = self:BuildTemplateEvent(client, "grenade_danger")

	if (event) then
		return self:EmitVoiceEvent(client, event.text, event.sounds, 75, event.forceLocal, event.isCheck)
	end

	return false
end

function PLUGIN:BuildManDownSequence(speaker, target)
	local vType = self:GetVoiceType(speaker)
	local templateSet = (vType and TEMPLATE_SETS[vType]) or COMBINE_TEMPLATE_SETS

	local _, info = Schema:GetCombineUnitID(target)

	if (!info) then
		return nil
	end

	local variant = table.Random(templateSet.man_down) or {}
	local sequence = {}
	local parts = {}

	-- The designation is handled by the victimDesignation handler in BuildTemplateEvent
	-- We just need to ensure the variant has usesVictim = true and the layout includes victimDesignation

	for _, soundPath in ipairs(variant.sounds or {}) do
		sequence[#sequence + 1] = soundPath
	end

	if (variant.text) then
		parts[#parts + 1] = variant.text
	end

	if (variant.suffix and variant.suffix != "") then
		parts[#parts + 1] = variant.suffix
	end

	if (#sequence == 0 or #parts == 0) then
		return nil
	end

	-- Re-use BuildTemplateEvent for proper layout and designation handling
	return self:BuildTemplateEvent(nil, "man_down", {target = target})
end

function PLUGIN:GetNearbyAutoVoiceCount(client, radius)
	local count = 0
	local radiusSqr = (radius or SQUAD_RADIUS) ^ 2
	local origin = client:GetPos()

	for _, target in ipairs(player.GetAll()) do
		if (self:IsConnectedToLink(target) and self:CanAutoVoice(target)) then
			if (origin:DistToSqr(target:GetPos()) <= radiusSqr) then
				count = count + 1
			end
		end
	end

	return count
end

function PLUGIN:OnNPCKilled(npc, attacker, inflictor)
	if (!self:IsVoicePluginAvailable()) then
		return
	end

	-- Handle Manhack killed near Combine
	if (npc:GetClass() == "npc_manhack") then
		local pos = npc:GetPos()
		for _, v in ipairs(player.GetAll()) do
			if (v:Alive() and v:IsCombine() and v:GetPos():DistToSqr(pos) < (800 * 800) and self:CanAutoVoice(v)) then
				if (self:CanUsePlayerCooldown(v, "manhack_killed", 10)) then
					local event = self:BuildTemplateEvent(v, "manhack_killed")
					if (event) then
						self:EmitVoiceEvent(v, event.text, event.sounds, 75)
						break
					end
				end
			end
		end
	end

	-- NPC Killed
	if (IsValid(attacker) and attacker:IsPlayer() and attacker:Alive() and self:IsConnectedToLink(attacker) and self:CanAutoVoice(attacker)) then
		if (attacker.ixLastSeenTime != nil) then
			attacker.ixVoiceKills = (attacker.ixVoiceKills or 0) + 1
			if (self:CanUsePlayerCooldown(attacker, "kill_monster", 5)) then
				local event = self:BuildTemplateEvent(attacker, "kill_monster")
				if (event) then
					self:EmitVoiceEvent(attacker, event.text, event.sounds, 75, event.forceLocal, event.isCheck)
				end
			end
		end
	end

	-- Airwatch destroyed
	local class = npc:GetClass():lower()
	if (class == "npc_combinegunship" or class == "npc_combinedropship" or class == "npc_helicopter") then
		local pos = npc:GetPos()
		for _, client in ipairs(player.GetAll()) do
			if (client:Alive() and self:IsConnectedToLink(client) and self:CanAutoVoice(client)) then
				if (client:GetPos():DistToSqr(pos) <= (2000 * 2000)) then
					if (self:CanUsePlayerCooldown(client, "skyshield_lost", 30)) then
						local event = self:BuildTemplateEvent(client, "skyshield_lost")
						if (event) then
							self:EmitVoiceEvent(client, event.text, event.sounds, 75, event.forceLocal, event.isCheck)
							break
						end
					end
				end
			end
		end
	end
end

function PLUGIN:PostEntityTakeDamage(target, damageInfo)
	if (!self:IsVoicePluginAvailable()) then
		return
	end

	local attacker = damageInfo:GetAttacker()

	-- Handle Combine/MPF getting hurt
	if (IsValid(target) and target:IsPlayer() and target:Alive() and self:IsConnectedToLink(target)) then
		local voiceType = self:GetVoiceType(target)

		if (voiceType == "metropolice") then
			target.ixLastDamageTime = CurTime() -- Record last damage for idle logic
			
			-- Detect burn damage
			if (damageInfo:IsDamageType(DMG_BURN) and self:CanUsePlayerCooldown(target, "on_fire", 30)) then
				local event = self:BuildTemplateEvent(target, "on_fire")
				if (event) then
					self:EmitVoiceEvent(target, event.text, event.sounds, 75, event.forceLocal, event.isCheck)
				end
			end

			if (damageInfo:IsDamageType(DMG_CRUSH)) then
				local physicsAttacker = damageInfo:GetAttacker()
				local inflictor = damageInfo:GetInflictor()

				-- If the attacker isn't a valid player, check if the inflictor (the prop) has a physics attacker (the player who threw it)
				if (IsValid(inflictor) and (!IsValid(physicsAttacker) or !physicsAttacker:IsPlayer())) then
					physicsAttacker = inflictor:GetPhysicsAttacker()
				end

				-- Make sure the object was moved/thrown by some hostile entity (Player/NPC)
				if (IsValid(physicsAttacker) and physicsAttacker != target and self:IsHostileToCombine(physicsAttacker, target)) then
					if (self:CanUsePlayerCooldown(target, "physics_hit", 15)) then
						local event = self:BuildTemplateEvent(target, "physics_hit")
						if (event) then
							self:EmitVoiceEvent(target, event.text, event.sounds, 75, event.forceLocal, event.isCheck)
						end
					end
				end
			end

			if (IsValid(attacker) and attacker != target and self:IsHostileToCombine(attacker, target)) then
				local health = target:Health()
				local maxHealth = target:GetMaxHealth() or 100
				local healthPercent = (health / maxHealth) * 100

				if (healthPercent > 90) then
					if (!target.ixPainLightUsed) then
						target.ixPainLightUsed = true
						local event = self:BuildTemplateEvent(target, "pain_light")
						if (event) then
							self:EmitVoiceEvent(target, event.text, event.sounds, 75, event.forceLocal, event.isCheck)
						end
					end
				elseif (healthPercent >= 25) then
					if (!target.ixPainMediumUsed) then
						target.ixPainMediumUsed = true
						local event = self:BuildTemplateEvent(target, "pain_medium")
						if (event) then
							self:EmitVoiceEvent(target, event.text, event.sounds, 75, event.forceLocal, event.isCheck)
						end
					end
				elseif (healthPercent < 25) then
					if (!target.ixPainHeavyUsed) then
						target.ixPainHeavyUsed = true
						local event = self:BuildTemplateEvent(target, "pain_heavy")
						if (event) then
							self:EmitVoiceEvent(target, event.text, event.sounds, 75, event.forceLocal, event.isCheck)
						end
					end
				end
			end
		elseif (IsValid(attacker) and attacker != target and self:IsHostileToCombine(attacker, target)) then
			local damage = damageInfo:GetDamage()
			local health = target:Health()
			local maxHealth = target:GetMaxHealth() or 100

			if (damage > 15 or (health / maxHealth) <= 0.5) then
				if (self:CanUsePlayerCooldown(target, "cover", 10)) then
					local event = self:BuildTemplateEvent(target, "cover")
					if (event) then
						self:EmitVoiceEvent(target, event.text, event.sounds, 75, event.forceLocal, event.isCheck)
					end
				end
			else
				if (self:CanUsePlayerCooldown(target, "taunt", 10)) then
					local event = self:BuildTemplateEvent(target, "taunt")
					if (event) then
						self:EmitVoiceEvent(target, event.text, event.sounds, 75, event.forceLocal, event.isCheck)
					end
				end
			end

			local damage = damageInfo:GetDamage()
			if (damage > 20) then
				for _, leader in ipairs(player.GetAll()) do
					if (leader != target and leader:Alive() and self:IsConnectedToLink(leader) and self:IsSquadLeader(leader) and self:CanAutoVoice(leader)) then
						if (leader:GetPos():DistToSqr(target:GetPos()) <= (SQUAD_RADIUS * SQUAD_RADIUS)) then
							if (self:CanUsePlayerCooldown(leader, "ally_hurt", 30)) then
								local event = self:BuildTemplateEvent(leader, "ally_hurt", {target = target})
								if (event) then
									self:EmitVoiceEvent(leader, event.text, event.sounds, 75, event.forceLocal, event.isCheck)
									break
								end
							end
						end
					end
				end
			end
		end

		-- Manhack specific "rogue" detection (friendly fire or accidental hits)
		if (IsValid(attacker) and attacker:GetClass() == "npc_manhack") then
			if (self:CanUsePlayerCooldown(target, "manhack_danger", 20)) then
				local event = self:BuildTemplateEvent(target, "manhack_danger")
				if (event) then
					self:EmitVoiceEvent(target, event.text, event.sounds, 75, event.forceLocal, event.isCheck)
				end
			end
		end
	end

	-- Only care if the attacker is a valid Combine unit
	if (!IsValid(attacker) or !attacker:IsPlayer() or !attacker:Alive() or !self:IsConnectedToLink(attacker)) then
		return
	end

	-- Only care if the target is a player and NOT Combine
	if (!IsValid(target) or !target:IsPlayer() or !target:Alive() or self:IsConnectedToLink(target)) then
		return
	end

	local health = target:Health()
	local maxHealth = target:GetMaxHealth() or 100

	-- If the target is significantly damaged (below 30%)
	if (health > 0 and (health / maxHealth) <= 0.3) then
		if (self:CanUsePlayerCooldown(attacker, "player_hit", 15)) then
			local event = self:BuildTemplateEvent(attacker, "player_hit")

			if (event) then
				self:EmitVoiceEvent(attacker, event.text, event.sounds, 75, event.forceLocal, event.isCheck)
			end
		end
	end
end

function PLUGIN:HandleThrownGrenade(grenade)
	if (!IsValid(grenade) or grenade:GetClass() != GRENADE_CLASS) then
		return
	end

	-- Harassment and Arrest scan for nearby non-MPF players
	if ((self.nextHarassScan or 0) < currentTime) then
		self.nextHarassScan = currentTime + 2.0
		self:ScanForArrestSituations()
	end

	if (grenade.ixAutoVoiceThrowHandled) then
		return
	end

	local owner = grenade.GetOwner and grenade:GetOwner() or nil

	if (!self:IsConnectedToLink(owner) or !self:CanAutoVoice(owner) or !self:CanUsePlayerCooldown(owner, "throw_grenade", 1.5)) then
		return
	end

	grenade.ixAutoVoiceThrowHandled = true

	local event = self:BuildTemplateEvent(owner, "throwGrenade")

	if (event) then
		self:EmitVoiceEvent(owner, event.text, event.sounds, 75, event.forceLocal, event.isCheck)
	end
end

function PLUGIN:ScanForHarassment()
	local currentTime = CurTime()

	for _, client in ipairs(player.GetAll()) do
		if (client:Alive() and client:Team() == FACTION_MPF and self:IsConnectedToLink(client) and self:CanAutoVoice(client)) then
			-- Skip if busy or recently spoke
			if ((client.ixNextHarassVoice or 0) > currentTime) then
				continue
			end

			local origin = client:GetPos()
			
			for _, other in ipairs(player.GetAll()) do
				if (other == client or !other:Alive() or other:GetMoveType() == MOVETYPE_NOCLIP or other:IsCombine()) then
					continue
				end

				local distSqr = origin:DistToSqr(other:GetPos())
				if (distSqr > (50 * 50)) then continue end -- Pestering range: 50 units

				-- Check LOS
				if (!client:IsLineOfSightClear(other)) then continue end

				-- They are pestering the unit!
				other.ixPesterData = other.ixPesterData or {count = 0, lastTime = 0}
				local data = other.ixPesterData

				-- If it's been a while (e.g. 30s), reset the pester count
				if (currentTime - data.lastTime > 30) then
					data.count = 0
				end

				data.lastTime = currentTime
				data.count = data.count + 1

				local currentLevel
				if (data.count <= 2) then currentLevel = 1
				elseif (data.count <= 4) then currentLevel = 2
				else currentLevel = 3 end

				-- Find valid indices for this level
				local validIndices = {}
				for i, v in ipairs(MPF_TEMPLATE_SETS.harassment) do
					if (v.level == currentLevel) then
						table.insert(validIndices, i)
					end
				end

				if (#validIndices > 0) then
					local index = table.Random(validIndices)
					local variant = MPF_TEMPLATE_SETS.harassment[index]
					
					client.ixNextHarassVoice = currentTime + 8 -- Don't yell too often at the same guy
					local event = self:BuildTemplateEvent(client, "harassment", {forcedIndex = index})
					if (event) then
						self:EmitVoiceEvent(client, event.text, event.sounds, variant.volume or 75, true, event.isCheck)
					end
				end
				break -- Only yell at one person at a time
			end
		end
	end
end

function PLUGIN:PhysicsCollide(data, phys)
	local ent = data.HitEntity
	local target = data.Entity

	if (IsValid(target) and target:GetVelocity():LengthSqr() > (150 * 150)) then
		local attacker = target:GetPhysicsAttacker()
		if (IsValid(attacker) and attacker:IsPlayer()) then
			for _, client in ipairs(player.GetAll()) do
				if (client:Alive() and self:IsConnectedToLink(client) and self:CanAutoVoice(client) and client != attacker) then
					if (client:GetPos():DistToSqr(target:GetPos()) <= (PHYSICS_THREAT_SCAN_RADIUS * PHYSICS_THREAT_SCAN_RADIUS)) then
						if (self:IsHostileToCombine(attacker, client)) then
							if (self:CanUsePlayerCooldown(client, "physics_hit", 10)) then
								local event = self:BuildTemplateEvent(client, "physics_hit")
								if (event) then
									self:EmitVoiceEvent(client, event.text, event.sounds, 75, event.forceLocal, event.isCheck)
								end
							end
						end
					end
				end
			end
		end
	end
end

function PLUGIN:Think()
	if (!self:IsVoicePluginAvailable()) then
		return
	end

	local currentTime = CurTime()

	if (self.nextGrenadeScan > currentTime) then
		return
	end

	self.nextGrenadeScan = currentTime + GRENADE_SCAN_INTERVAL

	for _, grenade in ipairs(ents.FindByClass(GRENADE_CLASS)) do
		if (!IsValid(grenade) or !self:IsGrenadeRestingOnWorld(grenade)) then
			if (IsValid(grenade)) then
				self:HandleThrownGrenade(grenade)
			end

			continue
		end

		self:HandleThrownGrenade(grenade)

		local reactors = player.GetAll()

		table.sort(reactors, function(a, b)
			return self:GetPlayerVoicePriority(a) > self:GetPlayerVoicePriority(b)
		end)

		for _, client in ipairs(reactors) do
			if (self:TryGrenadeReaction(client, grenade)) then
				break
			end
		end
	end

	for _, class in ipairs(DANGER_CLASSES) do
		for _, ent in ipairs(ents.FindByClass(class)) do
			if (!IsValid(ent)) then continue end

			local origin = ent:GetPos()
			local isDanger = false
			local radiusSqr = (250 * 250)

			if (class == "combine_mine") then
				-- Hopper mine jumping
				isDanger = ent:GetVelocity().z > 30 and !ent:IsOnGround()
				radiusSqr = (200 * 200)
			elseif (class == "prop_explosive_barrel") then
				-- Red barrel on fire
				isDanger = ent:IsOnFire()
				radiusSqr = (220 * 220)
			elseif (class == "rpg_missile" or class == "prop_combine_ball" or class == "grenade_ar2") then
				-- Moving projective threats - basic speed check
				isDanger = ent:GetVelocity():LengthSqr() > (150 * 150)
				radiusSqr = (350 * 350)
			elseif (class == "npc_satchel" or class == "npc_tripmine" or class == "gmod_dynamite") then
				-- SLAM / Dynamite
				isDanger = true
				radiusSqr = (220 * 220)
			elseif (class == "npc_manhack") then
				-- Manhacks are danger if they are hostile and flying
				isDanger = ent:GetVelocity():LengthSqr() > (100 * 100)
				radiusSqr = (250 * 250)
			elseif (class:find("prop_vehicle")) then
				-- Vehicles moving fast
				isDanger = ent:GetVelocity():LengthSqr() > (150 * 150)
				radiusSqr = (400 * 400)
			end

			if (isDanger) then
				for _, client in ipairs(player.GetAll()) do
					if (self:IsConnectedToLink(client) and self:CanAutoVoice(client)) then
						local clientPos = client:GetPos()

						if (clientPos:DistToSqr(origin) <= radiusSqr) then
							-- Unique category selection based on threat type
							local template = "danger"

							if (class == "npc_grenade_frag" or class == "grenade_ar2" or class == "rpg_missile") then
								template = "grenade_danger"
							elseif (class == "npc_manhack") then
								-- Only MPF/Combine react to MANHACKS if they are hostile
								if (!self:IsHostileToCombine(ent, client)) then
									continue
								end
								template = "manhack_danger"
							elseif (class:find("prop_vehicle")) then
								-- Vehicles: only if coming towards
								local vel = ent:GetVelocity():GetNormalized()
								local toPlayer = (clientPos - origin):GetNormalized()
								if (vel:Dot(toPlayer) < 0.6) then
									continue
								end
								template = "vehicle_danger"
							elseif (class == "rpg_missile" or class == "grenade_ar2" or class == "prop_combine_ball") then
								-- Projectiles: only react if moving TOWARDS the player to avoid reacting to self-fires
								local vel = ent:GetVelocity():GetNormalized()
								local toPlayer = (clientPos - origin):GetNormalized()

								-- If dot product is low, it's not moving towards the player
								if (vel:Dot(toPlayer) < 0.6) then
									continue
								end
								template = "grenade_danger"
							end

							if (self:CanUsePlayerCooldown(client, "danger", 3)) then
								local event = self:BuildTemplateEvent(client, template)

								if (event) then
									self:EmitVoiceEvent(client, event.text, event.sounds, 75, event.forceLocal, event.isCheck)
									break -- Only one reactor per entity to avoid noise
								end
							end
						end
					end
				end
			end
		end
	end

	if (self.nextCombatScan > currentTime) then
		return
	end

	self.nextCombatScan = currentTime + COMBAT_SCAN_INTERVAL
	self:ScanForCombatCallouts()

	if ((self.nextHarassScan or 0) < currentTime) then
		self.nextHarassScan = currentTime + 2
		self:ScanForHarassment()
	end

	-- Scan for physics hits (objects tossed/thrown near units)
	for index, data in pairs(self.activePhysicsThreats) do
		local ent = data.ent
		if (!IsValid(ent) or data.dieTime < currentTime or ent:GetVelocity():LengthSqr() < (50 * 50)) then
			self.activePhysicsThreats[index] = nil
			continue
		end

		local entPos = ent:GetPos()
		local attacker = data.attacker

		for _, client in ipairs(player.GetAll()) do
			if (client:Alive() and self:IsConnectedToLink(client) and self:CanAutoVoice(client)) then
				-- Check if the prop is very close to this client
				if (entPos:DistToSqr(client:GetPos()) <= (PHYSICS_THREAT_SCAN_RADIUS * PHYSICS_THREAT_SCAN_RADIUS)) then
					-- Hostile check
					if (attacker != client and self:IsHostileToCombine(attacker, client)) then
						if (self:CanUsePlayerCooldown(client, "physics_hit", 10)) then
							local event = self:BuildTemplateEvent(client, "physics_hit")
							if (event) then
								self:EmitVoiceEvent(client, event.text, event.sounds, 75, event.forceLocal, event.isCheck)
								-- Once triggered for a unit, the prop stops being a threat to avoid repeat firing
								self.activePhysicsThreats[index] = nil
								break
							end
						end
					end
				end
			end
		end
	end
end

local HARASSMENT_DISTANCE_SQR = 55 * 55

function PLUGIN:ScanForArrestSituations()
	local currentTime = CurTime()
	
	for _, client in ipairs(player.GetAll()) do
		if (client:Alive() and client:Team() == FACTION_MPF and self:IsConnectedToLink(client) and self:CanAutoVoice(client)) then
			-- Skip if busy or recently spoke
			if ((client.ixNextHarassVoice or 0) > currentTime) then
				continue
			end
			
			local origin = client:GetPos()
			local cto = ix.plugin.Get("cto")
			
			for _, other in ipairs(player.GetAll()) do
				if (other == client or !other:Alive() or other:GetMoveType() == MOVETYPE_NOCLIP or other:IsCombine()) then
					continue
				end
				
				local distSqr = origin:DistToSqr(other:GetPos())
				if (distSqr > (500 * 500)) then continue end -- Only within 500 units

				-- LOS check
				if (!client:IsLineOfSightClear(other)) then continue end

				local hasViolation = false
				if (cto and cto.IsVisibleWeaponViolation and cto:IsVisibleWeaponViolation(other)) then
					hasViolation = true
				elseif (other:IsWepRaised()) then
					hasViolation = true
				end

				if (hasViolation) then
					-- Track suspect state
					other.ixSuspectData = other.ixSuspectData or {state = "none", lastStationary = 0}
					local data = other.ixSuspectData
					local isRunning = other:GetVelocity():LengthSqr() > (150 * 150)

					if (data.state == "none") then
						-- Initial freeze command
						data.state = "warned"
						client.ixNextHarassVoice = currentTime + 10
						local event = self:BuildTemplateEvent(client, "freeze")
						if (event) then
							self:EmitVoiceEvent(client, event.text, event.sounds, 75, event.forceLocal, event.isCheck)
						end
						break
					elseif (data.state == "warned" and isRunning) then
						-- Suspect is fleeing
						data.state = "fleeing"
						client.ixNextHarassVoice = currentTime + 15
						local event = self:BuildTemplateEvent(client, "suspect_running")
						if (event) then
							self:EmitVoiceEvent(client, event.text, event.sounds, 75, event.forceLocal, event.isCheck)
						end
						break
					elseif (data.state == "fleeing" and !isRunning) then
						-- Suspect stopped fleeing
						if (data.lastStationary == 0 or other:GetVelocity():LengthSqr() > (10 * 10)) then
							data.lastStationary = currentTime
						end

						if (currentTime - data.lastStationary >= 3.0) then
							-- Complied for 3 seconds
							data.state = "arrested"
							client.ixNextHarassVoice = currentTime + 20
							local event = self:BuildTemplateEvent(client, "arrest")
							if (event) then
								self:EmitVoiceEvent(client, event.text, event.sounds, 75, event.forceLocal, event.isCheck)
								
								-- Trigger leader response
								timer.Simple(1.5, function()
									if (IsValid(client)) then
										self:TriggerResponders(client, "arrest_answer")
									end
								end)
							end
							break
						end
					end
				else
					-- No violation, reset if they were a suspect but now clean?
					-- Usually they stay suspect until cuffed or leave range.
					if (other.ixSuspectData and distSqr > (800 * 800)) then
						other.ixSuspectData = nil
					end
				end
			end
		end
	end
end

function PLUGIN:IsHostileToCombine(entity, source)
	if (!IsValid(entity)) then
		return false
	end

	if (entity:IsNPC()) then
		if (IsValid(source) and source:IsPlayer()) then
			return entity:Disposition(source) == D_HT
		end

		for _, v in ipairs(player.GetAll()) do
			if (v:Alive() and v:IsCombine()) then
				if (entity:Disposition(v) == D_HT) then
					return true
				end
			end
		end

		return false
	end

	if (entity:IsPlayer()) then
		local client = entity
		local character = client:GetCharacter()

		if (!character) then
			return false
		end

		local faction = client:Team()

		if (client:IsCombine() or faction == FACTION_ADMIN or faction == FACTION_CONSCRIPT) then
			return false
		end

		local weapon = client:GetActiveWeapon()

		if (IsValid(weapon)) then
			local class = weapon:GetClass()

			if (EXCLUDED_WEAPONS[class]) then
				return false
			end
		end

		return true
	end

	return false
end

function PLUGIN:GetEnemyType(entity)
	if (!IsValid(entity)) then return "none" end
	if (entity:IsPlayer()) then
		if (entity:InVehicle()) then return "vehicle" end
		
		local char = entity:GetCharacter()
		if (char) then
			local name = char:GetName():lower()
			if (name:find("gordon") or name:find("freeman")) then return "freeman" end
		end
		
		return "human"
	end

	local class = entity:GetClass():lower()
	if (class:find("zombie") or class == "npc_zombine") then return "zombie" end
	if (class:find("antlion")) then return "antlion" end
	if (class:find("headcrab")) then return "headcrab" end
	if (class == "npc_alyx" or class == "npc_barney") then return "character" end
	
	-- Humanoid NPCs like Citizens, Rebels, or other factions
	if (class:find("citizen") or class:find("rebel") or class:find("combine") or class:find("metropolice")) then
		return "human_npc"
	end
	
	return "unknown"
end

-- Callout mappings for cleaner logic
local MPF_LEADER_CALLOUTS = {
	-- Keep empty to use smart fallbacks
}

local OTA_LEADER_CALLOUTS = {
	-- Keep empty to use smart fallbacks
}

local GENERIC_MONSTER_CALLOUTS = {
	vehicle = "monster_vehicle",
	human_npc = "monster_citizens",
	zombie = "monster_zombies",
	antlion = "monster_bugs",
	headcrab = "monster_parasites",
	character = "monster_character",
	freeman = "monster_freeman",
	unknown = "monster_alert"
}

function PLUGIN:IsSquadLeader(client)
	if (!IsValid(client) or !client:GetCharacter()) then
		return false
	end

	local _, info = Schema:GetCombineUnitID(client)
	if (info and info.callsign == "LEADER") then
		return true
	end

	local class = client:GetCharacter():GetClass()
	local classData = class and ix.class.list[class]
	if (classData) then
		local uid = classData.uniqueID:upper()
		if (uid:find("EOW") or uid:find("SGS") or uid:find("ELITE") or uid:find("SHOTGUN")) then
			return true
		end
	end

	return false
end

function PLUGIN:TriggerResponders(client, responseType)
	local responders = {}
	local clientRadio = self:GetActiveRadioState(client)
	
	for _, other in ipairs(player.GetAll()) do
		if (other != client and self:IsConnectedToLink(other) and self:CanAutoVoice(other)) then
			-- OTA Hierarchy check: OTA only responds to OTA. MPF responds to both.
			if (client:Team() == FACTION_MPF and other:Team() == FACTION_OTA) then
				continue
			end

			local otherRadio = self:GetActiveRadioState(other)
			local distSqr = other:GetPos():DistToSqr(client:GetPos())
			local canHear = false
			
			if (distSqr <= (600 * 600)) then
				canHear = true
			elseif (clientRadio and otherRadio and clientRadio.freq == otherRadio.freq and clientRadio.chan == otherRadio.chan) then
				canHear = true
			end
			
			if (canHear) then
				responders[#responders + 1] = other
			end
		end
	end
	
	for _, responder in ipairs(responders) do
		timer.Simple(math.random(2, 4), function()
			if (IsValid(responder) and responder:Alive() and responder:IsCombine() and self:CanAutoVoice(responder)) then
				if (responder:GetNetVar("typing", false) or (responder.ixLastChatTime and CurTime() - responder.ixLastChatTime < 60)) then return end
				if (responder.ixLastSeenTime) then return end
				
				local respEvent = self:BuildTemplateEvent(responder, responseType)
				if (respEvent) then
					self:EmitVoiceEvent(responder, respEvent.text, respEvent.sounds, 75, respEvent.forceLocal, respEvent.isCheck)
				end
			end
		end)
	end
end

function PLUGIN:ScanForCombatCallouts()
	local otaUnits = {}

	for _, client in ipairs(player.GetAll()) do
		if (client:Alive() and client:IsCombine() and self:CanAutoVoice(client)) then
			local weapon = client:GetActiveWeapon()
			local weaponClass = IsValid(weapon) and weapon:GetClass() or ""

			local isRaised = client:IsWepRaised() and !EXCLUDED_WEAPONS[weaponClass]
			if (isRaised) then
				otaUnits[#otaUnits + 1] = client

				if (!client.ixWasWepRaised) then
					client.ixWasWepRaised = true
					
					-- Stunstick
					if (weaponClass == "ix_stunstick" and client:Team() == FACTION_MPF) then
						if (self:CanUsePlayerCooldown(client, "activate_baton", 10)) then
							local event = self:BuildTemplateEvent(client, "activate_baton")
							if (event) then
								self:EmitVoiceEvent(client, event.text, event.sounds, 75, event.forceLocal, event.isCheck)
							end
						end
					end
				end
			else
				client.ixWasWepRaised = false
				client.ixFlankStartPos = nil
			end
		end
	end

	if (#otaUnits == 0) then
		return
	end

	table.sort(otaUnits, function(a, b)
		return self:GetPlayerVoicePriority(a) > self:GetPlayerVoicePriority(b)
	end)

	for _, client in ipairs(otaUnits) do
		local targets = {}
		local targetData = {}

		for _, entity in ipairs(ents.FindInSphere(client:GetPos(), COMBAT_SIGHT_RADIUS)) do
			if (entity == client or (!entity:IsNPC() and !entity:IsPlayer())) then
				continue
			end

			if (self:IsHostileToCombine(entity, client)) then
				-- Check LOS
				local trace = util.TraceLine({
					start = client:EyePos(),
					endpos = entity:EyePos(),
					filter = {client, entity},
					mask = MASK_SHOT
				})

				local behindPhysics = false
				if (trace.Hit and IsValid(trace.Entity) and trace.Entity:GetClass() == "prop_physics") then
					behindPhysics = true
				end

				if (!trace.Hit or behindPhysics) then
					targets[#targets + 1] = entity
					targetData[entity] = {behindPhysics = behindPhysics}
				end
			end
		end

		if (#targets > 0) then
			local target = targets[1]
			local isFirstContact = (client.ixLastSeenTime == nil)
			local forcedIndex = nil

			client.ixLastSeenTime = CurTime()
			client.ixHasTriggeredLostShort = false
			client.ixHasTriggeredLostLong = false

			if (self:CanUsePlayerCooldown(client, "combat_callout", COMBAT_REACTION_COOLDOWN)) then
				local template = "combatCallout"
				local distSqr = client:GetPos():DistToSqr(target:GetPos())

				if (isFirstContact) then
					-- Squad leaders report first contact
					local isMPF = (client:Team() == FACTION_MPF)
					local isLeader = (isMPF and self:IsHighestRankingMPF(client)) or (!isMPF and self:IsSquadLeader(client))

					if (isLeader) then
						local enemyType = self:GetEnemyType(target)
						local mapping = (isMPF and MPF_LEADER_CALLOUTS[enemyType]) or OTA_LEADER_CALLOUTS[enemyType]
						
						if (mapping) then
							template = mapping.template
							forcedIndex = mapping.forcedIndex
						else
							-- Smart fallback: Monster callouts for NPCs, standard leader_alert for players
							if (target:IsNPC()) then
								template = GENERIC_MONSTER_CALLOUTS[enemyType] or "leader_alert"
							else
								template = "leader_alert"
							end
							forcedIndex = nil
						end
					else
						-- Non-leaders or followers
						local enemyType = self:GetEnemyType(target)
						template = GENERIC_MONSTER_CALLOUTS[enemyType] or "go_alert"
					end
				else
					-- Check for flanking (moving towards enemy, and enemy isn't coming towards us)
					local velocity = client:GetVelocity()

					if (velocity:LengthSqr() > (100 * 100)) then
						local toTarget = (target:GetPos() - client:GetPos()):GetNormalized()
						local dot = velocity:GetNormalized():Dot(toTarget)

						-- Moving towards enemy (dot product check)
						if (dot > 0.7) then
							local enemyVelocity = target:GetVelocity()
							local toPlayer = (client:GetPos() - target:GetPos()):GetNormalized()
							local enemyDot = enemyVelocity:GetNormalized():Dot(toPlayer)

							-- Enemy is not coming towards us
							if (enemyDot < 0.3) then
								-- Only trigger flank if moved more than 20ft (240 units)
								client.ixFlankStartPos = client.ixFlankStartPos or client:GetPos()

								if (client:GetPos():DistToSqr(client.ixFlankStartPos) >= (240 * 240)) then
									template = "flank"
									client.ixFlankStartPos = nil
								end
							else
								client.ixFlankStartPos = nil
							end
						else
							client.ixFlankStartPos = nil
						end
					else
						client.ixFlankStartPos = nil
					end

					-- Check for incoming enemy (enemy moving towards player, player not moving towards enemy)
					if (template == "combatCallout") then
						local enemyVelocity = target:GetVelocity()

						if (enemyVelocity:LengthSqr() > (100 * 100)) then
							local toPlayer = (client:GetPos() - target:GetPos()):GetNormalized()
							local enemyDot = enemyVelocity:GetNormalized():Dot(toPlayer)

							-- Enemy is coming towards us
							if (enemyDot > 0.7) then
								local dot = velocity:GetNormalized():Dot(toTarget)

								-- Player is NOT moving towards the enemy
								if (dot < 0.3) then
									template = "incoming"
								end
							end
						end
					end

					-- Random chance for assault callout if not flanking/incoming
					if (template == "combatCallout" and math.random(1, 10) <= 4) then
						template = "assault"
					end

					-- If lost for more than 10 seconds, use refind_enemy
					-- Note: Since ixLastSeenTime was updated above, we check it against the previous value if needed, 
					-- but here we rely on the fact that if isFirstContact was false and it was a while, it's a refind.
					-- However, the original code had a bug where it checked against the JUST updated time.
					-- We'll assume the user wants the new logic to take precedence for active combat.
				end

				-- Use shoot_cover if the target is behind physics
				if (targetData[target] and targetData[target].behindPhysics and client:Team() == FACTION_MPF) then
					template = "shoot_cover"
				end

				local event = self:BuildTemplateEvent(client, template, {
					target = targets[1],
					distance = distSqr,
					bearing = (targets[1]:GetPos() - client:GetPos()):Angle().y,
					forcedIndex = forcedIndex
				})

				-- OTA/Faction fallback: If specialty template (like monster_vehicle) doesn't exist, try standard one
				if (!event and template != "leader_alert" and template != "go_alert") then
					template = isLeader and "leader_alert" or "go_alert"
					event = self:BuildTemplateEvent(client, template, {
						target = targets[1],
						distance = distSqr,
						bearing = (targets[1]:GetPos() - client:GetPos()):Angle().y
					})
				end

				if (event) then
					self:EmitVoiceEvent(client, event.text, event.sounds, 75, event.forceLocal, event.isCheck)

					-- Trigger responses for major combat alerts
					local responseTriggers = {
						["leader_alert"] = true,
						["monster_alert"] = true,
						["cto_discovery"] = true,
					}
					
					if (responseTriggers[template]) then
						self:TriggerResponders(client, "answer")
					end

					return -- Only one callout per scan interval to avoid noise
				end
			end
		else
			-- No hostile visible. Check how long since last contact.
			if (client.ixLastSeenTime) then
				local elapsed = CurTime() - client.ixLastSeenTime

				if (elapsed >= 60) then -- Beyond combat timeout
					client.ixLastSeenTime = nil
					client.ixVoiceKills = nil
				elseif (elapsed >= 10 and !client.ixHasTriggeredLostLong) then
					if (self:CanUsePlayerCooldown(client, "combat_callout", 15)) then
						client.ixHasTriggeredLostLong = true
						client.ixVoiceKills = nil
						local event = self:BuildTemplateEvent(client, "lost_long")

						if (event) then
							self:EmitVoiceEvent(client, event.text, event.sounds, 75, event.forceLocal, event.isCheck)
							return
						end
					end
				elseif (elapsed >= 5 and !client.ixHasTriggeredLostShort) then
					if (self:CanUsePlayerCooldown(client, "combat_callout", 15)) then
						client.ixHasTriggeredLostShort = true
						client.ixVoiceKills = nil
						local event = self:BuildTemplateEvent(client, "lost_short")

						if (event) then
							self:EmitVoiceEvent(client, event.text, event.sounds, 75, event.forceLocal, event.isCheck)
							return
						end
					end
				end
			else
				-- IDLE logic (client.ixLastSeenTime is nil)
				if ((client.ixNextIdleChatter or 0) < CurTime()) then
					local canIdle = true
					
					-- exclude if typing recently or currently typing, or took damage recently
					if (client:GetNetVar("typing", false) or (client.ixLastChatTime and CurTime() - client.ixLastChatTime < 60) or (client.ixLastDamageTime and CurTime() - client.ixLastDamageTime < 30)) then
						canIdle = false
					end
					
					-- Need at least one other combine nearby OR have radio access
					local hasRadio = self:GetActiveRadioState(client) != nil
					if (canIdle and (self:GetNearbyAutoVoiceCount(client, 600) > 1 or hasRadio)) then
						client.ixNextIdleChatter = CurTime() + 120 -- 2 minutes cooldown
						
						local choices = {"idle"}
						if (isLeader) then
							table.insert(choices, "check")
						end
						
						local selection = choices[math.random(#choices)]
						local event = self:BuildTemplateEvent(client, selection)
						
						if (event) then
							self:EmitVoiceEvent(client, event.text, event.sounds, 75, event.forceLocal, event.isCheck)
							
							if (selection == "check") then
								self:TriggerResponders(client, "clear")
							end
							
							return
						end
					end
				end
			end
		end
	end
end

-- Hook into scanner and cto photo transmissions
function PLUGIN:OnScannerPhotoReceived(receivers)
	timer.Simple(1.5, function()
		local candidates = {}

		for _, client in ipairs(player.GetAll()) do
			if (client:Alive() and client:Team() == FACTION_MPF and self:IsHighestRankingMPF(client)) then
				table.insert(candidates, client)
			end
		end

		if (#candidates > 0) then
			local speaker = table.Random(candidates)
			local event = self:BuildTemplateEvent(speaker, "cto_discovery")
							if (event) then
				self:EmitVoiceEvent(speaker, event.text, event.sounds, 75, event.forceLocal, event.isCheck)
			end
		end
	end, 1.5)
end

-- Initialize collision callbacks for all props
function PLUGIN:RegisterPropCollision(ent)
	if (ent:GetClass() == "prop_physics") then
		ent:AddCallback("PhysicsCollide", function(prop, data)
			self:HandlePropCollision(prop, data)
		end)
	end
end

function PLUGIN:OnEntityCreated(ent)
	self:RegisterPropCollision(ent)

	if (ent:GetClass() == "npc_manhack") then
		timer.Simple(0.1, function()
			if (!IsValid(ent)) then return end
			
			local pos = ent:GetPos()
			local speaker = ent:GetCreator() 
			
			if (!IsValid(speaker) or !speaker:IsCombine() or !speaker:Alive()) then
				for _, v in ipairs(player.GetAll()) do
					if (v:Alive() and v:IsCombine() and v:GetPos():DistToSqr(pos) < (500*500)) then
						speaker = v
						break
					end
				end
			end

			if (IsValid(speaker) and self:CanAutoVoice(speaker)) then
				if (self:CanUsePlayerCooldown(speaker, "deploy_manhack", 5)) then
					local event = self:BuildTemplateEvent(speaker, "deploy_manhack")
					if (event) then
						self:EmitVoiceEvent(speaker, event.text, event.sounds, 75)
					end
				end
			end
		end)
	end
end

function PLUGIN:WeaponReload(weapon, client)
	if (!IsValid(client) or !client:IsPlayer() or !client:Alive()) then return end
	
	-- Reloadable weapons
	if (!IsValid(weapon) or weapon:GetMaxClip1() <= 0 or weapon:GetPrimaryAmmoType() == -1) then
		return
	end

	if (!self:IsConnectedToLink(client) or !self:CanAutoVoice(client)) then return end

	-- Cooldown
	if (self:CanUsePlayerCooldown(client, "reload", 8)) then
		local event = self:BuildTemplateEvent(client, "reload")
		if (event) then
			self:EmitVoiceEvent(client, event.text, event.sounds, 75, event.forceLocal, event.isCheck)
		end
	end
end

function PLUGIN:InitPostEntity()
	for _, ent in ipairs(ents.FindByClass("prop_physics")) do
		self:RegisterPropCollision(ent)
	end
end

-- Remove old physics threat hooks
-- (Previous OnPlayerPhysicsPickup/Drop etc are no longer needed for this logic)


function PLUGIN:PostPlayerSay(client, chatType, message)
	client.ixLastChatTime = CurTime()
end

function PLUGIN:PlayerDeath(client, inflictor, attacker)
	if (!self:IsVoicePluginAvailable() or !IsValid(client)) then
		return
	end

	client.ixPainLightUsed = nil
	client.ixPainMediumUsed = nil
	client.ixPainHeavyUsed = nil

	-- Handle Combine killing a player
	if (!client:IsCombine() and IsValid(attacker) and attacker:IsPlayer() and attacker:IsCombine() and self:CanAutoVoice(attacker)) then
		if (attacker.ixLastSeenTime != nil) then
			attacker.ixVoiceKills = (attacker.ixVoiceKills or 0) + 1
			
			local templateName = (math.random(1, 2) == 1) and "player_dead" or "kill_monster"
			if (self:CanUsePlayerCooldown(attacker, templateName, 5)) then
				local event = self:BuildTemplateEvent(attacker, templateName, {target = client})
				if (event) then
					self:EmitVoiceEvent(attacker, event.text, event.sounds, 75, event.forceLocal, event.isCheck)
				end
			end
		end
	end

	if (!client:IsCombine()) then
		return
	end

	local currentTime = CurTime()
	if (self.nextDeathReaction > currentTime) then
		return
	end

	self.nextDeathReaction = currentTime + DEATH_EVENT_COOLDOWN

	-- Man down reaction - we don't build it yet because the listener provides the sequence
	-- But some parts of the logic require the sequence beforehand?
	-- In the current loop, the listener uses the event from BuildManDownSequence.
	-- Since different listeners might have different voice types, we should move BuildManDownSequence inside the loop.


	local clientPos = client:GetPos()
	local listeners = player.GetAll()

	table.sort(listeners, function(a, b)
		return self:GetPlayerVoicePriority(a) > self:GetPlayerVoicePriority(b)
	end)

	for _, listener in ipairs(listeners) do
		if (!self:CanAutoVoice(listener)) then
			continue
		end

		if (listener == client or listener:GetPos():DistToSqr(clientPos) > (DEATH_REACTION_RADIUS * DEATH_REACTION_RADIUS)) then
			continue
		end

		if (self:CanUsePlayerCooldown(listener, "death")) then
			local lastSquadEvent

			if (self:GetNearbyAutoVoiceCount(listener, SQUAD_RADIUS) <= 1) then
				lastSquadEvent = self:BuildTemplateEvent(listener, "lastSquad")
			end

			if (lastSquadEvent) then
				self:EmitVoiceEvent(listener, lastSquadEvent.text, lastSquadEvent.sounds, 75, lastSquadEvent.forceLocal, lastSquadEvent.isCheck)
				break
			else
				local event = self:BuildManDownSequence(listener, client)
				if (event) then
					self:EmitVoiceEvent(listener, event.text, event.sounds, 75, event.forceLocal, event.isCheck)
					break
				end
			end
		end
	end
end

function PLUGIN:EntityRemoved(entity)
	if (self.reactedGrenades) then
		self.reactedGrenades[entity] = nil
	end

	if (self.playerCooldowns and IsValid(entity) and entity:IsPlayer()) then
		self.playerCooldowns[entity] = nil
	end
end
