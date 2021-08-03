local _, NS = ...
local Timers = NS.Timers
local Icons = NS.Icons
local Info = NS.Info
local IsInBrawl = _G.C_PvP.IsInBrawl

local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local ElvUIPvP = E:NewModule('PvP', 'AceHook-3.0', 'AceEvent-3.0', 'AceTimer-3.0'); --Create a plugin within ElvUI and adopt AceHook-3.0, AceEvent-3.0 and AceTimer-3.0. We can make use of these later.
local EP = LibStub("LibElvUIPlugin-1.0") --We can use this to automatically insert our GUI tables when ElvUI_Config is loaded.
local DRList = LibStub("DRList-1.0")
local addonName, addonTable = ... --See http://www.wowinterface.com/forums/showthread.php?t=51502&p=304704&postcount=2

local Diminish = CreateFrame("Frame")
Diminish:RegisterEvent("PLAYER_LOGIN")
Diminish:SetScript("OnEvent", function(self, event, ...)
    return self[event](self, ...)
end)

NS.Diminish = Diminish

local unitEvents = {
    target = "PLAYER_TARGET_CHANGED",
    party = "GROUP_ROSTER_UPDATE, GROUP_JOINED",  -- csv
    player = "COMBAT_LOG_EVENT_UNFILTERED",
    nameplate = "NAME_PLATE_UNIT_ADDED, NAME_PLATE_UNIT_REMOVED",
    arena = not NS.IS_CLASSIC and "ARENA_OPPONENT_UPDATE" or nil,
    focus = not NS.IS_CLASSIC and "PLAYER_FOCUS_CHANGED" or nil,
}

function Diminish:ToggleUnitEvent(events, enable)
    for event in gmatch(events or "", "([^,%s]+)") do -- csv loop
        if enable then
            if not self:IsEventRegistered(event) then
                self:RegisterEvent(event)
                --[==[@debug@
                NS.Debug("Registered %s for instance %s.", event, self.currInstanceType)
                --@end-debug@]==]
            end
        else
            if self:IsEventRegistered(event) then
                self:UnregisterEvent(event)
                --[==[@debug@
                NS.Debug("Unregistered %s for instance %s.", event, self.currInstanceType)
                --@end-debug@]==]
            end
        end
    end
end

function Diminish:ToggleForZone(dontRunEnable)
    self.currInstanceType = select(2, IsInInstance())
    local registeredOnce = false

    --@retail@
    if self.currInstanceType == "arena" then
        -- HACK: check if inside arena brawl, C_PvP.IsInBrawl() doesn't
        -- always work on PLAYER_ENTERING_WORLD so delay it with this event.
        -- Once event is fired it'll call ToggleForZone again
        self:RegisterEvent("PVP_BRAWL_INFO_UPDATED")
    else
        self:UnregisterEvent("PVP_BRAWL_INFO_UPDATED")
    end

    -- PVP_BRAWL_INFO_UPDATED triggered ToggleForZone
    if self.currInstanceType == "arena" and IsInBrawl() then
        self.currInstanceType = "pvp" -- treat arena brawl as a battleground
        self:UnregisterEvent("PVP_BRAWL_INFO_UPDATED")
    end
    --@end-retail@

    -- (Un)register unit events for current zone depending on user settings
    for unit, settings in pairs(E.db.ElvUIPvP.DrTracker.unitFrames) do -- DR tracking for focus/target etc each have their own seperate settings
        local events = unitEvents[unit]
        if settings.enabled then
            -- Loop through every zone/instance enabled and see if we're currently in that instance
            for zone, state in pairs(settings.zones) do
                if state and zone == self.currInstanceType then
                    registeredOnce = true
                    settings.isEnabledForZone = true
                    self:ToggleUnitEvent(events, true)
                    break
                else
                    settings.isEnabledForZone = false
                    self:ToggleUnitEvent(events, false)
                end
            end
        else -- unitframe is not enabled for tracking at all
            settings.isEnabledForZone = false
            self:ToggleUnitEvent(events, false)
        end
    end

    if dontRunEnable then
        -- PVP_BRAWL_INFO_UPDATED triggered ToggleForZone again,
        -- so dont run Enable() twice, just update vars
        return self:SetCLEUWatchVariables()
    end
	-- print('registeredOnce = '..tostring(registeredOnce))
    if registeredOnce then -- atleast 1 event has been registered for zone
        self:Enable()
    else
        self:Disable()
    end
end

