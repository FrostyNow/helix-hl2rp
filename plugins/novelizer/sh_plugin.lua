local PLUGIN = PLUGIN

PLUGIN.name = "Novelizer"
PLUGIN.author = "Codex"
PLUGIN.description = "Localized automatic narrative emotes for item use, interactions, and ambient machine actions."

PLUGIN.itemActionPhrasePools = PLUGIN.itemActionPhrasePools or {}
PLUGIN.entityUsePhrasePools = PLUGIN.entityUsePhrasePools or {}
PLUGIN.itPhrasePools = PLUGIN.itPhrasePools or {}
PLUGIN.classPatternPhrasePools = PLUGIN.classPatternPhrasePools or {}

local unpackArgs = table.unpack or unpack
local DEFAULT_RANGE_MULTIPLIER = 2
local DEFAULT_USE_COOLDOWN = 1.25
local DEFAULT_IT_COOLDOWN = 10

ix.lang.AddTable("english", {
	optNovelizerAutoActions = "Enable novelizer auto actions",
	optdNovelizerAutoActions = "Automatically narrates your interactions, item use, and nearby machine sounds.",

	novelizerSomething = "something",
	novelizerWorkbench = "workbench",
	novelizerStove = "stove",
	novelizerCID = "CID card",
	novelizerMeFormat = "** %s %s",

	novelizerEat1 = "takes a measured bite of %s.",
	novelizerEat2 = "eats some of %s.",
	novelizerEat3 = "nibbles at %s.",
	novelizerEat4 = "helps themselves to %s.",

	novelizerDrink1 = "takes a careful sip from %s.",
	novelizerDrink2 = "drinks from %s.",
	novelizerDrink3 = "tips back %s for a drink.",
	novelizerDrink4 = "has a mouthful of %s.",

	novelizerOtaConsume1 = "slots %s into the thoracic intake valve built into the suit.",
	novelizerOtaConsume2 = "feeds %s into the suit's chest injector port.",
	novelizerOtaConsume3 = "presses %s against the armor's intake valve until it is accepted.",

	novelizerOverlayDrink1 = "pulls the respirator intake aside and works %s through the mask.",
	novelizerOverlayDrink2 = "tilts the intake assembly open and pushes %s into the drinking port.",
	novelizerOverlayDrink3 = "feeds %s through the respirator intake with practiced economy.",

	novelizerOverlayEat1 = "twists the filter housing aside and works %s through the opening.",
	novelizerOverlayEat2 = "loosens the respirator filter just long enough to push %s through.",
	novelizerOverlayEat3 = "opens the filter assembly and feeds %s in through it.",

	novelizerEquip1 = "puts on %s.",
	novelizerEquip2 = "straps %s into place.",
	novelizerEquip3 = "settles into %s.",
	novelizerUnequip1 = "takes off %s.",
	novelizerUnequip2 = "removes %s.",
	novelizerUnequip3 = "shrugs out of %s.",

	novelizerWater1 = "crouches down and fills a container with dirty water.",
	novelizerWater2 = "collects some murky water by hand.",
	novelizerWater3 = "draws up a measure of dirty water.",

	novelizerRaise1 = "raises %s into a ready posture.",
	novelizerRaise2 = "brings %s up into line.",
	novelizerRaise3 = "sets %s at the shoulder.",
	novelizerLower1 = "lowers %s.",
	novelizerLower2 = "lets %s dip back down.",
	novelizerLower3 = "takes %s out of a ready stance.",
	novelizerReload1 = "reloads %s.",
	novelizerReload2 = "works a fresh magazine into %s.",
	novelizerReload3 = "cycles %s through a reload.",
	novelizerSwitch1 = "switches to %s.",
	novelizerSwitch2 = "draws %s.",
	novelizerSwitch3 = "brings %s into hand.",

	novelizerRequest1 = "keys a request into the device.",
	novelizerRequest2 = "speaks a brief request into the unit.",
	novelizerRequest3 = "sends a short request through the device.",
	novelizerRadio1 = "keys the radio and transmits.",
	novelizerRadio2 = "leans to the radio and speaks.",
	novelizerRadio3 = "presses the transmit key on the radio.",
	novelizerSetFreq1 = "adjusts a radio frequency.",
	novelizerSetFreq2 = "retunes a radio channel.",
	novelizerSetFreq3 = "dials in a new radio frequency.",
	novelizerSearch1 = "starts patting someone down.",
	novelizerSearch2 = "begins a quick search.",
	novelizerSearch3 = "checks someone over for carried items.",
	novelizerAmmo1 = "loads ammunition from %s.",
	novelizerAmmo2 = "feeds rounds in from %s.",
	novelizerAmmo3 = "tops up on ammunition with %s.",
	novelizerBattery1 = "uses %s to top up their suit reserves.",
	novelizerBattery2 = "plugs %s into their suit's power system.",
	novelizerBattery3 = "feeds power from %s into their equipment.",
	novelizerMedSelf1 = "applies %s to treat their own injuries.",
	novelizerMedSelf2 = "uses %s on themselves.",
	novelizerMedSelf3 = "works %s over their wounds.",
	novelizerMedOther1 = "uses %s to tend to someone else's injuries.",
	novelizerMedOther2 = "applies %s to another person's wounds.",
	novelizerMedOther3 = "leans in with %s to treat someone.",
	novelizerBandageSelf1 = "wraps %s around their own injuries.",
	novelizerBandageSelf2 = "binds themselves up with %s.",
	novelizerBandageSelf3 = "winds %s tight over a wound.",
	novelizerBandageOther1 = "wraps %s around someone else's wounds.",
	novelizerBandageOther2 = "binds another person's injuries with %s.",
	novelizerBandageOther3 = "leans in to dress someone's wounds with %s.",
	novelizerAedSelf1 = "presses %s into place and triggers a harsh shock.",
	novelizerAedSelf2 = "fumbles %s into position and discharges it.",
	novelizerAedSelf3 = "braces and sets off %s against their body.",
	novelizerAedOther1 = "plants %s against someone and fires a defibrillating shock.",
	novelizerAedOther2 = "sets %s on another person's chest and discharges it.",
	novelizerAedOther3 = "leans over with %s and sends a violent jolt through someone.",

	novelizerEquipHead1 = "settles %s over their head.",
	novelizerEquipHead2 = "pulls %s on over their hair.",
	novelizerEquipHead3 = "fits %s onto their head.",
	novelizerEquipHelmet1 = "settles %s low over their brow and tightens it down.",
	novelizerEquipHelmet2 = "fits %s snugly over their head.",
	novelizerEquipHelmet3 = "sets %s in place with a firm adjustment.",
	novelizerEquipFace1 = "pulls %s into place over their face.",
	novelizerEquipFace2 = "secures %s across their face.",
	novelizerEquipFace3 = "fits %s over their mouth and nose.",
	novelizerEquipRespirator1 = "draws %s over their face and checks the seal.",
	novelizerEquipRespirator2 = "locks %s into place over their breathing gear.",
	novelizerEquipRespirator3 = "settles %s over their face and tightens the straps.",
	novelizerEquipTorso1 = "shrugs into %s.",
	novelizerEquipTorso2 = "pulls %s into place over their torso.",
	novelizerEquipTorso3 = "settles %s across their body.",
	novelizerEquipArmor1 = "straps %s tight over their chest.",
	novelizerEquipArmor2 = "settles %s into place like a second shell.",
	novelizerEquipArmor3 = "cinches %s down over their torso.",
	novelizerEquipUniform1 = "smooths %s into place across their body.",
	novelizerEquipUniform2 = "pulls %s on and straightens it out.",
	novelizerEquipUniform3 = "buttons into %s and adjusts the fit.",
	novelizerEquipLegs1 = "steps into %s.",
	novelizerEquipLegs2 = "pulls %s up into place.",
	novelizerEquipLegs3 = "works into %s.",
	novelizerEquipFeet1 = "steps into %s and plants their feet.",
	novelizerEquipFeet2 = "works their feet into %s.",
	novelizerEquipFeet3 = "stamps %s into a comfortable fit.",
	novelizerEquipHands1 = "pulls on %s.",
	novelizerEquipHands2 = "fits %s over their hands.",
	novelizerEquipHands3 = "works their hands into %s.",
	novelizerEquipBag1 = "slings %s into place.",
	novelizerEquipBag2 = "settles %s onto their shoulder.",
	novelizerEquipBag3 = "hoists %s into position.",
	novelizerEquipWeapon1 = "slings %s into a ready carry.",
	novelizerEquipWeapon2 = "settles %s where it can be drawn cleanly.",
	novelizerEquipWeapon3 = "hangs %s within easy reach.",
	novelizerUnequipHead1 = "pulls %s off their head.",
	novelizerUnequipHead2 = "lifts %s away from their head.",
	novelizerUnequipHead3 = "takes %s off.",
	novelizerUnequipHelmet1 = "lifts %s clear of their head.",
	novelizerUnequipHelmet2 = "unfastens %s and removes it.",
	novelizerUnequipHelmet3 = "pulls %s off and lowers it to one side.",
	novelizerUnequipFace1 = "peels %s away from their face.",
	novelizerUnequipFace2 = "unfastens %s from their face.",
	novelizerUnequipFace3 = "draws %s down and off.",
	novelizerUnequipRespirator1 = "breaks the seal on %s and peels it away.",
	novelizerUnequipRespirator2 = "loosens %s and draws it off their face.",
	novelizerUnequipRespirator3 = "unfastens %s from their respirator rig.",
	novelizerUnequipTorso1 = "shrugs out of %s.",
	novelizerUnequipTorso2 = "pulls %s off their torso.",
	novelizerUnequipTorso3 = "undoes %s and slips free of it.",
	novelizerUnequipArmor1 = "undoes %s and lifts it off their chest.",
	novelizerUnequipArmor2 = "shrugs free of %s's weight.",
	novelizerUnequipArmor3 = "loosens %s and slips out from under it.",
	novelizerUnequipUniform1 = "peels out of %s and straightens their clothes.",
	novelizerUnequipUniform2 = "undoes %s and slips it off.",
	novelizerUnequipUniform3 = "shrugs %s off in one practiced motion.",
	novelizerUnequipLegs1 = "steps out of %s.",
	novelizerUnequipLegs2 = "pulls free of %s.",
	novelizerUnequipLegs3 = "works out of %s.",
	novelizerUnequipFeet1 = "steps out of %s.",
	novelizerUnequipFeet2 = "kicks free of %s.",
	novelizerUnequipFeet3 = "works their feet back out of %s.",
	novelizerUnequipHands1 = "pulls %s off their hands.",
	novelizerUnequipHands2 = "peels %s away from their hands.",
	novelizerUnequipHands3 = "strips off %s.",
	novelizerUnequipBag1 = "slips %s from their shoulder.",
	novelizerUnequipBag2 = "takes %s off their back.",
	novelizerUnequipBag3 = "unshoulders %s.",
	novelizerUnequipWeapon1 = "unslings %s.",
	novelizerUnequipWeapon2 = "takes %s out of its carry position.",
	novelizerUnequipWeapon3 = "slips %s free of its strap.",

	novelizerGrenadePrime1 = "hooks a finger through the pin ring on %s.",
	novelizerGrenadePrime2 = "pulls the pin on %s.",
	novelizerGrenadePrime3 = "primes %s with a sharp tug.",
	novelizerMolotovPrime1 = "strikes a light and sets %s burning.",
	novelizerMolotovPrime2 = "touches flame to %s.",
	novelizerMolotovPrime3 = "sets %s alight and cocks their arm back.",

	novelizerFlashlightOn1 = "clicks %s on.",
	novelizerFlashlightOn2 = "thumbs %s to life.",
	novelizerFlashlightOn3 = "brings %s up and switches it on.",
	novelizerFlashlightOff1 = "switches %s off.",
	novelizerFlashlightOff2 = "kills the beam from %s.",
	novelizerFlashlightOff3 = "clicks %s dark.",

	novelizerMachineVending1 = "leans over %s and works its selector buttons.",
	novelizerMachineVending2 = "jabs at the controls on %s.",
	novelizerMachineVending3 = "coaxes a choice out of %s.",

	novelizerMachineCoffee1 = "keys a drink selection into %s.",
	novelizerMachineCoffee2 = "works through the options on %s.",
	novelizerMachineCoffee3 = "taps a selection into %s and waits.",

	novelizerMachineHealth1 = "presses into %s and steadies themselves for the injection.",
	novelizerMachineHealth2 = "leans against %s and activates its medical cycle.",
	novelizerMachineHealth3 = "triggers %s and braces for the dose.",

	novelizerMachineRation1 = "presents themselves to %s and works its controls.",
	novelizerMachineRation2 = "keys an authorization sequence into %s.",
	novelizerMachineRation3 = "operates %s with practiced motions.",

	novelizerMachineComputer1 = "types across %s.",
	novelizerMachineComputer2 = "works through a sequence on %s.",
	novelizerMachineComputer3 = "leans over %s and enters commands.",
	novelizerMachineComputer4 = "taps through menus on %s.",

	novelizerMachineTerminal1 = "uses %s for a quick request.",
	novelizerMachineTerminal2 = "works the interface on %s.",
	novelizerMachineTerminal3 = "keys a short submission into %s.",

	novelizerMachineLock1 = "checks %s and works at its mechanism.",
	novelizerMachineLock2 = "enters something into %s.",
	novelizerMachineLock3 = "manipulates the controls on %s.",

	novelizerMachineRecycler1 = "loads scrap into %s and starts the cycle.",
	novelizerMachineRecycler2 = "feeds material through %s.",
	novelizerMachineRecycler3 = "works %s into motion with a clatter of junk.",

	novelizerMachineForcefield1 = "reaches for the controls on %s.",
	novelizerMachineForcefield2 = "adjusts something on %s.",
	novelizerMachineForcefield3 = "works the field controls on %s.",

	novelizerMachineRadio1 = "adjusts the controls on %s.",
	novelizerMachineRadio2 = "tunes %s by hand.",
	novelizerMachineRadio3 = "fiddles with the dials on %s.",

	novelizerMachinePanel1 = "runs a hand over %s and presses at its controls.",
	novelizerMachinePanel2 = "works a sequence into %s.",
	novelizerMachinePanel3 = "uses %s with quick, practiced inputs.",
	novelizerMachineWasher1 = "loads %s and starts a wash cycle.",
	novelizerMachineWasher2 = "works the controls on %s and sets it turning.",
	novelizerMachineWasher3 = "shuts %s and sends it into a wash cycle.",
	novelizerMachineDoorOpen1 = "reaches for %s and pushes it open.",
	novelizerMachineDoorOpen2 = "works the handle on %s and opens it.",
	novelizerMachineDoorOpen3 = "pulls %s wide.",
	novelizerMachineDoorClose1 = "pulls %s shut.",
	novelizerMachineDoorClose2 = "swings %s closed.",
	novelizerMachineDoorClose3 = "guides %s back into place.",
	novelizerMachineDoorUse1 = "tries the handle on %s.",
	novelizerMachineDoorUse2 = "works %s open with a hand on the handle.",
	novelizerMachineDoorUse3 = "uses %s with a quick push and pull.",
	novelizerLoot1 = "starts rummaging through %s for anything useful.",
	novelizerLoot2 = "leans into %s and digs through the junk inside.",
	novelizerLoot3 = "starts pawing through %s in search of salvage.",
	novelizerApply1 = "takes out %s and holds it up for inspection.",
	novelizerApply2 = "produces %s and presents it.",
	novelizerApply3 = "pulls out %s to show their identification.",
	novelizerCraft1 = "sets to work assembling something at %s.",
	novelizerCraft2 = "starts piecing materials together at %s.",
	novelizerCraft3 = "leans over %s and begins a bit of fabrication.",
	novelizerCook1 = "starts cooking at %s.",
	novelizerCook2 = "works over %s with a cook's focus.",
	novelizerCook3 = "begins preparing food at %s.",
	novelizerDisassemble1 = "starts breaking material down at %s.",
	novelizerDisassemble2 = "takes something apart over %s.",
	novelizerDisassemble3 = "works scrap apart at %s.",
	novelizerTransform1 = "reworks material at %s.",
	novelizerTransform2 = "starts refining parts at %s.",
	novelizerTransform3 = "processes components at %s.",
	novelizerCookFood1 = "turns %s over the heat and starts cooking it.",
	novelizerCookFood2 = "sets %s to cook with patient care.",
	novelizerCookFood3 = "starts cooking %s.",

	novelizerUse1 = "interacts with %s.",
	novelizerUse2 = "fiddles with %s.",
	novelizerUse3 = "works at %s for a moment.",
	novelizerUse4 = "examines %s and uses it.",

	novelizerItDiskRead1 = "%s gives off the soft chatter of a disk drive.",
	novelizerItDiskRead2 = "%s emits a brief burst of disk-reading noise.",
	novelizerItDiskRead3 = "%s clicks and whirs as it reads from storage.",
	novelizerItMachineHum1 = "%s emits a low mechanical hum.",
	novelizerItMachineHum2 = "%s drones quietly as it runs.",
	novelizerItMachineHum3 = "%s vibrates with a steady industrial note.",
	novelizerItLaundryPipe1 = "%s rattles overhead as laundry drops through it.",
	novelizerItLaundryPipe2 = "%s clanks softly with the fall of bundled cloth.",
	novelizerItLaundryPipe3 = "%s shudders as another load of laundry slides down.",
	novelizerItWasher1 = "%s sloshes and churns through a wash cycle.",
	novelizerItWasher2 = "%s rocks with the heavy churn of wet laundry.",
	novelizerItWasher3 = "%s rumbles through another turn of its drum.",
	novelizerItVending1 = "%s hums and rattles behind its product coils.",
	novelizerItVending2 = "%s buzzes with a tired refrigeration motor.",
	novelizerItVending3 = "%s gives a metallic clunk from somewhere inside.",
	novelizerItForcefield1 = "%s crackles with a hard electric buzz.",
	novelizerItForcefield2 = "%s emits a taut, humming field-noise.",
	novelizerItForcefield3 = "%s snaps faintly with contained energy.",
	novelizerItRadio1 = "%s hisses with a wash of static.",
	novelizerItRadio2 = "%s spits a brief burst of radio noise.",
	novelizerItRadio3 = "%s crackles through an unstable channel.",
	novelizerItStove1 = "%s hisses with steady heat.",
	novelizerItStove2 = "%s crackles and throws off a wash of heat.",
	novelizerItStove3 = "%s pops softly as it burns.",
	novelizerItWorkbench1 = "%s answers with a light rattle of tools and loose parts.",
	novelizerItWorkbench2 = "%s gives a dry clink of metal tools.",
	novelizerItWorkbench3 = "%s chatters with the sound of parts being set down."
})

