local addonName, Data = ...
local DRList = LibStub("DRList-1.0")

Data.DrCategorys = {
	disorient = 'Disorient',
	incapacitate = 'Incapacitate',
	knockback = 'Knockback',
	root = 'Root',
	silence  = 'Silence',
	stun = 'Stun'
}

Data.Interruptdurations = {
    [6552] = 4,   -- [Warrior] Pummel
    [96231] = 4,  -- [Paladin] Rebuke
    [231665] = 3, -- [Paladin] Avengers Shield
    [147362] = 3, -- [Hunter] Countershot
    [187707] = 3, -- [Hunter] Muzzle
    [1766] = 5,   -- [Rogue] Kick
    [183752] = 3, -- [DH] Consume Magic
    [47528] = 3,  -- [DK] Mind Freeze
    [91802] = 2,  -- [DK] Shambling Rush
    [57994] = 3,  -- [Shaman] Wind Shear
    [115781] = 6, -- [Warlock] Optical Blast
    [19647] = 6,  -- [Warlock] Spell Lock
    [212619] = 6, -- [Warlock] Call Felhunter
    [132409] = 6, -- [Warlock] Spell Lock
    [171138] = 6, -- [Warlock] Shadow Lock
    [2139] = 6,   -- [Mage] Counterspell
    [116705] = 4, -- [Monk] Spear Hand Strike
    [106839] = 4, -- [Feral] Skull Bash
	[93985] = 4,  -- [Feral] Skull Bash
}

Data.RandomDrCategory = {} --key = number, value = categorieName, used for Testmode
Data.DrCategoryToSpell = {} --key = categorieName, value = table with key = number and value = spellID
Data.SpellPriorities = {}

local i = 1
for categorieName, localizedCategoryName in pairs(DRList:GetCategories()) do
	Data.RandomDrCategory[i] = categorieName
	Data.DrCategoryToSpell[categorieName] = {}
	i = i + 1
end

do
	local drCategoryToPriority = {
		stun = 8,
		disorient = 7,
		incapacitate = 6,
		silence = 5,
		root = 3,
		knockback = 2,
		taunt = 1
	}


	for spellID, categorieName in pairs(DRList.spells) do
		tinsert(Data.DrCategoryToSpell[categorieName], spellID)
		Data.SpellPriorities[spellID] = drCategoryToPriority[categorieName]
	end
end