function Diminish:SetCLEUWatchVariables()
    local cfg = E.db.ElvUIPvP.DrTracker.unitFrames

    local targetOrFocusWatchFriendly = false
    if cfg.target.watchFriendly and cfg.target.isEnabledForZone then
        targetOrFocusWatchFriendly = true
    elseif cfg.focus.watchFriendly and cfg.focus.isEnabledForZone then
        targetOrFocusWatchFriendly = true
    elseif cfg.nameplate.watchFriendly and cfg.nameplate.isEnabledForZone then
        targetOrFocusWatchFriendly = true
    end

    -- PvE mode
    self.isWatchingNPCs = E.db.ElvUIPvP.DrTracker.trackNPCs
    if not cfg.target.isEnabledForZone and not cfg.focus.isEnabledForZone and not cfg.nameplate.isEnabledForZone then
        -- PvE mode only works for target/focus/nameplate so disable mode if those frames are not active
        self.isWatchingNPCs = false
    end

    -- Check if we're tracking any friendly units and not just enemy only
    self.isWatchingFriendly = false
    if cfg.player.isEnabledForZone or cfg.party.isEnabledForZone or targetOrFocusWatchFriendly then
        self.isWatchingFriendly = true
    end

    -- Check if only PlayerFrame tracking is enabled for friendly, if it is
    -- we want to ignore all friendly units later in CLEU except where destGUID == playerGUID
    self.onlyPlayerWatchFriendly = cfg.player.isEnabledForZone
    if cfg.player.isEnabledForZone then
        if cfg.party.isEnabledForZone or targetOrFocusWatchFriendly then
            self.onlyPlayerWatchFriendly = false
        end
    end

    -- Check if we're only tracking friendly units so we can ignore enemy units in CLEU
    self.onlyFriendlyTracking = true
    if cfg.target.isEnabledForZone or cfg.focus.isEnabledForZone or cfg.arena.isEnabledForZone or cfg.nameplate.isEnabledForZone then
        self.onlyFriendlyTracking = false
    end

    -- Check if we're only tracking friendly party members so we can ignore outsiders
    self.onlyTrackingPartyForFriendly = cfg.party.isEnabledForZone
    if targetOrFocusWatchFriendly then
        self.onlyTrackingPartyForFriendly = false
    end
end

function Diminish:Disable()
    self:UnregisterAllEvents()
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("CVAR_UPDATE")
    Timers:ResetAll(true)
    --[==[@debug@
    Info("Disabled addon for zone %s.", self.currInstanceType)
    --@end-debug@]==]
end

function Diminish:Enable()
    -- Timers:ResetAll(true)

    self:SetCLEUWatchVariables()
    self:GROUP_ROSTER_UPDATE()
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    --[==[@debug@
    Info("Enabled addon for zone %s.", self.currInstanceType)
    --@end-debug@]==]
end

function Diminish:InitDB()
    if NS.IS_CLASSIC_OR_TBC and E.db.ElvUIPvP.DrTracker.unitFrames.player.usePersonalNameplate then
        E.db.ElvUIPvP.DrTracker.unitFrames.player.usePersonalNameplate = false
    end
    self.InitDB = nil
end

--------------------------------------------------------------
-- Events
--------------------------------------------------------------

local strfind = _G.string.find
local UnitIsUnit = _G.UnitIsUnit

function Diminish:PLAYER_LOGIN()
    self:InitDB()

    local Masque = LibStub and LibStub("Masque", true)
    NS.MasqueGroup = Masque and Masque:Group("Diminish")
    NS.useCompactPartyFrames = GetCVarBool("useCompactPartyFrames")
    self.PLAYER_GUID = UnitGUID("player")
    self.PLAYER_CLASS = select(2, UnitClass("player"))

    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("CVAR_UPDATE")
    self:UnregisterEvent("PLAYER_LOGIN")
    self.PLAYER_LOGIN = nil
end

function Diminish:CVAR_UPDATE(name, value)
    if name == "USE_RAID_STYLE_PARTY_FRAMES" then
        NS.useCompactPartyFrames = value ~= "0"
        Icons:AnchorPartyFrames()
    end
end

--@retail@
function Diminish:PVP_BRAWL_INFO_UPDATED()
    if not IsInBrawl() then
        self:UnregisterEvent("PVP_BRAWL_INFO_UPDATED")
    else
        self:ToggleForZone(true)
    end
end
--@end-retail@

function Diminish:PLAYER_ENTERING_WORLD()
    self:ToggleForZone()
end

function Diminish:PLAYER_TARGET_CHANGED()
    Timers:Refresh("target")
end

function Diminish:PLAYER_FOCUS_CHANGED()
    Timers:Refresh("focus")
end