ix.lang.AddTable("korean", {
	optNovelizerAutoActions = "노벨라이저 자동 행동 사용",
	optdNovelizerAutoActions = "상호작용, 물건 사용, 주변 기계음 묘사를 자동으로 현지화해 출력합니다.",

	novelizerSomething = "무언가",
	novelizerWorkbench = "작업대",
	novelizerStove = "조리대",
	novelizerCID = "신분증",
	novelizerMeFormat = "** %s %s",

	novelizerEat1 = "%s 천천히 한입 베어 뭅니다.",
	novelizerEat2 = "%s 조금 먹습니다.",
	novelizerEat3 = "%s 조금씩 뜯어 먹습니다.",
	novelizerEat4 = "%s 입에 가져갑니다.",

	novelizerDrink1 = "%s 조심스럽게 한 모금 마십니다.",
	novelizerDrink2 = "%s 들이켜 마십니다.",
	novelizerDrink3 = "%s 입에 대고 마십니다.",
	novelizerDrink4 = "%s 한 모금 머금습니다.",

	novelizerOtaConsume1 = "흉부에 달린 주입 밸브에 %s 밀어 넣습니다.",
	novelizerOtaConsume2 = "흉부 취입 포트에 %s 장착해 흡수시킵니다.",
	novelizerOtaConsume3 = "흉부의 밸브에 %s 눌러 넣어 처리합니다.",

	novelizerOverlayDrink1 = "방독면 취수구를 젖혀 %s 밀어 넣습니다.",
	novelizerOverlayDrink2 = "취수구를 열고 %s 밀어 넣습니다.",
	novelizerOverlayDrink3 = "호흡기 취수구를 비켜 %s 안으로 흘려 넣습니다.",

	novelizerOverlayEat1 = "정화통을 비틀어 열고 %s 밀어 넣습니다.",
	novelizerOverlayEat2 = "정화통을 잠깐 풀어 %s 안으로 넣습니다.",
	novelizerOverlayEat3 = "정화통을 돌려 열고 %s 밀어 넣습니다.",

	novelizerEquip1 = "%s 착용합니다.",
	novelizerEquip2 = "%s 맞춰 장착합니다.",
	novelizerEquip3 = "%s 걸치고 매무새를 다듬습니다.",
	novelizerUnequip1 = "%s 벗습니다.",
	novelizerUnequip2 = "%s 풀어 해제합니다.",
	novelizerUnequip3 = "%s 벗겨 냅니다.",

	novelizerWater1 = "더러운 물을 담습니다.",
	novelizerWater2 = "탁한 물을 조심스럽게 떠 담습니다.",
	novelizerWater3 = "물을 향해 손을 뻗어 더러운 물을 담습니다.",

	novelizerRaise1 = "%s 겨눌 태세로 들어 올립니다.",
	novelizerRaise2 = "%s 사격 준비 자세로 올립니다.",
	novelizerRaise3 = "%s 어깨선까지 끌어올립니다.",
	novelizerLower1 = "%s 내립니다.",
	novelizerLower2 = "%s 긴장한 자세에서 내립니다.",
	novelizerLower3 = "%s 준비 자세에서 풀어 둡니다.",
	novelizerReload1 = "%s 장전합니다.",
	novelizerReload2 = "%s 새 탄창을 밀어 넣습니다.",
	novelizerReload3 = "%s 장전 동작을 마칩니다.",
	novelizerSwitch1 = "%s 바꿔 듭니다.",
	novelizerSwitch2 = "%s 꺼내 듭니다.",
	novelizerSwitch3 = "%s 손에 쥡니다.",

	novelizerRequest1 = "단말기에 짧은 요청을 넣습니다.",
	novelizerRequest2 = "기기에 대고 짧게 요청합니다.",
	novelizerRequest3 = "장치로 간단한 요청을 보냅니다.",
	novelizerRadio1 = "무전을 잡고 송신합니다.",
	novelizerRadio2 = "무전기에 입을 가까이 대고 말합니다.",
	novelizerRadio3 = "무전 송신 키를 누릅니다.",
	novelizerSetFreq1 = "무전 주파수를 조정합니다.",
	novelizerSetFreq2 = "무전 채널을 다시 맞춥니다.",
	novelizerSetFreq3 = "새 무전 주파수를 입력합니다.",
	novelizerSearch1 = "몸을 수색하기 시작합니다.",
	novelizerSearch2 = "짧게 소지품 수색을 시작합니다.",
	novelizerSearch3 = "지닌 물건이 있는지 몸을 확인합니다.",
	novelizerBandageSelf1 = "%s 자기 상처에 감아 둡니다.",
	novelizerBandageSelf2 = "%s 자기 몸의 상처에 둘러 묶습니다.",
	novelizerBandageSelf3 = "%s 상처 부위에 단단히 감습니다.",
	novelizerBandageOther1 = "%s 다른 사람 상처에 감아 줍니다.",
	novelizerBandageOther2 = "%s 타인의 부상 부위를 감아 처치합니다.",
	novelizerBandageOther3 = "%s 상처를 감아 고정해줍니다.",
	novelizerAedSelf1 = "%s 몸에 대고 거친 충격을 가합니다.",
	novelizerAedSelf2 = "%s 자기 몸에 붙여 방전을 일으킵니다.",
	novelizerAedSelf3 = "%s 몸에 밀착시킨 채 충격을 보냅니다.",
	novelizerAedOther1 = "%s 다른 사람 몸에 대고 제세동 충격을 가합니다.",
	novelizerAedOther2 = "%s 흉부에 붙여 방전시킵니다.",
	novelizerAedOther3 = "%s 몸을 숙여 강한 전기 충격을 보냅니다.",

	novelizerEquipHead1 = "%s 머리에 눌러 씁니다.",
	novelizerEquipHead2 = "%s 머리 위에 바로잡아 씁니다.",
	novelizerEquipHead3 = "%s 머리에 맞춰 착용합니다.",
	novelizerEquipHelmet1 = "%s 이마 쪽까지 눌러 쓰고 단단히 고정합니다.",
	novelizerEquipHelmet2 = "%s 머리에 맞춰 깊게 눌러 씁니다.",
	novelizerEquipHelmet3 = "%s 제자리에 맞춘 뒤 고정합니다.",
	novelizerEquipFace1 = "%s 얼굴에 끌어올려 씁니다.",
	novelizerEquipFace2 = "%s 얼굴에 고정합니다.",
	novelizerEquipFace3 = "%s 입과 코 앞에 맞춰 씁니다.",
	novelizerEquipRespirator1 = "%s 얼굴에 대고 밀착을 확인합니다.",
	novelizerEquipRespirator2 = "%s 호흡 장비 위에 맞춰 고정합니다.",
	novelizerEquipRespirator3 = "%s 얼굴에 씌운 뒤 끈을 조여 맞춥니다.",
	novelizerEquipTorso1 = "%s 걸칩니다.",
	novelizerEquipTorso2 = "%s 몸통에 맞춰 입습니다.",
	novelizerEquipTorso3 = "%s 몸에 둘러 착용합니다.",
	novelizerEquipArmor1 = "%s 흉부에 단단히 조여 착용합니다.",
	novelizerEquipArmor2 = "%s 몸통 위에 단단히 맞춰 고정합니다.",
	novelizerEquipArmor3 = "%s 몸에 둘러 단단히 조입니다.",
	novelizerEquipUniform1 = "%s 몸에 맞춰 정리해 입습니다.",
	novelizerEquipUniform2 = "%s 꺼내 입고 매무새를 다듬습니다.",
	novelizerEquipUniform3 = "%s 여미고 옷매무새를 맞춥니다.",
	novelizerEquipLegs1 = "%s 다리에 걸쳐 입습니다.",
	novelizerEquipLegs2 = "%s 끌어올려 입습니다.",
	novelizerEquipLegs3 = "%s 다리에 맞춰 착용합니다.",
	novelizerEquipFeet1 = "%s 신고 발을 고정합니다.",
	novelizerEquipFeet2 = "%s 발에 맞춰 신습니다.",
	novelizerEquipFeet3 = "%s 신은 뒤 발을 몇 번 딛어 봅니다.",
	novelizerEquipHands1 = "%s 손에 낍니다.",
	novelizerEquipHands2 = "%s 손을 집어넣어 착용합니다.",
	novelizerEquipHands3 = "%s 손에 맞춰 끼웁니다.",
	novelizerEquipBag1 = "%s 어깨에 멥니다.",
	novelizerEquipBag2 = "%s 몸에 둘러 멥니다.",
	novelizerEquipBag3 = "%s 들어 메고 자리를 잡습니다.",
	novelizerEquipWeapon1 = "%s 몸에 걸쳐 휴대합니다.",
	novelizerEquipWeapon2 = "%s 바로 꺼낼 수 있게 멥니다.",
	novelizerEquipWeapon3 = "%s 손이 닿기 쉬운 자리로 걸어 둡니다.",
	novelizerUnequipHead1 = "%s 머리에서 벗습니다.",
	novelizerUnequipHead2 = "%s 머리에서 들어 올려 벗습니다.",
	novelizerUnequipHead3 = "%s 벗어 냅니다.",
	novelizerUnequipHelmet1 = "%s 머리에서 들어 올려 벗습니다.",
	novelizerUnequipHelmet2 = "%s 고정을 풀고 벗습니다.",
	novelizerUnequipHelmet3 = "%s 벗어 한쪽으로 내립니다.",
	novelizerUnequipFace1 = "%s 얼굴에서 벗깁니다.",
	novelizerUnequipFace2 = "%s 얼굴에서 풀어 냅니다.",
	novelizerUnequipFace3 = "%s 아래로 내렸다 벗습니다.",
	novelizerUnequipRespirator1 = "%s 밀착을 떼고 얼굴에서 벗깁니다.",
	novelizerUnequipRespirator2 = "%s 끈을 풀어 얼굴에서 떼어 냅니다.",
	novelizerUnequipRespirator3 = "%s 호흡 장비에서 분리해 벗습니다.",
	novelizerUnequipTorso1 = "%s 벗어 냅니다.",
	novelizerUnequipTorso2 = "%s 몸에서 풀어 냅니다.",
	novelizerUnequipTorso3 = "%s 어깨에서 벗겨 냅니다.",
	novelizerUnequipArmor1 = "%s 결속을 풀고 몸에서 벗깁니다.",
	novelizerUnequipArmor2 = "%s 흉부에서 풀어 냅니다.",
	novelizerUnequipArmor3 = "%s 무게를 풀어 내려 벗습니다.",
	novelizerUnequipUniform1 = "%s 매무새를 풀어 벗습니다.",
	novelizerUnequipUniform2 = "%s 여밈을 풀고 벗어 냅니다.",
	novelizerUnequipUniform3 = "%s 몸에서 벗겨 냅니다.",
	novelizerUnequipLegs1 = "%s 벗어 다리에서 빼냅니다.",
	novelizerUnequipLegs2 = "%s 끌어내려 벗습니다.",
	novelizerUnequipLegs3 = "%s 다리에서 벗겨 냅니다.",
	novelizerUnequipFeet1 = "%s 벗습니다.",
	novelizerUnequipFeet2 = "%s 발에서 빼냅니다.",
	novelizerUnequipFeet3 = "%s 벗어 발을 뺍니다.",
	novelizerUnequipHands1 = "%s 손에서 벗깁니다.",
	novelizerUnequipHands2 = "%s 손끝부터 벗겨 냅니다.",
	novelizerUnequipHands3 = "%s 손에서 빼냅니다.",
	novelizerUnequipBag1 = "%s 어깨에서 내립니다.",
	novelizerUnequipBag2 = "%s 몸에서 풀어 냅니다.",
	novelizerUnequipBag3 = "%s 내려놓듯 벗습니다.",
	novelizerUnequipWeapon1 = "%s 몸에서 풉니다.",
	novelizerUnequipWeapon2 = "%s 휴대 위치에서 빼냅니다.",
	novelizerUnequipWeapon3 = "%s 걸친 자리에서 풀어 냅니다.",

	novelizerGrenadePrime1 = "%s 안전핀 고리를 손가락에 겁니다.",
	novelizerGrenadePrime2 = "%s 핀을 뽑습니다.",
	novelizerGrenadePrime3 = "%s 짧게 당겨 기폭 준비를 합니다.",
	novelizerMolotovPrime1 = "%s 불을 붙입니다.",
	novelizerMolotovPrime2 = "%s 심지에 불을 옮깁니다.",
	novelizerMolotovPrime3 = "%s 점화한 채 팔을 뒤로 젖힙니다.",
	novelizerAmmo1 = "%s 탄약을 꺼내 장전합니다.",
	novelizerAmmo2 = "%s 탄환을 꺼내 보충합니다.",
	novelizerAmmo3 = "%s 탄약으로 잔탄을 채웁니다.",
	novelizerBattery1 = "%s 전력을 보충합니다.",
	novelizerBattery2 = "%s 장비 전원계에 연결합니다.",
	novelizerBattery3 = "%s 동력으로 장비를 충전합니다.",
	novelizerMedSelf1 = "%s 자기 상처에 사용합니다.",
	novelizerMedSelf2 = "%s 스스로 응급 처치에 씁니다.",
	novelizerMedSelf3 = "%s 자기 몸의 상처에 대어 처치합니다.",
	novelizerMedOther1 = "%s 다른 사람 상처를 치료합니다.",
	novelizerMedOther2 = "%s 타인의 부상 부위에 사용합니다.",
	novelizerMedOther3 = "%s 치료하려 몸을 숙입니다.",

	novelizerFlashlightOn1 = "%s 켭니다.",
	novelizerFlashlightOn2 = "%s 스위치를 올려 불을 밝힙니다.",
	novelizerFlashlightOn3 = "%s 켜 광선을 만듭니다.",
	novelizerFlashlightOff1 = "%s 끕니다.",
	novelizerFlashlightOff2 = "%s 불빛을 죽입니다.",
	novelizerFlashlightOff3 = "%s 스위치를 내려 광선을 끕니다.",

	novelizerMachineVending1 = "%s 선택 버튼을 눌러 봅니다.",
	novelizerMachineVending2 = "%s 조작부를 두드립니다.",
	novelizerMachineVending3 = "%s 앞에서 원하는 항목을 고릅니다.",

	novelizerMachineCoffee1 = "%s 음료 선택부를 눌러 봅니다.",
	novelizerMachineCoffee2 = "%s 메뉴를 훑으며 버튼을 누릅니다.",
	novelizerMachineCoffee3 = "%s 조작부에 짧게 입력합니다.",

	novelizerMachineHealth1 = "%s 몸을 붙이고 의료 주기를 작동시킵니다.",
	novelizerMachineHealth2 = "%s 기대선 채 주입을 받으려 합니다.",
	novelizerMachineHealth3 = "%s 활성화하고 투여를 기다립니다.",

	novelizerMachineRation1 = "%s 앞에서 인증 절차를 밟습니다.",
	novelizerMachineRation2 = "%s 조작부에 익숙한 손놀림으로 입력합니다.",
	novelizerMachineRation3 = "%s 사용해 배급 절차를 진행합니다.",

	novelizerMachineComputer1 = "%s 자판을 두드립니다.",
	novelizerMachineComputer2 = "%s 명령을 입력합니다.",
	novelizerMachineComputer3 = "%s 몸을 기울여 조작합니다.",
	novelizerMachineComputer4 = "%s 메뉴를 빠르게 넘깁니다.",

	novelizerMachineTerminal1 = "%s 짧은 요청을 입력합니다.",
	novelizerMachineTerminal2 = "%s 인터페이스를 조작합니다.",
	novelizerMachineTerminal3 = "%s 입력부에 손을 댑니다.",

	novelizerMachineLock1 = "%s 잠금 장치를 만져 봅니다.",
	novelizerMachineLock2 = "%s 제어부에 입력합니다.",
	novelizerMachineLock3 = "%s 메커니즘을 조작합니다.",

	novelizerMachineRecycler1 = "%s 폐품을 밀어 넣고 작동시킵니다.",
	novelizerMachineRecycler2 = "%s 투입구에 재료를 넣습니다.",
	novelizerMachineRecycler3 = "%s 덜컹거리게 만들며 주기를 시작합니다.",

	novelizerMachineForcefield1 = "%s 제어부에 손을 뻗습니다.",
	novelizerMachineForcefield2 = "%s 설정을 조정합니다.",
	novelizerMachineForcefield3 = "%s 필드 제어기를 조작합니다.",

	novelizerMachineRadio1 = "%s 다이얼을 만지작거립니다.",
	novelizerMachineRadio2 = "%s 주파수를 맞춥니다.",
	novelizerMachineRadio3 = "%s 조작부를 손으로 조정합니다.",

	novelizerMachinePanel1 = "%s 표면을 훑고 조작부를 누릅니다.",
	novelizerMachinePanel2 = "%s 짧은 입력 절차를 밟습니다.",
	novelizerMachinePanel3 = "%s 익숙한 손놀림으로 다룹니다.",
	novelizerMachineWasher1 = "%s 세탁물을 넣고 세탁을 시작합니다.",
	novelizerMachineWasher2 = "%s 조작부를 눌러 세탁을 돌리기 시작합니다.",
	novelizerMachineWasher3 = "%s 닫고 세탁을 돌립니다.",
	novelizerMachineDoorOpen1 = "%s 손잡이를 잡고 엽니다.",
	novelizerMachineDoorOpen2 = "%s 밀어 엽니다.",
	novelizerMachineDoorOpen3 = "%s 당겨 엽니다.",
	novelizerMachineDoorClose1 = "%s 닫습니다.",
	novelizerMachineDoorClose2 = "%s 밀어 닫습니다.",
	novelizerMachineDoorClose3 = "%s 원래 자리로 닫아 둡니다.",
	novelizerMachineDoorUse1 = "%s 손잡이를 시험하듯 잡아 봅니다.",
	novelizerMachineDoorUse2 = "%s 손으로 밀고 당겨 다룹니다.",
	novelizerMachineDoorUse3 = "%s 손잡이에 손을 얹고 움직입니다.",
	novelizerLoot1 = "%s 안을 뒤져 쓸 만한 것을 찾기 시작합니다.",
	novelizerLoot2 = "%s 안쪽을 뒤적이며 폐품을 찾습니다.",
	novelizerLoot3 = "%s 안을 파헤치듯 뒤집니다.",
	novelizerApply1 = "%s 꺼내 보입니다.",
	novelizerApply2 = "%s 손에 들어 제시합니다.",
	novelizerApply3 = "%s 신분을 확인시키듯 내밉니다.",
	novelizerCraft1 = "%s 앞에서 재료를 조립하기 시작합니다.",
	novelizerCraft2 = "%s 위에 재료를 늘어놓고 제작을 시작합니다.",
	novelizerCraft3 = "%s 몸을 숙여 제작 작업에 들어갑니다.",
	novelizerCook1 = "%s 앞에서 조리를 시작합니다.",
	novelizerCook2 = "%s 열을 살피며 조리합니다.",
	novelizerCook3 = "%s 앞에서 음식 준비를 시작합니다.",
	novelizerDisassemble1 = "%s 위에서 재료를 분해하기 시작합니다.",
	novelizerDisassemble2 = "%s 앞에서 물건을 뜯어 부품을 가려 냅니다.",
	novelizerDisassemble3 = "%s 위에 폐품을 올려 분해합니다.",
	novelizerTransform1 = "%s 위에서 재료를 다시 가공합니다.",
	novelizerTransform2 = "%s 앞에서 부품을 손질해 바꿉니다.",
	novelizerTransform3 = "%s 위에서 자재를 다른 형태로 가공합니다.",
	novelizerCookFood1 = "%s 불에 올려 조리하기 시작합니다.",
	novelizerCookFood2 = "%s 열 위에서 천천히 익히기 시작합니다.",
	novelizerCookFood3 = "%s 조리합니다.",

	novelizerUse1 = "%s 상호작용합니다.",
	novelizerUse2 = "%s 이것저것 만져 봅니다.",
	novelizerUse3 = "%s 잠시 다뤄 봅니다.",
	novelizerUse4 = "%s 살펴본 뒤 사용합니다.",

	novelizerItDiskRead1 = "%s 디스크를 읽는 달그락거림이 새어 나옵니다.",
	novelizerItDiskRead2 = "%s 저장 장치를 읽는 짧은 기계음이 울립니다.",
	novelizerItDiskRead3 = "%s 데이터를 읽으며 딸깍거리고 윙윙거립니다.",
	novelizerItMachineHum1 = "%s 낮은 기계음을 흘립니다.",
	novelizerItMachineHum2 = "%s 작동하며 조용히 웅웅거립니다.",
	novelizerItMachineHum3 = "%s 일정한 산업용 진동음을 냅니다.",
	novelizerItLaundryPipe1 = "%s 위쪽에서 세탁물이 떨어지며 덜컹거립니다.",
	novelizerItLaundryPipe2 = "%s 안에서 천 뭉치가 지나가며 약하게 금속음을 냅니다.",
	novelizerItLaundryPipe3 = "%s 세탁물이 미끄러져 내려오며 한차례 떨립니다.",
	novelizerItWasher1 = "%s 세탁 주기를 돌리며 철퍽거리고 웅웅거립니다.",
	novelizerItWasher2 = "%s 젖은 세탁물을 굴리며 무겁게 흔들립니다.",
	novelizerItWasher3 = "%s 드럼이 한 바퀴 돌 때마다 낮게 울립니다.",
	novelizerItVending1 = "%s 안쪽 코일 뒤에서 윙윙거리며 덜컹댑니다.",
	novelizerItVending2 = "%s 오래된 냉각 장치가 웅웅거립니다.",
	novelizerItVending3 = "%s 내부 어딘가에서 금속성 덜컥임이 납니다.",
	novelizerItForcefield1 = "%s 딱딱한 전기음과 함께 지직거립니다.",
	novelizerItForcefield2 = "%s 팽팽한 장막음처럼 웅웅거립니다.",
	novelizerItForcefield3 = "%s 갇힌 에너지가 튀듯 희미하게 딱딱거립니다.",
	novelizerItRadio1 = "%s 희미한 잡음을 흘립니다.",
	novelizerItRadio2 = "%s 짧은 무전 잡음을 튀깁니다.",
	novelizerItRadio3 = "%s 불안정한 채널에서 지직거립니다.",
	novelizerItStove1 = "%s 일정한 열기와 함께 치익거립니다.",
	novelizerItStove2 = "%s 타오르며 약하게 딱딱거립니다.",
	novelizerItStove3 = "%s 열기를 뿜으며 잔불 소리를 냅니다.",
	novelizerItWorkbench1 = "%s 위에서 공구와 부품이 가볍게 달그락거립니다.",
	novelizerItWorkbench2 = "%s 금속 공구 부딪히는 마른 소리를 냅니다.",
	novelizerItWorkbench3 = "%s 위에서 작은 부품들이 달각거리며 놓입니다."
})

