local PLUGIN = PLUGIN

-- Localize common metatables and functions
local playerMeta = FindMetaTable("Player")
local entityMeta = FindMetaTable("Entity")
local wordMeta = FindMetaTable("Vector") -- Just for consistency if needed
local L = L or (ix and ix.lang and ix.lang.Get)
local L2 = L -- Support both just in case a schema or other plugin expects L2

PLUGIN.name = "Novelizer"
PLUGIN.author = "Frosty"
PLUGIN.description = "Localized automatic narrative emotes for item use, interactions, and ambient machine actions."

PLUGIN.license = [[
Copyright © 2026 Frosty

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/
]]

PLUGIN.itemActionPhrasePools = PLUGIN.itemActionPhrasePools or {}
PLUGIN.entityUsePhrasePools = PLUGIN.entityUsePhrasePools or {}
PLUGIN.itPhrasePools = PLUGIN.itPhrasePools or {}
PLUGIN.classPatternPhrasePools = PLUGIN.classPatternPhrasePools or {}

local unpackArgs = table.unpack or unpack
local bitBand = bit.band or bit32.band
local DEFAULT_RANGE_MULTIPLIER = 2
local DEFAULT_USE_COOLDOWN = 1.25
local DEFAULT_IT_COOLDOWN = 60
local DEFAULT_ACTION_COOLDOWN = 10
local GLOBAL_ACTION_COOLDOWN = 2
local IDLE_WARMUP_MIN = 3
local IDLE_WARMUP_MAX = 7
local NOVELIZER_RAISE_PATCH_VERSION = 2
local NOVELIZER_3D_NET = "ixNovelizerDisplay3D"
local IDLE_IT_RANDOM_WINDOW = 5
local NOVELIZER_3D_SURFACE_PADDING = 2

local IDLE_COMPUTER_CLASSES = {
	"ix_computer",
	"ix_terminal",
	"ix_combinedisplay",
	"ix_combinescreen"
}

local DAMAGE_DEFINITIONS = {
	{key = "shock", hurt = "novelizerInjuredShock", death = "novelizerDeathShock", flags = {DMG_SHOCK}},
	{key = "radiation", hurt = "novelizerInjuredRadiation", death = "novelizerDeathRadiation", flags = {DMG_RADIATION}},
	{key = "burn", hurt = "novelizerInjuredBurn", death = "novelizerDeathBurn", flags = {DMG_BURN, DMG_SLOWBURN}},
	{key = "blast", hurt = "novelizerInjuredBlast", death = "novelizerDeathBlast", flags = {DMG_BLAST}},
	{key = "vehicle", hurt = "novelizerInjuredVehicle", death = "novelizerDeathVehicle", flags = {DMG_VEHICLE}},
	{key = "sonic", hurt = "novelizerInjuredSonic", death = "novelizerDeathSonic", flags = {DMG_SONIC}},
	{key = "energybeam", hurt = "novelizerInjuredEnergyBeam", death = "novelizerDeathEnergyBeam", flags = {DMG_ENERGYBEAM}},
	{key = "fall", hurt = "novelizerInjuredFall", death = "novelizerDeathFall", flags = {DMG_FALL}},
	{key = "gun", hurt = "novelizerInjuredGun", death = "novelizerDeathGun", flags = {DMG_BULLET, DMG_BUCKSHOT}},
	{key = "slash", hurt = "novelizerInjuredSlash", death = "novelizerDeathSlash", flags = {DMG_SLASH}},
	{key = "drown", hurt = "novelizerInjuredDrown", death = "novelizerDeathDrown", flags = {DMG_DROWN}},
	{key = "acid", hurt = "novelizerInjuredAcid", death = "novelizerDeathAcid", flags = {DMG_ACID}},
	{key = "poison", hurt = "novelizerInjuredPoison", death = "novelizerDeathPoison", flags = {DMG_POISON, DMG_NERVEGAS, DMG_PARALYZE}},
	{key = "blunt", hurt = "novelizerInjuredBlunt", death = "novelizerDeathBlunt", flags = {DMG_CLUB, DMG_CRUSH}},
	{key = "bite", hurt = "novelizerInjuredBite", death = "novelizerDeathBite", flags = {}},
	{key = "starve", hurt = "novelizerInjuredStarve", death = "novelizerDeathStarve", flags = {}}
}

if (SERVER) then
	util.AddNetworkString(NOVELIZER_3D_NET)
end