function Diminish:NAME_PLATE_UNIT_ADDED(namePlateUnitToken)
    if UnitIsUnit("player", namePlateUnitToken) then
        if not E.db.ElvUIPvP.DrTracker.unitFrames.player.usePersonalNameplate then return end
    end
    Timers:Refresh(namePlateUnitToken)
    if E.db.ElvUIPvP.IsTesting then
        Timers:Refresh("nameplate")
    end
end

function Diminish:NAME_PLATE_UNIT_REMOVED(namePlateUnitToken)
    Icons:ReleaseNameplate(namePlateUnitToken)
end

function Diminish:ARENA_OPPONENT_UPDATE(unitID, status)
    if status == "seen" and not strfind(unitID, "pet") then
        if IsInBrawl() and not E.db.ElvUIPvP.DrTracker.unitFrames.arena.zones.pvp then return end
        Timers:Refresh(unitID)
    end
end

function Diminish:GROUP_ROSTER_UPDATE()
    local members = min(GetNumGroupMembers(), 4)
    Icons:AnchorPartyFrames(members)

    -- Refresh every single party member, even if they have already just been refreshed
    -- incase unit IDs have been shifted
    for i = 1, 5 do
        if UnitExists("party"..i) then
            Timers:Refresh("party"..i)
        else
            Timers:RemoveActiveGUID("party"..i)
        end
    end
end

Diminish.GROUP_JOINED = Diminish.GROUP_ROSTER_UPDATE

-- Combat log scanning for DRs
do
    local COMBATLOG_PARTY_MEMBER = bit.bor(COMBATLOG_OBJECT_AFFILIATION_MINE, COMBATLOG_OBJECT_AFFILIATION_PARTY)
    local COMBATLOG_OBJECT_REACTION_FRIENDLY = _G.COMBATLOG_OBJECT_REACTION_FRIENDLY
    local COMBATLOG_OBJECT_TYPE_PLAYER = _G.COMBATLOG_OBJECT_TYPE_PLAYER
    local COMBATLOG_OBJECT_CONTROL_PLAYER = _G.COMBATLOG_OBJECT_CONTROL_PLAYER
    local CombatLogGetCurrentEventInfo = _G.CombatLogGetCurrentEventInfo
    local bit_band = _G.bit.band

    local IS_CLASSIC_OR_TBC = NS.IS_CLASSIC_OR_TBC
    local CATEGORY_STUN = NS.CATEGORIES.stun
    local CATEGORY_TAUNT = NS.CATEGORIES.taunt
    local CATEGORY_ROOT = NS.CATEGORIES.root
    local CATEGORY_INCAP = NS.CATEGORIES.incapacitate
    local CATEGORY_DISORIENT = NS.CATEGORIES.disorient
    local CATEGORY_KIDNEY = NS.CATEGORIES.kidney_shot
    local DRList = LibStub("DRList-1.0")

    function Diminish:COMBAT_LOG_EVENT_UNFILTERED()
        local _, eventType, _, srcGUID, _, srcFlags, _, destGUID, _, destFlags, _, spellID, spellName, _, auraType = CombatLogGetCurrentEventInfo()
        if not destGUID then return end -- sanity check

        if auraType == "DEBUFF" then
            if eventType ~= "SPELL_AURA_REMOVED" and eventType ~= "SPELL_AURA_APPLIED" and eventType ~= "SPELL_AURA_REFRESH" then return end
            if spellID == 0 then -- for classic
                spellID = spellName
            end

            local category, drSpellID = DRList:GetCategoryBySpellID(spellID)
            if not category or category == "knockback" then return end
            category = DRList:GetCategoryLocalization(category)
            if drSpellID then
                spellID = drSpellID
            end

            local isMindControlled = false
            local isNotPetOrPlayer = false
            local isPlayer = bit_band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0
            if not isPlayer then
                if strfind(destGUID, "Player-") then
                    -- Players have same bitmask as player pets when they're mindcontrolled and MC aura breaks, so we need to distinguish these
                    -- so we can ignore the player pets but not actual players
                    isMindControlled = true
                end
                if not self.isWatchingNPCs and not isMindControlled then return end

                if bit_band(destFlags, COMBATLOG_OBJECT_CONTROL_PLAYER) <= 0 then -- is not player pet or is not MCed
                    if IS_CLASSIC_OR_TBC then
                        if category ~= CATEGORY_STUN and category ~= CATEGORY_KIDNEY then return end
                    else
                        if category ~= CATEGORY_STUN and category ~= CATEGORY_TAUNT and category ~= CATEGORY_ROOT and category ~= CATEGORY_INCAP and category ~= CATEGORY_DISORIENT then
                            -- only show taunt and stun for normal mobs (roots/incaps/disorient for special mobs), player pets will show all
                            return
                        end
                    end
                    isNotPetOrPlayer = true
                end
            else
                -- Ignore taunts for players
                if category == CATEGORY_TAUNT then return end
                if IS_CLASSIC_OR_TBC then
                    local isSrcPlayer = bit_band(srcFlags, COMBATLOG_OBJECT_CONTROL_PLAYER) > 0
                    if not isSrcPlayer then return end
                end
            end

            local isFriendly = bit_band(destFlags, COMBATLOG_OBJECT_REACTION_FRIENDLY) ~= 0
            if isMindControlled then
                isFriendly = not isFriendly -- reverse values
            end

            if not isFriendly and self.onlyFriendlyTracking then return end

            if isFriendly then
                if not self.isWatchingFriendly then return end

                if self.onlyPlayerWatchFriendly then
                    -- Only store friendly timers for player
                    if destGUID ~= self.PLAYER_GUID  then return end
                end

                if self.onlyTrackingPartyForFriendly then
                    -- Only store friendly timers for party1-4 and player
                    if bit_band(destFlags, COMBATLOG_PARTY_MEMBER) == 0 then return end
                end
            end

            if eventType == "SPELL_AURA_REMOVED" then
                Timers:Insert(destGUID, srcGUID, category, spellID, isFriendly, isNotPetOrPlayer, false)
            elseif eventType == "SPELL_AURA_APPLIED" then
                Timers:Insert(destGUID, srcGUID, category, spellID, isFriendly, isNotPetOrPlayer, true)
            elseif eventType == "SPELL_AURA_REFRESH" then
                Timers:Update(destGUID, srcGUID, category, spellID, isFriendly, isNotPetOrPlayer, true)
            end
        end

        -------------------------------------------------------------------------------------------------------

        if eventType == "UNIT_DIED" or eventType == "PARTY_KILL" then
            if self.currInstanceType == "arena" and not IsInBrawl() then return end

            -- Delete all timers when player died
            if destGUID == self.PLAYER_GUID then
                if self.PLAYER_CLASS == "HUNTER" then
                    -- Don't delete if player is Feign Deathing
                    if NS.GetAuraDuration("player", 5384) then return end
                end

                return Timers:ResetAll()
            end

            -- Delete all timers for unit that died
            Timers:Remove(destGUID, false)
        end
    end