ix.option.Add("novelizerAutoActions", ix.type.bool, true, {
	category = "chat",
	bNetworked = true
})

ix.config.Add("novelizerEnableIt", true, "Whether novelizer should emit ambient /it lines for nearby machinery and systems.", nil, {
	category = "chat"
})

local function GetChatRange()
	return ix.config.Get("chatRange", 280) * DEFAULT_RANGE_MULTIPLIER
end

local function CopyArray(source)
	local result = {}

	for i = 1, #source do
		result[i] = source[i]
	end

	return result
end

local function IsFilledString(value)
	return isstring(value) and value:find("%S") ~= nil
end

local function GetLanguage()
	if (CLIENT) then
		return ix.option.Get("language", "english")
	end

	return "english"
end

local function GetPhraseTemplate(phraseKey, language)
	if (not IsFilledString(phraseKey)) then
		return nil
	end

	local languages = ix.lang and ix.lang.stored

	if (not istable(languages)) then
		return nil
	end

	language = language or GetLanguage()

	local info = languages[language] or languages.english

	return (info and info[phraseKey]) or (languages.english and languages.english[phraseKey]) or nil
end

local function GetLastUTF8Codepoint(text)
	if (not utf8 or not utf8.offset or not utf8.codepoint or not isstring(text) or text == "") then
		return nil
	end

	local success, offset = pcall(utf8.offset, text, -1)

	if (not success or not offset) then
		offset = #text

		while (offset > 1) do
			local byte = text:byte(offset)

			if (not byte or byte < 128 or byte > 191) then
				break
			end

			offset = offset - 1
		end
	end

	local codepointSuccess, codepoint = pcall(utf8.codepoint, text, offset)

	if (not codepointSuccess) then
		return nil
	end

	return codepoint