Data.cCduration = {	-- this is basically data from DRList-1 with durations, used for Relentless check
	--[[ INCAPACITATES ]]--
	incapacitate = {
		-- Druid
		[    99] = 3, -- Incapacitating Roar (talent)
		[236025] = 6, -- Main (Honor talent)
		[236026] = 6, -- Main (Honor talent)
		-- Hunter
		[213691] = 4, -- Scatter Shot
		-- Mage
		[   118] = 8, -- Polymorph
		[ 28272] = 8, -- Polymorph (pig)
		[ 28271] = 8, -- Polymorph (turtle)
		[ 61305] = 8, -- Polymorph (black cat)
		[277792] = 8, -- Polymorph (Bumblebee)
		[277787] = 8, -- Polymorph (Direhorn)
		[ 61721] = 8, -- Polymorph (rabbit)
		[ 61780] = 8, -- Polymorph (turkey)
		[126819] = 8, -- Polymorph (procupine)
		[161353] = 8, -- Polymorph (bear cub)
		[161354] = 8, -- Polymorph (monkey)
		[321395] = 8, -- Polymorph (Mawrat)
		[161355] = 8, -- Polymorph (penguin)
		[161372] = 8, -- Polymorph (peacock)
		[126819] = 8, -- Polymorph (Porcupine)
		[ 82691] = 8, -- Ring of Frost
		-- Monk
		[115078] = 4, -- Paralysis
		-- Paladin
		[ 20066] = 8, -- Repentance
		-- Priest
		[ 64044] = 4, -- Psychic Horror (Horror effect)
		-- Rogue
		[  1776] = 4, -- Gouge
		[  6770] = 8, -- Sap
		-- Shaman
		[ 51514] = 8, -- Hex
		[211004] = 8, -- Hex (spider)
		[210873] = 8, -- Hex (raptor)
		[211015] = 8, -- Hex (cockroach)
		[211010] = 8, -- Hex (snake)
		-- Warlock
		[  6789] = 3, -- Mortal Coil
		-- Pandaren
		[107079] = 4 -- Quaking Palm
	},

	--[[ SILENCES ]]--
	silence = {
		-- Death Knight
		[ 47476] = 5, -- Strangulate
		-- Hunter
		[202933] = 4, -- Spider Sting (pvp talent)
		-- Mage
		-- Paladin
		[ 31935] = 3, -- Avenger's Shield
		-- Priest
		[ 15487] = 4, -- Silence
		-- Rogue
		[  1330] = 3, -- Garrote
		-- Blood Elf
		[ 25046] = 2, -- Arcane Torrent (Energy version)
		[ 28730] = 2, -- Arcane Torrent (Priest/Mage/Lock version)
		[ 50613] = 2, -- Arcane Torrent (Runic power version)
		[ 69179] = 2, -- Arcane Torrent (Rage version)
		[ 80483] = 2, -- Arcane Torrent (Focus version)
		[129597] = 2, -- Arcane Torrent (Monk version)
		[155145] = 2, -- Arcane Torrent (Paladin version)
		[202719] = 2  -- Arcane Torrent (DH version)
	},

	--[[ DISORIENTS ]]--
	disorient = {
		-- Druid
		[ 33786] = 6, -- Cyclone
		-- Mage
		[ 31661] = 3, -- Dragon's Breath
		-- Paladin
		[105421] = 6, -- Blinding Light -- FIXME: is this the right category? Its missing from blizzard's list
		-- Priest
		[  8122] = 6, -- Psychic Scream
		-- Rogue
		[  2094] = 8, -- Blind
		-- Warlock
		[  5782] = 6, -- Fear -- probably unused
		[118699] = 6, -- Fear -- new debuff ID since MoP
		-- Warrior
		[  5246] = 5 -- Intimidating Shout (main target)
	},

	--[[ STUNS ]]--
	stun = {
		-- Death Knight
		[108194] = 4, -- Asphyxiate (talent for unholy)
		[221562] = 5, -- Asphyxiate (baseline for blood)
		[207171] = 4, -- Winter is Coming (Remorseless winter stun)
		-- Demon Hunter
		[179057] = 2, -- Chaos Nova
		[200166] = 3, -- Metamorphosis
		[205630] = 3, -- Illidan's Grasp, primary effect
		[211881] = 4, -- Fel Eruption
		-- Druid
		[  5211] = 4, -- Mighty Bash
		[163505] = 4, -- Rake (Stun from Prowl)
		-- Monk
		[120086] = 4, -- Fists of Fury (with Heavy-Handed Strikes, pvp talent)
		[232055] = 3, -- Fists of Fury (new ID in 7.1)
		[119381] = 3, -- Leg Sweep
		-- Paladin
		[   853] = 6, -- Hammer of Justice
		-- Priest
		[200200] = 4, -- Holy word: Chastise
		[226943] = 6, -- Mind Bomb
		-- Rogue
		[  1833] = 4, -- Cheap Shot
	--	[   408] = true, -- Kidney Shot, variable duration
	  --[199804] = true, -- Between the Eyes, variable duration
		-- Shaman
		[118345] = 4, -- Pulverize (Primal Earth Elemental)
		[118905] = 5, -- Static Charge (Capacitor Totem)
		[204399] = 2, -- Earthfury (pvp talent)
		-- Warlock
		[ 89766] = 4, -- Axe Toss (Felguard)
		[ 30283] = 3, -- Shadowfury
		-- Warrior
		[132168] = 2, -- Shockwave
		[132169] = 4, -- Storm Bolt
		-- Tauren
		[ 20549] = 2 -- War Stomp
	},

	--[[ ROOTS ]]--
	root = {
		-- Death Knight
		[ 96294] = 4, -- Chains of Ice (Chilblains Root)
		[204085] = 4, -- Deathchill (pvp talent)
		-- Druid
		[   339] = 8, -- Entangling Roots
		[102359] = 8, -- Mass Entanglement (talent)
		[ 45334] = 4, -- Immobilized (wild charge, bear form)
		-- Hunter
		[200108] = 3, -- Ranger's Net
		[212638] = 6, -- tracker's net
		[201158] = 4, -- Super Sticky Tar (Expert Trapper, Hunter talent, Tar Trap effect)
		-- Mage
		[   122] = 8, -- Frost Nova
		[ 33395] = 8, -- Freeze (Water Elemental)
		[228600] = 4, -- Glacial spike (talent)
		-- Shaman
		[ 64695] = 8 -- Earthgrab Totem
	}
}

Data.cCdurationBySpellID = {}
for category, spellIDs in pairs(Data.cCduration) do
	for spellID, duration in pairs(spellIDs) do
		Data.cCdurationBySpellID[spellID] = duration
	end
end