end

local defaultsDisabledCategories = {}

if NS.IS_CLASSIC then
	defaultsDisabledCategories[NS.CATEGORIES.frost_shock] = true
end

if not NS.IS_CLASSIC and NS.IS_CLASSIC_OR_TBC then -- is tbc
	defaultsDisabledCategories[NS.CATEGORIES.random_root] = true
	defaultsDisabledCategories[NS.CATEGORIES.death_coil] = true
	defaultsDisabledCategories[NS.CATEGORIES.freezing_trap] = true
	defaultsDisabledCategories[NS.CATEGORIES.scatter_shot] = true
end

--@retail@
defaultsDisabledCategories[NS.CATEGORIES.taunt] = true
--@end-retail@

--Default options
P["ElvUIPvP"] = {
	["Enabled"] = true,
	["IsTesting"] = false,
	["DrTracker"] = {
		["timerTextOutline"] = "OUTLINE",
        ["timerText"] = true,
        ["timerSwipe"] = true,
        ["timerColors"] = true,
        ["timerStartAuraEnd"] = false,
        ["showCategoryText"] = true,
        ["colorBlind"] = true,
		["colorBlindFontSize"] = 10,
        ["trackNPCs"] = false,
        ["categoryTextures"] = "DEFAULT",
        ["categoryFontSize"] = 12,
        ["border"] = {
			["edgeSize"] = 1.5,
            ["edgeFile"] = "Interface\\BUTTONS\\WHITE8X8",
            ["layer"] = "BORDER",
            ["name"] = "BRIGHT",
		},
		["categoryFont"] = {
			["font"] = nil, -- uses font from template instead
            ["size"] = tonumber(GetCVar("UIScale")) <= 0.75 and 11 or 9,
            ["x"] = 0,
            --y = 12,
            ["flags"] = nil
		},
		["unitFrames"] = {
			["target"] = {
				["enabled"] = true,
				["zones"] = {
					["pvp"] = true,
					["arena"] = true,
					["none"] = true,
					["party"] = false,
					["raid"] = false,
					["scenario"] = true
				},
				["disabledCategories"] = defaultsDisabledCategories,
				["anchorUIParent"] = false,
				["watchFriendly"] = true,
				["iconSize"] = 40,
				["iconPadding"] = 10,
				["growDirection"] = "LEFT",
				["offsetY"] = 15,
				["offsetX"] = -165,
				["timerTextSize"] = 30
			},
            ["focus"] = {
				["enabled"] = true,
				["zones"] = {
					["pvp"] = true,
					["arena"] = true,
					["none"] = true,
					["party"] = false,
					["raid"] = false,
					["scenario"] = true
				},
				["disabledCategories"] = defaultsDisabledCategories,
				["anchorUIParent"] = false,
				["watchFriendly"] = true,
				["iconSize"] = 35,
				["iconPadding"] = 10,
				["growDirection"] = "RIGHT",
				["offsetY"] = 0,
				["offsetX"] = 160,
				["timerTextSize"] = 25
			},
			["player"] = {
                ["enabled"] = true,
                ["zones"] = {
                    ["pvp"] = true,
					["arena"] = true,
					["none"] = true,
                    ["party"] = false,
					["raid"] = false,
					["scenario"] = true
                },
                ["disabledCategories"] = defaultsDisabledCategories,
                ["anchorUIParent"] = false,
                ["watchFriendly"] = true,
                ["iconSize"] = 40,
                ["iconPadding"] = 10,
                ["growDirection"] = "RIGHT",
                ["offsetY"] = 15,
                ["offsetX"] = 165,
                ["timerTextSize"] = 25,
                ["usePersonalNameplate"] = false
            },
			["party"] = {
                ["enabled"] = true,
                ["zones"] = {
                    ["pvp"] = false,
					["arena"] = true,
					["none"] = true,
                    ["party"] = false,
					["raid"] = false,
					["scenario"] = false
                },
                ["disabledCategories"] = defaultsDisabledCategories,
                ["anchorUIParent"] = false,
                ["watchFriendly"] = true,
                ["iconSize"] = 24,
                ["iconPadding"] = 10,
                ["growDirection"] = "RIGHT",
                ["offsetY"] = 7,
                ["offsetX"] = 76,
                ["timerTextSize"] = 12
            },
			["arena"] = {
                ["enabled"] = true,
                ["zones"] = {
                    ["pvp"] = false,
					["arena"] = true,
					["none"] = false,
                    ["party"] = false,
					["raid"] = false,
					["scenario"] = false
                },
                ["disabledCategories"] = defaultsDisabledCategories,
                ["anchorUIParent"] = false,
                ["iconSize"] = 22,
                ["iconPadding"] = 10,
                ["growDirection"] = "LEFT",
                ["offsetY"] = 20,
                ["offsetX"] = -66,
                ["timerTextSize"] = 12
            },
			["nameplate"] = {
                ["enabled"] = true,
                ["zones"] = {
                    ["pvp"] = true,
					["arena"] = true,
					["none"] = true,
                    ["party"] = false,
					["raid"] = false,
					["scenario"] = true
                },
                ["disabledCategories"] = defaultsDisabledCategories,
                ["watchFriendly"] = true,
                ["iconSize"] = 20,
                ["iconPadding"] = 10,
                ["growDirection"] = "RIGHT",
                ["offsetY"] = 0,
                ["offsetX"] = 80,
                ["timerTextSize"] = 16
            }
		}
	}
}