end

local function AppendKoreanParticle(text, particleType)
	if (not IsFilledString(text) or not IsFilledString(particleType)) then
		return text
	end

	local codepoint = GetLastUTF8Codepoint(text)

	if (not codepoint or codepoint < 0xAC00 or codepoint > 0xD7A3) then
		if (particleType == "object") then
			return text .. "를"
		elseif (particleType == "subject") then
			return text .. "가"
		elseif (particleType == "topic") then
			return text .. "는"
		elseif (particleType == "with") then
			return text .. "와"
		elseif (particleType == "direction") then
			return text .. "로"
		end

		return text
	end

	local finalConsonant = (codepoint - 0xAC00) % 28

	if (particleType == "object") then
		return text .. (finalConsonant == 0 and "를" or "을")
	elseif (particleType == "subject") then
		return text .. (finalConsonant == 0 and "가" or "이")
	elseif (particleType == "topic") then
		return text .. (finalConsonant == 0 and "는" or "은")
	elseif (particleType == "with") then
		return text .. (finalConsonant == 0 and "와" or "과")
	elseif (particleType == "direction") then
		return text .. ((finalConsonant == 0 or finalConsonant == 8) and "로" or "으로")
	end

	return text
end

local function BuildArgument(text, particle, phrase)
	return {
		text = text,
		particle = particle,
		phrase = phrase
	}
end

function PLUGIN:GetLocalizedArgumentValue(value, language)
	if (istable(value)) then
		local localized

		if (IsFilledString(value.phrase)) then
			localized = GetPhraseTemplate(value.phrase, language)
		end

		if (not IsFilledString(localized) and IsFilledString(value.text)) then
			localized = value.text
		end

		if (not IsFilledString(localized)) then
			localized = L("novelizerSomething")
		end

		if (language == "korean" and IsFilledString(value.particle)) then
			localized = AppendKoreanParticle(localized, value.particle)
		end

		return localized
	end

	if (isstring(value)) then
		return GetPhraseTemplate(value, language) or value
	end

	return value
end

function PLUGIN:GetLocalizedArguments(data)
	local arguments = {}
	local source = data and data.arguments or {}
	local language = GetLanguage()

	for i = 1, #source do
		arguments[i] = self:GetLocalizedArgumentValue(source[i], language)
	end

	return arguments
end

function PLUGIN:TranslatePhrase(phraseKey, data)
	local language = GetLanguage()
	local arguments = self:GetLocalizedArguments(data)
	local format = GetPhraseTemplate(phraseKey, language) or phraseKey

	return string.format(format, unpackArgs(arguments))
end

function PLUGIN:GetCharacterDisplayName(client, anonymous, info)
	if (anonymous or (info and info.anonymous)) then
		return L("someone"), ix.config.Get("chatColor")
	end

	local color = ix.config.Get("chatColor")
	local name = hook.Run("GetCharacterName", client, "novelme") or (IsValid(client) and client:Name() or "Console")

	if (IsValid(client)) then
		color = client:GetClassColor() or team.GetColor(client:Team())
	end

	return name, color
end

function PLUGIN:GetRawItemSubject(item)
	if (item and IsFilledString(item.novelizerSubject)) then
		return item.novelizerSubject
	end

	if (item and IsFilledString(item.name)) then
		return L2(item.name) or item.name
	end

	return L("novelizerSomething")