ix.lang.AddTable("english", {
	optNovelizerAutoActions = "Enable novelizer auto actions",
	optdNovelizerAutoActions = "Automatically narrates your interactions, item use, and nearby machine sounds.",

	novelizerSomething = "something",
	novelizerSomeone = "the person before them",
	novelizerObject = "object",
	novelizerFlashlight = "flashlight",
	novelizerDoor = "door",
	novelizerForcefield = "forcefield",
	novelizerWorkbench = "workbench",
	novelizerStove = "gas stove",
	novelizerHealthKit = "health kit",
	novelizerHealthVial = "health vial",
	novelizerDeskProp = "table",
	novelizerChairProp = "chair",
	novelizerCrateProp = "crate",
	novelizerDrumProp = "drum",
	novelizerPopcanProp = "pop can",
	novelizerCanProp = "can",
	novelizerBottleProp = "bottle",
	novelizerGascanProp = "gas can",
	novelizerVehicleProp = "vehicle",
	novelizerVendingMachine = "vending machine",
	novelizerCoffeeMachine = "coffee machine",
	novelizerPepsiMachine = "soda vending machine",
	novelizerRationDispenser = "ration dispenser",
	novelizerLock = "lock",
	novelizerShipment = "shipment",
	novelizerNewspaperProp = "newspaper",
	novelizerRadioProp = "radio",
	novelizerTVProp = "television",
	novelizerScanner = "scanner",
	novelizerBucketFire = "bucket fire",
	novelizerBonfire = "bonfire",
	novelizerBreachCharge = "breaching charge",
	novelizerDigitalClock = "digital clock",
	novelizerMachineGun = "machine gun",
	novelizerSniperRifle = "sniper rifle",
	novelizerKeys = "keyring",
	novelizerHands = "fists",
	novelizerBody = "body",
	novelizerHeadcrab = "headcrab",
	novelizerAntlion = "antlion",
	novelizerZombie = "zombie",
	novelizerCorpse = "corpse",
	novelizerSuitcase = "suitcase",
	novelizerRationPack = "ration pack",
	novelizerCID = "CID card",
	novelizerToken = "token",
	novelizerTokens = "tokens",
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
	novelizerTake1 = "picks up %s.",
	novelizerTake2 = "takes hold of %s.",
	novelizerTake3 = "collects %s.",
	novelizerDrop1 = "sets down %s.",
	novelizerDrop2 = "drops %s to the ground.",
	novelizerDrop3 = "puts %s down.",
	novelizerHandsPickup1 = "picks up %s with both hands.",
	novelizerHandsPickup2 = "gets a grip on %s and lifts it.",
	novelizerHandsPickup3 = "hauls %s up into their hands.",
	novelizerHandsDrop1 = "sets %s back down.",
	novelizerHandsDrop2 = "lowers %s out of their hands.",
	novelizerHandsDrop3 = "lets %s drop from their grip.",

	novelizerRequest1 = "keys a request into the device.",
	novelizerRequest2 = "speaks a brief request into the unit.",
	novelizerRequest3 = "sends a short request through the device.",
	novelizerRadio1 = "keys the radio and transmits.",
	novelizerRadio2 = "leans to the radio and speaks.",
	novelizerRadio3 = "presses the transmit key on the radio.",
	novelizerSetFreq1 = "adjusts a radio frequency.",
	novelizerSetFreq2 = "retunes a radio channel.",
	novelizerSetFreq3 = "dials in a new radio frequency.",
	novelizerSearch1 = "starts patting the person before them down.",
	novelizerSearch2 = "begins a quick search.",
	novelizerSearch3 = "checks the individual in front of them for carried items.",
	novelizerAmmo1 = "loads ammunition from %s.",
	novelizerAmmo2 = "feeds rounds in from %s.",
	novelizerAmmo3 = "tops up on ammunition with %s.",
	novelizerBattery1 = "uses %s to top up their suit reserves.",
	novelizerBattery2 = "plugs %s into their suit's power system.",
	novelizerBattery3 = "feeds power from %s into their equipment.",
	novelizerBandageSelf1 = "wraps %s around their own injuries.",
	novelizerBandageSelf2 = "binds themselves up with %s.",
	novelizerBandageSelf3 = "winds %s tight over a wound.",
	novelizerBandageOther1 = "wraps %s around the wounds of the person before them.",
	novelizerBandageOther2 = "binds the injuries of the individual in front of them with %s.",
	novelizerBandageOther3 = "leans in to dress the wounds of the figure before them with %s.",
	novelizerAedSelf1 = "presses %s into place and triggers a harsh shock.",
	novelizerAedSelf2 = "fumbles %s into position and discharges it.",
	novelizerAedSelf3 = "braces and sets off %s against their body.",
	novelizerAedOther1 = "plants %s against the person before them and fires a defibrillating shock.",
	novelizerAedOther2 = "sets %s on the chest of the individual in front of them and discharges it.",
	novelizerAedOther3 = "leans over with %s and sends a violent jolt through the subject.",

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
	novelizerGrenadeThrow1 = "throws %s.",
	novelizerGrenadeThrow2 = "hurls %s away.",
	novelizerGrenadeThrow3 = "whips %s out in a quick throw.",
	novelizerMolotovThrow1 = "throws %s with a burning arc.",
	novelizerMolotovThrow2 = "flings %s out while it burns.",
	novelizerMolotovThrow3 = "sends %s sailing in a sheet of fire.",

	novelizerFlashlightOn1 = "clicks %s on.",
	novelizerFlashlightOn2 = "thumbs %s to life.",
	novelizerFlashlightOn3 = "brings %s up and switches it on.",
	novelizerFlashlightOff1 = "switches %s off.",
	novelizerFlashlightOff2 = "kills the beam from %s.",
	novelizerFlashlightOff3 = "clicks %s dark.",
	novelizerStoveOn1 = "turns on %s.",
	novelizerStoveOn2 = "lights the burner on %s.",
	novelizerStoveOn3 = "clicks %s on and brings the gas to life.",
	novelizerStoveOff1 = "turns off %s.",
	novelizerStoveOff2 = "cuts the gas to %s.",
	novelizerStoveOff3 = "shuts %s back down.",
	novelizerFireOn1 = "lights %s.",
	novelizerFireOn2 = "sets %s burning.",
	novelizerFireOn3 = "coaxes a flame to life in %s.",
	novelizerFireOff1 = "puts out %s.",
	novelizerFireOff2 = "smothers the fire in %s.",
	novelizerFireOff3 = "snuffs %s out.",

	novelizerMachineVending1 = "leans over %s and works its selector buttons.",
	novelizerMachineVending2 = "jabs at the controls on %s.",
	novelizerMachineVending3 = "coaxes a choice out of %s.",

	novelizerMachineHealth1 = "starts the automated medical station.",
	novelizerMachineHealth2 = "leans into the automated medical station.",
	novelizerMachineHealth3 = "activates the automated medical station's treatment cycle.",
	novelizerMachineHealthGrub1 = "feeds %s into %s's intake slot.",
	novelizerMachineHealthGrub2 = "slides %s into %s for processing.",
	novelizerMachineHealthGrub3 = "pushes %s into %s's feeder port.",
	novelizerMachineSuit1 = "starts drawing charge from the suit charger.",
	novelizerMachineSuit2 = "leans into the charging unit as it comes alive.",
	novelizerMachineSuit3 = "activates the charger and starts taking power from it.",

	novelizerMachineRation1 = "presents themselves to %s and works its controls.",
	novelizerMachineRation2 = "slides their CID into %s's intake slot.",
	novelizerMachineRation3 = "operates %s with practiced motions.",
	novelizerMachineDigitalClock1 = "changes the mode on %s.",
	novelizerMachineDigitalClock2 = "waves a hand through %s's holographic controls.",
	novelizerMachineDigitalClock3 = "taps through the display modes on %s.",
	novelizerMachineMannable1 = "takes hold of %s and settles behind it.",
	novelizerMachineMannable2 = "grips %s into a firing posture.",
	novelizerMachineMannable3 = "plants themselves behind %s and takes control.",
	novelizerMachineSniper1 = "takes hold of %s and settles in behind the sights.",
	novelizerMachineSniper2 = "shoulders into %s and peers through its scope.",
	novelizerMachineSniper3 = "leans onto %s and lines up behind it.",
	novelizerDoorBreachPlace1 = "plants a breaching charge onto the door.",
	novelizerDoorBreachPlace2 = "presses a breaching charge against the door and locks it in place.",
	novelizerDoorBreachPlace3 = "attaches a breaching charge to the door.",
	novelizerDoorBreachUse1 = "arms %s.",
	novelizerDoorBreachUse2 = "starts the timer on %s.",
	novelizerDoorBreachUse3 = "thumbs the trigger on %s.",
	novelizerLockDetonate1 = "starts the detonation sequence on %s.",
	novelizerLockDetonate2 = "sets %s to blow.",
	novelizerLockDetonate3 = "arms %s for detonation.",

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

	novelizerMachineForcefield1 = "reaches for the forcefield controls.",
	novelizerMachineForcefield2 = "adjusts the forcefield settings.",
	novelizerMachineForcefield3 = "works the forcefield controls.",

	novelizerMachineRadio1 = "adjusts the controls on %s.",
	novelizerMachineRadio2 = "tunes %s by hand.",
	novelizerMachineRadio3 = "fiddles with the dials on %s.",

	novelizerMachinePanel1 = "runs a hand over %s and presses at its controls.",
	novelizerMachinePanel2 = "works a sequence into %s.",
	novelizerMachinePanel3 = "uses %s with quick, practiced inputs.",
	novelizerMachineContainer1 = "opens %s and checks inside.",
	novelizerMachineContainer2 = "works %s open and looks through it.",
	novelizerMachineContainer3 = "lifts open %s to search its contents.",
	novelizerMachineLaundryPipe1 = "works at %s and pulls down a load of laundry.",
	novelizerMachineLaundryPipe2 = "uses %s to draw out another bundle of cloth.",
	novelizerMachineLaundryPipe3 = "triggers %s and waits for laundry to drop.",
	novelizerMachineWasher1 = "loads %s and starts a wash cycle.",
	novelizerMachineWasher2 = "works the controls on %s and sets it turning.",
	novelizerMachineWasher3 = "shuts %s and sends it into a wash cycle.",
	novelizerMachineDoorOpen1 = "opens %s.",
	novelizerMachineDoorOpen2 = "works %s open.",
	novelizerMachineDoorOpen3 = "gets %s open.",
	novelizerMachineDoorClose1 = "closes %s.",
	novelizerMachineDoorClose2 = "shuts %s.",
	novelizerMachineDoorClose3 = "sets %s closed again.",
	novelizerMachineDoorUse1 = "checks %s.",
	novelizerMachineDoorUse2 = "works %s for a moment.",
	novelizerMachineDoorUse3 = "uses %s with a quick motion.",
	novelizerLoot1 = "starts rummaging through %s for anything useful.",
	novelizerLoot2 = "leans into %s and digs through the junk inside.",
	novelizerLoot3 = "starts pawing through %s in search of salvage.",
	novelizerLootGeneric1 = "starts rummaging for anything useful.",
	novelizerLootGeneric2 = "leans in and digs through the junk inside.",
	novelizerLootGeneric3 = "starts pawing through the contents in search of salvage.",
	novelizerApply1 = "takes out %s and holds it up for inspection.",
	novelizerApply2 = "produces %s and presents it.",
	novelizerApply3 = "pulls out %s to show their identification.",
	novelizerDropMoney1 = "picks out some %s and drops it to the ground.",
	novelizerDropMoney2 = "takes some %s and sets it down.",
	novelizerDropMoney3 = "sets down some %s.",
	novelizerGiveMoney1 = "hands over some %s.",
	novelizerGiveMoney2 = "passes some %s.",
	novelizerGiveMoney3 = "gives some %s.",
	novelizerMedSelf1 = "opens %s to check their own injuries.",
	novelizerMedSelf2 = "unfolds %s and begins self-treatment.",
	novelizerMedSelf3 = "takes out %s to treat their wounds.",
	novelizerMedOther1 = "opens %s to check the injuries of the person before them.",
	novelizerMedOther2 = "unfolds %s to treat the wounds of the individual in front of them.",
	novelizerMedOther3 = "leans in with %s to tend to the figure before them.",
	novelizerInjectionSelf1 = "stabs %s into their own body.",
	novelizerInjectionSelf2 = "injects themselves with %s.",
	novelizerInjectionSelf3 = "administers %s to themselves.",
	novelizerInjectionOther1 = "stabs %s into the body of the person before them.",
	novelizerInjectionOther2 = "injects the individual in front of them with %s.",
	novelizerInjectionOther3 = "leans in to administer %s to the subject.",
	novelizerRead1 = "reads %s.",
	novelizerRead2 = "unfolds %s and reads through it.",
	novelizerRead3 = "looks over %s for a moment.",
	novelizerVendorTrade1 = "finishes a trade with %s.",
	novelizerVendorTrade2 = "wraps up business with %s.",
	novelizerVendorTrade3 = "concludes a transaction with %s.",
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
	novelizerSelfCraft1 = "sets to work assembling something.",
	novelizerSelfCraft2 = "starts piecing materials together.",
	novelizerSelfCraft3 = "is busy with some handiwork.",
	novelizerSelfCook1 = "carefully prepares some food by hand.",
	novelizerSelfCook2 = "is busy preparing a meal.",
	novelizerSelfCook3 = "is focused on food preparation.",
	novelizerCookFood1 = "turns %s over the heat and starts cooking it.",
	novelizerCookFood2 = "sets %s to cook with patient care.",
	novelizerCookFood3 = "starts cooking %s.",
	novelizerRationOpen1 = "tears open %s.",
	novelizerRationOpen2 = "breaks the seal on %s.",
	novelizerRationOpen3 = "opens up %s and starts sorting through it.",
	novelizerEquipSuitcase1 = "takes %s into hand.",
	novelizerEquipSuitcase2 = "picks up %s by the handle.",
	novelizerEquipSuitcase3 = "lifts %s into a hand-carry grip.",
	novelizerUnequipSuitcase1 = "sets %s back down.",
	novelizerUnequipSuitcase2 = "lowers %s from their hand.",
	novelizerUnequipSuitcase3 = "puts %s aside.",
	novelizerSwitchSuitcase1 = "takes %s in hand.",
	novelizerSwitchSuitcase2 = "brings %s up by the handle.",
	novelizerSwitchSuitcase3 = "shifts %s into their grip.",
	novelizerHandsRaise1 = "clenches their fists.",
	novelizerHandsRaise2 = "brings both hands up into a guarded stance.",
	novelizerHandsRaise3 = "balls their hands into fists.",
	novelizerHandsLower1 = "loosens their fists.",
	novelizerHandsLower2 = "lets their hands ease back down.",
	novelizerHandsLower3 = "relaxes out of a fighting stance.",
	novelizerLadder1 = "grabs hold of a ladder and starts climbing.",
	novelizerLadder2 = "steps onto a ladder and begins to climb.",
	novelizerLadder3 = "hooks onto a ladder and starts moving along it.",
	novelizerVehicleSeatEnter1 = "sits down.",
	novelizerVehicleSeatEnter2 = "drops into a seat.",
	novelizerVehicleSeatEnter3 = "settles down into a sitting position.",
	novelizerVehicleSeatExit1 = "gets back to their feet.",
	novelizerVehicleSeatExit2 = "stands up from the seat.",
	novelizerVehicleSeatExit3 = "pushes themself upright again.",
	novelizerVehicleEnter1 = "gets into %s.",
	novelizerVehicleEnter2 = "climbs into %s.",
	novelizerVehicleEnter3 = "slides into %s.",
	novelizerVehicleExit1 = "gets out of %s.",
	novelizerVehicleExit2 = "climbs out of %s.",
	novelizerVehicleExit3 = "steps out of %s.",
	novelizerFallover1 = "drops hard to the ground.",
	novelizerFallover2 = "goes limp and collapses.",
	novelizerFallover3 = "crumples down, losing consciousness.",
	novelizerDoorKnock1 = "knocks on %s with their hand.",
	novelizerDoorKnock2 = "raps their knuckles against %s.",
	novelizerDoorKnock3 = "gives %s a quick knock.",
	novelizerEquipSidearm1 = "gets %s ready at hand.",
	novelizerEquipSidearm2 = "settles %s into an easy draw.",
	novelizerEquipSidearm3 = "positions %s for quick use.",
	novelizerUnequipSidearm1 = "puts %s away.",
	novelizerUnequipSidearm2 = "settles %s back out of immediate reach.",
	novelizerUnequipSidearm3 = "stows %s.",
	novelizerEquipMelee1 = "grips %s tightly.",
	novelizerEquipMelee2 = "settles %s into an easy draw.",
	novelizerEquipMelee3 = "positions %s for quick use.",
	novelizerUnequipMelee1 = "puts %s away.",
	novelizerUnequipMelee2 = "settles %s back out of immediate reach.",
	novelizerUnequipMelee3 = "stows %s.",
	novelizerGrenadeRaise1 = "brings %s up into a throwing stance.",
	novelizerGrenadeRaise2 = "sets %s into a ready throwing grip.",
	novelizerGrenadeRaise3 = "cocks their arm with %s ready.",
	novelizerGrenadeLower1 = "lowers %s from a throwing stance.",
	novelizerGrenadeLower2 = "lets %s dip back down.",
	novelizerGrenadeLower3 = "relaxes their grip on %s.",
	novelizerStaminaEmpty1 = "slows sharply, breathing hard as their stamina gives out.",
	novelizerStaminaEmpty2 = "sags for a moment as exhaustion catches up with them.",
	novelizerStaminaEmpty3 = "comes up short, spent and breathing heavily.",
	novelizerInjuredGun1 = "reels from a gunshot impact.",
	novelizerInjuredGun2 = "wails as a bullet tears through them.",
	novelizerInjuredGun3 = "buckles under the sharp sting of gunfire.",
	novelizerDeathGun1 = "is dropped by gunfire.",
	novelizerDeathGun2 = "collapses as the bullets finish their work.",
	novelizerDeathGun3 = "slumps to the ground after a fatal shot.",

	novelizerInjuredBurn1 = "flinches hard as the burn catches.",
	novelizerInjuredBurn2 = "hisses in pain from the searing heat.",
	novelizerInjuredBurn3 = "twists away from the licking flames.",
	novelizerDeathBurn1 = "goes down in the grip of the flames.",
	novelizerDeathBurn2 = "is consumed by the fire and collapses.",
	novelizerDeathBurn3 = "stops moving as the heat overcomes them.",

	novelizerInjuredBlunt1 = "staggers from a heavy blunt hit.",
	novelizerInjuredBlunt2 = "reels back from a solid impact.",
	novelizerInjuredBlunt3 = "grunts as a heavy strike connects.",
	novelizerDeathBlunt1 = "collapses under the force of the impact.",
	novelizerDeathBlunt2 = "is laid low by a crushing blow.",
	novelizerDeathBlunt3 = "goes limp after a final, heavy hit.",

	novelizerInjuredFall1 = "buckles from the impact of the fall.",
	novelizerInjuredFall2 = "stumbles as they hit the ground hard.",
	novelizerInjuredFall3 = "gives a sharp gasp after the drop.",
	novelizerDeathFall1 = "crumples after the fall.",
	novelizerDeathFall2 = "shudders and goes still after hitting the deck.",
	novelizerDeathFall3 = "is broken by the long drop.",

	novelizerInjuredRadiation1 = "shudders under a wave of radiation sickness.",
	novelizerInjuredRadiation2 = "chokes as the unseen sickness takes hold.",
	novelizerInjuredRadiation3 = "wavers, their body failing from exposure.",
	novelizerDeathRadiation1 = "gives out under severe radiation exposure.",
	novelizerDeathRadiation2 = "succumbs to the silent lethality of the zone.",
	novelizerDeathRadiation3 = "collapses, their cells yielding to the radiation.",

	novelizerInjuredShock1 = "jerks violently as the shock runs through them.",
	novelizerInjuredShock2 = "convulses under the sudden electric jolt.",
	novelizerInjuredShock3 = "spasms as the current arcs through their body.",
	novelizerDeathShock1 = "locks up under the current and drops.",
	novelizerDeathShock2 = "goes rigid as the electricity finishes them.",
	novelizerDeathShock3 = "falls still after a final, lethal shock.",

	novelizerInjuredBlast1 = "is thrown off balance by the blast.",
	novelizerInjuredBlast2 = "staggers as the pressure wave hits.",
	novelizerInjuredBlast3 = "reels from the nearby explosion.",
	novelizerDeathBlast1 = "is taken down in the explosion.",
	novelizerDeathBlast2 = "is thrown through the air and falls limp.",
	novelizerDeathBlast3 = "vanishes into the smoke and debris.",

	novelizerInjuredVehicle1 = "is jolted hard by the vehicle impact.",
	novelizerInjuredVehicle2 = "is knocked back by the heavy machine.",
	novelizerInjuredVehicle3 = "reels as the frame of the vehicle connects.",
	novelizerDeathVehicle1 = "is struck down by the vehicle impact.",
	novelizerDeathVehicle2 = "is crushed under the weight of the vehicle.",
	novelizerDeathVehicle3 = "is sent sprawling, never to rise again.",

	novelizerInjuredSonic1 = "reels as the sonic force hits them.",
	novelizerInjuredSonic2 = "clutches their head from the heavy soundwave.",
	novelizerInjuredSonic3 = "wavers as the high-frequency pulse strikes.",
	novelizerDeathSonic1 = "drops under the sonic blast.",
	novelizerDeathSonic2 = "is silenced by the intense sonic pressure.",
	novelizerDeathSonic3 = "collapses as their internal organs yield to the sound.",

	novelizerInjuredEnergyBeam1 = "twists back from the beam's impact.",
	novelizerInjuredEnergyBeam2 = "hisses as the concentrated light burns through.",
	novelizerInjuredEnergyBeam3 = "winces as the energy arc connects.",
	novelizerDeathEnergyBeam1 = "goes down under the beam.",
	novelizerDeathEnergyBeam2 = "is cut down by the focused energy.",
	novelizerDeathEnergyBeam3 = "collapses as the beam pierces through them.",

	novelizerInjuredSlash1 = "recoils from the strike.",
	novelizerInjuredSlash2 = "winces as the blade catches them.",
	novelizerInjuredSlash3 = "twists away from the cutting blow.",
	novelizerDeathSlash1 = "goes down under the blow.",
	novelizerDeathSlash2 = "is silenced by a deep, final cut.",
	novelizerDeathSlash3 = "falls as the strike proves fatal.",

	novelizerInjuredDrown1 = "chokes as water fills their lungs.",
	novelizerInjuredDrown2 = "thrashes weakly in the water.",
	novelizerInjuredDrown3 = "gasps as the fluid overwhelms their breath.",
	novelizerDeathDrown1 = "goes limp in the water.",
	novelizerDeathDrown2 = "sinks slowly beneath the surface.",
	novelizerDeathDrown3 = "is pulled down into the depths.",

	novelizerInjuredAcid1 = "lashes back from the corrosive burn.",
	novelizerInjuredAcid2 = "hisses as the chemical starts eating away.",
	novelizerInjuredAcid3 = "recoils from the stinging acid.",
	novelizerDeathAcid1 = "fails under the corrosive damage.",
	novelizerDeathAcid2 = "dissolves into a silent collapse.",
	novelizerDeathAcid3 = "succumbs to the chemical burn.",

	novelizerInjuredPoison1 = "wavers under a sudden toxic reaction.",
	novelizerInjuredPoison2 = "chokes as the toxin enters their system.",
	novelizerInjuredPoison3 = "staggers, their vision blurring from the poison.",
	novelizerDeathPoison1 = "succumbs to the poison.",
	novelizerDeathPoison2 = "falls still as the toxin stops their heart.",
	novelizerDeathPoison3 = "is finished by the lethal compound.",

	novelizerInjuredBite1 = "recoils from the sharp sting of the attack.",
	novelizerInjuredBite2 = "winces as teeth tear at them.",
	novelizerInjuredBite3 = "twists away from the lunging attack.",
	novelizerDeathBite1 = "is dragged down and overcome.",
	novelizerDeathBite2 = "is torn apart and falls still.",
	novelizerDeathBite3 = "falls as the attack proves fatal.",

	novelizerInjuredStarve1 = "doubles over from a sharp wave of hunger.",
	novelizerInjuredStarve2 = "staggers as their body starts to fail from lack of food.",
	novelizerInjuredStarve3 = "gasps in pain as starvation sets in.",
	novelizerDeathStarve1 = "collapses, their body finally giving out to hunger.",
	novelizerDeathStarve2 = "falls still, overcome by starvation.",
	novelizerDeathStarve3 = "succumbs to the silent lethality of hunger.",

	novelizerItRadioMusic1 = "%s plays a faint stream of music.",
	novelizerItRadioMusic2 = "%s carries a thin wash of music.",
	novelizerItRadioMusic3 = "%s murmurs with a steady broadcast.",
	novelizerItRadioOffFreq1 = "%s crackles off-station through bursts of static.",
	novelizerItRadioOffFreq2 = "%s hisses between channels without finding a clean signal.",
	novelizerItRadioOffFreq3 = "%s sputters with unstable radio noise.",

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
	novelizerItDoorLocked1 = "%s stays locked shut.",
	novelizerItDoorLocked2 = "%s gives a stubborn rattle but refuses to open.",
	novelizerItDoorLocked3 = "%s holds fast behind its lock.",
	novelizerItGasStove1 = "%s hisses with the steady burn of a gas flame.",
	novelizerItGasStove2 = "%s gives off a low, even heat from its lit burners.",
	novelizerItGasStove3 = "%s whispers with a controlled line of blue fire.",
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
	novelizerSomeone = "상대방",
	novelizerObject = "물건",
	novelizerFlashlight = "손전등",
	novelizerDoor = "문",
	novelizerForcefield = "역장",
	novelizerWorkbench = "작업대",
	novelizerStove = "가스레인지",
	novelizerHealthKit = "구급 상자",
	novelizerHealthVial = "체력 주사",
	novelizerDeskProp = "탁자",
	novelizerChairProp = "의자",
	novelizerCrateProp = "상자",
	novelizerDrumProp = "드럼통",
	novelizerPopcanProp = "캔",
	novelizerCanProp = "캔",
	novelizerBottleProp = "병",
	novelizerGascanProp = "기름통",
	novelizerVehicleProp = "탈것",
	novelizerVendingMachine = "자판기",
	novelizerCoffeeMachine = "커피 자판기",
	novelizerPepsiMachine = "음료 자판기",
	novelizerRationDispenser = "배급기",
	novelizerLock = "잠금장치",
	novelizerShipment = "보급품",
	novelizerNewspaperProp = "신문",
	novelizerRadioProp = "라디오",
	novelizerTVProp = "TV",
	novelizerScanner = "스캐너",
	novelizerBucketFire = "양동이 화로",
	novelizerBonfire = "모닥불",
	novelizerBreachCharge = "폭파 장치",
	novelizerDigitalClock = "디지털 시계",
	novelizerMachineGun = "기관총",
	novelizerSniperRifle = "저격총",
	novelizerKeys = "열쇠고리",
	novelizerHands = "주먹",
	novelizerBody = "몸",
	novelizerHeadcrab = "헤드크랩",
	novelizerAntlion = "개미귀신",
	novelizerZombie = "좀비",
	novelizerCorpse = "시신",
	novelizerSuitcase = "여행 가방",
	novelizerRationPack = "배급 포대",
	novelizerCID = "신분증",
	novelizerToken = "토큰",
	novelizerTokens = "토큰",
	novelizerMeFormat = "** %s %s",

	novelizerEat1 = "%s 천천히 한입 베어 뭅니다.",
	novelizerEat2 = "%s 조금 먹습니다.",
	novelizerEat3 = "%s 뜯어 조금씩 먹습니다.",
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
	novelizerRaise2 = "%s 전투 준비 자세로 올립니다.",
	novelizerRaise3 = "%s 들어 올립니다.",
	novelizerLower1 = "%s 내립니다.",
	novelizerLower2 = "%s 편안한 자세로 내립니다.",
	novelizerLower3 = "%s 준비 자세에서 풀어 둡니다.",
	novelizerReload1 = "%s 다시 장전합니다.",
	novelizerReload2 = "새 탄창을 갈아 끼웁니다.",
	novelizerReload3 = "장전을 마칩니다.",
	novelizerSwitch1 = "%s 바꿔 듭니다.",
	novelizerSwitch2 = "%s 꺼내 듭니다.",
	novelizerSwitch3 = "%s 손에 쥡니다.",
	novelizerTake1 = "%s 집어 듭니다.",
	novelizerTake2 = "%s 챙겨 듭니다.",
	novelizerTake3 = "%s 손에 넣습니다.",
	novelizerDrop1 = "%s 내려놓습니다.",
	novelizerDrop2 = "%s 바닥에 내려둡니다.",
	novelizerDrop3 = "%s 손에서 놓습니다.",
	novelizerHandsPickup1 = "%s 두 손으로 집어 듭니다.",
	novelizerHandsPickup2 = "%s 붙잡아 들어 올립니다.",
	novelizerHandsPickup3 = "%s 들어 올립니다.",
	novelizerHandsDrop1 = "%s 다시 내려놓습니다.",
	novelizerHandsDrop2 = "%s 조심스럽게 바닥에 내려둡니다.",
	novelizerHandsDrop3 = "%s 손에서 내려놓습니다.",

	novelizerRequest1 = "단말기에 짧은 요청을 넣습니다.",
	novelizerRequest2 = "기기에 대고 짧게 요청합니다.",
	novelizerRequest3 = "장치로 간단한 요청을 보냅니다.",
	novelizerRadio1 = "무전을 송신합니다.",
	novelizerRadio2 = "무전기에 입을 가까이 대고 말합니다.",
	novelizerRadio3 = "무전 송신 버튼을 누릅니다.",
	novelizerSetFreq1 = "무전 주파수를 조정합니다.",
	novelizerSetFreq2 = "무전 채널을 다시 맞춥니다.",
	novelizerSetFreq3 = "새 무전 주파수를 입력합니다.",
	novelizerSearch1 = "앞에 선 이의 몸을 수색하기 시작합니다.",
	novelizerSearch2 = "짧게 소지품 수색을 시작합니다.",
	novelizerSearch3 = "지닌 물건이 있는지 상대의 몸을 확인합니다.",
	novelizerBandageSelf1 = "%s 자기 상처에 감아 둡니다.",
	novelizerBandageSelf2 = "%s 자기 몸의 상처에 둘러 묶습니다.",
	novelizerBandageSelf3 = "%s 상처 부위에 단단히 감습니다.",
	novelizerBandageOther1 = "%s 상대의 상처에 감아 줍니다.",
	novelizerBandageOther2 = "%s 상대의 부상 부위를 감아 처치합니다.",
	novelizerBandageOther3 = "%s 상처를 감아 고정해줍니다.",
	novelizerAedSelf1 = "%s 몸에 대고 거친 충격을 가합니다.",
	novelizerAedSelf2 = "%s 자기 몸에 붙여 방전을 일으킵니다.",
	novelizerAedSelf3 = "%s 몸에 밀착시킨 채 충격을 보냅니다.",
	novelizerAedOther1 = "%s 제세동 충격을 가합니다.",
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
	novelizerMolotovPrime3 = "%s 불을 붙이고 던지려고 합니다.",
	novelizerGrenadeThrow1 = "%s 던집니다.",
	novelizerGrenadeThrow2 = "%s 힘껏 내던집니다.",
	novelizerGrenadeThrow3 = "%s 빠르게 투척합니다.",
	novelizerMolotovThrow1 = "%s 불붙은 궤적을 그리도록 던집니다.",
	novelizerMolotovThrow2 = "%s 화염병을 내던집니다.",
	novelizerMolotovThrow3 = "%s 불길을 그리며 투척합니다.",
	novelizerAmmo1 = "%s 장전합니다.",
	novelizerAmmo2 = "%s 보충합니다.",
	novelizerAmmo3 = "%s 채웁니다.",
	novelizerBattery1 = "%s 전력을 보충합니다.",
	novelizerBattery2 = "%s 장비 전원계에 연결합니다.",
	novelizerBattery3 = "%s 동력으로 장비를 충전합니다.",
	novelizerMedSelf1 = "%s 열어 자기 상처를 살핍니다.",
	novelizerMedSelf2 = "%s 펼쳐 스스로 응급 처치를 시작합니다.",
	novelizerMedSelf3 = "%s 꺼내 상처를 처치합니다.",
	novelizerMedOther1 = "%s 열어 앞에 선 이의 상처를 살핍니다.",
	novelizerMedOther2 = "%s 펼쳐 상대방의 부상을 처치합니다.",
	novelizerMedOther3 = "%s 꺼내 치료하려 몸을 숙입니다.",
	novelizerInjectionSelf1 = "%s 자기 몸에 찔러 넣습니다.",
	novelizerInjectionSelf2 = "%s 스스로 주사합니다.",
	novelizerInjectionSelf3 = "%s 자기 몸에 주입합니다.",
	novelizerInjectionOther1 = "앞에 선 이의 몸에 %s 찔러 넣습니다.",
	novelizerInjectionOther2 = "%s 상대방에게 주사합니다.",
	novelizerInjectionOther3 = "몸을 숙여 %s 주입합니다.",

	novelizerFlashlightOn1 = "손전등의 스위치를 올립니다.",
	novelizerFlashlightOn2 = "손전등 불빛을 켭니다.",
	novelizerFlashlightOn3 = "손전등을 켜 앞을 비춥니다.",
	novelizerFlashlightOff1 = "손전등의 스위치를 내립니다.",
	novelizerFlashlightOff2 = "손전등 불빛을 끕니다.",
	novelizerFlashlightOff3 = "손전등을 꺼 빛을 거둡니다.",
	novelizerStoveOn1 = "%s 불을 켭니다.",
	novelizerStoveOn2 = "%s 화구에 불을 붙입니다.",
	novelizerStoveOn3 = "%s 가스를 틀어 점화합니다.",
	novelizerStoveOff1 = "%s 불을 끕니다.",
	novelizerStoveOff2 = "%s 가스를 잠급니다.",
	novelizerStoveOff3 = "%s 화구를 꺼 둡니다.",
	novelizerFireOn1 = "%s 불을 붙입니다.",
	novelizerFireOn2 = "%s 점화합니다.",
	novelizerFireOn3 = "%s 불씨를 살립니다.",
	novelizerFireOff1 = "%s 불을 끕니다.",
	novelizerFireOff2 = "%s 불을 눌러 끕니다.",
	novelizerFireOff3 = "%s 불씨를 꺼뜨립니다.",

	novelizerMachineVending1 = "%s 선택 버튼을 누릅니다.",
	novelizerMachineVending2 = "%s 조작부를 건드립니다.",
	novelizerMachineVending3 = "%s 앞에서 원하는 항목을 고릅니다.",

	novelizerMachineHealth1 = "자동화 의료 장치를 작동시킵니다.",
	novelizerMachineHealth2 = "자동화 의료 장치에 손을 올려놓습니다.",
	novelizerMachineHealth3 = "자동화 의료 장치의 치료 기능을 작동시킵니다.",
	novelizerMachineHealthGrub1 = "%s %s의 투입구에 끼워 넣습니다.",
	novelizerMachineHealthGrub2 = "%s %s 앞에 끼워 넣습니다.",
	novelizerMachineHealthGrub3 = "%s %s의 공급구에 넣습니다.",
	novelizerMachineSuit1 = "충전 장치에서 전력을 받기 시작합니다.",
	novelizerMachineSuit2 = "충전 장치에 연결해 충전을 시작합니다.",
	novelizerMachineSuit3 = "충전 장치를 작동시켜 전력을 끌어옵니다.",

	novelizerMachineRation1 = "%s 앞에서 인증 절차를 밟습니다.",
	novelizerMachineRation2 = "%s 투입구에 CID를 밀어넣습니다.",
	novelizerMachineRation3 = "%s 사용해 배급 절차를 진행합니다.",
	novelizerMachineDigitalClock1 = "%s 모드를 바꿉니다.",
	novelizerMachineDigitalClock2 = "%s 홀로그램 표시를 손짓으로 넘깁니다.",
	novelizerMachineDigitalClock3 = "%s 표시 방식을 바꿉니다.",
	novelizerMachineMannable1 = "%s 손잡이를 붙잡고 자세를 잡습니다.",
	novelizerMachineMannable2 = "%s 붙잡고 사격 자세로 들어갑니다.",
	novelizerMachineMannable3 = "%s 뒤에 붙어 조작을 시작합니다.",
	novelizerMachineSniper1 = "%s 붙잡고 조준 자세를 잡습니다.",
	novelizerMachineSniper2 = "%s 조준경을 통해 조준합니다.",
	novelizerMachineSniper3 = "%s 몸을 붙여 사격 준비를 합니다.",
	novelizerDoorBreachPlace1 = "문에 장치를 부착합니다.",
	novelizerDoorBreachPlace2 = "문에 장치를 눌러 붙입니다.",
	novelizerDoorBreachPlace3 = "문에 장치를 고정합니다.",
	novelizerDoorBreachUse1 = "%s 기폭 장치를 작동시킵니다.",
	novelizerDoorBreachUse2 = "%s 타이머를 누릅니다.",
	novelizerDoorBreachUse3 = "%s 폭파 절차를 시작합니다.",
	novelizerLockDetonate1 = "%s 기폭 절차를 시작합니다.",
	novelizerLockDetonate2 = "%s 폭파 상태로 전환합니다.",
	novelizerLockDetonate3 = "%s 폭파되도록 설정합니다.",

	novelizerMachineComputer1 = "%s 자판을 두드립니다.",
	novelizerMachineComputer2 = "%s 명령을 입력합니다.",
	novelizerMachineComputer3 = "%s 조작합니다.",
	novelizerMachineComputer4 = "%s 메뉴를 빠르게 넘깁니다.",

	novelizerMachineTerminal1 = "%s 사용해 요청을 입력합니다.",
	novelizerMachineTerminal2 = "%s 조작합니다.",
	novelizerMachineTerminal3 = "%s 스크린을 터치합니다.",

	novelizerMachineLock1 = "%s 상태를 점검합니다.",
	novelizerMachineLock2 = "%s 입력 값을 넣습니다.",
	novelizerMachineLock3 = "%s 제어합니다.",

	novelizerMachineRecycler1 = "%s 폐품을 밀어 넣고 작동시킵니다.",
	novelizerMachineRecycler2 = "%s 투입구에 재료를 넣습니다.",
	novelizerMachineRecycler3 = "%s 작동시켜 재활용을 시작합니다.",

	novelizerMachineForcefield1 = "역장의 제어부에 손을 뻗습니다.",
	novelizerMachineForcefield2 = "역장 설정을 조정합니다.",
	novelizerMachineForcefield3 = "역장 제어기를 조작합니다.",

	novelizerMachineRadio1 = "%s 다이얼을 만지작거립니다.",
	novelizerMachineRadio2 = "%s 주파수를 맞춥니다.",
	novelizerMachineRadio3 = "%s 조작부를 손으로 조정합니다.",

	novelizerMachinePanel1 = "%s 표면을 훑고 조작부를 누릅니다.",
	novelizerMachinePanel2 = "%s 입력 절차를 밟습니다.",
	novelizerMachinePanel3 = "%s 익숙한 손놀림으로 다룹니다.",
	novelizerMachineContainer1 = "%s 열어 안쪽을 살핍니다.",
	novelizerMachineContainer2 = "%s 열고 안을 뒤적입니다.",
	novelizerMachineContainer3 = "%s 열어 내용물을 확인합니다.",
	novelizerMachineLaundryPipe1 = "%s 쳐서 세탁물을 받아 냅니다.",
	novelizerMachineLaundryPipe2 = "%s 두들겨 옷가지가 떨어지게 만듭니다.",
	novelizerMachineLaundryPipe3 = "%s 건드려 세탁물이 떨어지길 기다립니다.",
	novelizerMachineWasher1 = "%s 세탁물을 넣고 세탁을 시작합니다.",
	novelizerMachineWasher2 = "%s 조작하여 세탁을 돌리기 시작합니다.",
	novelizerMachineWasher3 = "%s 닫고 세탁을 돌립니다.",
	novelizerMachineDoorOpen1 = "%s 엽니다.",
	novelizerMachineDoorOpen2 = "%s 열어 둡니다.",
	novelizerMachineDoorOpen3 = "%s 열어 놓습니다.",
	novelizerMachineDoorClose1 = "%s 닫습니다.",
	novelizerMachineDoorClose2 = "%s 닫아 놓습니다.",
	novelizerMachineDoorClose3 = "%s 닫아 둡니다.",
	novelizerMachineDoorUse1 = "%s 만져 봅니다.",
	novelizerMachineDoorUse2 = "%s 건드려 봅니다.",
	novelizerMachineDoorUse3 = "%s 반응을 살펴봅니다.",
	novelizerLoot1 = "%s 안을 뒤져 쓸 만한 것을 찾기 시작합니다.",
	novelizerLoot2 = "%s 안쪽을 뒤적이며 폐품을 찾습니다.",
	novelizerLoot3 = "%s 안을 파헤치듯 뒤집니다.",
	novelizerLootGeneric1 = "안을 뒤져 쓸 만한 것을 찾기 시작합니다.",
	novelizerLootGeneric2 = "안쪽을 뒤적이며 폐품을 찾습니다.",
	novelizerLootGeneric3 = "안을 파헤치듯 뒤집니다.",
	novelizerApply1 = "%s 꺼내 보입니다.",
	novelizerApply2 = "%s 손에 들어 제시합니다.",
	novelizerApply3 = "%s 신분을 확인시키듯 내밉니다.",
	novelizerDropMoney1 = "%s 꺼내 바닥에 내려놓습니다.",
	novelizerDropMoney2 = "%s 바닥에 내려둡니다.",
	novelizerDropMoney3 = "%s 바닥에 내려놓습니다.",
	novelizerGiveMoney1 = "%s 건네줍니다.",
	novelizerGiveMoney2 = "%s 줍니다.",
	novelizerGiveMoney3 = "%s 전해줍니다.",
	novelizerRead1 = "%s 읽습니다.",
	novelizerRead2 = "%s 펼쳐 읽어 봅니다.",
	novelizerRead3 = "%s 잠시 훑어 읽습니다.",
	novelizerVendorTrade1 = "%s 거래를 마칩니다.",
	novelizerVendorTrade2 = "%s 물건값을 치르고 거래를 끝냅니다.",
	novelizerVendorTrade3 = "%s 매매를 마무리합니다.",
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
	novelizerSelfCraft1 = "자기 손으로 무언가 조립하며 제작하기 시작합니다.",
	novelizerSelfCraft2 = "재료를 맞추어 보며 무언가를 제작하기 시작합니다.",
	novelizerSelfCraft3 = "제작 작업에 열중하기 시작합니다.",
	novelizerSelfCook1 = "조심스럽게 손으로 음식을 준비하기 시작합니다.",
	novelizerSelfCook2 = "음식 준비 작업에 열중합니다.",
	novelizerSelfCook3 = "음식을 만드는 데 집중합니다.",
	novelizerCookFood1 = "%s 불에 올려 조리하기 시작합니다.",
	novelizerCookFood2 = "%s 열 위에서 천천히 익히기 시작합니다.",
	novelizerCookFood3 = "%s 조리합니다.",
	novelizerRationOpen1 = "%s 뜯어 엽니다.",
	novelizerRationOpen2 = "%s의 봉인을 뜯습니다.",
	novelizerRationOpen3 = "%s 열어 안의 물건을 꺼내기 시작합니다.",
	novelizerEquipSuitcase1 = "%s 손에 듭니다.",
	novelizerEquipSuitcase2 = "%s 손잡이째 들어 올립니다.",
	novelizerEquipSuitcase3 = "%s 손에 들고 자리를 잡습니다.",
	novelizerUnequipSuitcase1 = "%s 내려놓습니다.",
	novelizerUnequipSuitcase2 = "%s 손에서 내립니다.",
	novelizerUnequipSuitcase3 = "%s 곁에 내려 둡니다.",
	novelizerSwitchSuitcase1 = "%s 손에 듭니다.",
	novelizerSwitchSuitcase2 = "%s 손잡이째 들어 쥡니다.",
	novelizerSwitchSuitcase3 = "%s 손으로 고쳐 잡습니다.",
	novelizerHandsRaise1 = "주먹을 쥡니다.",
	novelizerHandsRaise2 = "두 주먹을 올려 경계 자세를 취합니다.",
	novelizerHandsRaise3 = "손을 말아쥐고 싸울 자세를 잡습니다.",
	novelizerHandsLower1 = "주먹을 풉니다.",
	novelizerHandsLower2 = "두 손을 천천히 내립니다.",
	novelizerHandsLower3 = "경계 자세를 풉니다.",
	novelizerLadder1 = "사다리를 붙잡습니다.",
	novelizerLadder2 = "사다리에 발을 딛습니다.",
	novelizerLadder3 = "사다리를 탑니다.",
	novelizerVehicleSeatEnter1 = "앉습니다.",
	novelizerVehicleSeatEnter2 = "자리에 털썩 앉습니다.",
	novelizerVehicleSeatEnter3 = "몸을 낮춰 앉습니다.",
	novelizerVehicleSeatExit1 = "일어섭니다.",
	novelizerVehicleSeatExit2 = "자리에서 몸을 일으킵니다.",
	novelizerVehicleSeatExit3 = "몸을 세워 다시 일어납니다.",
	novelizerVehicleEnter1 = "%s 올라탑니다.",
	novelizerVehicleEnter2 = "%s 탑니다.",
	novelizerVehicleEnter3 = "%s 몸을 싣습니다.",
	novelizerVehicleExit1 = "%s 내립니다.",
	novelizerVehicleExit2 = "%s 빠져나옵니다.",
	novelizerVehicleExit3 = "%s 내려섭니다.",
	novelizerFallover1 = "바닥에 힘없이 쓰러집니다.",
	novelizerFallover2 = "몸의 힘이 풀리며 고꾸라집니다.",
	novelizerFallover3 = "의식을 잃고 주저앉아 쓰러집니다.",
	novelizerDoorKnock1 = "%s 손으로 두드립니다.",
	novelizerDoorKnock2 = "%s 손등으로 가볍게 노크합니다.",
	novelizerDoorKnock3 = "%s 짧게 두드립니다.",
	novelizerEquipSidearm1 = "%s 손닿기 좋게 준비합니다.",
	novelizerEquipSidearm2 = "%s 바로 꺼낼 수 있게 정리합니다.",
	novelizerEquipSidearm3 = "%s 곧바로 쓸 수 있게 갖춥니다.",
	novelizerUnequipSidearm1 = "%s 다시 정리해 둡니다.",
	novelizerUnequipSidearm2 = "%s 손닿는 자리에서 치웁니다.",
	novelizerUnequipSidearm3 = "%s 휴대 위치에 정돈합니다.",
	novelizerEquipMelee1 = "%s 단단히 쥡니다.",
	novelizerEquipMelee2 = "%s 편안하게 고쳐 쥡니다.",
	novelizerEquipMelee3 = "%s 바로 쓸 수 있게 자세를 잡습니다.",
	novelizerUnequipMelee1 = "%s 도로 치워 둡니다.",
	novelizerUnequipMelee2 = "%s 손에서 내립니다.",
	novelizerUnequipMelee3 = "%s 휴대 위치에 정돈합니다.",
	novelizerGrenadeRaise1 = "%s 투척 자세로 들어 올립니다.",
	novelizerGrenadeRaise2 = "%s 던질 준비 자세로 쥡니다.",
	novelizerGrenadeRaise3 = "%s 투척할 태세를 잡습니다.",
	novelizerGrenadeLower1 = "%s 투척 자세에서 내립니다.",
	novelizerGrenadeLower2 = "%s 아래로 내려 잡습니다.",
	novelizerGrenadeLower3 = "%s 쥔 손의 힘을 풉니다.",
	novelizerStaminaEmpty1 = "지친 듯 거칠게 숨을 몰아쉽니다.",
	novelizerStaminaEmpty2 = "기진한 듯 잠시 몸을 늘어뜨립니다.",
	novelizerStaminaEmpty3 = "행동력이 다해 숨을 고릅니다.",
	novelizerInjuredGun1 = "총격을 받고 몸을 크게 움찔합니다.",
	novelizerInjuredGun2 = "날아든 총탄에 몸을 크게 휘청입니다.",
	novelizerInjuredGun3 = "총탄이 박히는 충격에 짧은 비명을 지릅니다.",
	novelizerDeathGun1 = "총격에 쓰러집니다.",
	novelizerDeathGun2 = "총탄 세례를 버티지 못하고 바닥에 고꾸라집니다.",
	novelizerDeathGun3 = "치명적인 총격 끝에 숨을 거두며 쓰러집니다.",

	novelizerInjuredBurn1 = "화상에 몸을 홱 움츠립니다.",
	novelizerInjuredBurn2 = "뜨거운 열기에 고통스러운 신음을 흘립니다.",
	novelizerInjuredBurn3 = "달라붙는 불길을 피하려 몸을 비틉니다.",
	novelizerDeathBurn1 = "불길에 휩싸여 쓰러집니다.",
	novelizerDeathBurn2 = "불에 타오르며 힘없이 주저앉습니다.",
	novelizerDeathBurn3 = "심한 화상을 견디지 못하고 의식을 잃습니다.",

	novelizerInjuredBlunt1 = "강한 타격에 휘청입니다.",
	novelizerInjuredBlunt2 = "묵직한 충격에 뒤로 밀려납니다.",
	novelizerInjuredBlunt3 = "둔중한 타격음에 짧게 숨을 들이킵니다.",
	novelizerDeathBlunt1 = "둔중한 충격을 버티지 못하고 쓰러집니다.",
	novelizerDeathBlunt2 = "무거운 타격에 짓눌리듯 고꾸라집니다.",
	novelizerDeathBlunt3 = "마지막 타격 끝에 몸의 힘이 풀리며 쓰러집니다.",

	novelizerInjuredFall1 = "추락 충격에 비틀거립니다.",
	novelizerInjuredFall2 = "바닥에 세게 부딪히며 몸을 가누지 못합니다.",
	novelizerInjuredFall3 = "높은 곳에서 떨어진 충격에 숨을 헐떡입니다.",
	novelizerDeathFall1 = "추락 충격 끝에 쓰러집니다.",
	novelizerDeathFall2 = "바닥에 떨어진 뒤 미동도 없이 굳어집니다.",
	novelizerDeathFall3 = "추락하며 입은 내상 끝에 숨을 거둡니다.",

	novelizerInjuredRadiation1 = "방사선에 몸을 떨며 고통스러워합니다.",
	novelizerInjuredRadiation2 = "보이지 않는 병마에 숨을 헐떡이며 비틀거립니다.",
	novelizerInjuredRadiation3 = "방사선 피폭에 신체가 무너지듯 흔들립니다.",
	novelizerDeathRadiation1 = "심한 방사선 피폭 끝에 쓰러집니다.",
	novelizerDeathRadiation2 = "침묵의 죽음인 방사능에 굴복해 쓰러집니다.",
	novelizerDeathRadiation3 = "피폭량이 한계를 넘어서며 그대로 고꾸라집니다.",

	novelizerInjuredShock1 = "전류에 몸이 튀듯 경련합니다.",
	novelizerInjuredShock2 = "갑작스러운 전격에 몸을 심하게 떱니다.",
	novelizerInjuredShock3 = "흐르는 전류에 몸이 마비된 듯 굳어집니다.",
	novelizerDeathShock1 = "강한 전격에 몸이 굳으며 쓰러집니다.",
	novelizerDeathShock2 = "전류에 타들어 가며 바닥에 고꾸라집니다.",
	novelizerDeathShock3 = "마지막 불꽃과 함께 의식을 잃고 쓰러집니다.",

	novelizerInjuredBlast1 = "폭발 충격에 크게 휘청입니다.",
	novelizerInjuredBlast2 = "충격파에 중심을 잃고 뒤로 밀려납니다.",
	novelizerInjuredBlast3 = "근처에서 터진 굉음에 몸을 움츠립니다.",
	novelizerDeathBlast1 = "폭발에 휩쓸려 쓰러집니다.",
	novelizerDeathBlast2 = "폭발 압력에 튕겨 나가며 힘없이 쓰러집니다.",
	novelizerDeathBlast3 = "연기와 잔해 속으로 사라지듯 쓰러집니다.",

	novelizerInjuredVehicle1 = "차량 충격에 크게 휘청입니다.",
	novelizerInjuredVehicle2 = "묵직한 기계의 충격에 나가떨어집니다.",
	novelizerInjuredVehicle3 = "차체에 부딪히며 고통스러운 신음을 냅니다.",
	novelizerDeathVehicle1 = "차량에 들이받혀 쓰러집니다.",
	novelizerDeathVehicle2 = "차량의 무게에 짓눌려 숨을 거둡니다.",
	novelizerDeathVehicle3 = "강한 충돌 끝에 다시는 일어나지 못합니다.",

	novelizerInjuredSonic1 = "음파 충격에 몸을 비틀거립니다.",
	novelizerInjuredSonic2 = "강렬한 음파에 머리를 감싸며 괴로워합니다.",
	novelizerInjuredSonic3 = "고주파 펄스에 중심을 잃고 휘청입니다.",
	novelizerDeathSonic1 = "강한 음파에 버티지 못하고 쓰러집니다.",
	novelizerDeathSonic2 = "음파 압력을 견디지 못하고 그대로 고꾸라집니다.",
	novelizerDeathSonic3 = "내장이 뒤틀리는 음파 충격 끝에 쓰러집니다.",

	novelizerInjuredEnergyBeam1 = "에너지 광선 충격에 몸을 젖힙니다.",
	novelizerInjuredEnergyBeam2 = "응축된 빛에 타들어 가며 신음합니다.",
	novelizerInjuredEnergyBeam3 = "에너지 아크가 몸에 닿자 비명을 지릅니다.",
	novelizerDeathEnergyBeam1 = "에너지 광선에 맞아 쓰러집니다.",
	novelizerDeathEnergyBeam2 = "집중된 에너지에 신체가 관통되며 쓰러집니다.",
	novelizerDeathEnergyBeam3 = "에너지 광선의 위력 앞에 무너져 내립니다.",

	novelizerInjuredSlash1 = "타격에 몸을 움찔합니다.",
	novelizerInjuredSlash2 = "날카로운 날붙이에 몸을 홱 비틉니다.",
	novelizerInjuredSlash3 = "베인 상처를 감싸며 고통스러워합니다.",
	novelizerDeathSlash1 = "강한 타격 끝에 쓰러집니다.",
	novelizerDeathSlash2 = "깊게 베인 상처로부터 피를 흘리며 쓰러집니다.",
	novelizerDeathSlash3 = "치명적인 베기 공격에 목숨을 잃습니다.",

	novelizerInjuredDrown1 = "물을 들이마시며 버둥입니다.",
	novelizerInjuredDrown2 = "물속에서 허우적거리며 괴로워합니다.",
	novelizerInjuredDrown3 = "액체가 폐를 채우자 숨이 막힌 듯 발작합니다.",
	novelizerDeathDrown1 = "익사하며 쓰러집니다.",
	novelizerDeathDrown2 = "수면 아래로 서서히 가라앉습니다.",
	novelizerDeathDrown3 = "깊은 물속으로 끌려가듯 미동을 멈춥니다.",

	novelizerInjuredAcid1 = "부식성 손상에 급히 몸을 뺍니다.",
	novelizerInjuredAcid2 = "화학 물질에 타들어 가며 고통스러워합니다.",
	novelizerInjuredAcid3 = "살아 있는 것처럼 쏘는 산성 통증에 비명을 지릅니다.",
	novelizerDeathAcid1 = "산성 손상에 버티지 못하고 쓰러집니다.",
	novelizerDeathAcid2 = "부식되어 가는 신체를 이기지 못하고 쓰러집니다.",
	novelizerDeathAcid3 = "화학적인 부식 끝에 조용히 고꾸라집니다.",

	novelizerInjuredPoison1 = "독성 반응에 비틀거립니다.",
	novelizerInjuredPoison2 = "독소가 퍼지자 목을 부여잡으며 컥컥댑니다.",
	novelizerInjuredPoison3 = "시야가 흐려지며 독성 쇼크에 휘청입니다.",
	novelizerDeathPoison1 = "독성 쇼크 끝에 쓰러집니다.",
	novelizerDeathPoison2 = "독이 심장에 도달하며 그대로 숨을 거둡니다.",
	novelizerDeathPoison3 = "치명적인 화합물에 중독되어 쓰러집니다.",

	novelizerInjuredBite1 = "날카로운 공격에 몸을 뒤틉니다.",
	novelizerInjuredBite2 = "물린 상처의 통증에 움찔하며 몸을 뺍니다.",
	novelizerInjuredBite3 = "달려드는 공격을 피하려 황급히 몸을 비틉니다.",
	novelizerDeathBite1 = "공격에 버티지 못하고 바닥으로 쓰러집니다.",
	novelizerDeathBite2 = "치명적인 상처를 입고 힘없이 무너집니다.",
	novelizerDeathBite3 = "흉폭한 공격 끝에 미동을 멈춥니다.",

	novelizerInjuredStarve1 = "극심한 허기에 배를 움켜쥐며 괴로워합니다.",
	novelizerInjuredStarve2 = "영양 부족으로 몸에 힘이 빠지며 비틀거립니다.",
	novelizerInjuredStarve3 = "속이 타들어 가는 듯한 배고픔에 신음을 냅니다.",
	novelizerDeathStarve1 = "기력이 다한 듯 힘없이 고꾸라집니다.",
	novelizerDeathStarve2 = "지독한 굶주림 끝에 결국 쓰러집니다.",
	novelizerDeathStarve3 = "허기를 이기지 못하고 조용히 숨을 거둡니다.",

	novelizerItRadioMusic1 = "%s 희미한 음악을 흘립니다.",
	novelizerItRadioMusic2 = "%s 잔잔한 음악 소리를 내보냅니다.",
	novelizerItRadioMusic3 = "%s 안정된 채널로 음악을 틀어 둡니다.",
	novelizerItRadioOffFreq1 = "%s 채널이 어긋난 채 지직거립니다.",
	novelizerItRadioOffFreq2 = "%s 주파수를 못 잡고 잡음만 흘립니다.",
	novelizerItRadioOffFreq3 = "%s 불안정한 주파수 사이를 헤매며 지직거립니다.",

	novelizerUse1 = "%s 상호작용합니다.",
	novelizerUse2 = "%s 이것저것 만져 봅니다.",
	novelizerUse3 = "%s 잠시 다뤄 봅니다.",
	novelizerUse4 = "%s 살펴본 뒤 사용합니다.",

	novelizerItDiskRead1 = "%s 디스크를 긁는 달그락거림이 새어 나옵니다.",
	novelizerItDiskRead2 = "%s 저장 장치를 읽는 짧은 기계음이 울립니다.",
	novelizerItDiskRead3 = "%s 데이터를 읽는 딸깍거리고 윙윙거리는 소음을 냅니다.",
	novelizerItMachineHum1 = "%s 낮은 기계음을 흘립니다.",
	novelizerItMachineHum2 = "%s 작동하며 조용히 웅웅거립니다.",
	novelizerItMachineHum3 = "%s 일정한 산업 진동을 냅니다.",
	novelizerItLaundryPipe1 = "%s 세탁물이 떨어지며 덜컹거립니다.",
	novelizerItLaundryPipe2 = "%s 안에서 옷가지가 지나가며 약하게 금속음을 냅니다.",
	novelizerItLaundryPipe3 = "%s 세탁물이 미끄러져 내려오며 한차례 떨립니다.",
	novelizerItWasher1 = "%s 빨래통을 돌리며 철퍽거리고 웅웅거립니다.",
	novelizerItWasher2 = "%s 젖은 세탁물을 굴리며 무겁게 흔들립니다.",
	novelizerItWasher3 = "%s 빨래통이 한 바퀴 돌 때마다 낮게 울립니다.",
	novelizerItVending1 = "%s 코일이 안쪽에서 윙윙거리며 덜컹댑니다.",
	novelizerItVending2 = "%s 오래된 냉각 장치가 웅웅거립니다.",
	novelizerItVending3 = "%s 내부 어딘가에서 금속성 덜컥임이 납니다.",
	novelizerItForcefield1 = "%s 딱딱 튀는 전기음과 함께 지직거립니다.",
	novelizerItForcefield2 = "%s 팽팽한 막처럼 웅웅거립니다.",
	novelizerItForcefield3 = "%s 갇힌 에너지가 튀듯 희미하게 딱딱거립니다.",
	novelizerItRadio1 = "%s 희미한 잡음을 흘립니다.",
	novelizerItRadio2 = "%s 짧은 무전 잡음을 튀깁니다.",
	novelizerItRadio3 = "%s 불안정한 채널에서 지직거립니다.",
	novelizerItDoorLocked1 = "%s 잠겨 있어 열리지 않습니다.",
	novelizerItDoorLocked2 = "%s 덜컹이기만 할 뿐 열리지 않습니다.",
	novelizerItDoorLocked3 = "%s 잠금장치가 버티며 열리지 않습니다.",
	novelizerItGasStove1 = "%s 일정한 가스 불꽃 소리와 함께 치익거립니다.",
	novelizerItGasStove2 = "%s 점화된 화구에서 고른 열기를 뿜습니다.",
	novelizerItGasStove3 = "%s 불꽃을 유지한 채 낮게 속삭이듯 타오릅니다.",
	novelizerItStove1 = "%s 일정하게 타오르며 치익거립니다.",
	novelizerItStove2 = "%s 타오르며 약하게 타닥거립니다.",
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
	category = "Novelizer"
})