local directions = {
	LEFT = 'LEFT',
	RIGHT = 'RIGHT'
}

function Diminish:ShowTooltip(owner, func)
	-- if ShowTooltips then
	if true then
		GameTooltip:SetOwner(owner, "ANCHOR_RIGHT", 0, 0)
		func()
		GameTooltip:Show()
	end
end

function ElvUIPvP:Update()
	local enabled = E.db.ElvUIPvP.SomeToggleOption
	local range = E.db.ElvUIPvP.SomeRangeOption
	if enabled then

	else

	end
	Diminish:ToggleForZone()
	Icons.OnFrameConfigChanged()
end

local function GetOptionsTable_General()
	local config = {
		order = 1,
		type = 'group',
		childGroups = 'tab',
		name = "General",
		args = {}
	}
	config.args.timerStartAuraEnd = {
		order = 1,
		type = 'toggle',
		name = "Start Cooldown on Aura Removed",
		get = function(info) return E.db.ElvUIPvP.DrTracker.timerStartAuraEnd end,
		set = function(info, value) E.db.ElvUIPvP.DrTracker.timerStartAuraEnd = value; ElvUIPvP:Update() end
	}
	config.args.timerSwipe = {
		order = 2,
		type = 'toggle',
		name = "Start Swipe for Cooldowns",
		get = function(info) return E.db.ElvUIPvP.DrTracker.timerSwipe end,
		set = function(info, value) E.db.ElvUIPvP.DrTracker.timerSwipe = value; ElvUIPvP:Update() end
	}
	config.args.timerText = {
		order = 3,
		type = 'toggle',
		name = "Show Countdowns for Cooldowns",
		get = function(info) return E.db.ElvUIPvP.DrTracker.timerText end,
		set = function(info, value) E.db.ElvUIPvP.DrTracker.timerText = value; ElvUIPvP:Update() end
	}
	config.args.timerColors = {
		order = 4,
		type = 'toggle',
		name = "Show Indicator Color on Countdowns",
		get = function(info) return E.db.ElvUIPvP.DrTracker.timerColors end,
		set = function(info, value) E.db.ElvUIPvP.DrTracker.timerColors = value; ElvUIPvP:Update() end
	}
	config.args.timerTextOutline = {
		order = 5,
		type = 'select',
		name = "Font Outline",
		values = {
			NONE = 'None',
			OUTLINE = 'Outline',
			MONOCHROME = 'Monochrome',
			MONOCHROMEOUTLINE = 'Monochrome Outline',
			THICKOUTLINE = 'Thick Outline'
		},
		get = function(info) return E.db.ElvUIPvP.DrTracker.timerTextOutline end,
		set = function(info, value) E.db.ElvUIPvP.DrTracker.timerTextOutline = value; ElvUIPvP:Update() end
	}
	config.args.trackNPCs = {
		order = 6,
		type = 'toggle',
		name = "Track NPCs",
		get = function(info) return E.db.ElvUIPvP.DrTracker.trackNPCs end,
		set = function(info, value) E.db.ElvUIPvP.DrTracker.trackNPCs = value; ElvUIPvP:Update() end
	}
	config.args.showCategoryText = {
		order = 7,
		type = 'toggle',
		name = "Show Category Text",
		get = function(info) return E.db.ElvUIPvP.DrTracker.showCategoryText end,
		set = function(info, value) E.db.ElvUIPvP.DrTracker.showCategoryText = value; ElvUIPvP:Update() end
	}
	config.args.colorBlind = {
		order = 8,
		type = 'toggle',
		name = "Show DR Indicator Numbers",
		get = function(info) return E.db.ElvUIPvP.DrTracker.colorBlind end,
		set = function(info, value) E.db.ElvUIPvP.DrTracker.colorBlind = value; ElvUIPvP:Update() end
	}
	config.args.colorBlindFontSize = {
		order = 10,
		type = "range",
		name = "DR Indicator Label Size",
		min = 1,
		max = 40,
		step = 1,
		get = function(info) return E.db.ElvUIPvP.DrTracker.colorBlindFontSize end,
		set = function(info, value) E.db.ElvUIPvP.DrTracker.colorBlindFontSize = value ElvUIPvP:Update() end
	}
	local borderTextures = {
		{
			edgeFile = "Interface\\BUTTONS\\UI-Quickslot-Depress",
			layer = "BORDER",
			edgeSize = 2.5,
			name = "DEFAULT", -- keep a reference to text in db so we can set correct dropdown value on login
		},
		{
			edgeFile = "Interface\\BUTTONS\\UI-Quickslot-Depress",
			layer = "OVERLAY",
			edgeSize = 1,
			name = "GLOW",
		},
		{
			edgeFile = "Interface\\BUTTONS\\WHITE8X8",
			--isBackdrop = true,
			edgeSize = 1.5,
			layer = "BORDER",
			name = "BRIGHT",
		},
		{
			layer = "BORDER",
			edgeFile = "",
			edgeSize = 0,
			name = "NONE",
		}
	}
	config.args.border = {
		order = 9,
		type = 'select',
		name = "Border",
		values = {
			NONE = 'None',
			DEFAULT = 'Default',
			GLOW = 'Default with glow',
			BRIGHT = 'Bright'
		},
		get = function(info) return E.db.ElvUIPvP.DrTracker.border.name end,
		set = function(info, value)
			for index, border in pairs(borderTextures) do
				if border.name == value then
					E.db.ElvUIPvP.DrTracker.border = border
				end
			end
			ElvUIPvP:Update()
		end
	}
	config.args.categoryFontSize = {
		order = 10,
		type = "range",
		name = "Category Label Size",
		min = 1,
		max = 40,
		step = 1,
		get = function(info) return E.db.ElvUIPvP.DrTracker.categoryFontSize end,
		set = function(info, value) E.db.ElvUIPvP.DrTracker.categoryFontSize = value ElvUIPvP:Update() end
	}
	return config