Data.TriggerSpellIDToTrinketnumber = {--key = which first row honor talent, value = fileID(used for SetTexture())
	[195710] = 1, 	-- 1: Honorable Medallion, 3. min. CD, detected by Combatlog
	[42292]  = 2,   -- 2: Medallion of the Alliance, Medallion of the Horde used in Classic, TBC, and probably some other Expansions  2 min. CD, detected by Combatlog
	[208683] = 2, 	-- 2: Gladiator's Medallion, 2 min. CD, detected by Combatlog
	[336126] = 2,   -- 2: Gladiator's Medallion, 2 min. CD, Shadowlands Update
	[195901] = 3, 	-- 3: Adaptation, 1 min. CD, detected by Aura 195901
	[214027] = 3, 	-- 3: Adaptation, 1 min. CD, detected by Aura 195901, for the Arena_cooldownupdate
	[336135] = 3, 	-- 3: Adaptation, 1 min. CD, Shadowlands Update
	[336139] = 3,   -- 3: Adapted, 1 min. CD, Shadowlands Update
	[196029] = 4, 	-- 4: Relentless, passive, no CD
	[336128] = 4 	-- 4: Relentless, passive, no CD, Shadowlands Update
}

local TrinketTriggerSpellIDtoDisplayfileID = {
	[42292]  = select(10, GetItemInfo(37865)),   	--PvP Trinket should show as Medaillon; used in TBC etc
	[195901] = GetSpellTexture(214027),				--Adapted, should display as Adaptation
	[336139] = GetSpellTexture(214027) 				--Adapted, should display as Adaptation, Shadowlands
}

Data.CovenantIcons = {
	[1] = GetSpellTexture(324739), --Kyrian
	[2] = GetSpellTexture(300728), --Ventyr
	[3] = GetSpellTexture(310143), --Night Fae
	[4] = GetSpellTexture(324631), --Necrolord
}

--C_Covenants.GetCovenantData()
Data.CovenantSpells = {
	--Kyrian
	[324739] = 1,--Summon Steward 				All Classes

	[312202] = 1,--Shackle the Unworthy 		Death Knight
	[306830] = 1,--Elysian Decree 				Demon Hunter
	[326434] = 1,--Kindred Spirits 				Druid
	[308491] = 1,--Resonating Arrow 			Hunter
	[307443] = 1,--Radiant Spark 				Mage
	[310454] = 1,--Weapons of Order 			Monk
	[304971] = 1,--Divine Toll 					Paladin
	[325013] = 1,--Boon of the Ascended 		Priest
	[323547] = 1,--Echoing Reprimand 			Rogue
	[324386] = 1,--Vesper Totem 				Shaman
	[312321] = 1,--Scouring Tithe 				Warrior
	[307865] = 1,--Spear of Bastion 			Warlock


	--Ventyr
	[300728] = 2, --Door of Shadows 			All Classes

	[311648] = 2,--Swarming Mist 				Death Knight
	[317009] = 2,--Sinful Brand  				Demon Hunter
	[323546] = 2,--Ravenous Frenzy				Druid
	[324149] = 2,--Flayed Shot 					Hunter
	[314793] = 2,--Mirrors of Torment 			Mage
	[326860] = 2,--Fallen Order 				Monk
	[316958] = 2,--Ashen Hallow 				Paladin
	[323673] = 2,--Mindgames 					Priest
	[323654] = 2,--Flagellation 				Rogue
	[320674] = 2,--Chain Harvest 				Shaman
	[321792] = 2,--Impending Catastrophe  		Warrior
	[317349] = 2,--Condemn 						Warlock


	--Night Fae
	[310143] = 3, --Soulshape 					All Classes

	[324128] = 3,--Death's Due 					Death Knight
	[323639] = 3,--The Hunt (ability)  			Demon Hunter
	[323764] = 3,--Convoke the Spirits 			Druid
	[328231] = 3,--Wild Spirits 				Hunter
	[314791] = 3,--Shifting Power 				Mage
	[327104] = 3,--Faeline Stomp				Monk
	[328278] = 3,--Blessing of the Seasons 		Paladin
	[327661] = 3,--Fae Guardians 				Priest
	[328305] = 3,--Sepsis 						Rogue
	[328923] = 3,--Fae Transfusion				Shaman
	[325640] = 3,--Soul Rot						Warrior
	[325886] = 3,--Ancient Aftershock 			Warlock


	--Necrolord
	[324631] = 4, --Fleshcraft					All Classes

	[315443] = 4,--Abomination Limb				Death Knight
	[329554] = 4,--Fodder to the Flame  		Demon Hunter
	[325727] = 4,--Adaptive Swarm 				Druid
	[325028] = 4,--Death Chakram 				Hunter
	[324220] = 4,--Deathborne 					Mage
	[325216] = 4,--Bonedust Brew 				Monk
	[328204] = 4,--Vanquisher's Hammer 			Paladin
	[324724] = 4,--Unholy Nova 					Priest
	[328547] = 4,--Serrated Bone Spike 			Rogue
	[326059] = 4,--Primordial Wave 				Shaman
	[325289] = 4,--Decimating Bolt  			Warrior
	[324143] = 4,--Conqueror's Banner 			Warlock
}

