local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local ElvUIPvP = E:NewModule('PvP', 'AceHook-3.0', 'AceEvent-3.0', 'AceTimer-3.0'); --Create a plugin within ElvUI and adopt AceHook-3.0, AceEvent-3.0 and AceTimer-3.0. We can make use of these later.
local EP = LibStub("LibElvUIPlugin-1.0") --We can use this to automatically insert our GUI tables when ElvUI_Config is loaded.
local DRList = LibStub("DRList-1.0")
local LSM = LibStub("LibSharedMedia-3.0")
local ACH = E.Libs.ACH
local addonName, addonTable = ... --See http://www.wowinterface.com/forums/showthread.php?t=51502&p=304704&postcount=2

LSM:Register("font", "PT Sans Narrow Bold", [[Interface\AddOns\ElvUI_PluginFramework\Fonts\PT Sans Narrow Bold.ttf]])

local ElvUIPvPFrame = CreateFrame("Frame", "ElvUIPvPFrame")
ElvUIPvPFrame.Objects = {}

--Default options
P["ElvUIPvP"] = {
	["Enabled"] = true,
	["SomeToggleOption"] = true,
	["SomeRangeOption"] = 5,
	["DrTracker"] = {
		["ElvUF_Player"] = {
			["Size"] = 60,
			["Anchor"] = "TOPRIGHT",
			["AnchorFrame"] = "TOPLEFT",
			["X"] = 2,
			["Y"] = 0,
			["Direction"] = "RIGHT",
			["Spacing"] = 2,
			["Border"] = 2,
			["FontSize"] = 30
		}
	},
}

local directions = {
	LEFT = 'LEFT',
	RIGHT = 'RIGHT'
}

local anchorPoints = {
	TOPLEFT = 'TOPLEFT',
	LEFT = 'LEFT',
	BOTTOMLEFT = 'BOTTOMLEFT',
	RIGHT = 'RIGHT',
	TOPRIGHT = 'TOPRIGHT',
	BOTTOMRIGHT = 'BOTTOMRIGHT',
	TOP = 'TOP',
	BOTTOM = 'BOTTOM',
}

local framelist = {}

local eventRegistered = {
	["SPELL_AURA_APPLIED"] = true,
	["SPELL_AURA_REFRESH"] = true,
	["SPELL_AURA_REMOVED"] = true
}

function ElvUIPvPFrame:ShowTooltip(owner, func)
	-- if ShowTooltips then
	if true then
		GameTooltip:SetOwner(owner, "ANCHOR_RIGHT", 0, 0)
		func()
		GameTooltip:Show()
	end
end

ElvUIPvPFrame.SetBasicPosition = function(frame, basicPoint, relativeTo, relativePoint, space)
	frame:ClearAllPoints()
	if relativeTo == "Button" then
		relativeTo = frame:GetParent()
	else
		relativeTo = frame:GetParent()[relativeTo]
	end
	frame:SetPoint('TOP'..basicPoint, relativeTo, 'TOP'..relativePoint, space, 0)
	frame:SetPoint('BOTTOM'..basicPoint, relativeTo, 'BOTTOM'..relativePoint, space, 0)
end

local function ApplyCooldownSettings(self, showNumber, cdReverse, setDrawSwipe, swipeColor)
	self:SetReverse(cdReverse)
	self:SetDrawSwipe(setDrawSwipe)
	if swipeColor then self:SetSwipeColor(unpack(swipeColor)) end
	self:SetHideCountdownNumbers(not showNumber)
end

local function ApplyFontStringSettings(fontString, Fontsize, FontOutline, enableShadow, shadowColor)
	fontString:SetFont(LSM:Fetch("font", 'PT Sans Narrow Bold'), Fontsize, FontOutline)
	fontString:EnableShadowColor(enableShadow, shadowColor)
end

local function EnableShadowColor(fontString, enableShadow, shadowColor)
	if shadowColor then fontString:SetShadowColor(unpack(shadowColor)) end
	if enableShadow then
		fontString:SetShadowOffset(1, -1)
	else
		fontString:SetShadowOffset(0, 0)
	end
end

function ElvUIPvPFrame.MyCreateCooldown(parent)
	local cooldown = CreateFrame("Cooldown", nil, parent)
	cooldown:SetAllPoints()
	cooldown:SetSwipeTexture('Interface/Buttons/WHITE8X8')
	cooldown.ApplyCooldownSettings = ApplyCooldownSettings
	-- Find fontstring of the cooldown
	for _, region in pairs{cooldown:GetRegions()} do
		if region:GetObjectType() == "FontString" then
			cooldown.Text = region
			cooldown.Text.ApplyFontStringSettings = ApplyFontStringSettings
			cooldown.Text.EnableShadowColor = EnableShadowColor
			break
		end
	end
	return cooldown