ix.config.Add("novelizerUse3DText", false, "Whether novelizer should show temporary 3D text for /it lines instead of chat lines.", nil, {
	category = "Novelizer"
})

ix.config.Add("novelizer3DTextDuration", 4.5, "How long temporary 3D novelizer text stays visible.", nil, {
	data = {min = 1, max = 12},
	category = "Novelizer"
})

ix.config.Add("novelizerIdleItCooldown", DEFAULT_IT_COOLDOWN, "Base cooldown for idle entity /it narration. Actual delay is randomized by about +/- 5 seconds.", nil, {
	data = {min = 10, max = 300},
	category = "Novelizer"
})

local function GetChatRange()
	return ix.config.Get("chatRange", 280)
end

local function GetNovelMeRange()
	return GetChatRange()
end

local function GetNovelItRange()
	return GetChatRange()
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

local function ResolvePhraseReference(text)
	if (not IsFilledString(text)) then
		return nil, nil
	end

	local resolved = GetPhraseTemplate(text, "english")

	if (IsFilledString(resolved)) then
		return resolved, text
	end

	local languages = ix.lang and ix.lang.stored

	if (istable(languages)) then
		for _, languageData in pairs(languages) do
			if (istable(languageData) and IsFilledString(languageData[text])) then
				return text, text
			end
		end
	end

	local normalized = text:gsub("%s+L$", "")

	if (normalized ~= text) then
		resolved = GetPhraseTemplate(normalized, "english")

		if (IsFilledString(resolved)) then
			return resolved, normalized
		end

		if (istable(languages)) then
			for _, languageData in pairs(languages) do
				if (istable(languageData) and IsFilledString(languageData[normalized])) then
					return normalized, normalized
				end
			end
		end
	end

	return text, nil