end

function PLUGIN:GetRawEntitySubject(entity)
	if (not IsValid(entity)) then
		return L("novelizerSomething")
	end

	if (IsFilledString(entity.novelizerSubject)) then
		return entity.novelizerSubject
	end

	if (isfunction(entity.GetDisplayName)) then
		local name = entity:GetDisplayName()

		if (IsFilledString(name)) then
			return L2(name) or name
		end
	end

	if (IsFilledString(entity.PrintName) and entity.PrintName ~= "Entity") then
		return L2(entity.PrintName) or entity.PrintName
	end

	local className = entity:GetClass()

	if (IsFilledString(className)) then
		return className
	end

	return L("novelizerSomething")
end

function PLUGIN:GetItemSubject(item)
	if (item and IsFilledString(item.novelizerSubject)) then
		return BuildArgument(item.novelizerSubject, "object")
	end

	if (item and IsFilledString(item.name)) then
		return BuildArgument(item.name, "object", item.name)
	end

	return BuildArgument(L("novelizerSomething"), "object")
end

function PLUGIN:GetEntitySubject(entity)
	if (not IsValid(entity)) then
		return BuildArgument(L("novelizerSomething"), "object")
	end

	if (IsFilledString(entity.novelizerSubject)) then
		return BuildArgument(entity.novelizerSubject, "object")
	end

	if (isfunction(entity.GetDisplayName)) then
		local name = entity:GetDisplayName()

		if (IsFilledString(name)) then
			return BuildArgument(name, "object", name)
		end
	end

	if (IsFilledString(entity.PrintName) and entity.PrintName ~= "Entity") then
		return BuildArgument(entity.PrintName, "object", entity.PrintName)
	end

	local className = entity:GetClass()

	if (IsFilledString(className)) then
		return BuildArgument(className, "object")
	end

	return BuildArgument(L("novelizerSomething"), "object")
end

function PLUGIN:GetWeaponSubject(weapon)
	if (not IsValid(weapon)) then
		return BuildArgument(L("novelizerSomething"), "object")
	end

	if (istable(weapon.ixItem)) then
		return self:GetItemSubject(weapon.ixItem)
	end

	local printName = weapon:GetPrintName()

	if (IsFilledString(printName) and printName ~= weapon:GetClass()) then
		return BuildArgument(printName, "object", printName)
	end

	if (IsFilledString(weapon.PrintName) and weapon.PrintName ~= "Scripted Weapon") then
		return BuildArgument(weapon.PrintName, "object", weapon.PrintName)
	end

	return BuildArgument(weapon:GetClass(), "object")
end

function PLUGIN:GetEquipCategory(item)
	if (not item) then
		return "generic"
	end

	if (item.isWeapon) then
		return "weapon"
	end

	local category = string.lower(tostring(item.outfitCategory or ""))
	local uniqueID = string.lower(tostring(item.uniqueID or ""))
	local name = string.lower(tostring(item.name or ""))

	if (item.gasmask or uniqueID:find("gasmask", 1, true) or name:find("gasmask", 1, true)
		or uniqueID:find("respirator", 1, true) or name:find("respirator", 1, true)) then
		return "respirator"
	end

	if (category == "mask" or category == "goggles" or uniqueID:find("mask", 1, true)
		or uniqueID:find("facewrap", 1, true) or uniqueID:find("goggles", 1, true)
		or uniqueID:find("visor", 1, true) or name:find("mask", 1, true)
		or name:find("goggles", 1, true) or name:find("visor", 1, true)) then
		return "face"
	end

	if (category == "head" or category == "headstrap" or uniqueID:find("helmet", 1, true)
		or name:find("helmet", 1, true) or name:find("hard helmet", 1, true)) then
		return "helmet"
	end

	if (uniqueID:find("hat", 1, true) or uniqueID:find("beanie", 1, true)
		or uniqueID:find("cap", 1, true) or uniqueID:find("beret", 1, true)
		or name:find("hat", 1, true) or name:find("beanie", 1, true)
		or name:find("cap", 1, true) or name:find("beret", 1, true)) then
		return "head"
	end

	if (category == "kevlar" or category == "armor" or uniqueID:find("armor", 1, true)
		or uniqueID:find("vest", 1, true) or uniqueID:find("rig", 1, true)
		or name:find("armor", 1, true) or name:find("vest", 1, true)) then
		return "armor"
	end

	if (category == "torso" or category == "outfit" or category == "model" or category == "suit"
		or uniqueID:find("uniform", 1, true) or uniqueID:find("jacket", 1, true)
		or uniqueID:find("coat", 1, true) or uniqueID:find("shirt", 1, true)
		or uniqueID:find("suit", 1, true) or name:find("uniform", 1, true)
		or name:find("jacket", 1, true) or name:find("coat", 1, true)
		or name:find("shirt", 1, true) or name:find("suit", 1, true)) then
		return "uniform"
	end

	if (category == "torso") then
		return "torso"
	end

	if (category == "legs" or uniqueID:find("pants", 1, true) or uniqueID:find("trousers", 1, true)
		or name:find("pants", 1, true) or name:find("trousers", 1, true)) then
		return "legs"
	end

	if (category == "feet" or uniqueID:find("boots", 1, true) or uniqueID:find("shoes", 1, true)
		or name:find("boots", 1, true) or name:find("shoes", 1, true)) then
		return "feet"
	end

	if (category == "hands" or uniqueID:find("glove", 1, true) or name:find("glove", 1, true)) then
		return "hands"
	end

	if (category == "bags" or uniqueID:find("bag", 1, true) or uniqueID:find("pack", 1, true)
		or uniqueID:find("backpack", 1, true) or uniqueID:find("satchel", 1, true)
		or uniqueID:find("suitcase", 1, true) or name:find("bag", 1, true)
		or name:find("backpack", 1, true) or name:find("satchel", 1, true)) then
		return "bag"
	end

	return "generic"
end

function PLUGIN:GetEquipPhrasePool(item, action)
	local category = self:GetEquipCategory(item)
	local isEquip = action == "Equip"

	if (category == "helmet") then
		return isEquip and {"novelizerEquipHelmet1", "novelizerEquipHelmet2", "novelizerEquipHelmet3"}
			or {"novelizerUnequipHelmet1", "novelizerUnequipHelmet2", "novelizerUnequipHelmet3"}
	elseif (category == "head") then
		return isEquip and {"novelizerEquipHead1", "novelizerEquipHead2", "novelizerEquipHead3"}
			or {"novelizerUnequipHead1", "novelizerUnequipHead2", "novelizerUnequipHead3"}
	elseif (category == "respirator") then
		return isEquip and {"novelizerEquipRespirator1", "novelizerEquipRespirator2", "novelizerEquipRespirator3"}
			or {"novelizerUnequipRespirator1", "novelizerUnequipRespirator2", "novelizerUnequipRespirator3"}
	elseif (category == "face") then
		return isEquip and {"novelizerEquipFace1", "novelizerEquipFace2", "novelizerEquipFace3"}
			or {"novelizerUnequipFace1", "novelizerUnequipFace2", "novelizerUnequipFace3"}
	elseif (category == "armor") then
		return isEquip and {"novelizerEquipArmor1", "novelizerEquipArmor2", "novelizerEquipArmor3"}
			or {"novelizerUnequipArmor1", "novelizerUnequipArmor2", "novelizerUnequipArmor3"}
	elseif (category == "uniform" or category == "torso") then
		return isEquip and {"novelizerEquipUniform1", "novelizerEquipUniform2", "novelizerEquipUniform3"}
			or {"novelizerUnequipUniform1", "novelizerUnequipUniform2", "novelizerUnequipUniform3"}
	elseif (category == "weapon") then
		return isEquip and {"novelizerEquipWeapon1", "novelizerEquipWeapon2", "novelizerEquipWeapon3"}
			or {"novelizerUnequipWeapon1", "novelizerUnequipWeapon2", "novelizerUnequipWeapon3"}
	elseif (category == "torso") then
		return isEquip and {"novelizerEquipTorso1", "novelizerEquipTorso2", "novelizerEquipTorso3"}
			or {"novelizerUnequipTorso1", "novelizerUnequipTorso2", "novelizerUnequipTorso3"}
	elseif (category == "legs") then
		return isEquip and {"novelizerEquipLegs1", "novelizerEquipLegs2", "novelizerEquipLegs3"}
			or {"novelizerUnequipLegs1", "novelizerUnequipLegs2", "novelizerUnequipLegs3"}
	elseif (category == "feet") then
		return isEquip and {"novelizerEquipFeet1", "novelizerEquipFeet2", "novelizerEquipFeet3"}
			or {"novelizerUnequipFeet1", "novelizerUnequipFeet2", "novelizerUnequipFeet3"}
	elseif (category == "hands") then
		return isEquip and {"novelizerEquipHands1", "novelizerEquipHands2", "novelizerEquipHands3"}
			or {"novelizerUnequipHands1", "novelizerUnequipHands2", "novelizerUnequipHands3"}
	elseif (category == "bag") then
		return isEquip and {"novelizerEquipBag1", "novelizerEquipBag2", "novelizerEquipBag3"}
			or {"novelizerUnequipBag1", "novelizerUnequipBag2", "novelizerUnequipBag3"}
	end

	return isEquip and {"novelizerEquip1", "novelizerEquip2", "novelizerEquip3"}
		or {"novelizerUnequip1", "novelizerUnequip2", "novelizerUnequip3"}
end

function PLUGIN:IsObserver(client)
	return IsValid(client) and client:GetMoveType() == MOVETYPE_NOCLIP and not client:InVehicle()
end

function PLUGIN:CanAutoNarrate(client)
	return IsValid(client)
		and client:IsPlayer()
		and client:GetCharacter()
		and client:Alive()
		and not self:IsObserver(client)
		and ix.option.Get(client, "novelizerAutoActions", true) ~= false
end

function PLUGIN:CanSeeCombineOverlay(client)
	return Schema and Schema.CanPlayerSeeCombineOverlay and Schema:CanPlayerSeeCombineOverlay(client) or false
end

function PLUGIN:GetConsumptionProfile(client)
	if (not IsValid(client) or not client:IsCombine()) then
		return "default"
	end

	if (client:Team() == FACTION_OTA) then
		return "ota"
	end

	if (self:CanSeeCombineOverlay(client)) then
		return "overlay"
	end

	return "default"
end

function PLUGIN:RegisterItemActionPhrases(uniqueID, action, phrasePool)
	self.itemActionPhrasePools[uniqueID] = self.itemActionPhrasePools[uniqueID] or {}
	self.itemActionPhrasePools[uniqueID][action] = CopyArray(phrasePool)
end

function PLUGIN:RegisterEntityUsePhrases(className, phrasePool)
	self.entityUsePhrasePools[className] = CopyArray(phrasePool)
end

function PLUGIN:RegisterPatternUsePhrases(pattern, phrasePool)
	self.classPatternPhrasePools[#self.classPatternPhrasePools + 1] = {
		pattern = pattern,
		pool = CopyArray(phrasePool)
	}
end

function PLUGIN:RegisterItPhrases(key, phrasePool)
	self.itPhrasePools[key] = CopyArray(phrasePool)
end