end

local function CombatLogCheck(self, ...)
	--TODO
	local _, _, eventType, _, _, _, _, _, destGUID, _, _, _, spellID, spellName, _, auraType, _ = ...
	if( not eventRegistered[eventType] ) then
		return
	end
	if(destGUID ~= UnitGUID(self.target)) then
		-- return
		-- TODO Check if the target id is within allowed ones...
	end
	--
end

function ElvUIPvP:Update()
	local enabled = E.db.ElvUIPvP.SomeToggleOption
	local range = E.db.ElvUIPvP.SomeRangeOption
	if enabled then
		for frame, target in pairs(framelist) do
			self = _G[frame]
			self.DRContainer:Show()
			self.DRContainer:ApplySettings();
		end
	else
		for frame, target in pairs(framelist) do
			self = _G[frame]
			self.DRContainer:Hide()
		end
	end
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
			cdTracker = {
				order = 20,
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
				order = 21,
				type = 'group',
				childGroups = 'tab',
				name = "DR Tracker",
				args = {
					player = {
						order = 1,
						type = 'group',
						childGroups = 'tab',
						name = "Player",
						args = {
							size = {
								order = 1,
								type = "range",
								name = "Size",
								min = 8,
								max = 256,
								step = 1,
								get = function(info)
									return E.db.ElvUIPvP.DrTracker.ElvUF_Player.Size
								end,
								set = function(info, value)
									E.db.ElvUIPvP.DrTracker.ElvUF_Player.Size = value
									ElvUIPvP:Update() --We changed a setting, call our Update function
								end,
							},
							fontSize = {
								order = 1,
								type = "range",
								name = "Font Size",
								min = 8,
								max = 32,
								step = 1,
								get = function(info)
									return E.db.ElvUIPvP.DrTracker.ElvUF_Player.FontSize
								end,
								set = function(info, value)
									E.db.ElvUIPvP.DrTracker.ElvUF_Player.FontSize = value
									ElvUIPvP:Update() --We changed a setting, call our Update function
								end,
							},
							anchor = {
								type = 'select',
								order = 2,
								name = "Anchor Point",
								values = anchorPoints,
								get = function(info)
									return E.db.ElvUIPvP.DrTracker.ElvUF_Player.Anchor
								end,
								set = function(info, value)
									E.db.ElvUIPvP.DrTracker.ElvUF_Player.Anchor = value
									ElvUIPvP:Update() --We changed a setting, call our Update function
								end
							},
							anchorFrame = {
								type = 'select',
								order = 2,
								name = "Anchor Frame",
								values = anchorPoints,
								get = function(info)
									return E.db.ElvUIPvP.DrTracker.ElvUF_Player.AnchorFrame
								end,
								set = function(info, value)
									E.db.ElvUIPvP.DrTracker.ElvUF_Player.AnchorFrame = value
									ElvUIPvP:Update() --We changed a setting, call our Update function
								end
							},
							x = {
								order = 5,
								type = "range",
								name = "X",
								min = -100,
								max = 100,
								step = 1,
								get = function(info)
									return E.db.ElvUIPvP.DrTracker.ElvUF_Player.X
								end,
								set = function(info, value)
									E.db.ElvUIPvP.DrTracker.ElvUF_Player.X = value
									ElvUIPvP:Update() --We changed a setting, call our Update function
								end
							},
							y = {
								order = 6,
								type = "range",
								name = "Y",
								min = -100,
								max = 100,
								step = 1,
								get = function(info)
									return E.db.ElvUIPvP.DrTracker.ElvUF_Player.Y
								end,
								set = function(info, value)
									E.db.ElvUIPvP.DrTracker.ElvUF_Player.Y = value
									ElvUIPvP:Update() --We changed a setting, call our Update function
								end,
							},
							directions = {
								type = 'select',
								order = 7,
								name = "Direction",
								values = directions,
								get = function(info)
									return E.db.ElvUIPvP.DrTracker.ElvUF_Player.Direction
								end,
								set = function(info, value)
									E.db.ElvUIPvP.DrTracker.ElvUF_Player.Direction = value
									ElvUIPvP:Update() --We changed a setting, call our Update function
								end
							},
							spacing = {
								order = 6,
								type = "range",
								name = "Spacing",
								min = 0,
								max = 100,
								step = 1,
								get = function(info)
									return E.db.ElvUIPvP.DrTracker.ElvUF_Player.Spacing
								end,
								set = function(info, value)
									E.db.ElvUIPvP.DrTracker.ElvUF_Player.Spacing = value
									ElvUIPvP:Update() --We changed a setting, call our Update function
								end,
							},
							border = {
								order = 6,
								type = "range",
								name = "Border",
								min = 1,
								max = 5,
								step = 1,
								get = function(info)
									return E.db.ElvUIPvP.DrTracker.ElvUF_Player.Border
								end,
								set = function(info, value)
									E.db.ElvUIPvP.DrTracker.ElvUF_Player.Border = value
									ElvUIPvP:Update() --We changed a setting, call our Update function
								end,
							}
						},
					},
				},
			},
			targetingTracker = {
				order = 22,
				type = 'group',
				childGroups = 'tab',
				name = "Targeting Tracker",
				args = {},
			},
			SomeToggleOption = {
				order = 1,
				type = "toggle",
				name = "MyToggle",
				get = function(info)
					return E.db.ElvUIPvP.SomeToggleOption
				end,
				set = function(info, value)
					E.db.ElvUIPvP.SomeToggleOption = value
					ElvUIPvP:Update() --We changed a setting, call our Update function
				end,
			},
			SomeRangeOption = {
				order = 1,
				type = "range",
				name = "MyRange",
				min = 0,
				max = 10,
				step = 1,
				get = function(info)
					return E.db.ElvUIPvP.SomeRangeOption
				end,
				set = function(info, value)
					E.db.ElvUIPvP.SomeRangeOption = value
					ElvUIPvP:Update() --We changed a setting, call our Update function
				end,
			},
		},
	}
