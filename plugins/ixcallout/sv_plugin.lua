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

local COMBAT_SCAN_INTERVAL = 1.0
local COMBAT_REACTION_COOLDOWN = 15
local COMBAT_SIGHT_RADIUS = 1000

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
			suffix = ".",
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
		}
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
		}
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
			suffix = ".",
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
			suffix = ".",
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
			suffix = ".",
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
	}
}

local COMBINE_CALLSIGN_KEYS = {
	-- soldier names, remembered by speaker:
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

	-- metropolice unit names, remembered by speaker:
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

function PLUGIN:InitializedPlugins()
	self.ixVoicePlugin = ix.plugin.list["ixvoice"]
	self.reactedGrenades = self.reactedGrenades or {}
	self.playerCooldowns = self.playerCooldowns or {}
	self.nextGrenadeScan = 0
	self.nextDeathReaction = 0
	self.nextCombatScan = 0

	if (self.voiceTypes and self.voiceTypes.combine) then
		self.voiceTypes.combine.factions = {
			[FACTION_OTA] = true
			-- [FACTION_MPF] = true
		}
	end

	self:AssignAreaSectors()
end

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
		local sector = self:GetAreaSectorNumber(areaID)

		if (sector) then
			usedSectors[sector] = true

			if (areaName != "") then
				nameToSector[areaName] = nameToSector[areaName] or sector
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
				area.properties.sector = sharedSector
			else
				while (usedSectors[nextSector]) do
					nextSector = nextSector + 1
				end

				area.properties.sector = nextSector
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

function PLUGIN:CanAutoVoice(client)
	if (!self:IsVoicePluginAvailable() or !IsValid(client) or !client:IsPlayer()) then
		return false
	end

	if (!client:Alive() or client:GetMoveType() == MOVETYPE_NOCLIP or client:IsRagdoll()) then
		return false
	end

	if (!client:GetCharacter() or ix.option.Get(client, "autoVoiceEnabled", true) == false) then
		return false
	end

	local voiceType = self:GetVoiceType(client)

	return voiceType == "combine" and Schema:CanPlayerSeeCombineOverlay(client)
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
	local templates = COMBINE_TEMPLATE_SETS[templateName]

	if (!istable(templates) or #templates == 0) then
		return nil
	end

	local variant = table.Random(templates)

	if (!variant) then
		return nil
	end

	local sequence = {}
	local parts = {}

	local handlers = {
		designation = function()
			if (variant.useDesignation == true) then
				local name, num = self:GetCombineDesignationParts(client)

				if (name) then
					sequence[#sequence + 1] = name.sound
					parts[#parts + 1] = name.text .. (num and "" or ",")

					if (num) then
						for _, soundPath in ipairs(num) do
							sequence[#sequence + 1] = soundPath
						end
						parts[#parts + 1] = tostring(self:GetCombineUnitID(client).number) .. "."
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
						local name, num = self:GetCombineDesignationParts(target)

						if (name) then
							sequence[#sequence + 1] = name.sound
							parts[#parts + 1] = name.text

							if (num) then
								for _, soundPath in ipairs(num) do
									sequence[#sequence + 1] = soundPath
								end
								parts[#parts + 1] = tostring(self:GetCombineUnitID(target).number)
							end
						end
					else
						-- Human Players use randomized V_G0_PLAYERS variants
						local choices = {
							{sound = "npc/combine_soldier/vo/anticitizenone.wav", text = "반시민 1"},
							{sound = "npc/combine_soldier/vo/targetone.wav", text = "목표 대상 1"},
							{sound = "npc/combine_soldier/vo/priority1objective.wav", text = "1번 임무 목표 완수"},
							{sound = "npc/combine_soldier/vo/phantom.wav", text = "팬텀"},
							{sound = "npc/combine_soldier/vo/ghost2.wav", text = "고스트"}
						}
						local choice = table.Random(choices)
						
						sequence[#sequence + 1] = choice.sound
						parts[#parts + 1] = choice.text
					end
				elseif (target:IsNPC()) then
					local class = target:GetClass():lower()

					if (class:find("zombie") or class == "npc_zombine") then
						sequence[#sequence + 1] = "npc/combine_soldier/vo/necrotics.wav"
						parts[#parts + 1] = "변종"
					elseif (class:find("antlion") or class:find("headcrab")) then
						sequence[#sequence + 1] = "npc/combine_soldier/vo/exogens.wav"
						parts[#parts + 1] = "엑소젠"
					else
						-- Monstruous NPCs use variants EXCEPT Anticitizen One
						local choices = {
							{sound = "npc/combine_soldier/vo/targetone.wav", text = "목표 대상 1"},
							{sound = "npc/combine_soldier/vo/priority1objective.wav", text = "1번 임무 목표 완수"},
							{sound = "npc/combine_soldier/vo/phantom.wav", text = "팬텀"},
							{sound = "npc/combine_soldier/vo/ghost2.wav", text = "고스트"}
						}
						local choice = table.Random(choices)
						
						sequence[#sequence + 1] = choice.sound
						parts[#parts + 1] = choice.text
					end
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
				local label = self:GetAreaSectorLabel(client:GetArea()) or "구역"
				parts[#parts + 1] = label
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

					if (num) then
						for _, soundPath in ipairs(num) do
							sequence[#sequence + 1] = soundPath
						end
						parts[#parts + 1] = tostring(self:GetCombineUnitID(context.target).number)
					end
				end
			end
		end,
		suffix = function()
			if (variant.suffix and variant.suffix != "") then
				parts[#parts + 1] = variant.suffix
			end
		end
	}

	local layout = variant.layout or {
		"designation", "text", "victimDesignation", "V_G0_PLAYERS", "V_DISTS", "V_DIRS", "grid", "gridX", "dash", "gridY", "sectorLabel", "V_SECTORS", "suffix"
	}

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
		text = resultText
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

function PLUGIN:PlayCombineSequence(client, sounds, volume, isRadioTransmission)
	if (!self:CanAutoVoice(client) or !istable(sounds) or #sounds == 0) then
		return false
	end

	netstream.Start(nil, "voicePlay", self:BuildCombineSpeech(sounds), volume or 75, client:EntIndex(), isRadioTransmission == true, "combine")

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

		if (!target:Alive() or target:IsRagdoll() or !target:IsCombine()) then
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

		ix.chat.Send(client, "radio", text, false, nil, chatData)
		ix.chat.Send(client, "radio_eavesdrop", text, false, nil, eavesdropData)

		return true, true
	end

	if (self:HasNearbyCombineICListener(client)) then
		ix.chat.Send(client, "ic", text)

		return true, false
	end

	return false
end

function PLUGIN:EmitVoiceEvent(client, text, sounds, volume)
	if (!self:CanAutoVoice(client)) then
		return false
	end

	local radioData = self:GetActiveRadioState(client)
	local didSend, usedRadio = self:SendChatForVoice(client, text, radioData)

	if (!didSend) then
		return false
	end

	return self:PlayCombineSequence(client, sounds, volume, usedRadio)
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
		return self:EmitVoiceEvent(client, event.text, event.sounds)
	end

	return false
end

function PLUGIN:BuildManDownSequence(target)
	local _, info = Schema:GetCombineUnitID(target)

	if (!info) then
		return nil
	end

	local variant = table.Random(COMBINE_TEMPLATE_SETS.man_down) or {}
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
		if (!self:CanAutoVoice(target)) then
			continue
		end

		if (origin:DistToSqr(target:GetPos()) <= radiusSqr) then
			count = count + 1
		end
	end

	return count
end

function PLUGIN:PostEntityTakeDamage(target, damageInfo)
	if (!self:IsVoicePluginAvailable()) then
		return
	end

	local attacker = damageInfo:GetAttacker()

	-- Only care if the attacker is a valid Combine unit
	if (!IsValid(attacker) or !attacker:IsPlayer() or !attacker:IsAlive() or !attacker:IsCombine()) then
		return
	end

	-- Only care if the target is a player and NOT Combine
	if (!IsValid(target) or !target:IsPlayer() or !target:Alive() or target:IsCombine()) then
		return
	end

	local health = target:Health()
	local maxHealth = target:GetMaxHealth() or 100

	-- If the target is significantly damaged (below 30%)
	if (health > 0 and (health / maxHealth) <= 0.3) then
		if (self:CanUsePlayerCooldown(attacker, "player_hit", 15)) then
			local event = self:BuildTemplateEvent(attacker, "player_hit")

			if (event) then
				self:EmitVoiceEvent(attacker, event.text, event.sounds)
			end
		end
	end
end

function PLUGIN:HandleThrownGrenade(grenade)
	if (!IsValid(grenade) or grenade:GetClass() != GRENADE_CLASS) then
		return
	end

	if (grenade.ixAutoVoiceThrowHandled) then
		return
	end

	local owner = grenade.GetOwner and grenade:GetOwner() or nil

	if (!self:CanAutoVoice(owner) or !self:CanUsePlayerCooldown(owner, "throw_grenade", 1.5)) then
		return
	end

	grenade.ixAutoVoiceThrowHandled = true

	local event = self:BuildTemplateEvent(owner, "throwGrenade")

	if (event) then
		self:EmitVoiceEvent(owner, event.text, event.sounds)
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

	for _, mine in ipairs(ents.FindByClass("combine_mine")) do
		if (!IsValid(mine)) then continue end

		-- Check if the hopper mine is currently jumping (has vertical velocity)
		if (mine:GetVelocity().z > 30 and !mine:IsOnGround()) then
			local origin = mine:GetPos()

			for _, client in ipairs(player.GetAll()) do
				if (client:Alive() and client:IsCombine() and self:CanAutoVoice(client)) then
					if (client:GetPos():DistToSqr(origin) <= (200 * 200)) then -- 200 units reaction radius
						if (self:CanUsePlayerCooldown(client, "danger", 3)) then
							local event = self:BuildTemplateEvent(client, "danger")

							if (event) then
								self:EmitVoiceEvent(client, event.text, event.sounds)
								break -- Only one reactor per mine jump to avoid noise
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

		if (client:IsCombine() or faction == (FACTION_ADMIN or FACTION_CONSCRIPT)) then
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

function PLUGIN:ScanForCombatCallouts()
	local otaUnits = {}

	for _, client in ipairs(player.GetAll()) do
		if (client:Alive() and (client:Team() == FACTION_OTA or client:Team() == FACTION_MPF) and self:CanAutoVoice(client)) then
			local weapon = client:GetActiveWeapon()
			local weaponClass = IsValid(weapon) and weapon:GetClass() or ""

			if (client:IsWepRaised() and !EXCLUDED_WEAPONS[weaponClass]) then
				otaUnits[#otaUnits + 1] = client
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

				if (!trace.Hit) then
					targets[#targets + 1] = entity
				end
			end
		end

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
				if (self:IsSquadLeader(client)) then
					template = "leader_alert"

					-- Specialty check for non-humans
					if (!target:IsPlayer()) then
						local class = target:GetClass():lower()

						if (class:find("zombie") or class == "npc_zombine") then
							template = "monster_alert"
							forcedIndex = 3 -- MONST2: infected
						elseif (class:find("antlion") or class:find("headcrab")) then
							template = "monster_alert"
							forcedIndex = 2 -- MONST1: exogens
						else
							template = "monster_alert"
							forcedIndex = 1 -- MONST0: sterile
						end
					else
						-- Non-leader units use specific hazard sets
						local class = target:GetClass():lower()

						if (class:find("antlion")) then
							template = "monster_bugs"
						elseif (class:find("headcrab")) then
							template = "monster_parasites"
						elseif (class:find("zombie") or class == "npc_zombine") then
							template = "monster_zombies"
						end
					end
				end
			else
					-- If lost for more than 10 seconds, use refind_enemy
					local timeSinceLastSeen = CurTime() - (client.ixLastSeenTime or 0)

					if (timeSinceLastSeen > 10) then
						template = "refind_enemy"
					end
				end

				local event = self:BuildTemplateEvent(client, template, {
					target = targets[1],
					distance = distSqr,
					bearing = (targets[1]:GetPos() - client:GetPos()):Angle().y,
					forcedIndex = forcedIndex
				})

				if (event) then
					self:EmitVoiceEvent(client, event.text, event.sounds)

					return -- Only one callout per scan interval to avoid noise
				end
			end
		else
			-- No hostile visible. Check how long since last contact.
			if (unit.ixLastSeenTime) then
				local elapsed = CurTime() - unit.ixLastSeenTime

				if (elapsed >= 60) then -- Beyond combat timeout
					unit.ixLastSeenTime = nil
				elseif (elapsed >= 10 and !unit.ixHasTriggeredLostLong) then
					if (self:CanUsePlayerCooldown(unit, "combat_callout", 15)) then
						unit.ixHasTriggeredLostLong = true
						local event = self:BuildTemplateEvent(unit, "lost_long")

						if (event) then
							self:EmitVoiceEvent(unit, event.text, event.sounds)
							return
						end
					end
				elseif (elapsed >= 5 and !unit.ixHasTriggeredLostShort) then
					if (self:CanUsePlayerCooldown(unit, "combat_callout", 15)) then
						unit.ixHasTriggeredLostShort = true
						local event = self:BuildTemplateEvent(unit, "lost_short")

						if (event) then
							self:EmitVoiceEvent(unit, event.text, event.sounds)
							return
						end
					end
				end
			end
		end
	end
end

function PLUGIN:PlayerDeath(client)
	if (!self:IsVoicePluginAvailable() or !IsValid(client) or !client:IsCombine()) then
		return
	end

	local currentTime = CurTime()

	if (self.nextDeathReaction > currentTime) then
		return
	end

	self.nextDeathReaction = currentTime + DEATH_EVENT_COOLDOWN

	local event = self:BuildManDownSequence(client)

	if (!event) then
		return
	end

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
				self:EmitVoiceEvent(listener, lastSquadEvent.text, lastSquadEvent.sounds)
				break
			else
				self:EmitVoiceEvent(listener, event.text, event.sounds)
				break
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