end

local function GetOptionsTableArgs_Unit(unit)
	local config = {}
	config.enabled = {
		order = 1,
		type = 'toggle',
		name = "Enabled",
		get = function(info) return E.db.ElvUIPvP.DrTracker.unitFrames[unit].enabled end,
		set = function(info, value) E.db.ElvUIPvP.DrTracker.unitFrames[unit].enabled = value; ElvUIPvP:Update() end
	}
	if unit == "player" then
		config.usePersonalNameplate = {
			order = 2,
			type = 'toggle',
			name = "Anchor ToPersonal Nameplate",
			get = function(info) return E.db.ElvUIPvP.DrTracker.unitFrames[unit].usePersonalNameplate end,
			set = function(info, value) E.db.ElvUIPvP.DrTracker.unitFrames[unit].usePersonalNameplate = value; ElvUIPvP:Update() end
		}
	end
	if unit ~= "player" and unit ~= "arena" then
		config.watchFriendly = {
			order = 2,
			type = 'toggle',
			name = "Show Friendly DRs",
			get = function(info) return E.db.ElvUIPvP.DrTracker.unitFrames[unit].watchFriendly end,
			set = function(info, value) E.db.ElvUIPvP.DrTracker.unitFrames[unit].watchFriendly = value; ElvUIPvP:Update() end
		}
	end
	if unit ~= "nameplate" then
		config.anchorUIParent = {
			order = 3,
			type = 'toggle',
			name = "Anchor to UIParent",
			get = function(info) return E.db.ElvUIPvP.DrTracker.unitFrames[unit].anchorUIParent end,
			set = function(info, value) E.db.ElvUIPvP.DrTracker.unitFrames[unit].anchorUIParent = value; ElvUIPvP:Update() end
		}
	end
	config.growDirection = {
		order = 4,
		type = 'select',
		name = "Grow Direction",
		values = {
			UP = 'Up',
			DOWN = 'Down',
			LEFT = 'Left',
			RIGHT = 'Right'
		},
		get = function(info) return E.db.ElvUIPvP.DrTracker.unitFrames[unit].growDirection end,
		set = function(info, value) E.db.ElvUIPvP.DrTracker.unitFrames[unit].growDirection = value; ElvUIPvP:Update() end
	}
	config.iconSize = {
		order = 5,
		type = "range",
		name = "Frame Size",
		min = 10,
		max = 100,
		step = 1,
		get = function(info) return E.db.ElvUIPvP.DrTracker.unitFrames[unit].iconSize end,
		set = function(info, value) E.db.ElvUIPvP.DrTracker.unitFrames[unit].iconSize = value ElvUIPvP:Update() end
	}
	config.iconPadding = {
		order = 6,
		type = "range",
		name = "Frame Padding",
		min = 0,
		max = 40,
		step = 1,
		get = function(info) return E.db.ElvUIPvP.DrTracker.unitFrames[unit].iconPadding end,
		set = function(info, value) E.db.ElvUIPvP.DrTracker.unitFrames[unit].iconPadding = value ElvUIPvP:Update() end
	}
	config.timerTextSize = {
		order = 7,
		type = "range",
		name = "Countdown Size",
		min = 7,
		max = 100,
		step = 1,
		get = function(info) return E.db.ElvUIPvP.DrTracker.unitFrames[unit].timerTextSize end,
		set = function(info, value) E.db.ElvUIPvP.DrTracker.unitFrames[unit].timerTextSize = value ElvUIPvP:Update() end
	}
	config.offsetX = {
		order = 8,
		type = "range",
		name = "Offset X",
		min = -500,
		max = 500,
		step = 1,
		get = function(info) return E.db.ElvUIPvP.DrTracker.unitFrames[unit].offsetX end,
		set = function(info, value) E.db.ElvUIPvP.DrTracker.unitFrames[unit].offsetX = value ElvUIPvP:Update() end
	}
	config.offsetY = {
		order = 9,
		type = "range",
		name = "Offset Y",
		min = -500,
		max = 500,
		step = 1,
		get = function(info) return E.db.ElvUIPvP.DrTracker.unitFrames[unit].offsetY end,
		set = function(info, value) E.db.ElvUIPvP.DrTracker.unitFrames[unit].offsetY = value ElvUIPvP:Update() end
	}
	config.zonePvp = {
		order = 10,
		type = 'toggle',
		name = "Battlegrounds & Brawls",
		get = function(info) return E.db.ElvUIPvP.DrTracker.unitFrames[unit].zones.pvp end,
		set = function(info, value) E.db.ElvUIPvP.DrTracker.unitFrames[unit].zones.pvp = value; ElvUIPvP:Update() end
	}
	config.zoneScenario = {
		order = 11,
		type = 'toggle',
		name = "Scenario",
		get = function(info) return E.db.ElvUIPvP.DrTracker.unitFrames[unit].zones.scenario end,
		set = function(info, value) E.db.ElvUIPvP.DrTracker.unitFrames[unit].zones.scenario = value; ElvUIPvP:Update() end
	}
	config.zoneArena = {
		order = 12,
		type = 'toggle',
		name = "Arena",
		get = function(info) return E.db.ElvUIPvP.DrTracker.unitFrames[unit].zones.arena end,
		set = function(info, value) E.db.ElvUIPvP.DrTracker.unitFrames[unit].zones.arena = value; ElvUIPvP:Update() end
	}
	config.zoneNone = {
		order = 13,
		type = 'toggle',
		name = "World",
		get = function(info) return E.db.ElvUIPvP.DrTracker.unitFrames[unit].zones.none end,
		set = function(info, value) E.db.ElvUIPvP.DrTracker.unitFrames[unit].zones.none = value; ElvUIPvP:Update() end
	}
	config.zoneRaid = {
		order = 14,
		type = 'toggle',
		name = "Raid",
		get = function(info) return E.db.ElvUIPvP.DrTracker.unitFrames[unit].zones.raid end,
		set = function(info, value) E.db.ElvUIPvP.DrTracker.unitFrames[unit].zones.raid = value; ElvUIPvP:Update() end
	}
	--
	return config