end

function ElvUIPvP:Initialize()
	--Register plugin so options are properly inserted when config is loaded
	EP:RegisterPlugin(addonName, ElvUIPvP.InsertOptions)

	framelist = {
		--[FRAME NAME]	= {UNITID,SIZE,ANCHOR,ANCHORFRAME,X,Y,"ANCHORNEXT","ANCHORPREVIOUS",nextx,nexty},
		-- My settings
		-- ["ElvUF_Target"]	= {"target",36,"TOPLEFT","BOTTOMLEFT",-1,-44,"LEFT","RIGHT",2,0},
		--
		["ElvUF_Player"] = "player",
		["ElvUF_PartyGroup1UnitButton1"] = "party1",
		["ElvUF_PartyGroup1UnitButton2"] = "party2",
		["ElvUF_PartyGroup1UnitButton3"] = "party3",
		["ElvUF_PartyGroup1UnitButton4"] = "party4",
		["ElvUF_PartyGroup1UnitButton5"] = "party5",
		-- --
		["ElvUF_Arena1"]	= "arena1",
		["ElvUF_Arena2"]	= "arena2",
		["ElvUF_Arena3"]	= "arena3",
		["ElvUF_Arena4"]	= "arena4",
		["ElvUF_Arena5"]	= "arena5",
	}

	local spellID = 5246
	local drCat = DRList:GetCategoryBySpellID(spellID)
	local spellID2 = 6770
	local drCat2 = DRList:GetCategoryBySpellID(spellID2)
	local spellID3 = 1330
	local drCat3 = DRList:GetCategoryBySpellID(spellID3)

	for frame, target in pairs(framelist) do
		self = _G[frame]
		-- COOLDOWN TRACKER
		-- DR TRACKER
		self.DRContainer = ElvUIPvPFrame.Objects.DR.New(self, frame)
		self.DRContainer:DisplayDR(drCat, spellID, 3600)
		self.DRContainer.DRFrames[drCat]:IncreaseDRState()
		self.DRContainer:DisplayDR(drCat2, spellID2, 3600)
		self.DRContainer.DRFrames[drCat2]:IncreaseDRState()
		self.DRContainer.DRFrames[drCat2]:IncreaseDRState()
		if drCat3 ~= nil then
			self.DRContainer:DisplayDR(drCat3, spellID3, 3600)
			self.DRContainer.DRFrames[drCat3]:IncreaseDRState()
			self.DRContainer.DRFrames[drCat3]:IncreaseDRState()
			self.DRContainer.DRFrames[drCat3]:IncreaseDRState()
		end
		self.DRContainer:ApplySettings()
	end
end

E:RegisterModule(ElvUIPvP:GetName()) --Register the module with ElvUI. ElvUI will now call ElvUIPvP:Initialize() when ElvUI is ready to load our plugin.