end

local function StripTrailingParticleNoise(text)
	if (not isstring(text) or text == "") then
		return text
	end

	local normalized = text:gsub("[%s%p%c]+$", "")

	while (normalized ~= "") do
		local lastChar = utf8 and utf8.sub and utf8.sub(normalized, -1) or normalized:sub(-1)

		if (lastChar == ")" or lastChar == "]" or lastChar == "}" or lastChar == "\"" or lastChar == "'") then
			normalized = utf8 and utf8.sub and utf8.sub(normalized, 1, -2) or normalized:sub(1, -2)
			normalized = normalized:gsub("[%s%p%c]+$", "")
		else
			break
		end
	end

	return normalized
end

local function GetLastUTF8Codepoint(text)
	if (not utf8 or not utf8.offset or not utf8.codepoint or not isstring(text) or text == "") then
		return nil
	end

	text = StripTrailingParticleNoise(text)

	if (not isstring(text) or text == "") then
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

local function HasFinalConsonantForNonHangul(text)
	text = StripTrailingParticleNoise(text)

	if (not IsFilledString(text)) then
		return false
	end

	local lastChar = text:sub(-1)
	local lowerLastChar = string.lower(lastChar)

	if (lowerLastChar:match("%d")) then
		local digitHasFinal = {
			["0"] = true,
			["1"] = true,
			["2"] = false,
			["3"] = true,
			["4"] = false,
			["5"] = false,
			["6"] = true,
			["7"] = true,
			["8"] = true,
			["9"] = false
		}

		return digitHasFinal[lastChar] == true
	end

	if (lowerLastChar:match("[%a]")) then
		return not lowerLastChar:match("[aeiouy]")
	end

	return false
end

local function AppendKoreanParticle(text, particleType)
	if (not IsFilledString(text) or not IsFilledString(particleType)) then
		return text
	end

	local codepoint = GetLastUTF8Codepoint(text)

	if (not codepoint or codepoint < 0xAC00 or codepoint > 0xD7A3) then
		local hasFinal = HasFinalConsonantForNonHangul(text)

		if (particleType == "object") then
			return text .. (hasFinal and "을" or "를")
		elseif (particleType == "subject") then
			return text .. (hasFinal and "이" or "가")
		elseif (particleType == "topic") then
			return text .. (hasFinal and "은" or "는")
		elseif (particleType == "with") then
			return text .. (hasFinal and "과" or "와")
		elseif (particleType == "possessive") then
			return text .. "의"
		elseif (particleType == "direction") then
			return text .. (hasFinal and "으로" or "로")
		elseif (particleType == "location") then
			return text .. "에"
		elseif (particleType == "source") then
			return text .. "에서"
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
	elseif (particleType == "possessive") then
		return text .. "의"
	elseif (particleType == "direction") then
		return text .. ((finalConsonant == 0 or finalConsonant == 8) and "로" or "으로")
	elseif (particleType == "location") then
		return text .. "에"
	elseif (particleType == "source") then
		return text .. "에서"
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

local classSubjectPhrases = {
	item_healthkit = "novelizerHealthKit",
	item_healthvial = "novelizerHealthVial",
	ix_assistance_terminal = "assistanceTerminal",
	ix_vendingmachine = "novelizerVendingMachine",
	ix_pepsimachine = "novelizerPepsiMachine",
	ix_coffeemachine = "novelizerCoffeeMachine",
	ix_stove = "novelizerStove",
	ix_bucket = "novelizerBucketFire",
	ix_bonfire = "novelizerBonfire",
	ix_rationdispenser = "novelizerRationDispenser",
	ix_station = "novelizerWorkbench",
	ix_combinelock = "novelizerLock",
	ix_unionlock = "novelizerLock",
	ix_doorbreach = "novelizerBreachCharge",
	stormfox_digitalclock = "novelizerDigitalClock",
	ent_mannable = "novelizerMachineGun",
	ent_mannable_combinesniper = "novelizerSniperRifle"
}

local modelSubjectPhrases = {
	{patterns = {"chair"}, phrase = "novelizerChairProp"},
	{patterns = {"table", "desk"}, phrase = "novelizerDeskProp"},
	{patterns = {"crate", "box"}, phrase = "novelizerCrateProp"},
	{patterns = {"drum"}, phrase = "novelizerDrumProp"},
	{patterns = {"popcan"}, phrase = "novelizerPopcanProp"},
	{patterns = {"bottle"}, phrase = "novelizerBottleProp"},
	{patterns = {"gascan"}, phrase = "novelizerGascanProp"},
	{patterns = {"vehicle"}, phrase = "novelizerVehicleProp"},
	{patterns = {"newspaper"}, phrase = "novelizerNewspaperProp"},
	{patterns = {"radio"}, phrase = "novelizerRadioProp"},
	{patterns = {"/tv", "_tv", "television"}, phrase = "novelizerTVProp"},
	{patterns = {"scanner"}, phrase = "novelizerScanner"},
	{patterns = {"shipment"}, phrase = "novelizerShipment"}
}

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
	local name = hook.Run("GetCharacterName", client, "me") or (IsValid(client) and client:Name() or "Console")

	if (IsValid(client)) then
		color = hook.Run("GetPlayerChatColor", client, ix.chat.classes.me)
			or client:GetClassColor()
			or team.GetColor(client:Team())
	end

	return name, color
end

function PLUGIN:ShouldUse3DText()
	return ix.config.Get("novelizerUse3DText", false) == true
end

function PLUGIN:GetNovelItDisplayText(phraseKey, data)
	local success, phrase = pcall(function()
		return self:TranslatePhrase(phraseKey, data)
	end)

	if (not success or not IsFilledString(phrase)) then
		return nil
	end

	return "** " .. phrase
end