end

function ElvUIPvP:InsertOptions()
	E.Options.args.ElvUIPvP = {
		type = "group",
		name = "PvP Enhancements",
		order = 100,
		get = function(info) return E.db.ElvUIPvP[info[#info]] end,
		set = function(info, value) E.db.ElvUIPvP[info[#info]] = value end,
		args = {
			enable = {
				order = 1,
				type = 'toggle',
				name = "Enable",
				get = function(info) return E.db.ElvUIPvP.Enabled end,
				set = function(info, value) E.db.ElvUIPvP.Enabled = value; ElvUIPvP:Update() end
			},
			isTesting = {
				order = 2,
				type = 'toggle',
				name = "Test Mode",
				get = function(info) return E.db.ElvUIPvP.IsTesting end,
				set = function(info, value)
					if InCombatLockdown() then
						E.db.ElvUIPvP.IsTesting = false
						NS.TestMode:Test(false)
					end
					E.db.ElvUIPvP.IsTesting = value;
					NS.TestMode:Test(value)
					ElvUIPvP:Update()
				end
			},
			cdTracker = {
				order = 3,
				type = 'group',
				childGroups = 'tab',
				name = "Cooldown Tracker",
				args = {
					player = {
						order = 1,
						type = 'group',
						childGroups = 'tab',
						name = "Player",
						args = {

						},
					},
					target = {
						order = 2,
						type = 'group',
						childGroups = 'tab',
						name = "Target",
						args = {

						},
					},
					party = {
						order = 3,
						type = 'group',
						childGroups = 'tab',
						name = "Party",
						args = {

						},
					},
					arena = {
						order = 4,
						type = 'group',
						childGroups = 'tab',
						name = "Arena",
						args = {

						},
					},
					nameplate = {
						order = 5,
						type = 'group',
						childGroups = 'tab',
						name = "Nameplate",
						args = {

						},
					},
				},
			},
			drTracker = {
				order = 4,
				type = 'group',
				childGroups = 'tab',
				name = "DR Tracker",
				args = {
					generalGroup = GetOptionsTable_General(),
					player = {
						order = 2,
						type = 'group',
						childGroups = 'tab',
						name = "Player",
						args = GetOptionsTableArgs_Unit('player')
					},
					target = {
						order = 3,
						type = 'group',
						childGroups = 'tab',
						name = "Target",
						args = GetOptionsTableArgs_Unit('target')
					},
					focus = {
						order = 4,
						type = 'group',
						childGroups = 'tab',
						name = "Focus",
						args = GetOptionsTableArgs_Unit('focus')
					},
					party = {
						order = 5,
						type = 'group',
						childGroups = 'tab',
						name = "Party",
						args = GetOptionsTableArgs_Unit('party')
					},
					arena = {
						order = 6,
						type = 'group',
						childGroups = 'tab',
						name = "Arena",
						args = GetOptionsTableArgs_Unit('arena')
					},
					nameplate = {
						order = 7,
						type = 'group',
						childGroups = 'tab',
						name = "Nameplate",
						args = GetOptionsTableArgs_Unit('nameplate')
					}
				}
			},
			targetingTracker = {
				order = 5,
				type = 'group',
				childGroups = 'tab',
				name = "Targeting Tracker",
				args = {},
			}
		}
	}
end

function ElvUIPvP:Initialize()
	--Register plugin so options are properly inserted when config is loaded
	EP:RegisterPlugin(addonName, ElvUIPvP.InsertOptions)
end

E:RegisterModule(ElvUIPvP:GetName()) --Register the module with ElvUI. ElvUI will now call ElvUIPvP:Initialize() when ElvUI is ready to load our plugin.