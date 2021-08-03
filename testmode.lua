local _, NS = ...
local E, L, V, P, G = unpack(ElvUI);
local UF = E and E:GetModule("UnitFrames")
local L = NS.L
local isTesting = false
local backdrop = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    tile = false,
}
local TestMode = CreateFrame("Frame")
TestMode.pool = CreateFramePool("Frame", nil, _G.BackdropTemplateMixin and "BackdropTemplate") -- just for testing purposes
NS.TestMode = TestMode

local function PartyOnHide(self)
    if not TestMode:IsTesting() then return end

    -- If you hit Escape or Cancel in InterfaceOptions instead of "Okay" button then for some reason
    -- blizzard auto hides the spawned PartyMember frames so hook them and prevent hiding when testing
    if not InCombatLockdown() and not self:IsForbidden() then
        if not GetCVarBool("useCompactPartyFrames") then -- user toggling cvar while testing would prevent hiding permanently
            self:Show()
        end
    end
end

function TestMode:IsTesting()
    return isTesting
end

function TestMode:ToggleArenaAndPartyFrames(state, forceHide)
    if isTesting then return end
    if InCombatLockdown() then return end
    local settings = E.db.ElvUIPvP.DrTracker.unitFrames
    if not NS.IS_CLASSIC then
        if not IsAddOnLoaded("Blizzard_ArenaUI") then
            LoadAddOn("Blizzard_ArenaUI")
        end
    end
    local showFlag = state
    if not NS.IS_CLASSIC then
        local isInArena = select(2, IsInInstance()) == "arena"
        if forceHide or settings.arena.enabled and not isInArena then
            if ArenaEnemyFrames then
                ArenaEnemyFrames:SetShown(showFlag)
            end
            if LibStub and LibStub("AceAddon-3.0", true) then
                local _, sArena = pcall(function() return LibStub("AceAddon-3.0"):GetAddon("sArena") end)
                if sArena and sArena.ArenaEnemyFrames then
                    -- (As of sArena 3.0.0 this is no longer needed, but we'll keep this for now
                    -- incase anyone is using the old version)
                    -- sArena anchors frames to sArena.ArenaEnemyFrames instead of _G.ArenaEnemyFrames
                    sArena.ArenaEnemyFrames:SetShown(showFlag)
                end
            end
        end
    end

    local useCompact = GetCVarBool("useCompactPartyFrames")
    if useCompact and settings.party.enabled and showFlag then
        if not IsInGroup() then
            -- print("Diminish: " .. L.COMPACTFRAMES_ERROR) -- luacheck: ignore
        end
    end

    if UF then
        if not NS.IS_CLASSIC then
            if settings.arena.enabled then
                for i=1, 3 do
                    if UF['arena'..i] and showFlag then
                        UF:ForceShow(UF['arena'..i])
                    elseif UF['arena'..i] then
                        UF:UnforceShow(UF['arena'..i])
                    end
                end
            end
        end
        if settings.party.enabled then
            UF:HeaderConfig(ElvUF_Party, showFlag)
        end
        return
    end

    for i = 1, 3 do
        if not NS.IS_CLASSIC then
            if select(2, IsInInstance()) ~= "arena" then
                local frame = NS.Icons:GetAnchor("arena"..i, true, true)
                if frame and frame ~= UIParent then
                    if frame:IsVisible() or settings.arena.enabled then
                        frame:SetShown(showFlag)
                    end
                end
            end
        end
        if forceHide or not useCompact and settings.party.enabled then
            if not UnitExists("party"..i) then -- do not toggle if frame belongs to a group member
                local frame = NS.Icons:GetAnchor("party"..i, true, true)
                if frame and frame ~= UIParent then
                    frame:SetShown(showFlag)
                    if not frame.Diminish_isHooked then
                        frame:HookScript("OnHide", PartyOnHide)
                        frame.Diminish_isHooked = true
                    end
                end
            end
        end
    end
end

local function OnTargetChanged(self, event)
    if event == "PLAYER_LOGOUT" then
        if TestMode.personalNameplateCfg ~= nil then
            SetCVar("NameplatePersonalShowAlways", TestMode.personalNameplateCfg)
        end
    else
        if TestMode:IsTesting() and UnitExists("target") then
            NS.Timers:Refresh("nameplate")
        end
    end
end
TestMode:RegisterEvent("PLAYER_LOGOUT")
TestMode:SetScript("OnEvent", OnTargetChanged)

function TestMode:Test(show)
    if InCombatLockdown() then
        return
        -- return print(L.COMBATLOCKDOWN_ERROR) -- luacheck: ignore
    end
    if show then
        TestMode:ToggleArenaAndPartyFrames(false, true)
        TestMode:ToggleArenaAndPartyFrames(true)
        isTesting = true
        self:RegisterEvent("PLAYER_TARGET_CHANGED")
        if E.db.ElvUIPvP.DrTracker.unitFrames.player.enabled and E.db.ElvUIPvP.DrTracker.unitFrames.player.usePersonalNameplate then
            self.personalNameplateCfg = self.personalNameplateCfg or GetCVar("NameplatePersonalShowAlways")
            SetCVar("NameplatePersonalShowAlways", 1)
            C_Timer.After(0.15, function()
                NS.Timers:Refresh("player")
            end)
        end
        NS.Timers:ResetAll()
        NS.Timers:Insert(UnitGUID("player"), nil, NS.CATEGORIES.stun, 853, false, false, true, true)
        NS.Timers:Insert(UnitGUID("player"), nil, NS.CATEGORIES.root, 122, false, false, true, true)
        NS.Timers:Insert(UnitGUID("player"), nil, NS.CATEGORIES.incapacitate, 118, false, true, true, true)
    else
        isTesting = false
        TestMode:ToggleArenaAndPartyFrames(false, true)
        NS.Timers:ResetAll()
        if not TestMode:IsTesting() then
            self:UnregisterEvent("PLAYER_TARGET_CHANGED")
        end

        if self.personalNameplateCfg ~= nil then
            SetCVar("NameplatePersonalShowAlways", self.personalNameplateCfg)
            self.personalNameplateCfg = nil
        end
    end
end