function PLUGIN:GetListenersInRange(position, range)
	if (not position) then
		return {}
	end

	local listeners = {}
	local radius = tonumber(range) or GetNovelItRange()
	local maxDistance = radius * radius

	for _, listener in ipairs(player.GetAll()) do
		if (IsValid(listener) and listener:GetPos():DistToSqr(position) <= maxDistance) then
			listeners[#listeners + 1] = listener
		end
	end

	return listeners
end

function PLUGIN:SendNovel3DText(receivers, payload)
	if (CLIENT or not istable(payload)) then
		return false
	end

	net.Start(NOVELIZER_3D_NET)
		net.WriteString(payload.kind or "it")
		net.WriteEntity(IsValid(payload.anchor) and payload.anchor or NULL)
		net.WriteEntity(IsValid(payload.speaker) and payload.speaker or NULL)
		net.WriteVector(payload.position or vector_origin)
		net.WriteString(tostring(payload.phraseKey or ""))
		net.WriteTable(payload.arguments or {})
		net.WriteFloat(tonumber(payload.duration) or ix.config.Get("novelizer3DTextDuration", 4.5))
		net.WriteFloat(tonumber(payload.range) or GetNovelItRange())
		net.WriteBool(payload.anonymous == true)
	net.Broadcast()

	return true
end

function PLUGIN:GetIdleItCooldown()
	local baseCooldown = math.max(tonumber(ix.config.Get("novelizerIdleItCooldown", DEFAULT_IT_COOLDOWN)) or DEFAULT_IT_COOLDOWN, 1)
	local minCooldown = math.max(baseCooldown - IDLE_IT_RANDOM_WINDOW, 1)
	local maxCooldown = math.max(baseCooldown + IDLE_IT_RANDOM_WINDOW, minCooldown)

	return math.Rand(minCooldown, maxCooldown)
end

function PLUGIN:GetIdleComputerEntities()
	local interactivePlugin = ix.plugin.list["interactive_computers"]
	local entities = {}

	if (not interactivePlugin or not interactivePlugin.IsPrimaryComputerEntity) then
		return entities
	end

	-- Optimize computer finding by using specific classes if available, otherwise fallback.
	-- This is much faster than iterating over thousands of props/items with ents.Iterator().
	local computerClasses = interactivePlugin.ComputerClasses or IDLE_COMPUTER_CLASSES
	for _, className in ipairs(computerClasses) do
		local found = ents.FindByClass(className)
		for i = 1, #found do
			local entity = found[i]
			if (interactivePlugin:IsPrimaryComputerEntity(entity)
				and entity.GetPowered
				and entity:GetPowered()) then
				entities[#entities + 1] = entity
			end
		end
	end

	return entities
end

function PLUGIN:ResolveItemSubjectData(item)
	if (item and IsFilledString(item.novelizerSubject)) then
		local text, phrase = ResolvePhraseReference(item.novelizerSubject)
		return text or item.novelizerSubject, phrase
	end

	if (item) then
		local uniqueID = string.lower(tostring(item.uniqueID or ""))
		local className = string.lower(tostring(item.class or ""))

		if (uniqueID == "ration" or uniqueID == "ration_gr1" or uniqueID == "ration_gr2" or uniqueID == "ration_gr3" or uniqueID == "metropolice_ration") then
			return "ration pack", "novelizerRationPack"
		end

		if (uniqueID:find("suitcase", 1, true) or className == "ix_suitcase") then
			return "suitcase", "novelizerSuitcase"
		end
	end

	if (item and IsFilledString(item.name)) then
		local text, phrase = ResolvePhraseReference(item.name)
		return text or item.name, phrase
	end

	return L("novelizerSomething"), "novelizerSomething"
end

function PLUGIN:GetRawItemSubject(item)
	local text, phrase = self:ResolveItemSubjectData(item)
	local localized = phrase and (L(phrase) or phrase) or text

	return localized or L("novelizerSomething")
end

function PLUGIN:ResolveEntitySubjectData(entity)
	if (not IsValid(entity)) then
		return L("novelizerSomething"), "novelizerSomething"
	end

	local className = entity:GetClass()
	
	if (className == "ix_money") then
		local amount = entity.GetAmount and entity:GetAmount() or 0
		local name = (tonumber(amount) == 1) and (ix.currency.singular or "novelizerToken") or (ix.currency.plural or "novelizerTokens")
		local text, phrase = ResolvePhraseReference(name)

		return text or name, phrase
	end

	if (className == "prop_ragdoll") then
		local owner = entity.GetNetVar and entity:GetNetVar("player") or nil
		local isCorpse = (entity.GetNetVar and (entity:GetNetVar("ixInventory") or entity:GetNetVar("ixPlayerName")))
			or entity.ixInventory or entity.ixPlayerName

		if (isCorpse or (IsValid(owner) and owner:IsPlayer() and not owner:Alive())) then
			return "corpse", "novelizerCorpse"
		end

		local model = string.lower(tostring(entity:GetModel() or ""))

		if (model:find("headcrab", 1, true)) then
			return "headcrab", "novelizerHeadcrab"
		end

		if (model:find("antlion", 1, true)) then
			return "antlion", "novelizerAntlion"
		end

		if (model:find("zombie", 1, true)) then
			return "zombie", "novelizerZombie"
		end

		return "body", "novelizerBody"
	end

	local subjectPhrase = classSubjectPhrases[className]

	if (IsFilledString(subjectPhrase)) then
		local text, phrase = ResolvePhraseReference(subjectPhrase)
		return text or subjectPhrase, phrase or subjectPhrase
	end

	if (entity:IsVehicle()) then
		if (self:IsSeatLikeVehicle(entity)) then
			return "chair", "novelizerChairProp"
		end

		return "vehicle", "novelizerVehicleProp"
	end

	if (entity:IsDoor()) then
		return "door", "novelizerDoor"
	end

	if (entity:GetClass() == "ix_forcefield") then
		return "forcefield", "novelizerForcefield"
	end

	if (IsFilledString(entity.novelizerSubject)) then
		local text, phrase = ResolvePhraseReference(entity.novelizerSubject)
		return text or entity.novelizerSubject, phrase
	end

	if (isfunction(entity.GetItemTable)) then
		local itemTable = entity:GetItemTable()

		if (istable(itemTable)) then
			if (IsFilledString(itemTable.novelizerSubject)) then
				local text, phrase = ResolvePhraseReference(itemTable.novelizerSubject)
				return text or itemTable.novelizerSubject, phrase
			end

			if (IsFilledString(itemTable.name)) then
				local text, phrase = ResolvePhraseReference(itemTable.name)
				return text or itemTable.name, phrase
			end
		end
	end

	local interactivePlugin = ix.plugin.list["interactive_computers"]

	if (interactivePlugin and interactivePlugin.IsComputerEntity and interactivePlugin:IsComputerEntity(entity)) then
		local definition = interactivePlugin.GetComputerDefinition and interactivePlugin:GetComputerDefinition(entity:GetClass()) or nil

		if (definition) then
			if (IsFilledString(definition.langKey)) then
				local text, phrase = ResolvePhraseReference(definition.langKey)
				return text or definition.langKey, phrase or definition.langKey
			end

			if (IsFilledString(definition.name)) then
				local text, phrase = ResolvePhraseReference(definition.name)
				return text or definition.name, phrase
			end
		end
	end

	if (isfunction(entity.GetDisplayName)) then
		local name = entity:GetDisplayName()

		if (IsFilledString(name)) then
			local text, phrase = ResolvePhraseReference(name)
			return text or name, phrase
		end
	end

	if (IsFilledString(entity.PrintName) and entity.PrintName ~= "Entity") then
		local text, phrase = ResolvePhraseReference(entity.PrintName)
		return text or entity.PrintName, phrase
	end

	local stored = scripted_ents.GetStored(entity:GetClass())
	local storedTable = stored and stored.t

	if (istable(storedTable) and IsFilledString(storedTable.PrintName) and storedTable.PrintName ~= "Entity") then
		local text, phrase = ResolvePhraseReference(storedTable.PrintName)
		return text or storedTable.PrintName, phrase
	end

	for _, data in ipairs(modelSubjectPhrases) do
		local model = string.lower(tostring(entity:GetModel() or ""))

		if (model ~= "") then
			for _, pattern in ipairs(data.patterns or {}) do
				if (model:find(pattern, 1, true)) then
					return data.phrase, data.phrase
				end
			end
		end
	end

	if (IsFilledString(className) and className:find("^ix_", 1)) then
		return className, className
	end

	return "object", "novelizerObject"
end

function PLUGIN:GetRawEntitySubject(entity)
	local text, phrase = self:ResolveEntitySubjectData(entity)
	local localized = phrase and (L(phrase) or phrase) or text

	return localized or L("novelizerSomething")
end

function PLUGIN:GetItemSubject(item)
	local text, phrase = self:ResolveItemSubjectData(item)
	return BuildArgument(text, "object", phrase)
end

function PLUGIN:GetItemSubjectWithParticle(item, particle)
	local text, phrase = self:ResolveItemSubjectData(item)
	return BuildArgument(text, particle or "object", phrase)
end

function PLUGIN:GetPossessiveItemSubject(item)
	return self:GetItemSubjectWithParticle(item, "possessive")
end

function PLUGIN:GetEntitySubjectWithParticle(entity, particle)
	if (not IsValid(entity)) then
		return BuildArgument(L("novelizerSomething"), particle or "object")
	end

	local text, phrase = self:ResolveEntitySubjectData(entity)
	return BuildArgument(text, particle or "object", phrase)
end

function PLUGIN:GetEntitySubject(entity)
	return self:GetEntitySubjectWithParticle(entity, "object")
end

function PLUGIN:GetBareEntitySubject(entity)
	if (not IsValid(entity)) then
		return BuildArgument(L("novelizerSomething"), false)
	end

	local text, phrase = self:ResolveEntitySubjectData(entity)
	return BuildArgument(text, false, phrase)
end

function PLUGIN:GetItEntitySubject(entity)
	return self:GetEntitySubjectWithParticle(entity, "subject")
end

function PLUGIN:GetPossessiveEntitySubject(entity)
	return self:GetEntitySubjectWithParticle(entity, "possessive")
end

function PLUGIN:GetWithEntitySubject(entity)
	return self:GetEntitySubjectWithParticle(entity, "with")
end

function PLUGIN:GetWeaponSubjectWithParticle(weapon, particle)
	if (not IsValid(weapon)) then
		return BuildArgument(L("novelizerSomething"), particle or "object")
	end

	local className = string.lower(tostring(weapon:GetClass() or ""))

	if (className == "ix_keys") then
		return BuildArgument("keyring", particle or "object", "novelizerKeys")
	end

	if (className == "ix_hands") then
		return BuildArgument("fists", particle or "object", "novelizerHands")
	end

	if (istable(weapon.ixItem)) then
		local text, phrase = self:ResolveItemSubjectData(weapon.ixItem)
		return BuildArgument(text, particle or "object", phrase)
	end

	local printName = weapon:GetPrintName()

	if (IsFilledString(printName) and printName ~= weapon:GetClass()) then
		return BuildArgument(printName, particle or "object", printName)
	end

	if (IsFilledString(weapon.PrintName) and weapon.PrintName ~= "Scripted Weapon") then
		return BuildArgument(weapon.PrintName, particle or "object", weapon.PrintName)
	end

	return BuildArgument(weapon:GetClass(), particle or "object")
end

function PLUGIN:GetWeaponSubject(weapon)
	return self:GetWeaponSubjectWithParticle(weapon, "object")
end

function PLUGIN:IsGrenadeWeapon(weapon)
	return IsValid(weapon) and istable(weapon.ixItem) and weapon.ixItem.isGrenade == true
end

function PLUGIN:GetEquipCategory(item)
	if (not item) then
		return "generic"
	end

	local uniqueID = string.lower(tostring(item.uniqueID or ""))
	local name = string.lower(tostring(item.name or ""))
	local className = string.lower(tostring(item.class or ""))
	local category = string.lower(tostring(item.outfitCategory or ""))

	if (uniqueID:find("suitcase", 1, true) or className == "ix_suitcase") then
		return "suitcase"
	end

	local weaponCategory = string.lower(tostring(item.weaponCategory or ""))

	if (item.isWeapon and (weaponCategory == "sidearm"
		or uniqueID:find("pistol", 1, true) or uniqueID:find("revolver", 1, true)
		or uniqueID:find("handgun", 1, true) or name:find("pistol", 1, true)
		or name:find("revolver", 1, true) or name:find("handgun", 1, true))) then
		return "sidearm"
	end

	if (item.isWeapon and weaponCategory == "melee") then
		return "melee"
	end

	if (item.isWeapon) then
		return "weapon"
	end

	if (uniqueID:find("gasmask", 1, true) or name:find("gasmask", 1, true)
		or uniqueID:find("cp_mask", 1, true) or name:find("cp mask", 1, true)
		or uniqueID:find("respirator", 1, true) or name:find("respirator", 1, true)) then
		return "respirator"
	end

	if (category == "face" or category == "goggles" or uniqueID:find("facewrap", 1, true) or uniqueID:find("goggles", 1, true) or uniqueID:find("visor", 1, true) or name:find("goggles", 1, true) or name:find("visor", 1, true)) then
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

	if (category == "kevlar" or category == "vest" or category == "armor" or uniqueID:find("armor", 1, true)
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

	-- torso is handled as uniform above
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
	elseif (category == "sidearm") then
		return isEquip and {"novelizerEquipSidearm1", "novelizerEquipSidearm2", "novelizerEquipSidearm3"}
			or {"novelizerUnequipSidearm1", "novelizerUnequipSidearm2", "novelizerUnequipSidearm3"}
	elseif (category == "melee") then
		return isEquip and {"novelizerEquipMelee1", "novelizerEquipMelee2", "novelizerEquipMelee3"}
			or {"novelizerUnequipMelee1", "novelizerUnequipMelee2", "novelizerUnequipMelee3"}
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

function PLUGIN:IsSpecialSwitchWeapon(weapon)
	if (not IsValid(weapon)) then
		return false
	end

	local className = string.lower(tostring(weapon:GetClass() or ""))

	return self:IsNarratableWeapon(weapon)
end

function PLUGIN:GetSwitchPhrasePool(weapon)
	if (not IsValid(weapon)) then
		return {
			"novelizerSwitch1",
			"novelizerSwitch2",
			"novelizerSwitch3"
		}
	end

	local className = string.lower(tostring(weapon:GetClass() or ""))

	if (istable(weapon.ixItem) and self:GetEquipCategory(weapon.ixItem) == "suitcase") then
		return {
			"novelizerSwitchSuitcase1",
			"novelizerSwitchSuitcase2",
			"novelizerSwitchSuitcase3"
		}
	end

	return {
		"novelizerSwitch1",
		"novelizerSwitch2",
		"novelizerSwitch3"
	}
end

function PLUGIN:GetSwitchArguments(weapon, phraseKey)
	if (phraseKey == "novelizerSwitch1") then
		return {
			self:GetWeaponSubjectWithParticle(weapon, "direction")
		}
	end

	return {
		self:GetWeaponSubject(weapon)
	}
end

function PLUGIN:CanNarrateRaisedWeapon(weapon)
	if (not IsValid(weapon)) then
		return false
	end

	local className = string.lower(tostring(weapon:GetClass() or ""))

	return className == "ix_hands" or self:IsNarratableWeapon(weapon)
end

function PLUGIN:GetRaisePhrasePool(weapon, raised)
	if (IsValid(weapon) and string.lower(tostring(weapon:GetClass() or "")) == "ix_hands") then
		return raised and {
			"novelizerHandsRaise1",
			"novelizerHandsRaise2",
			"novelizerHandsRaise3"
		} or {
			"novelizerHandsLower1",
			"novelizerHandsLower2",
			"novelizerHandsLower3"
		}
	end

	if (self:IsGrenadeWeapon(weapon)) then
		return raised and {
			"novelizerGrenadeRaise1",
			"novelizerGrenadeRaise2",
			"novelizerGrenadeRaise3"
		} or {
			"novelizerGrenadeLower1",
			"novelizerGrenadeLower2",
			"novelizerGrenadeLower3"
		}
	end

	return raised and {
		"novelizerRaise1",
		"novelizerRaise2",
		"novelizerRaise3"
	} or {
		"novelizerLower1",
		"novelizerLower2",
		"novelizerLower3"
	}
end

function PLUGIN:GetRaiseArguments(weapon)
	if (IsValid(weapon) and string.lower(tostring(weapon:GetClass() or "")) == "ix_hands") then
		return nil
	end

	return {
		self:GetWeaponSubject(weapon)
	}
end

function PLUGIN:HandleManualRaiseToggle(client, weapon, raised)
	if (not SERVER or not IsValid(client) or not IsValid(weapon)) then
		return
	end

	if (not self:CanAutoNarrate(client) or not self:CanNarrateRaisedWeapon(weapon)) then
		return
	end

	local weaponClass = weapon:GetClass()
	local currentTime = CurTime()
	local lastNarration = client.ixNovelizerLastRaiseNarration

	if (istable(lastNarration)
		and lastNarration.weaponClass == weaponClass
		and lastNarration.raised == (raised == true)
		and (lastNarration.time or 0) + 0.35 >= currentTime) then
		return
	end

	client.ixNovelizerLastRaiseNarration = {
		weaponClass = weaponClass,
		raised = raised == true,
		time = currentTime
	}

	self:SendNovelMe(client, table.Random(self:GetRaisePhrasePool(weapon, raised == true)), self:GetRaiseArguments(weapon), {
		actionKey = raised == true and "weapon_raise" or "weapon_lower",
		cooldown = 0.35,
		bypassGlobalCooldown = true
	})
end

function PLUGIN:IsObserver(client)
	return IsValid(client) and client:GetMoveType() == MOVETYPE_NOCLIP and not client:InVehicle()
end

function PLUGIN:CanAutoNarrate(client, allowDead)
	return IsValid(client)
		and client:IsPlayer()
		and client:GetCharacter()
		and (allowDead == true or client:Alive())
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

function PLUGIN:GetNarratedConsumeAction(item, action)
	if (action ~= "Eat" or not item) then
		return action
	end

	if (item.isDrink) then
		return "Drink"
	end

	if (IsFilledString(item.novelizerConsumeAction)) then
		return item.novelizerConsumeAction
	end

	return action
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
	local narratedAction = self:GetNarratedConsumeAction(item, action)

	if (item and istable(item.novelizerPhrases) and istable(item.novelizerPhrases[narratedAction])) then
		return item.novelizerPhrases[narratedAction]
	end

	if (item and istable(item.novelizerPhrases) and istable(item.novelizerPhrases[action])) then
		return item.novelizerPhrases[action]
	end

	if (item and self.itemActionPhrasePools[item.uniqueID] and self.itemActionPhrasePools[item.uniqueID][narratedAction]) then
		return self.itemActionPhrasePools[item.uniqueID][narratedAction]
	end

	if (item and self.itemActionPhrasePools[item.uniqueID] and self.itemActionPhrasePools[item.uniqueID][action]) then
		return self.itemActionPhrasePools[item.uniqueID][action]
	end

	local profile = self:GetConsumptionProfile(client)
	action = narratedAction

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

	return nil
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

	if (entity:IsDoor()) then
		return not self:HasDoorHandle(entity)
	end

	local className = entity:GetClass()

	if (className == "ix_health_charger" or className == "ix_suit_charger"
		or className == "ix_washing_machine" or className == "ix_washing_machine_small"
		or className == "ix_stove" or className == "ix_recycler"
		or className == "ix_laundry_pipe" or className == "ix_bucket"
		or className == "ix_bonfire" or className == "ix_station"
		or className:find("ix_station_", 1, true)) then
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

function PLUGIN:HasDoorHandle(entity)
	if (not IsValid(entity) or not entity:IsDoor()) then
		return false
	end

	local handleBone = entity.LookupBone and entity:LookupBone("handle") or nil
	return isnumber(handleBone) and handleBone >= 0
end

function PLUGIN:GetDoorPhrasePool(entity)
	if (not IsValid(entity) or not entity:IsDoor()) then
		return nil
	end

	if (isfunction(entity.IsLocked) and entity:IsLocked()) then
		return {
			"novelizerMachineDoorUse1",
			"novelizerMachineDoorUse2",
			"novelizerMachineDoorUse3"
		}
	end

	local saveTable = entity.GetSaveTable and entity:GetSaveTable() or nil
	local toggleState = saveTable and (saveTable.m_toggle_state or saveTable.m_eDoorState) or nil

	-- 0: Closed, 1: Opening, 2: Open, 3: Closing
	if (toggleState == 0 or toggleState == 3) then
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

function PLUGIN:GetDoorActionKey(entity)
	if (not IsValid(entity) or not entity:IsDoor()) then
		return "door_use"
	end

	if (isfunction(entity.IsLocked) and entity:IsLocked()) then
		return "door_locked"
	end

	local saveTable = entity.GetSaveTable and entity:GetSaveTable() or nil
	local toggleState = saveTable and (saveTable.m_toggle_state or saveTable.m_eDoorState) or nil

	if (toggleState == 0) then
		return "door_open"
	elseif (toggleState == 1 or toggleState == 2) then
		return "door_close"
	end

	return "door_use"
end

function PLUGIN:GetEntityUseArguments(entity, phraseKey)
	if (phraseKey == "novelizerMachineLock1" or phraseKey == "novelizerMachineLock2"
		or phraseKey == "novelizerMachineTerminal3"
		or phraseKey == "novelizerMachineDoorUse3" or phraseKey == "novelizerMachineVending1"
		or phraseKey == "novelizerMachineVending2" or phraseKey == "novelizerMachineComputer4"
		or phraseKey == "novelizerMachineRadio1" or phraseKey == "novelizerMachineRadio2"
		or phraseKey == "novelizerMachineRadio3"
		or phraseKey == "novelizerDoorBreachUse1" or phraseKey == "novelizerDoorBreachUse2"
		or phraseKey == "novelizerDoorBreachUse3" or phraseKey == "novelizerMachineDigitalClock2"
		or phraseKey == "novelizerStoveOn1" or phraseKey == "novelizerStoveOn2" or phraseKey == "novelizerStoveOn3"
		or phraseKey == "novelizerStoveOff1" or phraseKey == "novelizerStoveOff2" or phraseKey == "novelizerStoveOff3"
		or phraseKey == "novelizerFireOn1" or phraseKey == "novelizerFireOn2" or phraseKey == "novelizerFireOn3"
		or phraseKey == "novelizerFireOff1" or phraseKey == "novelizerFireOff2" or phraseKey == "novelizerFireOff3") then
		return {
			self:GetPossessiveEntitySubject(entity)
		}
	end

	if (phraseKey == "novelizerMachineVending3" or phraseKey == "novelizerMachineRation1" or phraseKey == "novelizerMachineRation2") then
		return {
			self:GetBareEntitySubject(entity)
		}
	end

	if (phraseKey == "novelizerMachineComputer2") then
		return {
			self:GetEntitySubjectWithParticle(entity, "direction")
		}
	end

	return {
		self:GetEntitySubject(entity)
	}
end

function PLUGIN:GetCharacterSubject(client)
	if (not IsValid(client)) then
		return BuildArgument(L("novelizerSomeone"), "object")
	end

	local name = hook.Run("GetCharacterName", client, "me") or client:Name()
	return BuildArgument(name, "object")
end

function PLUGIN:GetMoneySubject(amount)
	local name = (tonumber(amount) == 1) and (ix.currency.singular or "novelizerToken") or (ix.currency.plural or "novelizerTokens")
	local text, phrase = ResolvePhraseReference(name)

	return BuildArgument(text or name, "object", phrase)
end

function PLUGIN:GetItArguments(entity, key, phraseKey)
	if (phraseKey == "novelizerItVending1" or phraseKey == "novelizerItVending2") then
		return {
			self:GetPossessiveEntitySubject(entity)
		}
	end

	if (phraseKey == "novelizerItDoorLocked3") then
		return {
			self:GetPossessiveEntitySubject(entity)
		}
	end

	if (phraseKey == "novelizerItVending3" or key == "workbench_rattle") then
		return {
			self:GetBareEntitySubject(entity)
		}
	end

	return {
		self:GetItEntitySubject(entity)
	}
end

function PLUGIN:SetIdleWarmup(entity, minDelay, maxDelay)
	if (not IsValid(entity)) then
		return
	end

	entity.ixNovelizerIdleDelayUntil = CurTime() + math.Rand(minDelay or IDLE_WARMUP_MIN, maxDelay or IDLE_WARMUP_MAX)
end

function PLUGIN:ClearIdleWarmup(entity)
	if (IsValid(entity)) then
		entity.ixNovelizerIdleDelayUntil = nil
	end
end

function PLUGIN:CanEmitIdleNow(entity)
	return not IsValid(entity) or (entity.ixNovelizerIdleDelayUntil or 0) <= CurTime()
end

function PLUGIN:IsInteractiveComputerEntity(entity, requireInteractive)
	local interactivePlugin = ix.plugin.list["interactive_computers"]

	if (not interactivePlugin or not interactivePlugin.IsComputerEntity or not interactivePlugin:IsComputerEntity(entity)) then
		return false
	end

	if (requireInteractive ~= true) then
		return true
	end

	local definition = interactivePlugin.GetComputerDefinition and interactivePlugin:GetComputerDefinition(entity:GetClass()) or nil

	return entity:GetClass() == "ix_interactive_computer" or (definition and definition.interactive == true)
end

function PLUGIN:HasDamageFlag(damageType, flag)
	return isnumber(flag) and isnumber(damageType) and bitBand(damageType, flag) == flag
end

function PLUGIN:GetWeaponItemByClass(className)
	className = string.lower(tostring(className or ""))

	if (not IsFilledString(className) or not istable(ix and ix.item and ix.item.list)) then
		return nil
	end

	for _, itemTable in pairs(ix.item.list) do
		if (istable(itemTable) and itemTable.isWeapon == true
			and string.lower(tostring(itemTable.class or "")) == className) then
			return itemTable
		end
	end
end

function PLUGIN:IsDamageFromMeleeWeapon(dmgInfo)
	if (not dmgInfo) then
		return false
	end

	local entities = {
		dmgInfo:GetInflictor(),
		dmgInfo:GetAttacker()
	}

	for _, entity in ipairs(entities) do
		if (not IsValid(entity)) then
			continue
		end

		local className = string.lower(tostring(entity.GetClass and entity:GetClass() or ""))
		local itemTable = entity.ixItem

		if (not istable(itemTable) and entity:IsWeapon()) then
			itemTable = self:GetWeaponItemByClass(className)
		end

		if (istable(itemTable) and itemTable.isWeapon == true
			and string.lower(tostring(itemTable.weaponCategory or "")) == "melee") then
			return true
		end

		if (className == "ix_hands" or className == "ix_stunstick" or className == "weapon_crowbar"
			or className == "weapon_hl2axe" or className == "weapon_hl2bottle"
			or className == "weapon_hl2brokenbottle" or className == "weapon_hl2hook"
			or className == "weapon_hl2pan" or className == "weapon_hl2pickaxe"
			or className == "weapon_hl2pipe" or className == "weapon_hl2pot"
			or className == "weapon_hl2shovel") then
			return true
		end
	end

	return false
end

function PLUGIN:ClassifyDamageType(dmgInfo, victim)
	if (not dmgInfo) then
		return nil
	end

	local damageType = dmgInfo:GetDamageType()
	local attacker = dmgInfo:GetAttacker()

	-- Handle starvation (self-damage from hunger/thirst plugin, or generic suicide)
	if (IsValid(attacker) and attacker:IsPlayer() and (attacker == victim) and (damageType == 0 or damageType == DMG_DIRECT)) then
		return DAMAGE_DEFINITIONS[16]
	end

	-- Handle bites/non-weapon creature attacks
	if (self:HasDamageFlag(damageType, DMG_SLASH) and not self:IsDamageFromMeleeWeapon(dmgInfo)) then
		return DAMAGE_DEFINITIONS[15]
	end

	if (self:IsDamageFromMeleeWeapon(dmgInfo)) then
		if (self:HasDamageFlag(damageType, DMG_SLASH)) then
			return DAMAGE_DEFINITIONS[10]
		end

		return DAMAGE_DEFINITIONS[14]
	end

	for i = 1, #DAMAGE_DEFINITIONS do
		local definition = DAMAGE_DEFINITIONS[i]
		for j = 1, #definition.flags do
			if (self:HasDamageFlag(damageType, definition.flags[j])) then
				return definition
			end
		end
	end
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
	data = data or {}

	if (not self:CanAutoNarrate(client, data.allowDead == true) or not IsFilledString(phraseKey)) then
		return false
	end

	if (data.bypassGlobalCooldown ~= true
		and not self:PassNamedCooldown(client, "action_global", tonumber(data.globalCooldown) or GLOBAL_ACTION_COOLDOWN)) then
		return false
	end

	if (IsFilledString(data.actionKey)) then
		local cooldown = tonumber(data.cooldown) or DEFAULT_ACTION_COOLDOWN

		if (not self:PassNamedCooldown(client, "action_" .. data.actionKey, cooldown)) then
			return false
		end
	end

	data.arguments = arguments or {}
	data.range = data.range or GetNovelMeRange()

	ix.chat.Send(client, "novelme", phraseKey, false, nil, data)
	return true
end

function PLUGIN:SendNovelIt(phraseKey, arguments, data)
	if (not IsFilledString(phraseKey)) then
		return false
	end

	data = data or {}

	if (not data.position) then
		return false
	end

	if (self:ShouldUse3DText()) then
		return self:SendNovel3DText(nil, {
			kind = "it",
			anchor = data.anchor,
			position = data.position,
			phraseKey = phraseKey,
			arguments = arguments or {},
			range = data.range or GetNovelItRange(),
			duration = data.duration
		})
	end

	ix.chat.Send(nil, data.chatType or "novelit", phraseKey, false, nil, {
		arguments = arguments or {},
		position = data.position,
		range = data.range or GetNovelItRange()
	})

	return true
end

function PLUGIN:GetHeatItKey(entity)
	if (IsValid(entity) and entity:GetClass() == "ix_stove") then
		return "stove_gas_heat"
	end

	return "stove_heat"
end

function PLUGIN:HandleFlashlightStateChange(client, enabled)
	if (not self:CanAutoNarrate(client) or not self:PassNamedCooldown(client, "flashlight", 0.5)) then
		return false
	end

	local phrasePool = enabled and {
		"novelizerFlashlightOn1",
		"novelizerFlashlightOn2",
		"novelizerFlashlightOn3"
	} or {
		"novelizerFlashlightOff1",
		"novelizerFlashlightOff2",
		"novelizerFlashlightOff3"
	}

	return self:SendNovelMe(client, table.Random(phrasePool), {
		BuildArgument("flashlight", "object", "novelizerFlashlight")
	}, {
		actionKey = enabled and "flashlight_on" or "flashlight_off"
	})
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

	local phraseKey = table.Random(phrasePool)

	if (not IsFilledString(phraseKey)) then
		return false
	end

	local arguments = data.arguments and CopyArray(data.arguments) or self:GetItArguments(entity, key, phraseKey)

	return self:SendNovelIt(phraseKey, arguments, {
		chatType = data.chatType,
		position = position,
		range = data.range or GetNovelItRange(),
		duration = data.duration,
		anchor = entity
	})
end

function PLUGIN:GetItemActionArguments(item, phraseKey)
	if (phraseKey == "novelizerRationOpen2") then
		return {
			self:GetPossessiveItemSubject(item)
		}
	end

	return {
		self:GetItemSubject(item)
	}
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

	itemTable:PostHook(action, function(item, result)
		local client = item.player
		local narratedAction = self:GetNarratedConsumeAction(item, action)
		local phrasePool = self:ResolveItemPhrasePool(item, action, client)

		if (not self:CanAutoNarrate(client) or result == false or not istable(phrasePool) or #phrasePool == 0) then
			return
		end

		local phrase = table.Random(phrasePool)

		self:SendNovelMe(client, phrase, self:GetItemActionArguments(item, phrase), {
			actionKey = "item_" .. string.lower(narratedAction or action)
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

		if (not self:CanAutoNarrate(client) or result == false) then
			return
		end

		if (action == "Equip" and item:GetData("equip") == true) then
			local pool = self:GetEquipPhrasePool(item, action)

			if (pool and self:SendNovelMe(client, table.Random(pool), {
				self:GetItemSubject(item)
			}, {
				actionKey = "equip_" .. self:GetEquipCategory(item)
			})) then
				item.ixNovelizerLastEquipmentNarration = {
					state = true,
					time = CurTime()
				}
			end
		elseif (action == "EquipUn" and item:GetData("equip") ~= true) then
			local pool = self:GetEquipPhrasePool(item, action)

			if (pool and self:SendNovelMe(client, table.Random(pool), {
				self:GetItemSubject(item)
			}, {
				actionKey = "unequip_" .. self:GetEquipCategory(item)
			})) then
				item.ixNovelizerLastEquipmentNarration = {
					state = false,
					time = CurTime()
				}
			end
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

	itemTable:PostHook(action, function(item, result)
		local client = item.player or item:GetOwner()

		if (not self:CanAutoNarrate(client) or result == false) then
			return
		end

		local phrase = table.Random(phrasePool)

		self:SendNovelMe(client, phrase, self:GetItemActionArguments(item, phrase), {
			actionKey = "item_" .. string.lower(action)
		})
	end)
end

function PLUGIN:PatchDoorBreachAction(itemTable)
	if (not itemTable.functions or not itemTable.functions.Place or itemTable.ixNovelizerDoorBreachWrapped) then
		return
	end

	itemTable.ixNovelizerDoorBreachWrapped = true

	local action = itemTable.functions.Place
	local originalOnRun = action.OnRun

	if (not isfunction(originalOnRun)) then
		return
	end

	action.OnRun = function(item, ...)
		local client = item.player or item:GetOwner()
		local result = originalOnRun(item, ...)

		if (result ~= false and self:CanAutoNarrate(client)) then
			self:SendNovelMe(client, table.Random({
				"novelizerDoorBreachPlace1",
				"novelizerDoorBreachPlace2",
				"novelizerDoorBreachPlace3"
			}), nil, {
				actionKey = "doorbreach_place"
			})
		end

		return result
	end
end

function PLUGIN:GetMedicalPhrasePool(itemTable, action)
	local uniqueID = string.lower(tostring(itemTable.uniqueID or ""))
	local name = string.lower(tostring(itemTable.name or ""))

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

	if (uniqueID:find("vial", 1, true) or uniqueID:find("syringe", 1, true)
		or uniqueID:find("inject", 1, true) or name:find("vial", 1, true)
		or name:find("syringe", 1, true) or name:find("inject", 1, true)) then
		return action == "selfheal"
			and {"novelizerInjectionSelf1", "novelizerInjectionSelf2", "novelizerInjectionSelf3"}
			or {"novelizerInjectionOther1", "novelizerInjectionOther2", "novelizerInjectionOther3"}
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
		self:PatchDirectItemAction(itemTable, "take", {
			"novelizerTake1",
			"novelizerTake2",
			"novelizerTake3"
		})
		self:PatchDirectItemAction(itemTable, "drop", {
			"novelizerDrop1",
			"novelizerDrop2",
			"novelizerDrop3"
		})

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

		if (itemTable.uniqueID == "paper") then
			self:PatchDirectItemAction(itemTable, "use", {
				"novelizerRead1",
				"novelizerRead2",
				"novelizerRead3"
			})
		end

		if (itemTable.uniqueID == "ration" or itemTable.uniqueID == "metropolice_ration") then
			self:PatchDirectItemAction(itemTable, "Open", {
				"novelizerRationOpen1",
				"novelizerRationOpen2",
				"novelizerRationOpen3"
			})
		end

		if (itemTable.uniqueID == "doorbreach") then
			self:PatchDoorBreachAction(itemTable)
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
			}, {
				actionKey = "cook_food"
			})

			if (stove) then
				self:EmitConditionalIt(stove, self:GetHeatItKey(stove), {
					cooldown = 4
				})
			end
		end

		return result
	end
end

function PLUGIN:RegisterDefaultEntityPhrases()
	self.classPatternPhrasePools = {}
	self.entityUsePhrasePools = {}

	self:RegisterEntityUsePhrases("ix_money", {
		"novelizerTake1",
		"novelizerTake2",
		"novelizerTake3"
	})
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
		"novelizerMachineVending1",
		"novelizerMachineVending2",
		"novelizerMachineVending3"
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
	local interactivePlugin = ix.plugin.list["interactive_computers"]

	if (interactivePlugin and istable(interactivePlugin.entityDefinitions)) then
		for _, definition in ipairs(interactivePlugin.entityDefinitions) do
			if (IsFilledString(definition.class) and definition.interactive == true) then
				self:RegisterEntityUsePhrases(definition.class, {
					"novelizerMachineComputer1",
					"novelizerMachineComputer2",
					"novelizerMachineComputer3",
					"novelizerMachineComputer4"
				})
			end
		end
	end
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
	-- self:RegisterEntityUsePhrases("ix_forcefield", {
	-- 	"novelizerMachineForcefield1",
	-- 	"novelizerMachineForcefield2",
	-- 	"novelizerMachineForcefield3"
	-- })
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
	self:RegisterEntityUsePhrases("ix_music_radio", {
		"novelizerMachineRadio1",
		"novelizerMachineRadio2",
		"novelizerMachineRadio3"
	})
	self:RegisterEntityUsePhrases("ent_mannable", {
		"novelizerMachineMannable1",
		"novelizerMachineMannable2",
		"novelizerMachineMannable3"
	})
	self:RegisterEntityUsePhrases("ent_mannable_combinesniper", {
		"novelizerMachineSniper1",
		"novelizerMachineSniper2",
		"novelizerMachineSniper3"
	})
	self:RegisterEntityUsePhrases("stormfox_digitalclock", {
		"novelizerMachineDigitalClock1",
		"novelizerMachineDigitalClock2",
		"novelizerMachineDigitalClock3"
	})
	self:RegisterEntityUsePhrases("ix_doorbreach", {
		"novelizerDoorBreachUse1",
		"novelizerDoorBreachUse2",
		"novelizerDoorBreachUse3"
	})
	self:RegisterEntityUsePhrases("ix_ctocameraterminal", {
		"novelizerMachineTerminal1",
		"novelizerMachineTerminal2",
		"novelizerMachineTerminal3"
	})
	self:RegisterEntityUsePhrases("ix_container", {
		"novelizerMachineContainer1",
		"novelizerMachineContainer2",
		"novelizerMachineContainer3"
	})
	self:RegisterEntityUsePhrases("ix_laundry_pipe", {
		"novelizerMachineLaundryPipe1",
		"novelizerMachineLaundryPipe2",
		"novelizerMachineLaundryPipe3"
	})
	self:RegisterEntityUsePhrases("ix_note", {
		"novelizerRead1",
		"novelizerRead2",
		"novelizerRead3"
	})
	self:RegisterEntityUsePhrases("ix_station", {
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
			}), {}, {
				actionKey = "collectwater"
			})
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
			self:SendNovelMe(client, table.Random(phrasePool), arguments, {
				actionKey = "command_" .. string.lower(commandName)
			})
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
	self:PatchCommand("DropMoney", {
		"novelizerDropMoney1",
		"novelizerDropMoney2",
		"novelizerDropMoney3"
	}, function(client, amount)
		return { self:GetMoneySubject(amount) }
	end)
	self:PatchCommand("GiveMoney", {
		"novelizerGiveMoney1",
		"novelizerGiveMoney2",
		"novelizerGiveMoney3"
	}, function(client, target, amount)
		return { self:GetMoneySubject(amount) }
	end)
end

function PLUGIN:PatchToggleRaiseCommand()
	local command = ix.command.list["toggleraise"] or ix.command.list["ToggleRaise"]

	if (not command or command.ixNovelizerWrapped) then
		return
	end

	command.ixNovelizerWrapped = true

	local originalOnRun = command.OnRun

	command.OnRun = function(this, client, ...)
		return originalOnRun(this, client, ...)
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

function PLUGIN:GetRecipePhrasePool(recipeTable, hasStation)
	local category = string.lower(tostring(recipeTable and recipeTable.category or ""))

	if (not hasStation) then
		if (category == "food") then
			return {
				"novelizerSelfCook1",
				"novelizerSelfCook2",
				"novelizerSelfCook3"
			}
		end

		return {
			"novelizerSelfCraft1",
			"novelizerSelfCraft2",
			"novelizerSelfCraft3"
		}
	end

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
		return self:GetBareEntitySubject(entity), entity
	end

	return nil, nil
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
			local phrasePool
			local arguments = nil

			if (IsValid(ent) and ent:GetClass():find("ix_loot_", 1, true)) then
				phrasePool = {
					"novelizerLootGeneric1",
					"novelizerLootGeneric2",
					"novelizerLootGeneric3"
				}
			else
				phrasePool = {
					"novelizerLoot1",
					"novelizerLoot2",
					"novelizerLoot3"
				}
				arguments = {
					self:GetEntitySubject(ent)
				}
			end

			self:SendNovelMe(ply, table.Random(phrasePool), arguments, {
				actionKey = "loot_search"
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
	local categorySounds = {
		disassemble = "physics/metal/metal_box_break1.wav",
		transform = "ambient/materials/gears_short2.wav",
		medical = "items/smallmedkit1.wav",
		weapon = "weapons/shotgun/shotgun_reload2.wav",
		armor = "physics/metal/metal_solid_impact_bullet1.wav",
		generic = "physics/wood/wood_box_scrape1.wav"
	}

	if (not craftPlugin or not craftPlugin.craft or craftPlugin.ixNovelizerCraftWrapped) then
		return
	end

	craftPlugin.ixNovelizerCraftWrapped = true

	hook.Add("CraftRecipeCompleted", "ixNovelizerCraftingActions", function(client, recipeTable, success)
		if (not success or not self:CanAutoNarrate(client) or not recipeTable) then
			return
		end

		local stationSubject, stationEntity = self:ResolveCraftStationSubject(client, recipeTable)
		local phrasePool = self:GetRecipePhrasePool(recipeTable, IsValid(stationEntity))
		local chosenPhrase = table.Random(phrasePool)

		-- Dynamic particle handling for Korean
		if (GetLanguage() == "korean" and IsValid(stationEntity)) then
			if (chosenPhrase == "novelizerCook2") then
				stationSubject = self:GetEntitySubjectWithParticle(stationEntity, "possessive")
			elseif (chosenPhrase == "novelizerCraft3") then
				stationSubject = self:GetEntitySubjectWithParticle(stationEntity, "location")
			end
		end

		self:SendNovelMe(client, chosenPhrase, stationSubject and {
			stationSubject
		} or {}, {
			actionKey = "craft_" .. string.lower(tostring(recipeTable.category or "generic"))
		})

		local category = string.lower(tostring(recipeTable.category or "generic"))
		local sound = recipeTable.sound or categorySounds[category] or categorySounds.generic

		if (sound and category ~= "food") then
			(IsValid(stationEntity) and stationEntity or client):EmitSound(sound)
		end

		if (IsValid(stationEntity)) then
			local itKey = string.lower(tostring(recipeTable.category or "")) == "food"
				and self:GetHeatItKey(stationEntity)
				or "workbench_rattle"

			self:EmitConditionalIt(stationEntity, itKey, {
				cooldown = 4
			})
		end
	end)

	hook.Add("CraftRecipeStarted", "ixNovelizerCraftingActionsStart", function(client, recipeTable)
		if (not self:CanAutoNarrate(client) or not recipeTable) then
			return
		end

		local stationSubject, stationEntity = self:ResolveCraftStationSubject(client, recipeTable)
		local phrasePool = self:GetRecipePhrasePool(recipeTable, IsValid(stationEntity))
		local chosenPhrase = table.Random(phrasePool)

		-- Dynamic particle handling for Korean
		if (GetLanguage() == "korean" and IsValid(stationEntity)) then
			if (chosenPhrase == "novelizerCook2") then
				stationSubject = self:GetEntitySubjectWithParticle(stationEntity, "possessive")
			elseif (chosenPhrase == "novelizerCraft3") then
				stationSubject = self:GetEntitySubjectWithParticle(stationEntity, "location")
			end
		end

		self:SendNovelMe(client, chosenPhrase, stationSubject and {
			stationSubject
		} or {}, {
			actionKey = "craft_start"
		})

		local category = string.lower(tostring(recipeTable.category or "generic"))
		local sound = recipeTable.sound or categorySounds[category] or categorySounds.generic

		if (sound and category ~= "food") then
			(IsValid(stationEntity) and stationEntity or client):EmitSound(sound)
		end
	end)
end

function PLUGIN:PatchRaiseState()
	local playerMeta = FindMetaTable("Player")

	if (not playerMeta) then
		return
	end

	if (playerMeta.SetWepRaised == self.ixNovelizerPatchedSetWepRaised
		and playerMeta.ToggleWepRaised == self.ixNovelizerPatchedToggleWepRaised) then
		return
	end

	playerMeta.ixNovelizerRaisePatchVersion = NOVELIZER_RAISE_PATCH_VERSION

	local patchedSetWepRaised = function(client, bState, weapon)
		weapon = weapon or client:GetActiveWeapon()

		if (IsValid(weapon)) then
			local canShoot = (not bState and weapon.FireWhenLowered) or bState
			client:SetNetVar("raised", bState)

			if (canShoot) then
				timer.Create("ixWeaponRaise" .. client:SteamID64(), 1, 1, function()
					if (IsValid(client)) then
						client:SetNetVar("canShoot", true)
					end
				end)
			else
				timer.Remove("ixWeaponRaise" .. client:SteamID64())
				client:SetNetVar("canShoot", false)
			end
		else
			timer.Remove("ixWeaponRaise" .. client:SteamID64())
			client:SetNetVar("raised", false)
			client:SetNetVar("canShoot", false)
		end
	end

	local patchedToggleWepRaised = function(client)
		local weapon = client:GetActiveWeapon()

		if (not IsValid(weapon)) then
			return
		end

		local alwaysRaised = ALWAYS_RAISED and ALWAYS_RAISED[weapon:GetClass()]

		if (weapon.IsAlwaysRaised or alwaysRaised
			or weapon.IsAlwaysLowered or weapon.NeverRaised) then
			return
		end

		local wasRaised = client:IsWepRaised()
		client:SetWepRaised(not wasRaised, weapon)

		local isRaised = client:IsWepRaised()

		if (isRaised and weapon.OnRaised) then
			weapon:OnRaised()
		elseif (not isRaised and weapon.OnLowered) then
			weapon:OnLowered()
		end

		if (wasRaised ~= isRaised) then
			PLUGIN:HandleManualRaiseToggle(client, weapon, isRaised)
		end
	end

	playerMeta.SetWepRaised = patchedSetWepRaised
	playerMeta.ToggleWepRaised = patchedToggleWepRaised

	self.ixNovelizerPatchedSetWepRaised = patchedSetWepRaised
	self.ixNovelizerPatchedToggleWepRaised = patchedToggleWepRaised
end

function PLUGIN:PatchHandsWeapon()
	local weaponTable = weapons.GetStored("ix_hands")

	if (not weaponTable or weaponTable.ixNovelizerHandsWrapped) then
		return
	end

	weaponTable.ixNovelizerHandsWrapped = true

	local originalPickupObject = weaponTable.PickupObject
	local originalDropObject = weaponTable.DropObject
	local originalSecondaryAttack = weaponTable.SecondaryAttack

	local function GetNearbyHealthCharger(entity)
		if (not IsValid(entity)) then
			return nil
		end

		for _, charger in ipairs(ents.FindInSphere(entity:GetPos(), 48)) do
			if (IsValid(charger) and charger:GetClass() == "ix_health_charger"
				and isfunction(charger.CanConsumeGrubEntity) and charger:CanConsumeGrubEntity(entity)) then
				return charger
			end
		end

		return nil
	end

	if (isfunction(originalPickupObject)) then
		weaponTable.PickupObject = function(weapon, entity)
			local result = originalPickupObject(weapon, entity)
			local client = weapon:GetOwner()

			if (SERVER and IsValid(client) and IsValid(entity)
				and weapon.heldEntity == entity and entity.ixHeldOwner == client) then
				PLUGIN:SendNovelMe(client, table.Random({
					"novelizerHandsPickup1",
					"novelizerHandsPickup2",
					"novelizerHandsPickup3"
				}), {
					PLUGIN:GetEntitySubject(entity)
				}, {
					actionKey = "hands_pickup"
				})
			end

			return result
		end
	end

	if (isfunction(originalDropObject)) then
		weaponTable.DropObject = function(weapon, bThrow)
			local heldEntity = weapon.heldEntity
			local client = weapon:GetOwner()
			local result = originalDropObject(weapon, bThrow)

			if (SERVER and IsValid(client) and IsValid(heldEntity)
				and bThrow ~= true and not IsValid(weapon.heldEntity)) then
				local charger = GetNearbyHealthCharger(heldEntity)

				if (charger) then
					PLUGIN:SendNovelMe(client, table.Random({
						"novelizerMachineHealthGrub1",
						"novelizerMachineHealthGrub2",
						"novelizerMachineHealthGrub3"
					}), {
						PLUGIN:GetEntitySubject(heldEntity),
						PLUGIN:GetPossessiveEntitySubject(charger)
					}, {
						actionKey = "health_charger_grub"
					})

					return result
				end

				PLUGIN:SendNovelMe(client, table.Random({
					"novelizerHandsDrop1",
					"novelizerHandsDrop2",
					"novelizerHandsDrop3"
				}), {
					PLUGIN:GetEntitySubject(heldEntity)
				}, {
					actionKey = "hands_drop"
				})
			end

			return result
		end
	end

	if (isfunction(originalSecondaryAttack)) then
		weaponTable.SecondaryAttack = function(weapon, ...)
			local client = weapon:GetOwner()
			local knockedDoor

			if (SERVER and IsValid(client) and not weapon:IsHoldingObject()) then
				local startPos = client:GetShootPos()
				local trace = util.TraceLine({
					start = startPos,
					endpos = startPos + client:GetAimVector() * 84,
					filter = {weapon, client}
				})
				local entity = trace.Entity

				if (IsValid(entity) and entity:IsDoor() and PLUGIN:HasDoorHandle(entity)
					and hook.Run("CanPlayerKnock", client, entity) ~= false) then
					knockedDoor = entity
				end
			end

			local result = originalSecondaryAttack(weapon, ...)

			if (SERVER and IsValid(client) and IsValid(knockedDoor)) then
				PLUGIN:SendNovelMe(client, table.Random({
					"novelizerDoorKnock1",
					"novelizerDoorKnock2",
					"novelizerDoorKnock3"
				}), {
					PLUGIN:GetEntitySubject(knockedDoor)
				}, {
					actionKey = "door_knock",
					cooldown = 0.45,
					bypassGlobalCooldown = true
				})
			end

			return result
		end
	end
end

function PLUGIN:PatchStoveEntity()
	local stored = scripted_ents.GetStored("ix_stove")
	local entityTable = stored and stored.t

	if (not istable(entityTable) or entityTable.ixNovelizerUseWrapped or not isfunction(entityTable.Use)) then
		return
	end

	entityTable.ixNovelizerUseWrapped = true

	local originalUse = entityTable.Use

	entityTable.Use = function(entity, activator, ...)
		local wasActive = entity:GetNetVar("active", false)
		local result = originalUse(entity, activator, ...)
		local isActive = entity:GetNetVar("active", false)

		if (SERVER and IsValid(activator) and activator:IsPlayer() and wasActive ~= isActive) then
			if (isActive) then
				PLUGIN:SetIdleWarmup(entity)
			else
				PLUGIN:ClearIdleWarmup(entity)
			end

			local phrasePool = isActive and {
				"novelizerStoveOn1",
				"novelizerStoveOn2",
				"novelizerStoveOn3"
			} or {
				"novelizerStoveOff1",
				"novelizerStoveOff2",
				"novelizerStoveOff3"
			}
			local phraseKey = table.Random(phrasePool)

			PLUGIN:SendNovelMe(activator, phraseKey, PLUGIN:GetEntityUseArguments(entity, phraseKey), {
				actionKey = isActive and "stove_on" or "stove_off"
			})
		end

		return result
	end
end

function PLUGIN:PatchFireEntity(className)
	local stored = scripted_ents.GetStored(className)
	local entityTable = stored and stored.t

	if (not istable(entityTable) or entityTable["ixNovelizerUseWrapped_" .. className] or not isfunction(entityTable.Use)) then
		return
	end

	entityTable["ixNovelizerUseWrapped_" .. className] = true

	local originalUse = entityTable.Use

	entityTable.Use = function(entity, activator, ...)
		local wasActive = entity:GetNetVar("active", false)
		local result = originalUse(entity, activator, ...)

		timer.Simple(1.6, function()
			if (not SERVER or not IsValid(entity) or not IsValid(activator) or not activator:IsPlayer()) then
				return
			end

			local isActive = entity:GetNetVar("active", false)

			if (wasActive == isActive) then
				return
			end

			if (isActive) then
				PLUGIN:SetIdleWarmup(entity)
			else
				PLUGIN:ClearIdleWarmup(entity)
			end

			local phrasePool = isActive and {
				"novelizerFireOn1",
				"novelizerFireOn2",
				"novelizerFireOn3"
			} or {
				"novelizerFireOff1",
				"novelizerFireOff2",
				"novelizerFireOff3"
			}
			local phraseKey = table.Random(phrasePool)

			PLUGIN:SendNovelMe(activator, phraseKey, PLUGIN:GetEntityUseArguments(entity, phraseKey), {
				actionKey = isActive and (className .. "_on") or (className .. "_off")
			})
		end)

		return result
	end
end

function PLUGIN:PatchRecyclerEntity()
	local stored = scripted_ents.GetStored("ix_recycler")
	local entityTable = stored and stored.t

	if (not istable(entityTable) or entityTable.ixNovelizerTurnOnWrapped or not isfunction(entityTable.TurnOn)) then
		return
	end

	entityTable.ixNovelizerTurnOnWrapped = true

	local originalTurnOn = entityTable.TurnOn

	entityTable.TurnOn = function(entity, client, ...)
		local wasActive = entity.GetIsActivated and entity:GetIsActivated() or false
		local result = originalTurnOn(entity, client, ...)
		local isActive = entity.GetIsActivated and entity:GetIsActivated() or false

		if (SERVER and result == true and not wasActive and isActive and IsValid(client) and client:IsPlayer()) then
			PLUGIN:SetIdleWarmup(entity)

			PLUGIN:SendNovelMe(client, table.Random({
				"novelizerMachineRecycler1",
				"novelizerMachineRecycler2",
				"novelizerMachineRecycler3"
			}), {
				PLUGIN:GetEntitySubject(entity)
			}, {
				actionKey = "recycler_start"
			})
		end

		return result
	end
end

function PLUGIN:PatchLockEntity(className)
	local stored = scripted_ents.GetStored(className)
	local entityTable = stored and stored.t

	if (not istable(entityTable) or entityTable["ixNovelizerDetonateWrapped_" .. className] or not isfunction(entityTable.Detonate)) then
		return
	end

	entityTable["ixNovelizerDetonateWrapped_" .. className] = true

	local originalDetonate = entityTable.Detonate

	entityTable.Detonate = function(entity, client, ...)
		local wasDetonating = entity.GetDetonating and entity:GetDetonating() or false
		local result = originalDetonate(entity, client, ...)
		local isDetonating = entity.GetDetonating and entity:GetDetonating() or false

		if (SERVER and IsValid(client) and client:IsPlayer() and not wasDetonating and isDetonating) then
			PLUGIN:SendNovelMe(client, table.Random({
				"novelizerLockDetonate1",
				"novelizerLockDetonate2",
				"novelizerLockDetonate3"
			}), {
				PLUGIN:GetEntitySubject(entity)
			}, {
				actionKey = className .. "_detonate"
			})
		end

		return result
	end
end

function PLUGIN:PatchStaminaConsumption()
	if (self.ixNovelizerStaminaWrapped) then
		return
	end

	local playerMeta = FindMetaTable("Player")

	if (not playerMeta or not isfunction(playerMeta.ConsumeStamina)) then
		return
	end

	self.ixNovelizerStaminaWrapped = true

	local originalConsumeStamina = playerMeta.ConsumeStamina

	playerMeta.ConsumeStamina = function(client, amount)
		local previous = client:GetLocalVar("stm", 0)
		local result = originalConsumeStamina(client, amount)
		local current = client:GetLocalVar("stm", 0)

		if (SERVER and previous > 0 and current <= 0 and PLUGIN:CanAutoNarrate(client)) then
			PLUGIN:SendNovelMe(client, table.Random({
				"novelizerStaminaEmpty1",
				"novelizerStaminaEmpty2",
				"novelizerStaminaEmpty3"
			}), nil, {
				actionKey = "stamina_empty",
				cooldown = 5,
				bypassGlobalCooldown = true
			})
		end

		return result
	end
end

function PLUGIN:PatchChargerEntity(className, phrasePool, actionKey)
	local stored = scripted_ents.GetStored(className)
	local entityTable = stored and stored.t

	if (not istable(entityTable) or entityTable["ixNovelizerUseWrapped_" .. className] or not isfunction(entityTable.Use)) then
		return
	end

	entityTable["ixNovelizerUseWrapped_" .. className] = true

	local originalUse = entityTable.Use

	entityTable.Use = function(entity, client, ...)
		local wasActive = entity.IsActive and entity:IsActive() or entity:GetNetVar("active", false)
		local result = originalUse(entity, client, ...)
		local isActive = entity.IsActive and entity:IsActive() or entity:GetNetVar("active", false)

		if (SERVER and not wasActive and isActive and IsValid(client) and client:IsPlayer()) then
			PLUGIN:SendNovelMe(client, table.Random(phrasePool), nil, {
				actionKey = actionKey
			})
		end

		return result
	end
end

function PLUGIN:PatchChargers()
	self:PatchChargerEntity("ix_health_charger", {
		"novelizerMachineHealth1",
		"novelizerMachineHealth2",
		"novelizerMachineHealth3"
	}, "health_charger")
	self:PatchChargerEntity("ix_suit_charger", {
		"novelizerMachineSuit1",
		"novelizerMachineSuit2",
		"novelizerMachineSuit3"
	}, "suit_charger")
end

function PLUGIN:PatchLaundryPipeEntity()
	local stored = scripted_ents.GetStored("ix_laundry_pipe")
	local entityTable = stored and stored.t

	if (not istable(entityTable) or entityTable.ixNovelizerUseWrapped or not isfunction(entityTable.Use)) then
		return
	end

	entityTable.ixNovelizerUseWrapped = true

	local originalUse = entityTable.Use

	entityTable.Use = function(entity, activator, caller, ...)
		local client = IsValid(caller) and caller:IsPlayer() and caller or activator
		local previousNextUse = entity.nextUse or 0
		local result = originalUse(entity, activator, caller, ...)
		local nextUse = entity.nextUse or 0

		if (SERVER and IsValid(client) and client:IsPlayer() and previousNextUse <= CurTime() and nextUse > CurTime()) then
			if (PLUGIN:SendNovelMe(client, table.Random({
				"novelizerMachineLaundryPipe1",
				"novelizerMachineLaundryPipe2",
				"novelizerMachineLaundryPipe3"
			}), {
				PLUGIN:GetEntitySubject(entity)
			}, {
				actionKey = "laundry_pipe_use"
			})) then
				PLUGIN:EmitConditionalIt(entity, "laundry_pipe", {
					cooldown = 4
				})
			end
		end

		return result
	end
end

function PLUGIN:EnsureCorePatches()
	self:PatchRaiseState()
	self:PatchHandsWeapon()
	self:PatchStoveEntity()
	self:PatchFireEntity("ix_bucket")
	self:PatchFireEntity("ix_bonfire")
	self:PatchLaundryPipeEntity()
end

function PLUGIN:CanOpenInteractiveComputer(client, entity, interactivePlugin)
	if (not IsValid(client) or not client:GetCharacter() or not interactivePlugin) then
		return false
	end

	entity = interactivePlugin.ResolveComputerEntity and interactivePlugin:ResolveComputerEntity(entity) or entity

	if (not IsValid(entity)) then
		return false
	end

	if (client:GetPos():DistToSqr(entity:GetPos()) > (160 * 160)) then
		return false
	end

	local isCombineTerminal = entity.IsCombineTerminal and entity:IsCombineTerminal()
	local isSecurityBypassed = entity.IsSecurityBypassed and entity:IsSecurityBypassed()

	if (isCombineTerminal
		and interactivePlugin.HasCombineTerminalAccess
		and not interactivePlugin:HasCombineTerminalAccess(client)
		and not isSecurityBypassed) then
		if (interactivePlugin.IsCivicComputer and interactivePlugin:IsCivicComputer(entity)) then
			if (not interactivePlugin.HasCivicTerminalAccess or not interactivePlugin:HasCivicTerminalAccess(client)) then
				return false
			end
		else
			return false
		end
	end

	local storageEntity = interactivePlugin.ResolveStorageEntity and interactivePlugin:ResolveStorageEntity(entity) or entity

	if (IsValid(storageEntity) and IsValid(storageEntity.ixActiveUser) and storageEntity.ixActiveUser != client) then
		return false
	end

	if (interactivePlugin.IsComputerAssemblyValid and not interactivePlugin:IsComputerAssemblyValid(entity)) then
		return false
	end

	return true, entity
end

function PLUGIN:PatchInteractiveComputers()
	local interactivePlugin = ix.plugin.list["interactive_computers"]

	if (not interactivePlugin or interactivePlugin.ixNovelizerOpenWrapped) then
		return
	end

	if (not isfunction(interactivePlugin.OpenComputer)) then
		return
	end

	interactivePlugin.ixNovelizerOpenWrapped = true

	local originalOpenComputer = interactivePlugin.OpenComputer

	interactivePlugin.OpenComputer = function(this, client, entity, ...)
		local result = originalOpenComputer(this, client, entity, ...)

		if (SERVER and IsValid(client) and IsValid(entity) and PLUGIN:CanAutoNarrate(client)) then
			local canOpen, resolvedEntity = PLUGIN:CanOpenInteractiveComputer(client, entity, this)

			if (canOpen and IsValid(resolvedEntity) and PLUGIN:IsInteractiveComputerEntity(resolvedEntity, true)
				and PLUGIN:CanNarrateEntityUse(client, resolvedEntity)) then
				local phrasePool = PLUGIN:ResolveEntityUsePhrasePool(resolvedEntity)

				if (istable(phrasePool) and #phrasePool > 0 and PLUGIN:PassUseCooldown(client, resolvedEntity)) then
					local phraseKey = table.Random(phrasePool)

					if (IsFilledString(phraseKey)) then
						PLUGIN:SendNovelMe(client, phraseKey, PLUGIN:GetEntityUseArguments(resolvedEntity, phraseKey), {
							actionKey = "use_" .. resolvedEntity:GetClass()
						})

						PLUGIN:EmitConditionalIt(resolvedEntity, "disk_read", {
							cooldown = 4
						})
					end
				end
			end
		end

		return result
	end
end

function PLUGIN:PatchStorageLibrary()
	local originalOpen = ix.storage.Open

	if (not originalOpen or self.ixNovelizerStorageWrapped) then
		return
	end

	self.ixNovelizerStorageWrapped = true

	ix.storage.Open = function(client, inventory, info, ...)
		if (SERVER and IsValid(client) and info and IsValid(info.entity)) then
			local entity = info.entity
			local className = entity:GetClass()

			if (className == "ix_container" and self:CanAutoNarrate(client)) then
				local originalStart = info.OnPlayerOpenStart

				info.OnPlayerOpenStart = function(ply)
					if (isfunction(originalStart)) then
						originalStart(ply)
					end

					if (IsValid(ply) and self:CanAutoNarrate(ply) and self:PassUseCooldown(ply, entity)) then
						local phrasePool = self:ResolveEntityUsePhrasePool(entity)

						if (phrasePool) then
							local phraseKey = table.Random(phrasePool)

							self:SendNovelMe(ply, phraseKey, self:GetEntityUseArguments(entity, phraseKey), {
								actionKey = "open_storage_" .. className
							})
						end
					end
				end
			end
		end

		return originalOpen(client, inventory, info, ...)
	end
end

function PLUGIN:CanNarrateEntityUse(client, entity)
	if (not IsValid(client) or not IsValid(entity)) then
		return false
	end

	local className = entity:GetClass()

	if (className == "ix_forcefield") then
		return entity.IsAuthorized and entity:IsAuthorized(client) == true
	end

	if (className == "ix_health_charger") then
		return client:Health() < client:GetMaxHealth()
	end

	if (className == "ix_suit_charger") then
		local maxArmor = entity.GetClientMaxArmor and entity:GetClientMaxArmor(client) or 0

		return client:Armor() < maxArmor
	end

	if (className == "ix_rationdispenser") then
		if ((entity.nextUseTime or 0) > CurTime() or entity.canUse == false or client:IsCombine()) then
			return false
		end

		if (not entity:GetEnabled()) then
			return false
		end

		local character = client:GetCharacter()
		local inventory = character and character.GetInventory and character:GetInventory() or nil
		local cid = inventory and inventory:HasItem("cid") or nil
		local token = inventory and inventory:HasItem("ration_token") or nil

		return token ~= false and token ~= nil or (cid and cid:GetData("nextRationTime", 0) < os.time())
	end

	if (className == "ix_doorbreach") then
		return (entity.nextUseTime or 0) <= CurTime() and entity:GetNWBool("beep", false) ~= true
	end

	if (className == "ix_combinelock" or className == "ix_unionlock") then
		if (client:KeyDown(IN_WALK)) then
			return false
		end

		return (entity.nextUseTime or 0) <= CurTime()
			and (not entity.IsLockDisabled or entity:IsLockDisabled() ~= true)
			and (not entity.detonatePreparing)
			and (not entity.HasAccess or entity:HasAccess(client) == true)
	end

	if (className == "ix_interactive_computer" or className:find("computer", 1, true) or className:find("terminal", 1, true)) then
		return self:IsInteractiveComputerEntity(entity, true)
	end

	return true
end

function PLUGIN:HasNarrationListenerNear(entity, range, listeners)
	if (not IsValid(entity)) then
		return false
	end

	local checkRange = tonumber(range) or GetNovelItRange()
	local maxDist = checkRange * checkRange
	local testPlayers = listeners or player.GetAll()

	for i = 1, #testPlayers do
		local client = testPlayers[i]
		if (self:CanAutoNarrate(client) and client:GetPos():DistToSqr(entity:GetPos()) <= maxDist) then
			return true
		end
	end

	return false
end

function PLUGIN:IsSeatLikeVehicle(vehicle)
	if (not IsValid(vehicle)) then
		return false
	end

	if (vehicle.playerdynseat) then
		return true
	end

	local className = string.lower(tostring(vehicle:GetClass() or ""))
	local model = string.lower(tostring(vehicle:GetModel() or ""))

	local parent = vehicle:GetParent()
	local parentClass = IsValid(parent) and string.lower(tostring(parent:GetClass() or "")) or ""

	if (className:find("^glide_", 1) or className:find("^sim_fphys_", 1)
		or parentClass:find("^glide_", 1) or parentClass:find("^sim_fphys_", 1)) then
		return false
	end

	return className:find("chair", 1, true) or className:find("seat", 1, true)
		or model:find("chair", 1, true) or model:find("seat", 1, true)
end

function PLUGIN:GetMusicRadioSignalState(entity)
	if (not IsValid(entity) or entity:GetClass() ~= "ix_music_radio") then
		return nil
	end

	if (entity:GetNetVar("power", false) ~= true or entity:GetNetVar("volume", 100) <= 0) then
		return nil
	end

	local musicPlugin = ix.plugin.list["music_radio"]

	if (not musicPlugin or not istable(musicPlugin.channels)) then
		return "radio_static"
	end

	local currentFreq = tonumber(entity:GetNetVar("channel", 88.0)) or 88.0
	local bestDist = math.huge

	for _, channel in ipairs(musicPlugin.channels) do
		local distance = math.abs((tonumber(channel.freq) or 0) - currentFreq)

		if (distance < bestDist) then
			bestDist = distance
		end
	end

	if (bestDist <= 0.05) then
		return "radio_music"
	end

	return "radio_offfreq"
end

local IDLE_DEFINITIONS = {
	{
		finder = function(plugin)
			return plugin:GetIdleComputerEntities()
		end,
		key = "machine_hum",
		cooldownKey = "computer_idle"
	},
	{
		classes = {"ix_forcefield"},
		key = "forcefield_buzz",
		cooldownKey = "forcefield_ambient",
		canEmit = function(entity)
			return entity.GetMode and entity:GetMode() ~= 1
		end
	},
	{
		classes = {"ix_stationary_radio", "ix_radiorepeater"},
		key = "radio_static",
		cooldownKey = "radio_idle"
	},
	{
		classes = {"ix_music_radio"},
		key = "radio_music",
		cooldownKey = "music_radio_idle",
		canEmit = function(entity, plugin)
			return plugin:GetMusicRadioSignalState(entity) ~= nil
		end,
		getKey = function(entity, plugin)
			return plugin:GetMusicRadioSignalState(entity)
		end,
		listenerRange = function(entity, plugin)
			return ix.config.Get("radioDist", 550)
		end
	},
	{
		classes = {"ix_stove"},
		key = "stove_gas_heat",
		cooldownKey = "stove_idle",
		canEmit = function(entity)
			return entity:GetNetVar("active", false) == true
		end
	},
	{
		classes = {"ix_bonfire", "ix_bucket"},
		key = "stove_heat",
		cooldownKey = "stove_idle",
		canEmit = function(entity)
			return entity:GetNetVar("active", false) == true
		end
	},
	{
		classes = {"ix_recycler"},
		key = "machine_hum",
		cooldownKey = "recycler_idle",
		canEmit = function(entity)
			return entity.GetIsActivated and entity:GetIsActivated() == true
		end
	},
	{
		classes = {"ix_washing_machine", "ix_washing_machine_small"},
		key = "washer",
		cooldownKey = "washer_idle",
		canEmit = function(entity)
			return entity.GetWashing and entity:GetWashing() == true
		end
	}
}

function PLUGIN:EmitIdleIt()
	local players = player.GetAll()
	local validListeners = {}
	
	-- Pre-filter players to reduce distance checks in the inner loops
	for i = 1, #players do
		local client = players[i]
		if (self:CanAutoNarrate(client)) then
			validListeners[#validListeners + 1] = client
		end
	end

	if (#validListeners == 0) then
		return
	end

	for i = 1, #IDLE_DEFINITIONS do
		local definition = IDLE_DEFINITIONS[i]
		local entityLists = {}

		if (isfunction(definition.finder)) then
			entityLists[1] = definition.finder(self)
		else
			for j = 1, #definition.classes do
				entityLists[#entityLists + 1] = ents.FindByClass(definition.classes[j])
			end
		end

		for j = 1, #entityLists do
			local entityList = entityLists[j]
			for k = 1, #entityList do
				local entity = entityList[k]
				
				if (IsValid(entity)) then
					local key = definition.getKey and definition.getKey(entity, self) or definition.key
					local listenerRange = definition.listenerRange and definition.listenerRange(entity, self) or nil
					
					-- IMPORTANT: Check cooldown and entity state BEFORE expensive distance checks.
					-- This reordering saves thousands of DistToSqr calls per cycle on populated servers.
					if (IsFilledString(key)
						and self:CanEmitIdleNow(entity)
						and (not isfunction(definition.canEmit) or definition.canEmit(entity, self))
						and self:HasNarrationListenerNear(entity, listenerRange, validListeners)) then
						
						self:EmitConditionalIt(entity, key, {
							chatType = "novelit_idle",
							cooldown = self:GetIdleItCooldown(),
							cooldownKey = definition.cooldownKey,
							range = math.min(GetNovelItRange() * 0.6, listenerRange or GetNovelItRange())
						})
					end
				end
			end
		end
	end
end

function PLUGIN:PerformAllPatches()
	-- Register ambient phrase pools
	self:RegisterItPhrases("disk_read", { "novelizerItDiskRead1", "novelizerItDiskRead2", "novelizerItDiskRead3" })
	self:RegisterItPhrases("machine_hum", { "novelizerItMachineHum1", "novelizerItMachineHum2", "novelizerItMachineHum3" })
	self:RegisterItPhrases("laundry_pipe", { "novelizerItLaundryPipe1", "novelizerItLaundryPipe2", "novelizerItLaundryPipe3" })
	self:RegisterItPhrases("washer", { "novelizerItWasher1", "novelizerItWasher2", "novelizerItWasher3" })
	self:RegisterItPhrases("vending_hum", { "novelizerItVending1", "novelizerItVending2", "novelizerItVending3" })
	self:RegisterItPhrases("forcefield_buzz", { "novelizerItForcefield1", "novelizerItForcefield2", "novelizerItForcefield3" })
	self:RegisterItPhrases("radio_static", { "novelizerItRadio1", "novelizerItRadio2", "novelizerItRadio3" })
	self:RegisterItPhrases("radio_music", { "novelizerItRadioMusic1", "novelizerItRadioMusic2", "novelizerItRadioMusic3" })
	self:RegisterItPhrases("radio_offfreq", { "novelizerItRadioOffFreq1", "novelizerItRadioOffFreq2", "novelizerItRadioOffFreq3" })
	self:RegisterItPhrases("door_locked", { "novelizerItDoorLocked1", "novelizerItDoorLocked2", "novelizerItDoorLocked3" })
	self:RegisterItPhrases("stove_gas_heat", { "novelizerItGasStove1", "novelizerItGasStove2", "novelizerItGasStove3" })
	self:RegisterItPhrases("stove_heat", { "novelizerItStove1", "novelizerItStove2", "novelizerItStove3" })
	self:RegisterItPhrases("workbench_rattle", { "novelizerItWorkbench1", "novelizerItWorkbench2", "novelizerItWorkbench3" })

	-- Run entity and action patches
	self:RegisterDefaultEntityPhrases()
	self:PatchItems()
	self:PatchWaterCommand()
	self:PatchCommandActions()
	self:PatchApplyCommand()
	self:PatchToggleRaiseCommand()
	self:PatchLootSearch()
	self:PatchCraftingActions()
	self:PatchLockEntity("ix_combinelock")
	self:PatchLockEntity("ix_unionlock")
	self:PatchRecyclerEntity()
	self:PatchChargers()
	self:EnsureCorePatches()
	self:PatchInteractiveComputers()
	self:PatchStaminaConsumption()
	self:PatchStorageLibrary()
end

function PLUGIN:InitializedPlugins()
	self:PerformAllPatches()
end

function PLUGIN:OnReloaded()
	self:PerformAllPatches()
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

			local range = (data and tonumber(data.range)) or GetNovelMeRange()
			if (not range or range <= 0) then
				range = ix.config.Get("chatRange", 280)
			end

			return listener:GetPos():DistToSqr(speaker:GetPos()) <= (range * range)
		end,
		OnChatAdd = function(self, speaker, text, anonymous, data)
			local color = self:GetColor(speaker, text, data)
			local name, nameColor = PLUGIN:GetCharacterDisplayName(speaker, anonymous, data)
			local success, phrase = pcall(function()
				return PLUGIN:TranslatePhrase(text, data)
			end)

			if (not success or not IsFilledString(phrase)) then
				return
			end
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
			local range = data and data.range or GetNovelItRange()

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
			if (not IsFilledString(text)) then
				return
			end

			local color = ix.config.Get("chatColor")
			local success, phrase = pcall(function()
				return PLUGIN:TranslatePhrase(text, data)
			end)

			if (not success or not IsFilledString(phrase)) then
				return
			end

			chat.AddText(color, "** " .. phrase)
		end,
		font = "ixChatFontItalics",
		indicator = "chatPerforming",
		deadCanChat = true
	})

	ix.chat.Register("novelit_idle", {
		CanHear = function(self, speaker, listener, data)
			local position = data and data.position
			local range = data and data.range or (GetNovelItRange() * 0.6)

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
			if (not IsFilledString(text)) then
				return
			end

			local color = ix.config.Get("chatColor")
			local success, phrase = pcall(function()
				return PLUGIN:TranslatePhrase(text, data)
			end)

			if (not success or not IsFilledString(phrase)) then
				return
			end

			chat.AddText(color, "** " .. phrase)
		end,
		font = "ixChatFontItalics",
		indicator = "chatPerforming",
		deadCanChat = true
	})
end

function PLUGIN:PlayerUse(client, entity)
	if (not self:CanAutoNarrate(client) or self:ShouldIgnoreEntityUse(entity)) then
		return
	end

	if (self:IsInteractiveComputerEntity(entity, true)) then
		return
	end

	local className = entity:GetClass()

	if (className == "ix_container") then
		return
	end

	if (not self:CanNarrateEntityUse(client, entity)) then
		return
	end

	local phrasePool = entity:IsDoor() and self:GetDoorPhrasePool(entity) or self:ResolveEntityUsePhrasePool(entity)

	if (not istable(phrasePool) or #phrasePool == 0 or not self:PassUseCooldown(client, entity)) then
		return
	end

	local phraseKey = table.Random(phrasePool)

	if (not IsFilledString(phraseKey)) then
		return
	end

	local actionKey = entity:IsDoor() and self:GetDoorActionKey(entity) or ("use_" .. className)

	-- if (entity:IsDoor() and actionKey == "door_locked") then
	-- 	local lockedPool = self:ResolveItPhrasePool(entity, "door_locked")
	-- 	local lockedPhraseKey = istable(lockedPool) and table.Random(lockedPool) or nil

	-- 	self:SendNovelIt(lockedPhraseKey, self:GetItArguments(entity, "door_locked", lockedPhraseKey), {
	-- 		position = entity:GetPos()
	-- 	})
	-- 	return
	-- end

	self:SendNovelMe(client, phraseKey, entity:IsDoor() and {
		self:GetEntitySubject(entity)
	} or self:GetEntityUseArguments(entity, phraseKey), {
		actionKey = actionKey
	})

	if (className == "ix_washing_machine" or className == "ix_washing_machine_small") then
		self:EmitConditionalIt(entity, "washer", {
			cooldown = 5
		})
	-- elseif (className == "ix_vendingmachine" or className == "ix_pepsimachine" or className == "ix_coffeemachine") then
	-- 	self:EmitConditionalIt(entity, "vending_hum", {
	-- 		cooldown = 5
	-- 	})
	elseif (className == "ix_stationary_radio" or className == "ix_radiorepeater") then
		self:EmitConditionalIt(entity, "radio_static", {
			cooldown = 4
		})
	elseif (className == "ix_music_radio") then
		local itKey = self:GetMusicRadioSignalState(entity)

		if (itKey and self:HasNarrationListenerNear(entity, ix.config.Get("radioDist", 550))) then
			self:EmitConditionalIt(entity, itKey, {
				cooldown = 4,
				range = math.min(GetNovelItRange(), ix.config.Get("radioDist", 550))
			})
		end
	elseif (className == "ix_rationdispenser") then
		self:EmitConditionalIt(entity, "machine_hum", {
			cooldown = 5
		})
	elseif (className == "ix_bonfire" or className == "ix_bucket") then
		self:EmitConditionalIt(entity, "stove_heat", {
			cooldown = 4
		})
	elseif (className == "ix_station" or className:find("ix_station_", 1, true)) then
		self:EmitConditionalIt(entity, "workbench_rattle", {
			cooldown = 4
		})
	end
end

if (CLIENT) then
	PLUGIN.active3DTexts = PLUGIN.active3DTexts or {}

	function PLUGIN:LoadFonts(font, genericFont)
		surface.CreateFont("ixNovelizer3DText", {
			font = genericFont,
			size = 38,
			weight = 700,
			extended = true
		})
	end

	function PLUGIN:GetNovelizer3DOrigin(entry)
		local localPlayer = LocalPlayer()

		if (IsValid(entry.anchor) and IsValid(localPlayer)) then
			local centerLocal = entry.anchor:OBBCenter()
			local centerWorld = entry.anchor:LocalToWorld(centerLocal)
			local toPlayer = localPlayer:EyePos() - centerWorld
			toPlayer.z = 0

			if (toPlayer:LengthSqr() <= 0.001) then
				toPlayer = localPlayer:GetForward()
				toPlayer.z = 0
			end

			toPlayer:Normalize()

			local directionLocal = entry.anchor:WorldToLocal(centerWorld + toPlayer) - centerLocal
			local length = directionLocal:Length()

			if (length > 0) then
				directionLocal:Mul(1 / length)
			end

			local mins = entry.anchor:OBBMins() - centerLocal
			local maxs = entry.anchor:OBBMaxs() - centerLocal
			local surfaceDistance = math.abs(directionLocal.x) * math.max(math.abs(mins.x), math.abs(maxs.x))
				+ math.abs(directionLocal.y) * math.max(math.abs(mins.y), math.abs(maxs.y))
				+ math.abs(directionLocal.z) * math.max(math.abs(mins.z), math.abs(maxs.z))
			local origin = centerWorld + toPlayer * (surfaceDistance + NOVELIZER_3D_SURFACE_PADDING)

			origin.z = centerWorld.z

			return origin
		end

		return entry.position
	end

	net.Receive(NOVELIZER_3D_NET, function()
		local kind = net.ReadString()
		local anchor = net.ReadEntity()
		local speaker = net.ReadEntity()
		local position = net.ReadVector()
		local phraseKey = net.ReadString()
		local arguments = net.ReadTable() or {}
		local duration = math.max(net.ReadFloat(), 0.1)
		local range = math.max(net.ReadFloat(), 1)
		local anonymous = net.ReadBool()
		local data = {
			arguments = arguments,
			anonymous = anonymous
		}
		local color = ix.config.Get("chatColor")
		local text = PLUGIN:GetNovelItDisplayText(phraseKey, data)

		if (not IsFilledString(text)) then
			return
		end

		table.insert(PLUGIN.active3DTexts, {
			kind = kind,
			anchor = IsValid(anchor) and anchor or nil,
			speaker = IsValid(speaker) and speaker or nil,
			position = position,
			range = range,
			text = text,
			color = color,
			startTime = CurTime(),
			dieTime = CurTime() + duration
		})
	end)

	function PLUGIN:PostDrawTranslucentRenderables(bDrawingDepth, bDrawingSkybox)
		if (bDrawingDepth or bDrawingSkybox or not self:ShouldUse3DText()) then
			return
		end

		local texts = self.active3DTexts or {}
		local curTime = CurTime()
		local eyePos = EyePos()
		local angle = EyeAngles()

		angle:RotateAroundAxis(angle:Up(), -90)
		angle:RotateAroundAxis(angle:Forward(), 90)

		for index = #texts, 1, -1 do
			local entry = texts[index]

			if (curTime >= entry.dieTime) then
				table.remove(texts, index)
				continue
			end

			local origin = self:GetNovelizer3DOrigin(entry)

			if (not origin or eyePos:DistToSqr(origin) > (entry.range * entry.range)) then
				continue
			end

			local distance = eyePos:Distance(origin)
			local alpha = math.Clamp((entry.dieTime - curTime) / math.min(entry.dieTime - entry.startTime, 1.25), 0, 1) * 255
			local scale = math.Clamp(distance * 0.0003, 0.07, 0.14)

			cam.Start3D2D(origin, angle, scale)
				draw.SimpleTextOutlined(
					entry.text,
					"ixNovelizer3DText",
					0,
					0,
					ColorAlpha(entry.color, alpha),
					TEXT_ALIGN_CENTER,
					TEXT_ALIGN_CENTER,
					1,
					ColorAlpha(color_black, alpha)
				)
			cam.End3D2D()
		end
	end
end

function PLUGIN:PlayerSwitchFlashlight(client, enabled)
	if (not IsValid(client)) then
		return
	end

	self.ixNovelizerFlashlightStates = self.ixNovelizerFlashlightStates or {}
	self.ixNovelizerFlashlightStates[client] = self.ixNovelizerFlashlightStates[client]
		or client:GetNetVar("flashlight", false)
end

function PLUGIN:Think()
	local currentTime = CurTime()

	if ((self.nextPatchEnsure or 0) <= currentTime) then
		self.nextPatchEnsure = currentTime + 5
		self:EnsureCorePatches()
	end

	if ((self.nextIdleItThink or 0) <= currentTime) then
		self.nextIdleItThink = currentTime + 3
		self:EmitIdleIt()
	end

	if ((self.nextStateThink or 0) <= currentTime) then
		self.nextStateThink = currentTime + 0.1 -- 10Hz is plenty for responsive ladder/flashlight detection

		local players = player.GetAll()
		local server = SERVER

		for i = 1, #players do
			local client = players[i]
			if (not IsValid(client) or not client:GetCharacter()) then continue end

			-- Flashlight state change detection
			if (server) then
				self.ixNovelizerFlashlightStates = self.ixNovelizerFlashlightStates or {}
				local enabled = client:GetNetVar("flashlight", false) == true
				local previous = self.ixNovelizerFlashlightStates[client]

				if (previous == nil) then
					self.ixNovelizerFlashlightStates[client] = enabled
				elseif (previous ~= enabled) then
					self.ixNovelizerFlashlightStates[client] = enabled

					if (client:Alive()) then
						self:HandleFlashlightStateChange(client, enabled)
					end
				end
			end

			if (server) then
				-- Ladder narration must be server-authoritative to avoid duplicate novelme sends.
				local onLadder = client:GetMoveType() == MOVETYPE_LADDER
				self.ixNovelizerLadderStates = self.ixNovelizerLadderStates or {}
				local state = self.ixNovelizerLadderStates[client]

				if (not state) then
					state = { active = false, startTime = 0, narrated = false, leaveTime = nil }
					self.ixNovelizerLadderStates[client] = state
				end

				if (onLadder) then
					state.leaveTime = nil

					if (not state.active) then
						state.active = true
						state.startTime = currentTime
						state.narrated = false
					elseif (not state.narrated
						and currentTime >= state.startTime + 0.25
						and self:CanAutoNarrate(client)
						and (client.ixNovelizerLastLadderTime or 0) + 2 <= currentTime
						and self:PassNamedCooldown(client, "ladder", 3)) then

						state.narrated = true
						client.ixNovelizerLastLadderTime = currentTime

						self:SendNovelMe(client, table.Random({
							"novelizerLadder1",
							"novelizerLadder2",
							"novelizerLadder3"
						}), nil, { actionKey = "ladder" })
					end
				elseif (state.active) then
					state.leaveTime = state.leaveTime or currentTime

					if (state.leaveTime + 0.4 <= currentTime) then
						state.active = false
						state.startTime = 0
						state.narrated = false
						state.leaveTime = nil
					end
				end
			end
		end
	end
end

function PLUGIN:OnItemEquipped(item, client)
	if (not item or item.isWeapon ~= true or not self:CanAutoNarrate(client)) then
		return
	end

	local lastNarration = item.ixNovelizerLastEquipmentNarration

	if (istable(lastNarration) and lastNarration.state == true and (lastNarration.time or 0) + 0.25 >= CurTime()) then
		return
	end

	if (self:SendNovelMe(client, table.Random(self:GetEquipPhrasePool(item, "Equip")), {
		self:GetItemSubject(item)
	}, {
		actionKey = "equip_" .. self:GetEquipCategory(item)
	})) then
		item.ixNovelizerLastEquipmentNarration = {
			state = true,
			time = CurTime()
		}
	end
end

function PLUGIN:OnItemUnequipped(item, client)
	if (not item or item.isWeapon ~= true or not self:CanAutoNarrate(client)) then
		return
	end

	local lastNarration = item.ixNovelizerLastEquipmentNarration

	if (istable(lastNarration) and lastNarration.state == false and (lastNarration.time or 0) + 0.25 >= CurTime()) then
		return
	end

	if (self:SendNovelMe(client, table.Random(self:GetEquipPhrasePool(item, "EquipUn")), {
		self:GetItemSubject(item)
	}, {
		actionKey = "unequip_" .. self:GetEquipCategory(item)
	})) then
		item.ixNovelizerLastEquipmentNarration = {
			state = false,
			time = CurTime()
		}
	end
end

function PLUGIN:CharacterVendorTraded(client, vendor, uniqueID, isSellingToVendor)
	if (not self:CanAutoNarrate(client) or not IsValid(vendor)) then
		return
	end

	self:SendNovelMe(client, table.Random({
		"novelizerVendorTrade1",
		"novelizerVendorTrade2",
		"novelizerVendorTrade3"
	}), {
		self:GetWithEntitySubject(vendor)
	}, {
		actionKey = isSellingToVendor and "vendor_sell" or "vendor_buy"
	})
end

function PLUGIN:PlayerEnteredVehicle(client, vehicle, role)
	if (not self:CanAutoNarrate(client) or not IsValid(vehicle)) then
		return
	end

	local seatedOnly = self:IsSeatLikeVehicle(vehicle)
	local phrasePool = seatedOnly and {
		"novelizerVehicleSeatEnter1",
		"novelizerVehicleSeatEnter2",
		"novelizerVehicleSeatEnter3"
	} or {
		"novelizerVehicleEnter1",
		"novelizerVehicleEnter2",
		"novelizerVehicleEnter3"
	}

	self:SendNovelMe(client, table.Random(phrasePool), seatedOnly and nil or {
		self:GetEntitySubjectWithParticle(vehicle, "location")
	}, {
		actionKey = "vehicle_enter"
	})
end

function PLUGIN:PlayerLeaveVehicle(client, vehicle)
	if (not self:CanAutoNarrate(client) or not IsValid(vehicle)) then
		return
	end

	local seatedOnly = self:IsSeatLikeVehicle(vehicle)
	local phrasePool = seatedOnly and {
		"novelizerVehicleSeatExit1",
		"novelizerVehicleSeatExit2",
		"novelizerVehicleSeatExit3"
	} or {
		"novelizerVehicleExit1",
		"novelizerVehicleExit2",
		"novelizerVehicleExit3"
	}

	self:SendNovelMe(client, table.Random(phrasePool), seatedOnly and nil or {
		self:GetEntitySubjectWithParticle(vehicle, "source")
	}, {
		actionKey = "vehicle_exit"
	})
end

function PLUGIN:PostEntityTakeDamage(target, dmgInfo, tookDamage)
	if (not tookDamage or not IsValid(target) or not target:IsPlayer() or not target:Alive()
		or dmgInfo:GetDamage() <= 0 or not self:CanAutoNarrate(target)) then
		return
	end

	local damageData = self:ClassifyDamageType(dmgInfo, target)

	if (not damageData) then
		return
	end

	self:SendNovelMe(target, damageData.hurt .. math.random(1, 3), nil, {
		actionKey = "hurt_" .. damageData.key,
		cooldown = 1.5,
		bypassGlobalCooldown = true
	})
end

function PLUGIN:DoPlayerDeath(client, attacker, dmgInfo)
	if (not IsValid(client) or not client:GetCharacter()) then
		return
	end

	local damageData = self:ClassifyDamageType(dmgInfo, client)

	if (not damageData) then
		return
	end

	self:SendNovelMe(client, damageData.death .. math.random(1, 3), nil, {
		actionKey = "death_" .. damageData.key,
		cooldown = 2,
		allowDead = true,
		bypassGlobalCooldown = true
	})
end

function PLUGIN:OnCharacterFallover(client, entity, bFallenOver)
	if (bFallenOver ~= true or not self:CanAutoNarrate(client)) then
		return
	end

	self:SendNovelMe(client, table.Random({
		"novelizerFallover1",
		"novelizerFallover2",
		"novelizerFallover3"
	}), nil, {
		actionKey = "fallover",
		cooldown = 2,
		bypassGlobalCooldown = true
	})
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
			}, {
				actionKey = weapon.ixItem and weapon.ixItem.isGrenade and weapon.ixItem.uniqueID == "molotov" and "molotov_prime" or "grenade_prime"
			})
			client.ixNovelizerGrenadePrimeData = {
				className = weapon:GetClass(),
				time = CurTime(),
				isMolotov = weapon.ixItem and weapon.ixItem.uniqueID == "molotov",
				subject = self:GetWeaponSubject(weapon)
			}
		return
	end

	-- Ensure we only narrate if the weapon actually needs reloading and we have ammo.
	if (key == IN_RELOAD and self:IsNarratableWeapon(weapon)) then
		local maxClip = weapon:GetMaxClip1()
		local clip = weapon:Clip1()
		local ammoCount = client:GetAmmoCount(weapon:GetPrimaryAmmoType())

		if (maxClip > 0 and clip >= 0 and clip < maxClip and ammoCount > 0 and self:PassNamedCooldown(client, "reload", 1.4)) then
			self:SendNovelMe(client, table.Random({
				"novelizerReload1",
				"novelizerReload2",
				"novelizerReload3"
			}), {
				self:GetWeaponSubject(weapon)
			}, {
				actionKey = "weapon_reload"
			})
		end
	end
end

function PLUGIN:KeyRelease(client, key)
	if (key ~= IN_ATTACK or not self:CanAutoNarrate(client)) then
		return
	end

	local weapon = client:GetActiveWeapon()
	local primeData = client.ixNovelizerGrenadePrimeData

	if (not istable(primeData) or (primeData.time or 0) + 8 < CurTime()) then
		return
	end

	if (IsValid(weapon) and primeData.className ~= weapon:GetClass()) then
		return
	end

	client.ixNovelizerGrenadePrimeData = nil

	if (not self:PassNamedCooldown(client, "grenade_throw", 0.75)) then
		return
	end

	local phrasePool = primeData.isMolotov and {
		"novelizerMolotovThrow1",
		"novelizerMolotovThrow2",
		"novelizerMolotovThrow3"
	} or {
		"novelizerGrenadeThrow1",
		"novelizerGrenadeThrow2",
		"novelizerGrenadeThrow3"
	}

	self:SendNovelMe(client, table.Random(phrasePool), {
		primeData.subject or self:GetWeaponSubject(weapon)
	}, {
		actionKey = primeData.isMolotov and "molotov_throw" or "grenade_throw"
	})
end

function PLUGIN:PlayerSwitchWeapon(client, oldWeapon, weapon)
	if (not self:CanAutoNarrate(client) or not self:IsSpecialSwitchWeapon(weapon)) then
		return
	end

	client.ixNovelizerLastSwitchTime = CurTime()

	if (not self:PassNamedCooldown(client, "weapon_switch", 0.75)) then
		return
	end

	local phraseKey = table.Random(self:GetSwitchPhrasePool(weapon))

	self:SendNovelMe(client, phraseKey, self:GetSwitchArguments(weapon, phraseKey), {
		actionKey = "weapon_switch"
	})
end