Data.RacialSpellIDtoCooldown = {
    [7744] = 120,	--Will of the Forsaken, Undead Racial, 30 sec cooldown trigger on trinket
   [20594] = 120,	--Stoneform, Dwarf Racial
   [58984] = 120,	--Shadowmeld, Night Elf Racial
   [59752] = 180,  --Every Man for Himself, Human Racial, 90 sec cooldown trigger on trinket
   [28730] = 90,	--Arcane Torrent, Blood Elf Racial, Mage and Warlock,
   [50613] = 90,	--Arcane Torrent, Blood Elf Racial, Death Knight,
   [202719] = 90,	--Arcane Torrent, Blood Elf Racial, Demon Hunter,
   [80483] = 90,	--Arcane Torrent, Blood Elf Racial, Hunter,
   [129597] = 90,	--Arcane Torrent, Blood Elf Racial, Monk,
   [155145] = 90,	--Arcane Torrent, Blood Elf Racial, Paladin,
   [232633] = 90,	--Arcane Torrent, Blood Elf Racial, Priest,
   [25046] = 90,	--Arcane Torrent, Blood Elf Racial, Rogue,
   [69179] = 90,	--Arcane Torrent, Blood Elf Racial, Warrior,
   [20589] = 90, 	--Escape Artist, Gnome Racial
   [26297] = 180,	--Berserkering, Troll Racial
   [33702] = 120,	--Blood Fury, Orc Racial, Mage,  Warlock
   [20572]	= 120,	--Blood Fury, Orc Racial, Warrior, Hunter, Rogue, Death Knight
   [33697] = 120,	--Blood Fury, Orc Racial, Shaman, Monk
   [20577] = 120, 	--Cannibalize, Undead Racial
   [68992]	= 120,	--Darkflight, Worgen Racial
   [59545] = 180,	--Gift of the Naaru, Draenei Racial, Death Knight
   [59543] = 180,	--Gift of the Naaru, Draenei Racial, Hunter
   [59548] = 180,	--Gift of the Naaru, Draenei Racial, Mage
   [121093]	= 180,	--Gift of the Naaru, Draenei Racial, Monk
   [59542] = 180,	--Gift of the Naaru, Draenei Racial, Paladin
   [59544] = 180,	--Gift of the Naaru, Draenei Racial, Priest
   [59547] = 180,	--Gift of the Naaru, Draenei Racial, Shaman
   [28880] = 180,	--Gift of the Naaru, Draenei Racial, Warrior
   [107079] = 120,	--Quaking Palm, Pandaren Racial
   [69041] = 90,	--Rocket Barrage, Goblin Racial
   [69070] = 90,	--Rocket Jump, Goblin Racial
   [20549] = 90	--War Stomp, Tauren Racial
}

Data.TriggerSpellIDToDisplayFileId = {}
for triggerSpellID in pairs(Data.TriggerSpellIDToTrinketnumber) do
	if TrinketTriggerSpellIDtoDisplayfileID[triggerSpellID] then
		Data.TriggerSpellIDToDisplayFileId[triggerSpellID] = TrinketTriggerSpellIDtoDisplayfileID[triggerSpellID]
	else
		Data.TriggerSpellIDToDisplayFileId[triggerSpellID] = GetSpellTexture(triggerSpellID)
	end
end

Data.RacialNameToSpellIDs = {}
Data.Racialnames = {}
for spellID in pairs(Data.RacialSpellIDtoCooldown) do
	Data.TriggerSpellIDToDisplayFileId[spellID] = GetSpellTexture(spellID)
	local racialName = GetSpellInfo(spellID)
	if racialName then
		if not Data.RacialNameToSpellIDs[racialName] then
			Data.RacialNameToSpellIDs[racialName] = {}
			Data.Racialnames[GetSpellInfo(spellID)] = GetSpellInfo(spellID)
		end
		Data.RacialNameToSpellIDs[racialName][spellID] = true
	end

end

Data.TrinketTriggerSpellIDtoCooldown = {
	[195710] = 180,	-- Honorable Medallion, 3 min. CD
	[208683] = 120,	-- Gladiator's Medallion, 2 min. CD
	[336126] = 120, -- Gladiator's Medallion, 2 min. CD, Shadowlands Update
	[195901] = 60, 	-- Adaptation PvP Talent
	[336135] = 60   -- Adapation, Shadowlands Update
}

Data.RacialSpellIDtoCooldownTrigger = {
	 [7744] = 30, 	--Will of the Forsaken, Undead Racial, 30 sec cooldown trigger on trinket
	[59752] = 90  	--Every Man for Himself, Human Racial, 30 sec cooldown trigger on trinket
}