function PLUGIN:ResolveItemPhrasePool(item, action, client)
	if (item and istable(item.novelizerPhrases) and istable(item.novelizerPhrases[action])) then
		return item.novelizerPhrases[action]
	end

	if (item and self.itemActionPhrasePools[item.uniqueID] and self.itemActionPhrasePools[item.uniqueID][action]) then
		return self.itemActionPhrasePools[item.uniqueID][action]
	end

	local profile = self:GetConsumptionProfile(client)

	if (profile == "ota") then
		return {
			"novelizerOtaConsume1",
			"novelizerOtaConsume2",
			"novelizerOtaConsume3"
		}
		elseif (profile == "overlay" and action == "Drink") then
			return {
				"novelizerOverlayDrink1",
				"novelizerOverlayDrink2",
				"novelizerOverlayDrink3"
			}
		elseif (profile == "overlay" and action == "Eat") then
			return {
				"novelizerOverlayEat1",
				"novelizerOverlayEat2",
				"novelizerOverlayEat3"
			}
		end

	if (action == "Eat") then
		return {
			"novelizerEat1",
			"novelizerEat2",
			"novelizerEat3",
			"novelizerEat4"
		}
	elseif (action == "Drink") then
		return {
			"novelizerDrink1",
			"novelizerDrink2",
			"novelizerDrink3",
			"novelizerDrink4"
		}
	end
end

function PLUGIN:ResolveEntityUsePhrasePool(entity)
	if (not IsValid(entity)) then
		return nil
	end

	if (istable(entity.novelizerUsePhrases)) then
		return entity.novelizerUsePhrases
	end

	local className = entity:GetClass()

	if (self.entityUsePhrasePools[className]) then
		return self.entityUsePhrasePools[className]
	end

	for _, entry in ipairs(self.classPatternPhrasePools) do
		if (className:find(entry.pattern, 1, true)) then
			return entry.pool
		end
	end

	return {
		"novelizerUse1",
		"novelizerUse2",
		"novelizerUse3",
		"novelizerUse4"
	}
end

function PLUGIN:ResolveItPhrasePool(entity, key)
	if (IsValid(entity) and istable(entity.novelizerItPhrases) and istable(entity.novelizerItPhrases[key])) then
		return entity.novelizerItPhrases[key]
	end

	return self.itPhrasePools[key]
end

function PLUGIN:ShouldIgnoreEntityUse(entity)
	if (not IsValid(entity)) then
		return true
	end

	if (entity.novelizerSuppressUse) then
		return true
	end

	if (entity:IsPlayer() or entity:IsWeapon() or entity:IsVehicle() or entity:IsWorld()) then
		return true
	end

	if (entity:GetClass() == "ix_item" or entity:GetClass() == "prop_ragdoll") then
		return true
	end

	if (entity:GetClass():find("ix_loot_", 1, true)) then
		return true
	end

	return false
end

function PLUGIN:PassUseCooldown(client, entity, cooldown)
	client.ixNovelizerUseCooldowns = client.ixNovelizerUseCooldowns or {}

	local key = IsValid(entity) and entity:EntIndex() or 0
	local nextUse = client.ixNovelizerUseCooldowns[key] or 0
	local currentTime = CurTime()

	if (nextUse > currentTime) then
		return false
	end

	client.ixNovelizerUseCooldowns[key] = currentTime + (cooldown or DEFAULT_USE_COOLDOWN)
	return true
end

function PLUGIN:PassNamedCooldown(client, key, cooldown)
	client.ixNovelizerNamedCooldowns = client.ixNovelizerNamedCooldowns or {}

	local nextUse = client.ixNovelizerNamedCooldowns[key] or 0
	local currentTime = CurTime()

	if (nextUse > currentTime) then
		return false
	end

	client.ixNovelizerNamedCooldowns[key] = currentTime + cooldown
	return true
end

function PLUGIN:IsNarratableWeapon(weapon)
	if (not IsValid(weapon)) then
		return false
	end

	local item = weapon.ixItem

	return istable(item)
		and item.isWeapon == true
		and IsFilledString(item.class)
		and item.class == weapon:GetClass()
end

function PLUGIN:GetDoorPhrasePool(entity)
	if (not IsValid(entity) or not entity:IsDoor()) then
		return nil
	end

	local saveTable = entity.GetSaveTable and entity:GetSaveTable() or nil
	local toggleState = saveTable and (saveTable.m_toggle_state or saveTable.m_eDoorState) or nil

	if (toggleState == 0) then
		return {
			"novelizerMachineDoorOpen1",
			"novelizerMachineDoorOpen2",
			"novelizerMachineDoorOpen3"
		}
	elseif (toggleState == 1 or toggleState == 2) then
		return {
			"novelizerMachineDoorClose1",
			"novelizerMachineDoorClose2",
			"novelizerMachineDoorClose3"
		}
	end

	return {
		"novelizerMachineDoorUse1",
		"novelizerMachineDoorUse2",
		"novelizerMachineDoorUse3"
	}
end

function PLUGIN:PassItCooldown(entity, key, cooldown)
	if (not IsValid(entity)) then
		return true
	end

	entity.ixNovelizerItCooldowns = entity.ixNovelizerItCooldowns or {}

	local nextUse = entity.ixNovelizerItCooldowns[key] or 0
	local currentTime = CurTime()

	if (nextUse > currentTime) then
		return false
	end

	entity.ixNovelizerItCooldowns[key] = currentTime + (cooldown or DEFAULT_IT_COOLDOWN)
	return true
end

function PLUGIN:SendNovelMe(client, phraseKey, arguments, data)
	if (not self:CanAutoNarrate(client) or not IsFilledString(phraseKey)) then
		return false
	end

	data = data or {}
	data.arguments = arguments or {}
	data.range = data.range or GetChatRange()

	ix.chat.Send(client, "novelme", phraseKey, false, nil, data)
	return true
end

