
local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local ElvUIPvPFrame = ElvUIPvPFrame
local addonName, Data = ...
local GetTime = GetTime

ElvUIPvPFrame.Objects.DR = {}
local DRList = LibStub("DRList-1.0")
local LSM = LibStub("LibSharedMedia-3.0")

local dRstates = {
	[1] = { 0, 1, 0, 1}, --green (next cc in DR time will be only half duration)
	[2] = { 1, 1, 0, 1}, --yellow (next cc in DR time will be only 1/4 duration)
	[3] = { 1, 0, 0, 1}, --red (next cc in DR time will not apply, player is immune)
}

local function drFrameUpdateStatusBorder(drFrame)
    print('setting status border '..(unpack(dRstates[drFrame.status] or dRstates[3])))
	drFrame:SetBackdropBorderColor(unpack(dRstates[drFrame.status] or dRstates[3]))
end

local function drFrameUpdateStatusText(drFrame)
    print('setting status text '..(unpack(dRstates[drFrame.status] or dRstates[3])))
	drFrame.Cooldown.Text:SetTextColor(unpack(dRstates[drFrame.status] or dRstates[3]))
end

function ElvUIPvPFrame.Objects.DR.New(playerButton, frameName)
    print(frameName)
    print(E.db.ElvUIPvP.DrTracker[frameName].Anchor)
	local DRContainer = CreateFrame("Frame", nil, playerButton, BackdropTemplateMixin and "BackdropTemplate")
    DRContainer:SetPoint(
        E.db.ElvUIPvP.DrTracker[frameName].Anchor,
        playerButton,
        E.db.ElvUIPvP.DrTracker[frameName].AnchorFrame,
        E.db.ElvUIPvP.DrTracker[frameName].X,
        E.db.ElvUIPvP.DrTracker[frameName].Y
    )
	-- DRContainer:SetPoint("TOPRIGHT", playerButton, "TOPLEFT", -1, 0)
	-- DRContainer:SetPoint("BOTTOMRIGHT", playerButton, "BOTTOMLEFT", -1, 0)
	DRContainer:SetBackdropColor(0, 0, 0, 0)
	DRContainer.DRFrames = {}
    DRContainer.frameName = frameName
	DRContainer.ApplySettings = function(self)
		self:UpdateBackdrop(E.db.ElvUIPvP.DrTracker[self.frameName].Border)
		self:SetPosition()
		self:DrPositioning()
		for drCategory, drFrame in pairs(self.DRFrames) do
			drFrame:ApplyDrFrameSettings()
			drFrame:ChangeDisplayType()
		end
	end
	DRContainer.Reset = function(self)
		for drCategory, drFrame in pairs(self.DRFrames) do
			drFrame.Cooldown:Clear()
		end
	end

	DRContainer.SetPosition = function(self)
        self:ClearAllPoints()
        print('clear all points')
        print(E.db.ElvUIPvP.DrTracker[self.frameName].Anchor)
        self:SetHeight(E.db.ElvUIPvP.DrTracker[self.frameName].Size)
        self:SetPoint(
            E.db.ElvUIPvP.DrTracker[self.frameName].Anchor,
            self:GetParent(),
            E.db.ElvUIPvP.DrTracker[self.frameName].AnchorFrame,
            E.db.ElvUIPvP.DrTracker[self.frameName].X,
            E.db.ElvUIPvP.DrTracker[self.frameName].Y
        )
        -- print('set basic position')
		-- ElvUIPvPFrame.SetBasicPosition(self, "RIGHT", "Button", "LEFT", 1)
	end

	DRContainer.SetSizeOfAuraFrames = function(self, size)
		local borderThickness = E.db.ElvUIPvP.DrTracker[self.frameName].Border
		for drCategorie, drFrame in pairs(self.DRFrames) do
			drFrame:SetWidth(size - borderThickness * 2)
			drFrame:SetHeight(size - borderThickness * 2)
		end
	end

	DRContainer.DisplayDR = function(self, drCat, spellID, additionalDuration)
		local drFrame = self.DRFrames[drCat]
		if not drFrame then  --create a new frame for this categorie

			drFrame = CreateFrame("Frame", nil, self, BackdropTemplateMixin and "BackdropTemplate")

			drFrame:HookScript("OnEnter", function(self)
				ElvUIPvPFrame:ShowTooltip(self, function()
					GameTooltip:SetSpellByID(self.SpellID)
				end)
			end)

			drFrame:HookScript("OnLeave", function(self)
				if GameTooltip:IsOwned(self) then
					GameTooltip:Hide()
				end
			end)

			drFrame.Container = self

			drFrame.ApplyDrFrameSettings = function(self)
				self.Cooldown:ApplyCooldownSettings(true, false, false)
				self.Cooldown.Text:ApplyFontStringSettings(E.db.ElvUIPvP.DrTracker[drFrame.Container.frameName].FontSize, "OUTLINE", false, {0, 0, 0, 1})

			end

			drFrame.ChangeDisplayType = function(self)
                print('ChangeDisplayType')
				self:SetDisplayType()
				--reset settings
				self.Cooldown.Text:SetTextColor(1, 1, 1, 1)
				self:SetBackdropBorderColor(0, 0, 0, 0)
				if self.status ~= 0 then self:SetStatus() end
			end

			drFrame.IncreaseDRState = function(self)
				self.status = self.status + 1
				self:SetStatus()
			end

			drFrame.SetDisplayType = function(self)
                print('SetDisplayType')
				if "Countdowntext" == "Frame" then
                -- if true then
					self.SetStatus = drFrameUpdateStatusBorder
				else
					self.SetStatus = drFrameUpdateStatusText
				end
			end

			drFrame:SetWidth(E.db.ElvUIPvP.DrTracker[drFrame.Container.frameName].Size - E.db.ElvUIPvP.DrTracker[drFrame.Container.frameName].Border * 2)
			drFrame:SetHeight(E.db.ElvUIPvP.DrTracker[drFrame.Container.frameName].Size - E.db.ElvUIPvP.DrTracker[drFrame.Container.frameName].Border * 2)

			drFrame:SetBackdrop({
                bgFile = "Interface/Buttons/WHITE8X8", --drawlayer "BACKGROUND"
                edgeFile = 'Interface/Buttons/WHITE8X8', --drawlayer "BORDER"
                edgeSize = 1
            })

			drFrame:SetBackdropColor(0, 0, 0, 0)
			drFrame:SetBackdropBorderColor(0, 0, 0, 0)

			drFrame.Icon = drFrame:CreateTexture(nil, "BORDER", nil, -1) -- -1 to make it behind the SetBackdrop bg
			drFrame.Icon:SetAllPoints()

            local ctext = drFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            ctext:SetFont(LSM:Fetch("font", 'PT Sans Narrow Bold'), 16, "OUTLINE")
            ctext:SetPoint("BOTTOMLEFT", 0, E.db.ElvUIPvP.DrTracker[drFrame.Container.frameName].Size + 2)
            ctext:SetShown(true)--Add setting for Show Category Text
            ctext:SetJustifyH("LEFT")
            ctext:SetJustifyH("TOP")
            drFrame.categoryText = ctext
            if _G.string.len(drCat) >= 10 then
                -- truncate text. Could set max width instead but it adds "..." at the end
                -- and changes text position
                drFrame.categoryText:SetText(strsub(drCat, 1, 5))
            else
                drFrame.categoryText:SetText(drCat)
            end

			drFrame.Cooldown = ElvUIPvPFrame.MyCreateCooldown(drFrame)
			drFrame.Cooldown:SetScript("OnHide", function()
				drFrame:Hide()
				drFrame.SpellID = false
				drFrame.status = 0
				self:DrPositioning() --self = DRContainer
			end)
			-- drFrame.Cooldown:SetScript("OnCooldownDone", function()
			-- 	print("OnCooldownDone")
			-- 	drFrame:Hide()
			-- 	drFrame.status = 0
			-- 	self:DrPositioning() --self = DRContainer
			-- end)

			drFrame.status = 0

			drFrame:SetDisplayType()
			drFrame:ApplyDrFrameSettings()

			drFrame:Hide()

			self.DRFrames[drCat] = drFrame
		end

		if not drFrame:IsShown() then
			drFrame:Show()
			self:DrPositioning()
		end
		drFrame.SpellID = spellID
		drFrame.Icon:SetTexture(GetSpellTexture(spellID))
		drFrame.Cooldown:SetCooldown(GetTime(), DRList:GetResetTime(drCat) + additionalDuration)
	end

	DRContainer.DrPositioning = function(self)
		local spacing = E.db.ElvUIPvP.DrTracker[self.frameName].Spacing
		local borderThickness = E.db.ElvUIPvP.DrTracker[self.frameName].Border
		local growLeft = E.db.ElvUIPvP.DrTracker[self.frameName].Direction == "LEFT"
		local barSize = E.db.ElvUIPvP.DrTracker[self.frameName].Size
		local anchor = self
		local totalWidth = 0
		local point, relativePoint, offsetX
		self:Show()

		if growLeft then
			point = "RIGHT"
			relativePoint = "LEFT"
			offsetX = -borderThickness
		else
			point = "LEFT"
			relativePoint = "RIGHT"
			offsetX = borderThickness
		end

		for categorie, drFrame in pairs(self.DRFrames) do
            drFrame:SetWidth(E.db.ElvUIPvP.DrTracker[drFrame.Container.frameName].Size - borderThickness * 2)
            drFrame:SetHeight(E.db.ElvUIPvP.DrTracker[drFrame.Container.frameName].Size - borderThickness * 2)
			if drFrame:IsShown() then
				drFrame:ClearAllPoints()
				if totalWidth == 0 then
					drFrame:SetPoint("TOP"..point, anchor, "TOP"..point, offsetX, -borderThickness)
					-- drFrame:SetPoint("BOTTOM"..point, anchor, "BOTTOM"..point, offsetX, borderThickness)
				else
					drFrame:SetPoint("TOP"..point, anchor, "TOP"..relativePoint, growLeft and -spacing or spacing, 0)
					-- drFrame:SetPoint("BOTTOM"..point, anchor, "BOTTOM"..relativePoint, growLeft and -spacing or spacing, 0)
				end
				anchor = drFrame
				totalWidth = totalWidth + spacing + barSize - 2 * borderThickness
			end
		end
		if totalWidth == 0 then
			self:Hide()
			self:SetWidth(0.001)
		else
			totalWidth = totalWidth + 2 * borderThickness - spacing
			self:SetWidth(totalWidth)
		end
	end

	DRContainer.UpdateBackdrop = function(self, borderThickness)
		self:SetBackdrop(nil)
		self:SetBackdrop({
			bgFile = "Interface/Buttons/WHITE8X8", --drawlayer "BACKGROUND"
			edgeFile = 'Interface/Buttons/WHITE8X8', --drawlayer "BORDER"
			edgeSize = borderThickness
		})
		self:SetBackdropColor(0, 0, 0, 0)
		self:SetBackdropBorderColor(unpack({0, 0, 1, 1}))
		self:SetSizeOfAuraFrames(E.db.ElvUIPvP.DrTracker[self.frameName].Size)
		self:DrPositioning()
	end
	return DRContainer
end