function PLUGIN:EmitConditionalIt(entity, key, data)
	if (ix.config.Get("novelizerEnableIt", true) ~= true) then
		return false
	end

	local phrasePool = self:ResolveItPhrasePool(entity, key)

	if (not istable(phrasePool) or #phrasePool == 0) then
		return false
	end

	data = data or {}

	local cooldownKey = data.cooldownKey or key or phrasePool[1]
	if (not self:PassItCooldown(entity, cooldownKey, data.cooldown)) then
		return false
	end

	local position = data.position or (IsValid(entity) and entity:GetPos())

	if (not position) then
		return false
	end

	local arguments = data.arguments and CopyArray(data.arguments) or {
		self:GetEntitySubject(entity)
	}

	ix.chat.Send(nil, "novelit", table.Random(phrasePool), false, nil, {
		arguments = arguments,
		position = position,
		range = data.range or GetChatRange()
	})

	return true
end

function PLUGIN:PatchItemAction(itemTable, action)
	if (not itemTable.functions or not itemTable.functions[action]) then
		return
	end

	itemTable.ixNovelizerPatchedActions = itemTable.ixNovelizerPatchedActions or {}

	if (itemTable.ixNovelizerPatchedActions[action]) then
		return
	end

	itemTable.ixNovelizerPatchedActions[action] = true

	itemTable:PostHook(action, function(item)
		local client = item.player
		local phrasePool = self:ResolveItemPhrasePool(item, action, client)

		if (not self:CanAutoNarrate(client) or not istable(phrasePool) or #phrasePool == 0) then
			return
		end

		self:SendNovelMe(client, table.Random(phrasePool), {
			self:GetItemSubject(item)
		})
	end)
end

function PLUGIN:PatchEquipmentAction(itemTable, action)
	if (not itemTable.functions or not itemTable.functions[action]) then
		return
	end

	itemTable.ixNovelizerPatchedActions = itemTable.ixNovelizerPatchedActions or {}

	if (itemTable.ixNovelizerPatchedActions[action]) then
		return
	end

	itemTable.ixNovelizerPatchedActions[action] = true

	itemTable:PostHook(action, function(item, result)
		local client = item.player or item:GetOwner()

		if (not self:CanAutoNarrate(client)) then
			return
		end

		if (action == "Equip" and item:GetData("equip") == true) then
			self:SendNovelMe(client, table.Random(self:GetEquipPhrasePool(item, action)), {
				self:GetItemSubject(item)
			})
		elseif (action == "EquipUn" and item:GetData("equip") ~= true) then
			self:SendNovelMe(client, table.Random(self:GetEquipPhrasePool(item, action)), {
				self:GetItemSubject(item)
			})
		end
	end)
end

function PLUGIN:PatchDirectItemAction(itemTable, action, phrasePool)
	if (not itemTable.functions or not itemTable.functions[action]) then
		return
	end

	itemTable.ixNovelizerPatchedActions = itemTable.ixNovelizerPatchedActions or {}

	if (itemTable.ixNovelizerPatchedActions[action]) then
		return
	end

	itemTable.ixNovelizerPatchedActions[action] = true

	itemTable:PostHook(action, function(item)
		local client = item.player or item:GetOwner()

		if (not self:CanAutoNarrate(client)) then
			return
		end

		self:SendNovelMe(client, table.Random(phrasePool), {
			self:GetItemSubject(item)
		})
	end)
end

function PLUGIN:GetMedicalPhrasePool(itemTable, action)
	local uniqueID = string.lower(tostring(itemTable.uniqueID or ""))

	if (uniqueID == "bandage" or uniqueID == "bandage_dirty") then
		return action == "selfheal"
			and {"novelizerBandageSelf1", "novelizerBandageSelf2", "novelizerBandageSelf3"}
			or {"novelizerBandageOther1", "novelizerBandageOther2", "novelizerBandageOther3"}
	end

	if (uniqueID == "aed") then
		return action == "selfheal"
			and {"novelizerAedSelf1", "novelizerAedSelf2", "novelizerAedSelf3"}
			or {"novelizerAedOther1", "novelizerAedOther2", "novelizerAedOther3"}
	end

	return action == "selfheal"
		and {"novelizerMedSelf1", "novelizerMedSelf2", "novelizerMedSelf3"}
		or {"novelizerMedOther1", "novelizerMedOther2", "novelizerMedOther3"}
end

function PLUGIN:PatchItems()
	for _, itemTable in pairs(ix.item.list) do
		self:PatchItemAction(itemTable, "Eat")
		self:PatchItemAction(itemTable, "Drink")
		self:PatchCookAction(itemTable)
		self:PatchEquipmentAction(itemTable, "Equip")
		self:PatchEquipmentAction(itemTable, "EquipUn")

		if (itemTable.base == "ammo" or itemTable.ammo) then
			self:PatchDirectItemAction(itemTable, "use", {
				"novelizerAmmo1",
				"novelizerAmmo2",
				"novelizerAmmo3"
			})
			self:PatchDirectItemAction(itemTable, "useall", {
				"novelizerAmmo1",
				"novelizerAmmo2",
				"novelizerAmmo3"
			})
		end

		if (itemTable.uniqueID == "battery") then
			self:PatchDirectItemAction(itemTable, "Use", {
				"novelizerBattery1",
				"novelizerBattery2",
				"novelizerBattery3"
			})
		end

		if (itemTable.base == "base_medikit" or itemTable.healthPoint ~= nil and itemTable.medAttr ~= nil) then
			self:PatchDirectItemAction(itemTable, "selfheal", self:GetMedicalPhrasePool(itemTable, "selfheal"))
			self:PatchDirectItemAction(itemTable, "heal", self:GetMedicalPhrasePool(itemTable, "heal"))
		end
	end
end

function PLUGIN:PatchCookAction(itemTable)
	if (not itemTable.functions or not itemTable.functions.Cook or itemTable.ixNovelizerCookWrapped) then
		return
	end

	itemTable.ixNovelizerCookWrapped = true

	local action = itemTable.functions.Cook
	local originalOnRun = action.OnRun

	if (not isfunction(originalOnRun)) then
		return
	end

	action.OnRun = function(item, ...)
		local client = item.player or item:GetOwner()
		local previousCooklevel = item:GetData("cooklevel", 0)
		local result = originalOnRun(item, ...)

		if (self:CanAutoNarrate(client) and previousCooklevel == 0 and item:GetData("cooklevel", 0) > 0) then
			local stove = self:GetNearbyCookingEntity(client)

			self:SendNovelMe(client, table.Random({
				"novelizerCookFood1",
				"novelizerCookFood2",
				"novelizerCookFood3"
			}), {
				self:GetItemSubject(item)
			})

			if (stove) then
				self:EmitConditionalIt(stove, "stove_heat", {
					cooldown = 4
				})
			end
		end

		return result
	end
end

function PLUGIN:RegisterDefaultEntityPhrases()
	self:RegisterEntityUsePhrases("ix_vendingmachine", {
		"novelizerMachineVending1",
		"novelizerMachineVending2",
		"novelizerMachineVending3"
	})
	self:RegisterEntityUsePhrases("ix_pepsimachine", {
		"novelizerMachineVending1",
		"novelizerMachineVending2",
		"novelizerMachineVending3"
	})
	self:RegisterEntityUsePhrases("ix_coffeemachine", {
		"novelizerMachineCoffee1",
		"novelizerMachineCoffee2",
		"novelizerMachineCoffee3"
	})
	self:RegisterEntityUsePhrases("ix_health_charger", {
		"novelizerMachineHealth1",
		"novelizerMachineHealth2",
		"novelizerMachineHealth3"
	})
	self:RegisterEntityUsePhrases("ix_rationdispenser", {
		"novelizerMachineRation1",
		"novelizerMachineRation2",
		"novelizerMachineRation3"
	})
	self:RegisterEntityUsePhrases("ix_interactive_computer", {
		"novelizerMachineComputer1",
		"novelizerMachineComputer2",
		"novelizerMachineComputer3",
		"novelizerMachineComputer4"
	})
	self:RegisterEntityUsePhrases("ix_assistance_terminal", {
		"novelizerMachineTerminal1",
		"novelizerMachineTerminal2",
		"novelizerMachineTerminal3"
	})
	self:RegisterEntityUsePhrases("ix_broadcast_console", {
		"novelizerMachineTerminal1",
		"novelizerMachineTerminal2",
		"novelizerMachineTerminal3"
	})
	self:RegisterEntityUsePhrases("ix_combinelock", {
		"novelizerMachineLock1",
		"novelizerMachineLock2",
		"novelizerMachineLock3"
	})
	self:RegisterEntityUsePhrases("ix_unionlock", {
		"novelizerMachineLock1",
		"novelizerMachineLock2",
		"novelizerMachineLock3"
	})
	self:RegisterEntityUsePhrases("ix_recycler", {
		"novelizerMachineRecycler1",
		"novelizerMachineRecycler2",
		"novelizerMachineRecycler3"
	})
	self:RegisterEntityUsePhrases("ix_washing_machine", {
		"novelizerMachineWasher1",
		"novelizerMachineWasher2",
		"novelizerMachineWasher3"
	})
	self:RegisterEntityUsePhrases("ix_washing_machine_small", {
		"novelizerMachineWasher1",
		"novelizerMachineWasher2",
		"novelizerMachineWasher3"
	})
	self:RegisterEntityUsePhrases("ix_forcefield", {
		"novelizerMachineForcefield1",
		"novelizerMachineForcefield2",
		"novelizerMachineForcefield3"
	})
	self:RegisterEntityUsePhrases("ix_scrollpanel", {
		"novelizerMachinePanel1",
		"novelizerMachinePanel2",
		"novelizerMachinePanel3"
	})
	self:RegisterEntityUsePhrases("ix_radiorepeater", {
		"novelizerMachineRadio1",
		"novelizerMachineRadio2",
		"novelizerMachineRadio3"
	})
	self:RegisterEntityUsePhrases("ix_stationary_radio", {
		"novelizerMachineRadio1",
		"novelizerMachineRadio2",
		"novelizerMachineRadio3"
	})
	self:RegisterEntityUsePhrases("ix_station", {
		"novelizerCraft1",
		"novelizerCraft2",
		"novelizerCraft3"
	})
	self:RegisterEntityUsePhrases("ix_station_workbench", {
		"novelizerCraft1",
		"novelizerCraft2",
		"novelizerCraft3"
	})
	self:RegisterEntityUsePhrases("ix_station_craftingtable", {
		"novelizerCraft1",
		"novelizerCraft2",
		"novelizerCraft3"
	})
	self:RegisterEntityUsePhrases("ix_stove", {
		"novelizerCook1",
		"novelizerCook2",
		"novelizerCook3"
	})
	self:RegisterEntityUsePhrases("ix_bonfire", {
		"novelizerCook1",
		"novelizerCook2",
		"novelizerCook3"
	})
	self:RegisterEntityUsePhrases("ix_bucket", {
		"novelizerCook1",
		"novelizerCook2",
		"novelizerCook3"
	})

	self:RegisterPatternUsePhrases("computer", {
		"novelizerMachineComputer1",
		"novelizerMachineComputer2",
		"novelizerMachineComputer3",
		"novelizerMachineComputer4"
	})
	self:RegisterPatternUsePhrases("terminal", {
		"novelizerMachineTerminal1",
		"novelizerMachineTerminal2",
		"novelizerMachineTerminal3"
	})
	self:RegisterPatternUsePhrases("console", {
		"novelizerMachineTerminal1",
		"novelizerMachineTerminal2",
		"novelizerMachineTerminal3"
	})
	self:RegisterPatternUsePhrases("lock", {
		"novelizerMachineLock1",
		"novelizerMachineLock2",
		"novelizerMachineLock3"
	})
	self:RegisterPatternUsePhrases("panel", {
		"novelizerMachinePanel1",
		"novelizerMachinePanel2",
		"novelizerMachinePanel3"
	})
	self:RegisterPatternUsePhrases("radio", {
		"novelizerMachineRadio1",
		"novelizerMachineRadio2",
		"novelizerMachineRadio3"
	})
	self:RegisterPatternUsePhrases("washer", {
		"novelizerMachineWasher1",
		"novelizerMachineWasher2",
		"novelizerMachineWasher3"
	})
	self:RegisterPatternUsePhrases("station_", {
		"novelizerCraft1",
		"novelizerCraft2",
		"novelizerCraft3"
	})
end

function PLUGIN:PatchWaterCommand()
	local command = ix.command.list["collectwater"] or ix.command.list["CollectWater"]

	if (not command or command.ixNovelizerWrapped) then
		return
	end

	command.ixNovelizerWrapped = true

	local originalOnRun = command.OnRun

	command.OnRun = function(this, client, ...)
		local result = originalOnRun(this, client, ...)

		if (result == nil) then
			self:SendNovelMe(client, table.Random({
				"novelizerWater1",
				"novelizerWater2",
				"novelizerWater3"
			}), {})
		end

		return result
	end
end

function PLUGIN:PatchCommand(commandName, phrasePool, argumentsBuilder)
	local command = ix.command.list[commandName] or ix.command.list[string.lower(commandName)]

	if (not command or command.ixNovelizerWrapped) then
		return
	end

	command.ixNovelizerWrapped = true

	local originalOnRun = command.OnRun

	command.OnRun = function(this, client, ...)
		local result = originalOnRun(this, client, ...)

		if (result == nil and self:CanAutoNarrate(client)) then
			local arguments = argumentsBuilder and argumentsBuilder(client, ...) or {}
			self:SendNovelMe(client, table.Random(phrasePool), arguments)
		end

		return result
	end
end

function PLUGIN:PatchCommandActions()
	self:PatchCommand("Request", {
		"novelizerRequest1",
		"novelizerRequest2",
		"novelizerRequest3"
	})
	self:PatchCommand("Radio", {
		"novelizerRadio1",
		"novelizerRadio2",
		"novelizerRadio3"
	})
	self:PatchCommand("RadioWhisper", {
		"novelizerRadio1",
		"novelizerRadio2",
		"novelizerRadio3"
	})
	self:PatchCommand("RadioYell", {
		"novelizerRadio1",
		"novelizerRadio2",
		"novelizerRadio3"
	})
	self:PatchCommand("RadioBroadcast", {
		"novelizerRadio1",
		"novelizerRadio2",
		"novelizerRadio3"
	})
	self:PatchCommand("SetFreq", {
		"novelizerSetFreq1",
		"novelizerSetFreq2",
		"novelizerSetFreq3"
	})
	self:PatchCommand("StationaryFreq", {
		"novelizerSetFreq1",
		"novelizerSetFreq2",
		"novelizerSetFreq3"
	})
	self:PatchCommand("SetListenFreq", {
		"novelizerSetFreq1",
		"novelizerSetFreq2",
		"novelizerSetFreq3"
	})
	self:PatchCommand("CharSearch", {
		"novelizerSearch1",
		"novelizerSearch2",
		"novelizerSearch3"
	})
end

function PLUGIN:PatchToggleRaiseCommand()
	local command = ix.command.list["toggleraise"] or ix.command.list["ToggleRaise"]

	if (not command or command.ixNovelizerWrapped) then
		return
	end

	command.ixNovelizerWrapped = true

	local originalOnRun = command.OnRun

	command.OnRun = function(this, client, ...)
		local weapon = client:GetActiveWeapon()
		local wasRaised = client:IsWepRaised()
		local result = originalOnRun(this, client, ...)

		if (result == nil and self:CanAutoNarrate(client) and self:IsNarratableWeapon(weapon)) then
			local phrasePool = wasRaised and {
				"novelizerLower1",
				"novelizerLower2",
				"novelizerLower3"
			} or {
				"novelizerRaise1",
				"novelizerRaise2",
				"novelizerRaise3"
			}

			self:SendNovelMe(client, table.Random(phrasePool), {
				self:GetWeaponSubject(weapon)
			})
		end

		return result
	end
end

function PLUGIN:GetNearbyCookingEntity(client)
	if (not IsValid(client)) then
		return nil
	end

	for _, entity in ipairs(ents.FindInSphere(client:GetPos(), 128)) do
		if (IsValid(entity) and (entity:GetClass() == "ix_stove" or entity:GetClass() == "ix_bucket" or entity:GetClass() == "ix_bonfire")) then
			return entity
		end
	end

	return nil
end

function PLUGIN:GetNearbyCraftStation(client)
	if (not IsValid(client)) then
		return nil
	end

	for _, entity in ipairs(ents.FindInSphere(client:GetPos(), 128)) do
		if (IsValid(entity)) then
			local className = entity:GetClass()

			if (className == "ix_station" or className:find("ix_station_", 1, true)) then
				return entity
			end
		end
	end

	return nil
end

function PLUGIN:GetRecipePhrasePool(recipeTable)
	local category = string.lower(tostring(recipeTable and recipeTable.category or ""))

	if (category == "food") then
		return {
			"novelizerCook1",
			"novelizerCook2",
			"novelizerCook3"
		}
	elseif (category == "disassemble") then
		return {
			"novelizerDisassemble1",
			"novelizerDisassemble2",
			"novelizerDisassemble3"
		}
	elseif (category == "transform") then
		return {
			"novelizerTransform1",
			"novelizerTransform2",
			"novelizerTransform3"
		}
	end

	return {
		"novelizerCraft1",
		"novelizerCraft2",
		"novelizerCraft3"
	}
end

function PLUGIN:ResolveCraftStationSubject(client, recipeTable)
	local category = string.lower(tostring(recipeTable and recipeTable.category or ""))
	local entity

	if (category == "food") then
		entity = self:GetNearbyCookingEntity(client)
	else
		entity = self:GetNearbyCraftStation(client)
	end

	if (IsValid(entity)) then
		return self:GetEntitySubject(entity), entity
	end

	if (category == "food") then
		return BuildArgument("stove", "object", "novelizerStove"), nil
	end

	return BuildArgument("workbench", "object", "novelizerWorkbench"), nil
end

function PLUGIN:PatchLootSearch()
	local lootPlugin = ix.plugin.list["ixloot"]

	if (not lootPlugin or lootPlugin.ixNovelizerWrappedSearchLoot) then
		return
	end

	lootPlugin.ixNovelizerWrappedSearchLoot = true

	local originalSearchLootContainer = lootPlugin.SearchLootContainer

	if (not isfunction(originalSearchLootContainer)) then
		return
	end

	lootPlugin.SearchLootContainer = function(this, ent, ply, ...)
		local canNarrate = self:CanAutoNarrate(ply)
		local canSearch = canNarrate
			and IsValid(ent)
			and not ply:IsCombine()
			and (not ent.containerAlreadyUsed or ent.containerAlreadyUsed <= CurTime())
			and ply.isEatingConsumeable ~= true
			and self:PassUseCooldown(ply, ent, 1.5)
		local result = originalSearchLootContainer(this, ent, ply, ...)

		if (canSearch) then
			self:SendNovelMe(ply, table.Random({
				"novelizerLoot1",
				"novelizerLoot2",
				"novelizerLoot3"
			}), {
				self:GetEntitySubject(ent)
			})
		end

		return result
	end
end

function PLUGIN:PatchApplyCommand()
	self:PatchCommand("Apply", {
		"novelizerApply1",
		"novelizerApply2",
		"novelizerApply3"
	}, function(client)
		return {
			BuildArgument("CID", "object", "novelizerCID")
		}
	end)
end

function PLUGIN:PatchCraftingActions()
	local craftPlugin = ix.plugin.list["ixcraft"]

	if (not craftPlugin or not craftPlugin.craft or craftPlugin.ixNovelizerCraftWrapped) then
		return
	end

	craftPlugin.ixNovelizerCraftWrapped = true

	local originalCraftRecipe = craftPlugin.craft.CraftRecipe

	if (not isfunction(originalCraftRecipe)) then
		return
	end

	craftPlugin.craft.CraftRecipe = function(client, uniqueID, ...)
		local recipeTable = craftPlugin.craft.recipes and craftPlugin.craft.recipes[uniqueID]
		local result = originalCraftRecipe(client, uniqueID, ...)

		if (result and self:CanAutoNarrate(client) and recipeTable) then
			local phrasePool = self:GetRecipePhrasePool(recipeTable)
			local stationSubject, stationEntity = self:ResolveCraftStationSubject(client, recipeTable)

			self:SendNovelMe(client, table.Random(phrasePool), {
				stationSubject
			})

			if (IsValid(stationEntity)) then
				local itKey = string.lower(tostring(recipeTable.category or "")) == "food" and "stove_heat" or "workbench_rattle"

				self:EmitConditionalIt(stationEntity, itKey, {
					cooldown = 4
				})
			end
		end

		return result
	end
end

function PLUGIN:InitializedPlugins()
	self:RegisterItPhrases("disk_read", {
		"novelizerItDiskRead1",
		"novelizerItDiskRead2",
		"novelizerItDiskRead3"
	})
	self:RegisterItPhrases("machine_hum", {
		"novelizerItMachineHum1",
		"novelizerItMachineHum2",
		"novelizerItMachineHum3"
	})
	self:RegisterItPhrases("laundry_pipe", {
		"novelizerItLaundryPipe1",
		"novelizerItLaundryPipe2",
		"novelizerItLaundryPipe3"
	})
	self:RegisterItPhrases("washer", {
		"novelizerItWasher1",
		"novelizerItWasher2",
		"novelizerItWasher3"
	})
	self:RegisterItPhrases("vending_hum", {
		"novelizerItVending1",
		"novelizerItVending2",
		"novelizerItVending3"
	})
	self:RegisterItPhrases("forcefield_buzz", {
		"novelizerItForcefield1",
		"novelizerItForcefield2",
		"novelizerItForcefield3"
	})
	self:RegisterItPhrases("radio_static", {
		"novelizerItRadio1",
		"novelizerItRadio2",
		"novelizerItRadio3"
	})
	self:RegisterItPhrases("stove_heat", {
		"novelizerItStove1",
		"novelizerItStove2",
		"novelizerItStove3"
	})
	self:RegisterItPhrases("workbench_rattle", {
		"novelizerItWorkbench1",
		"novelizerItWorkbench2",
		"novelizerItWorkbench3"
	})

	self:RegisterDefaultEntityPhrases()
	self:PatchItems()
	self:PatchWaterCommand()
	self:PatchCommandActions()
	self:PatchApplyCommand()
	self:PatchToggleRaiseCommand()
	self:PatchLootSearch()
	self:PatchCraftingActions()
end

function PLUGIN:OnReloaded()
	self:PatchItems()
	self:PatchWaterCommand()
	self:PatchCommandActions()
	self:PatchApplyCommand()
	self:PatchToggleRaiseCommand()
	self:PatchLootSearch()
	self:PatchCraftingActions()
end

function PLUGIN:InitializedConfig()
	ix.chat.Register("novelme", {
		GetColor = function(self, speaker, text, data)
			if (ix.chat.classes.me and ix.chat.classes.me.GetColor) then
				return ix.chat.classes.me:GetColor(speaker, text, data)
			end

			return ix.config.Get("chatColor")
		end,
		CanHear = function(self, speaker, listener, data)
			if (not IsValid(speaker)) then
				return false
			end

			local range = data and data.range or GetChatRange()
			return listener:GetPos():DistToSqr(speaker:GetPos()) <= (range * range)
		end,
		OnChatAdd = function(self, speaker, text, anonymous, data)
			local color = self:GetColor(speaker, text, data)
			local name, nameColor = PLUGIN:GetCharacterDisplayName(speaker, anonymous, data)
			local phrase = PLUGIN:TranslatePhrase(text, data)
			local placeholder = "@@NAME@@"
			local format = GetPhraseTemplate("novelizerMeFormat") or "** %s %s"
			local formatted = string.format(format, placeholder, phrase)
			local nameStart, nameEnd = formatted:find(placeholder, 1, true)

			if (nameStart and nameEnd) then
				chat.AddText(color, formatted:sub(1, nameStart - 1), nameColor, name, color, formatted:sub(nameEnd + 1))
				return
			end

			chat.AddText(color, L("novelizerMeFormat", name, phrase))
		end,
		font = "ixChatFontItalics",
		indicator = "chatPerforming",
		deadCanChat = true
	})

	ix.chat.Register("novelit", {
		CanHear = function(self, speaker, listener, data)
			local position = data and data.position
			local range = data and data.range or GetChatRange()

			if (not position) then
				if (IsValid(speaker)) then
					position = speaker:GetPos()
				else
					return false
				end
			end

			return listener:GetPos():DistToSqr(position) <= (range * range)
		end,
		OnChatAdd = function(self, speaker, text, anonymous, data)
			local color = ix.config.Get("chatColor")
			local phrase = PLUGIN:TranslatePhrase(text, data)

			chat.AddText(color, "** " .. phrase)
		end,
		font = "ixChatFontItalics",
		indicator = "chatPerforming",
		deadCanChat = true
	})
end

function PLUGIN:PlayerUse(client, entity)
	if (not self:CanAutoNarrate(client) or self:ShouldIgnoreEntityUse(entity) or not self:PassUseCooldown(client, entity)) then
		return
	end

	local phrasePool = entity:IsDoor() and self:GetDoorPhrasePool(entity) or self:ResolveEntityUsePhrasePool(entity)

	if (not istable(phrasePool) or #phrasePool == 0) then
		return
	end

	self:SendNovelMe(client, table.Random(phrasePool), {
		self:GetEntitySubject(entity)
	})

	local className = entity:GetClass()

	if (className == "ix_interactive_computer" or className:find("computer", 1, true) or className:find("terminal", 1, true)) then
		self:EmitConditionalIt(entity, "disk_read", {
			cooldown = 4
		})
	elseif (className == "ix_washing_machine" or className == "ix_washing_machine_small") then
		self:EmitConditionalIt(entity, "washer", {
			cooldown = 5
		})
	elseif (className == "ix_vendingmachine" or className == "ix_pepsimachine" or className == "ix_coffeemachine") then
		self:EmitConditionalIt(entity, "vending_hum", {
			cooldown = 5
		})
	elseif (className == "ix_stationary_radio" or className == "ix_radiorepeater") then
		self:EmitConditionalIt(entity, "radio_static", {
			cooldown = 4
		})
	elseif (className == "ix_recycler" or className == "ix_forcefield" or className == "ix_rationdispenser") then
		self:EmitConditionalIt(entity, className == "ix_forcefield" and "forcefield_buzz" or "machine_hum", {
			cooldown = 5
		})
	elseif (className == "ix_stove" or className == "ix_bonfire" or className == "ix_bucket") then
		self:EmitConditionalIt(entity, "stove_heat", {
			cooldown = 4
		})
	elseif (className == "ix_station" or className:find("ix_station_", 1, true)) then
		self:EmitConditionalIt(entity, "workbench_rattle", {
			cooldown = 4
		})
	end
end

function PLUGIN:PlayerSwitchFlashlight(client, enabled)
	if (not self:CanAutoNarrate(client) or not self:PassNamedCooldown(client, "flashlight", 0.5)) then
		return
	end

	local nextState = not client:GetNetVar("flashlight", false)
	local phrasePool = nextState and {
		"novelizerFlashlightOn1",
		"novelizerFlashlightOn2",
		"novelizerFlashlightOn3"
	} or {
		"novelizerFlashlightOff1",
		"novelizerFlashlightOff2",
		"novelizerFlashlightOff3"
	}

	local subject = BuildArgument("Flashlight", "object", "Flashlight")
	self:SendNovelMe(client, table.Random(phrasePool), {subject})
end

function PLUGIN:KeyPress(client, key)
	if (not self:CanAutoNarrate(client)) then
		return
	end

	local weapon = client:GetActiveWeapon()

	if (key == IN_ATTACK and self:IsNarratableWeapon(weapon) and weapon.ixItem and weapon.ixItem.isGrenade
		and self:PassNamedCooldown(client, "grenade_prime", 1.1)) then
		local phrasePool

		if (weapon.ixItem.uniqueID == "molotov" or weapon:GetClass() == "weapon_molotov") then
			phrasePool = {
				"novelizerMolotovPrime1",
				"novelizerMolotovPrime2",
				"novelizerMolotovPrime3"
			}
		else
			phrasePool = {
				"novelizerGrenadePrime1",
				"novelizerGrenadePrime2",
				"novelizerGrenadePrime3"
			}
		end

		self:SendNovelMe(client, table.Random(phrasePool), {
			self:GetWeaponSubject(weapon)
		})
		return
	end

	if (key == IN_RELOAD and self:IsNarratableWeapon(weapon)) then
		local maxClip = weapon:GetMaxClip1()
		local clip = weapon:Clip1()

		if (maxClip > 0 and clip >= 0 and clip < maxClip and self:PassNamedCooldown(client, "reload", 1.4)) then
			self:SendNovelMe(client, table.Random({
				"novelizerReload1",
				"novelizerReload2",
				"novelizerReload3"
			}), {
				self:GetWeaponSubject(weapon)
			})
		end
	end
end

function PLUGIN:PlayerSwitchWeapon(client, oldWeapon, weapon)
	if (not self:CanAutoNarrate(client) or not self:IsNarratableWeapon(weapon)) then
		return
	end

	if (not self:PassNamedCooldown(client, "weapon_switch", 0.75)) then
		return
	end

	self:SendNovelMe(client, table.Random({
		"novelizerSwitch1",
		"novelizerSwitch2",
		"novelizerSwitch3"
	}), {
		self:GetWeaponSubject(weapon)
	})
end
