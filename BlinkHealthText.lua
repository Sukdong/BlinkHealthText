-------------------------------------------------------------------------------
--
--  Mod Name : BlinkHealthText 3.2
--  Author   : Blink
--  Date     : 2005/05/10
--  LastUpdate : 2018/07/22
--
-------------------------------------------------------------------------------

local addonName = "BlinkHealthText"
local addon = {}
_G[addonName] = addon

addon.inCombat = false
addon.db = {}
addon.unitFrame = {}
addon.fadingFrame = {}
addon.flashingFrame = {}


-------------------------------------------------------------------------------
-- locale load
-------------------------------------------------------------------------------

local L = _G["BlinkHealthTextLocale"]

-------------------------------------------------------------------------------
-- WOW APIs/variables
-------------------------------------------------------------------------------

local CreateFrame, AbbreviateLargeNumbers = CreateFrame, AbbreviateLargeNumbers
local UnitIsVisible, UnitHealth, UnitHealthMax = UnitIsVisible, UnitHealth, UnitHealthMax
local UnitGetTotalAbsorbs, UnitPowerType, UnitHasVehicleUI = UnitGetTotalAbsorbs, UnitPowerType, UnitHasVehicleUI
local UnitIsDead, UnitIsGhost, UnitExists = UnitIsDead, UnitIsGhost, UnitExists
local UnitIsConnected, UnitPower, UnitPowerMax = UnitIsConnected, UnitPower, UnitPowerMax
local GetRaidTargetIndex = GetRaidTargetIndex
local UIFrameFade, UIFrameFlash, UIFrameFadeRemoveFrame = UIFrameFade, UIFrameFlash, UIFrameFadeRemoveFrame
local UIParent = UIParent
local select = select

-------------------------------------------------------------------------------
-- local variables
-------------------------------------------------------------------------------

local FadeOutTime = .35
local UPDATE_INTERVAL = 0.1

local tcopy
-- local FrameOnEvent
-- local FrameOnUpdate
local MainFrameOnEvent

-- local class = select(2, UnitClass("player"))

local module = _G["BlinkHealthTextModule"]

local RaidIconList = {
    "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:",
    "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2:",
    "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:",
    "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_4:",
    "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5:",
    "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_6:",
    "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:",
    "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:",
}

local defaultDB = {
    db_ver = 1.22,
    enable = true,
    font = "Fonts\\K_Pagetext.TTF",
    fontSizeHealth = 28,
    fontSizePower = 20,
    fontSizeHealthForPet = 14,
    fontSizePowerForPet = 10,
    fontOutline = "THICKOUTLINE",
    posX = 170,
    posY = 10,
    predictedText = true,
    useModule = true,
    showRaidIcons = true,
    unit = {
        player = {
            hideOOC = true,
            alpha = 1.0,
            realValue = false,
            realPowerValue = true,
        },
        target = {
            hideOOC = true,
            alpha = 1.0,
            realValue = false,
            realPowerValue = true,
        },
        pet = {
            hideOOC = true,
            alpha = 1.0,
            realValue = false,
            realPowerValue = true,
        },
        --[[
		vehicle = {
			hideOOC = true,
			alpha = 1.0,
			realValue = false,
			realPowerValue = true,
		},
		]]
    },
    powerColor = {
        -- mana
        [0] = {
            r = 0,
            g = 0.6,
            b = 1.0,
        },
        -- rage
        [1] = {
            r = 1.0,
            g = 0.2,
            b = 0.2,
        },
        -- focus
        [2] = {
            r = 1.0,
            g = 0.6,
            b = 0.2,
        },
        -- energy
        [3] = {
            r = 1.0,
            g = 1.0,
            b = 0.2,
        },
        -- COMBO_POINTS
        [4] = {
            r = 1.00,
            g = 0.96,
            b = 0.41
        },
        -- runes
        [5] = {
            r = 0.5,
            g = 0.5,
            b = 0.5,
        },
        -- runic power
        [6] = {
            r = 0.0,
            g = 0.82,
            b = 1.0,
        },
        -- SOUL_SHARDS
        [7] = {
            r = 0.50,
            g = 0.32,
            b = 0.55
        },
        -- LUNAR_POWER
        [8] = {
            r = 0.75,
            g = 0.75,
            b = 1.0,
        },
        -- HOLY_POWER
        [9] = {
            r = 0.95,
            g = 0.90,
            b = 0.60
        },
        -- ALTERNATE_POWER
        [10] = {
            r = 0.90,
            g = 0.90,
            b = 0.90
        },
        -- MAELSTROM
        [11] = {
            r = 0.00,
            g = 0.50,
            b = 1.00
        },
        -- CHI
        [12] = {
            r = 0.71,
            g = 1.0,
            b = 0.92
        },
        -- INSANITY
        [13] = {
            r = 0.40,
            g = 0,
            b = 0.80
        },
        -- fury
        [17] = {
            r = 0.788,
            g = 0.259,
            b = 0.992,
        },
        -- pain
        [18] = {
            r = 255 / 255,
            g = 156 / 255,
            b = 0,
        },
        -- AMMOSLOT
        ["AMMOSLOT"] = {
            r = 0.80,
            g = 0.60,
            b = 0.00,
        },
        -- FUEL
        ["FUEL"] = {
            r = 0.0,
            g = 0.55,
            b = 0.5,
        },
        -- STAGGER
        ["STAGGER"] = {
            { r = 0.52, g = 1.0, b = 0.52 },
            { r = 1.0, g = 0.98, b = 0.72 },
            { r = 1.0, g = 0.42, b = 0.42 },
        },
    },
}

local fonts = {
    {
        text = "퀘스트글꼴",
        value = "Fonts\\K_Pagetext.TTF",
        font = "Fonts\\K_Pagetext.TTF",
        r = 1,
        g = .82,
        b = 0,
        size = 16,
    },
    {
        text = "기본글꼴",
        value = "Fonts\\2002.TTF",
        font = "Fonts\\2002.TTF",
        r = 1,
        g = .82,
        b = 0,
        size = 16,
    },
    {
        text = "데미지글꼴",
        value = "Fonts\\K_Damage.TTF",
        font = "Fonts\\K_Damage.TTF",
        r = 1,
        g = .82,
        b = 0,
        size = 16,
    },
    --[[
	더 추가하고싶은 폰트가 있다면 여기에 다음 형식으로 넣으시면됩니다.
	{
		text = "화면에 표시할 텍스트",
		value = "설정값에 저장될 값",
		font = (생략가능) text부분의 글꼴지정,
		r = (생략가능) text부분의 글자의 red색상값 0~1,
		g = (생략가능) text부분의 글자의 green색상값 0~1,
		b = (생략가능) text부분의 글자의 blue색상값 0~1,
		a = (생략가능) text부분의 글자의 투명도 0~1,
		size = (생략가능) text의 글자크기,
	}
	]]
}

-- if LibStub and LibStub["libs"]["LibSharedMedia-3.0"] then
--     local SharedMedia = LibStub:GetLibrary("LibSharedMedia-3.0")
--     fonts = {}
--     local temp = SharedMedia:List("font")
--     for _, name in ipairs(temp) do
--         local font = { text = name, value = SharedMedia:Fetch("font", name), font = SharedMedia:Fetch("font", name),
--             r = 1, g = .82, b = 0, size = 16 }
--         table.insert(fonts, font)
--     end
-- end

function BlinkHealthTextOnUpdate(unitFrame, elapsed)
    unitFrame.timer = unitFrame.timer + elapsed
    if unitFrame.timer > UPDATE_INTERVAL then
        unitFrame.timer = 0
        if unitFrame.unit and UnitIsConnected(unitFrame.unit) then
            addon:DisplayHealthText(unitFrame.unit)
            addon:DisplayPowerText(unitFrame.unit)
            if addon.db.useModule then
                addon:DisplayText(unitFrame.unit)

                if module and module.ExtraUpdators then
                    module:ExtraUpdators(unitFrame.unit)
                end
            end

            --			local currHealth = UnitHealth(unitFrame.unit)
            --			if ( currHealth ~= unitFrame.healthValue ) then
            --				addon:DisplayHealthText(unitFrame.unit)
            --				unitFrame.healthValue = currHealth;
            --			end
            --
            --			local currPower = UnitPower(unitFrame.unit)
            --			if ( currPower ~= unitFrame.powerValue ) then
            --				addon:DisplayPowerText(unitFrame.unit)
            --				unitFrame.powerValue = currPower;
            --			end
            --			addon:DisplayText(unitFrame.unit)
        end
    end
end

-------------------------------------------------------------------------------
-- local functions
-------------------------------------------------------------------------------

function tcopy(to, from) -- "to" must be a table (possibly empty)
    for k, v in pairs(from) do
        if (type(v) == "table") then
            if not to then to = {} end
            to[k] = {}
            tcopy(to[k], v)
        else
            to[k] = v
        end
    end
end

local function FrameOnUpdate(unitFrame, elapsed)
    unitFrame.timer = unitFrame.timer + elapsed
    if unitFrame.timer > UPDATE_INTERVAL then
        unitFrame.timer = 0
        if unitFrame.unit and UnitIsConnected(unitFrame.unit) then
            addon:DisplayHealthText(unitFrame.unit)
            addon:DisplayPowerText(unitFrame.unit)
            if addon.db.useModule then
                addon:DisplayText(unitFrame.unit)

                if module and module.ExtraUpdators then
                    module:ExtraUpdators(unitFrame.unit)
                end
            end

            --			local currHealth = UnitHealth(unitFrame.unit)
            --			if ( currHealth ~= unitFrame.healthValue ) then
            --				addon:DisplayHealthText(unitFrame.unit)
            --				unitFrame.healthValue = currHealth;
            --			end
            --
            --			local currPower = UnitPower(unitFrame.unit)
            --			if ( currPower ~= unitFrame.powerValue ) then
            --				addon:DisplayPowerText(unitFrame.unit)
            --				unitFrame.powerValue = currPower;
            --			end
            --			addon:DisplayText(unitFrame.unit)
        end
    end
end

function addon:RegisterEvents(frame)
    --	if self.db.predictedText then
    --		frame:SetScript("OnUpdate", FrameOnUpdate)
    --	else
    --		-- health Event
    --		frame:RegisterEvent("UNIT_HEALTH")
    --		-- power Events
    --		frame:RegisterEvent("UNIT_MANA")
    --		frame:RegisterEvent("UNIT_RAGE")
    --		frame:RegisterEvent("UNIT_FOCUS")
    --		frame:RegisterEvent("UNIT_ENERGY")
    --		frame:RegisterEvent("UNIT_HAPPINESS")
    --		frame:RegisterEvent("UNIT_RUNIC_POWER")
    --	end
    --	-- health Event
    --	frame:RegisterEvent("UNIT_MAXHEALTH")
    --	-- power Events
    --	frame:RegisterEvent("UNIT_MAXMANA")
    --	frame:RegisterEvent("UNIT_MAXRAGE")
    --	frame:RegisterEvent("UNIT_MAXFOCUS")
    --	frame:RegisterEvent("UNIT_MAXENERGY")
    --	frame:RegisterEvent("UNIT_MAXHAPPINESS")
    --	frame:RegisterEvent("UNIT_MAXRUNIC_POWER")
    --	frame:RegisterEvent("UNIT_DISPLAYPOWER")
    --	frame:SetScript("OnEvent", FrameOnEvent)

    frame:SetScript("OnUpdate", FrameOnUpdate)
end

function addon:UnregisterEvents(frame)
    --	frame:UnregisterAllEvents()
    --	frame:SetScript("OnEvent", nil)
    frame:SetScript("OnUpdate", nil)
end

function addon:CreateFrames()
    -- player
    if not self.playerFrame then
        self.playerFrame = CreateFrame("Frame", "BHT_playerFrame", UIParent)
        self.playerFrame:ClearAllPoints()
        self.playerFrame:SetPoint("CENTER", -self.db.posX, self.db.posY)
        -- self.playerFrame:SetFrameStrata("BACKGROUND")
        -- self.playerFrame:SetFrameLevel(0)

        self.playerFrame.health = self.playerFrame:CreateFontString(nil, "OVERLAY")
        self.playerFrame.health:SetFont(self.db.font, self.db.fontSizeHealth, self.db.fontOutline)
        self.playerFrame.health:SetPoint("CENTER", self.playerFrame)
        self.playerFrame.health:SetAlpha(self.db.unit.player.alpha)
        self.playerFrame.health:SetJustifyH("CENTER")

        self.playerFrame.power = self.playerFrame:CreateFontString(nil, "OVERLAY")
        self.playerFrame.power:SetFont(self.db.font, self.db.fontSizePower, self.db.fontOutline)
        self.playerFrame.power:SetPoint("TOP", self.playerFrame.health, "BOTTOM")
        self.playerFrame.power:SetAlpha(self.db.unit.player.alpha)
        self.playerFrame.power:SetJustifyH("CENTER")

        self.playerFrame.text = self.playerFrame:CreateFontString(nil, "OVERLAY")
        self.playerFrame.text:SetFont(self.db.font, self.db.fontSizeHealth, self.db.fontOutline)
        self.playerFrame.text:SetPoint("LEFT", self.playerFrame.health, "RIGHT")
        self.playerFrame.text:SetAlpha(self.db.unit.player.alpha)
        self.playerFrame.text:SetJustifyH("LEFT")

        self.playerFrame:SetHeight(self.playerFrame.health:GetHeight() + self.playerFrame.power:GetHeight())
        self.playerFrame:SetWidth(150)

        self.playerFrame.timer = 0
        self.playerFrame.healthValue = 0
        self.playerFrame.powerValue = 0
        self.playerFrame.unit = "player"
        self.unitFrame["player"] = self.playerFrame
    end
    self:RegisterEvents(self.playerFrame)

    -- target
    if not self.targetFrame then
        self.targetFrame = CreateFrame("Frame", "BHT_targetFrame", UIParent)
        self.targetFrame:ClearAllPoints()
        self.targetFrame:SetPoint("CENTER", self.db.posX, self.db.posY)
        -- self.targetFrame:SetFrameStrata("BACKGROUND")
        -- self.targetFrame:SetFrameLevel(0)

        self.targetFrame.health = self.targetFrame:CreateFontString(nil, "OVERLAY")
        self.targetFrame.health:SetFont(self.db.font, self.db.fontSizeHealth, self.db.fontOutline)
        self.targetFrame.health:SetPoint("CENTER", self.targetFrame)
        self.targetFrame.health:SetAlpha(self.db.unit.target.alpha)
        self.targetFrame.health:SetJustifyH("CENTER")

        self.targetFrame.power = self.targetFrame:CreateFontString(nil, "OVERLAY")
        self.targetFrame.power:SetFont(self.db.font, self.db.fontSizePower, self.db.fontOutline)
        self.targetFrame.power:SetPoint("TOP", self.targetFrame.health, "BOTTOM")
        self.targetFrame.power:SetAlpha(self.db.unit.target.alpha)
        self.targetFrame.power:SetJustifyH("CENTER")

        self.targetFrame.text = self.targetFrame:CreateFontString(nil, "OVERLAY")
        self.targetFrame.text:SetFont(self.db.font, self.db.fontSizeHealth, self.db.fontOutline)
        self.targetFrame.text:SetPoint("LEFT", self.targetFrame.health, "RIGHT")
        self.targetFrame.text:SetAlpha(self.db.unit.target.alpha)
        self.targetFrame.text:SetJustifyH("LEFT")

        self.targetFrame:SetHeight(self.targetFrame.health:GetHeight() + self.targetFrame.power:GetHeight())
        self.targetFrame:SetWidth(150)

        self.targetFrame.timer = 0
        self.targetFrame.healthValue = 0
        self.targetFrame.powerValue = 0
        self.targetFrame.unit = "target"
        self.unitFrame["target"] = self.targetFrame
    end
    self:RegisterEvents(self.targetFrame)

    -- player's pet
    if not self.petFrame then
        self.petFrame = CreateFrame("Frame", "BHT_petFrame", UIParent)
        self.petFrame:ClearAllPoints()
        self.petFrame:SetPoint("TOPRIGHT", self.playerFrame.health, "TOPLEFT", 0, 0)
        -- self.petFrame:SetFrameStrata("BACKGROUND")
        -- self.petFrame:SetFrameLevel(0)

        self.petFrame.health = self.petFrame:CreateFontString(nil, "OVERLAY")
        self.petFrame.health:SetFont(self.db.font, self.db.fontSizeHealthForPet, self.db.fontOutline)
        self.petFrame.health:SetPoint("TOPRIGHT", self.petFrame, "TOPRIGHT")
        self.petFrame.health:SetAlpha(self.db.unit.pet.alpha)
        self.petFrame.health:SetJustifyH("CENTER")

        self.petFrame.power = self.petFrame:CreateFontString(nil, "OVERLAY")
        self.petFrame.power:SetFont(self.db.font, self.db.fontSizePowerForPet, self.db.fontOutline)
        self.petFrame.power:SetPoint("TOP", self.petFrame.health, "BOTTOM")
        self.petFrame.power:SetAlpha(self.db.unit.pet.alpha)
        self.petFrame.power:SetJustifyH("CENTER")

        self.petFrame.text = self.petFrame:CreateFontString(nil, "OVERLAY")
        self.petFrame.text:SetFont(self.db.font, self.db.fontSizeHealthForPet, self.db.fontOutline)
        self.petFrame.text:SetPoint("LEFT", self.petFrame.health, "RIGHT")
        self.petFrame.text:SetAlpha(self.db.unit.pet.alpha)
        self.petFrame.text:SetJustifyH("LEFT")

        self.petFrame:SetHeight(self.petFrame.health:GetHeight() + self.petFrame.power:GetHeight())
        self.petFrame:SetWidth(150)

        self.petFrame.timer = 0
        self.petFrame.healthValue = 0
        self.petFrame.powerValue = 0
        self.petFrame.unit = "pet"
        self.unitFrame["pet"] = self.petFrame
    end
    self:RegisterEvents(self.petFrame)
end

-------------------------------------------------------------------------------
-- functions
-------------------------------------------------------------------------------

function addon:getHealthColor(unit)
    local r, g, b = .7, .7, .7
    if (not UnitIsVisible(unit)) then
        return .7, .7, .7
    end

    if self.db.useModule then
        local exist
        if unit == "target" and module and module.getTargetHealthColor and type(module.getTargetHealthColor) ==
            'function' then
            exist, r, g, b = module:getTargetHealthColor()
            if exist then
                return r, g, b
            end
        elseif unit == "player" and module and module.getPlayerHealthColor and
            type(module.getPlayerHealthColor) == 'function' then
            exist, r, g, b = module:getPlayerHealthColor()
            if exist then
                return r, g, b
            end
        end
    end

    local perH = UnitHealth(unit) / UnitHealthMax(unit) * 100
    if (perH < 20) then -- Execute, Hammer of Wrath
        r, g, b = 1.0, 0.0, 0.2
    elseif (perH < 80 and perH >= 20) then
        r, g, b = 1.0, 1.0, 0.2
    else
        r, g, b = 0.0, 1.0, 0.2
    end
    -- 보호막이 있으면 색상변경
    local totalAbsorb = UnitGetTotalAbsorbs(unit) or 0
    if totalAbsorb > 0 then
        r, g, b = 0.4, 0.4, 0.97
    end
    return r, g, b
end

function addon:getPowerColor(unit)
    local powerType, powerToken, altR, altG, altB = UnitPowerType(unit)
    local info = self.db.powerColor[powerToken]

    if (not info) then
        if (not altR) then
            -- couldn't find a power token entry...default to indexing by power type or just mana if we don't have that either
            info = self.db.powerColor[powerType] or self.db.powerColor[0]
        else
            return altR, altG, altB;
        end
    end
    return info.r, info.g, info.b
end

function addon:DisplayText(unit)
    local frame
    if not unit then
        return
    end

    if self.unitFrame[unit] then
        frame = self.unitFrame[unit]
    else
        return
    end

    if not frame.text then
        return
    end

    if (frame and not frame:IsShown()) then
        return
    end

    local func
    local text = ""
    if module and self.db.useModule then
        if unit == "player" then
            func = module.getPlayerText
        elseif unit == "target" then
            func = module.getTargetText
        elseif unit == "pet" or unit == "vehicle" then
            func = module.getPetText
        end
        if func and type(func) == 'function' then
            if unit == "target" then
                if not UnitHasVehicleUI("player") then
                    text = self:DisplayRaidIcon("target") .. (func(module) or "")
                else
                    text = self:DisplayRaidIcon("target")
                end
            else
                text = func(module)
            end
            frame.text:SetText(text)
        else
            frame.text:SetText("")
        end
    else
        frame.text:SetText("")
    end
end

function addon:DisplayHealthText(unit)
    local frame
    if not unit then
        return
    end

    if self.unitFrame[unit] then
        frame = self.unitFrame[unit]
    else
        return
    end

    if (frame and not frame:IsShown()) then
        return
    end

    if UnitIsDead(unit) or UnitIsGhost(unit) then
        frame.health:SetTextColor(0.6, 0.6, 0.6)
        if UnitIsGhost(unit) then
            frame.health:SetText("Ghost")
            return
        else
            frame.health:SetText("Dead")
            return
        end
    elseif not UnitExists(unit) then
        frame:Hide()
        -- HideUIPanel(frame)
        return
    elseif not UnitIsConnected(unit) then
        frame.health:SetTextColor(0.6, 0.6, 0.6)
        frame.health:SetText("Offline")
        return
    end

    local ch, mh, perH, healthText = UnitHealth(unit), UnitHealthMax(unit), 0, ""
    local totalAbsorb = UnitGetTotalAbsorbs(unit) or 0

    perH = (ch + totalAbsorb) / mh * 100
    if unit == "player" and self.db.unit.player.realValue then
        healthText = AbbreviateLargeNumbers(ch)
    elseif unit == "pet" and self.db.unit.pet.realValue then
        healthText = AbbreviateLargeNumbers(ch)
    elseif unit == "vehicle" and self.db.unit.pet.realValue then -- @.@
        healthText = AbbreviateLargeNumbers(ch)
    elseif unit == "target" and self.db.unit.target.realValue then
        healthText = AbbreviateLargeNumbers(ch)
    else
        healthText = string.format("%d", perH)
    end

    local r, g, b = self:getHealthColor(unit)
    frame.health:SetTextColor(r, g, b)
    frame.health:SetText(healthText)
end

function addon:DisplayPowerText(unit)
    local frame
    if not unit then
        return
    end

    if self.unitFrame[unit] then
        frame = self.unitFrame[unit]
    else
        return
    end

    if (not frame:IsShown()) then
        return
    end
    local currValue, maxMana, perM, powerText = UnitPower(unit), UnitPowerMax(unit), 0, ""
    if (currValue <= 0 or maxMana <= 0) then
        powerText = ""
    else
        perM = currValue / maxMana * 100
        if unit == "player" and self.db.unit.player.realPowerValue then
            powerText = currValue
        elseif unit == "pet" and self.db.unit.pet.realPowerValue then
            powerText = currValue
        elseif unit == "vehicle" and self.db.unit.pet.realPowerValue then -- @.@
            powerText = currValue
        elseif unit == "target" and self.db.unit.target.realPowerValue then
            powerText = currValue
        else
            powerText = string.format("%d", perM)
        end
    end

    local r, g, b = self:getPowerColor(unit)
    frame.power:SetTextColor(r, g, b)
    frame.power:SetText(powerText)
end

function addon:DisplayRaidIcon(unit)
    if self.db.showRaidIcons then
        local icon = GetRaidTargetIndex(unit)
        if icon and RaidIconList[icon] then
            return RaidIconList[icon] .. "0|t"
        else
            return ""
        end
    else
        return ""
    end
end

-------------------------------------------------------------------------------
-- functions
-------------------------------------------------------------------------------

function addon:FrameFadeOut(frame, timeToFade, startAlpha, endAlpha)
    if not self.fadingFrame[frame] then
        return
    end
    local fadeInfo = {}
    fadeInfo.mode = "OUT"
    fadeInfo.timeToFade = timeToFade
    fadeInfo.startAlpha = startAlpha
    fadeInfo.endAlpha = endAlpha
    fadeInfo.finishedFunc = function()
        addon.fadingFrame[frame] = nil
        --[[
		if addon.db.enable then
			if frame == addon.playerFrame then
				if ( addon.db.alphaType == "Combat" and InCombatLockdown() ) or ( addon.db.alphaType == "Target" and UnitExists("target") ) then
					frame:SetAlpha(db.alphaPlayerB)
					return
				end
			elseif frame == targetFrame and UnitExists("target") then
				if ( db.alphaType == "Combat" and InCombatLockdown() ) or ( db.alphaType == "Target" and UnitExists("target") ) then
					frame:SetAlpha(db.alphaTargetB)
					return
				end
			elseif frame == petFrame and UnitExists("pet") then
				if ( db.alphaType == "Combat" and InCombatLockdown() ) or ( db.alphaType == "Target" and UnitExists("target") ) then
					frame:SetAlpha(db.alphaPetB)
					return
				end
			end
		end
		]]
        frame:Hide()
        -- HideUIPanel(frame)
        if frame.text then
            frame.text:SetText("")
        end
    end
    UIFrameFade(frame, fadeInfo)
end

function addon:FrameFlash(frame, fadeInTime, fadeOutTime, flashDuration, showWhenDone, flashInHoldTime, flashOutHoldTime)
    if not self.flashingFrame[frame] then
        return
    end
    UIFrameFlash(frame, fadeInTime, fadeOutTime, flashDuration, showWhenDone, flashInHoldTime, flashOutHoldTime)
end

function addon:FrameUpdate(unit)
    local db_unit = unit == "vehicle" and "player" or unit

    if not unit or not self.unitFrame[unit] then
        return
    end

    if not self.db.unit[db_unit] then
        return
    end
    if (not self.db.unit[db_unit].hideOOC or self.inCombat) and UnitExists(unit) then
        if not self.unitFrame[unit]:IsShown() then
            self.unitFrame[unit]:Show()
        end
        -- ShowUIPanel(self.unitFrame[unit])
        self.unitFrame[unit]:SetAlpha(self.db.unit[db_unit].alpha)
        self:DisplayHealthText(unit)
        self:DisplayPowerText(unit)
        if self.db.useModule then
            self:DisplayText(unit)
        end
        UIFrameFadeRemoveFrame(self.unitFrame[unit])
        self.fadingFrame[self.unitFrame[unit]] = nil
    else
        if self.unitFrame[unit]:IsShown() then
            self.fadingFrame[self.unitFrame[unit]] = true
            self:FrameFadeOut(self.unitFrame[unit], FadeOutTime, self.unitFrame[unit]:GetAlpha(), 0)
        end
    end
end

function addon:FrameFontUpdate()
    local healthSize, powerSize
    for unit, frame in pairs(self.unitFrame) do
        if frame == self.petFrame then
            healthSize, powerSize = self.db.fontSizeHealthForPet, self.db.fontSizePowerForPet
        else
            healthSize, powerSize = self.db.fontSizeHealth, self.db.fontSizePower
        end
        frame.health:SetFont(self.db.font, healthSize, self.db.fontOutline)
        frame.power:SetFont(self.db.font, powerSize, self.db.fontOutline)
        if frame.text then
            frame.text:SetFont(self.db.font, healthSize, self.db.fontOutline)
        end
    end
end

function addon:FramePositionUpdate()
    self.playerFrame:ClearAllPoints()
    self.playerFrame:SetPoint("CENTER", -self.db.posX, self.db.posY)

    self.targetFrame:ClearAllPoints()
    self.targetFrame:SetPoint("CENTER", self.db.posX, self.db.posY)
end

function addon:EnableAddon()
    self.mainFrame:RegisterEvent("UNIT_PET")
    self.mainFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    self.mainFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    self.mainFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    self.mainFrame:RegisterEvent("UNIT_ENTERED_VEHICLE")
    self.mainFrame:RegisterEvent("UNIT_ENTERING_VEHICLE")
    self.mainFrame:RegisterEvent("UNIT_EXITING_VEHICLE")
    self.mainFrame:RegisterEvent("UNIT_EXITED_VEHICLE")
    --self.mainFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
    self.mainFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    --mainFrame:RegisterEvent("PLAYER_ENTERING_WORLD")


    self:CreateFrames()
    self:FrameFontUpdate()
    self:FramePositionUpdate()

    if module then
        module.addon = self
        if module.init and type(module.init) == 'function' then
            module:init()
        end
    end

    self:FrameUpdate("player")
    self:FrameUpdate("target")
    if UnitHasVehicleUI("player") then
        self:FrameUpdate("vehicle")
    else
        self:FrameUpdate("pet")
    end
end

function addon:DisableAddon()
    self.mainFrame:UnregisterAllEvents()

    self.playerFrame:Hide()
    self:UnregisterEvents(self.playerFrame)
    self.playerFrame = nil

    self.targetFrame:Hide()
    self:UnregisterEvents(self.targetFrame)
    self.targetFrame = nil

    self.petFrame:Hide()
    self:UnregisterEvents(self.petFrame)
    self.petFrame = nil
end

function addon:GetMiscConfig()
    if module and module.GetMiscConfig then
        return module:GetMiscConfig()
    end
end

function addon:ShowHideMiscConfig()
    if module and module.GetMiscConfig then
        return #module:GetMiscConfig() > 0
    end
    return false
end

-- event handler --------------------------------------------------------------

function FrameOnEvent(self, event, ...)
    local unit = select(1, ...)
    if (unit ~= "player" and unit ~= "target" and unit ~= "pet" and unit ~= "vehicle") then
        return
    end
    if (event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH") then
        addon:DisplayHealthText(unit)
    else
        addon:DisplayPowerText(unit)
    end
end

function MainFrameOnEvent(self, event, ...)
    local arg1, arg2, arg3, arg4, arg5 = ...;
    if (event == "PLAYER_ENTERING_WORLD") then
        if not BlinkHealthTextDB or not BlinkHealthTextDB.db_ver or BlinkHealthTextDB.db_ver < defaultDB.db_ver then
            BlinkHealthTextDB = {}
            tcopy(BlinkHealthTextDB, defaultDB)
            print(L.DB_MIGRATION)
        end
        addon.db = BlinkHealthTextDB
        if addon.db.enable then
            addon:EnableAddon()
        end

        if module then
            module.addon = addon
            if module.init and type(module.init) == 'function' then
                module:init()
            end
        end

        -- addon:registGUI()

    elseif event == "PLAYER_TARGET_CHANGED" then
        addon:FrameUpdate("target")
    elseif event == "PLAYER_REGEN_DISABLED" then
        addon.inCombat = true
        addon:FrameUpdate("player")
        addon:FrameUpdate("target")
        if UnitHasVehicleUI("player") then
            addon:FrameUpdate("vehicle")
        else
            addon:FrameUpdate("pet")
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        addon.inCombat = false
        addon:FrameUpdate("player")
        addon:FrameUpdate("target")
        if UnitHasVehicleUI("player") then
            addon:FrameUpdate("vehicle")
        else
            addon:FrameUpdate("pet")
        end
    elseif event == "UNIT_PET" and arg1 == "player" then
        addon:FrameUpdate("player")
        addon:FrameUpdate("target")
        if UnitHasVehicleUI("player") then
            addon:FrameUpdate("vehicle")
        else
            addon:FrameUpdate("pet")
        end
    elseif event == "UNIT_ENTERED_VEHICLE" and arg1 == "player" then
        if (UnitHasVehicleUI("player")) then
            addon.petFrame.unit = "player"
            addon.playerFrame.unit = "vehicle"
            addon.unitFrame["pet"] = nil
            addon.unitFrame["player"] = addon.petFrame
            addon.unitFrame["vehicle"] = addon.playerFrame
            addon:FrameUpdate("player")
            addon:FrameUpdate("vehicle")
        end
    elseif event == "UNIT_EXITED_VEHICLE" then --and arg1 == "player" then
        addon.petFrame.unit = "pet"
        addon.playerFrame.unit = "player"
        addon.unitFrame["vehicle"] = nil
        addon.unitFrame["pet"] = addon.petFrame
        addon.unitFrame["player"] = addon.playerFrame
        addon:FrameUpdate("pet")
        addon:FrameUpdate("player")
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        if module and arg1 == "player" then
            module.addon = addon
            if module.init and type(module.init) == 'function' then
                module:init()
            end
        end
    end

    if module and addon.db.useModule then
        if module[event] then
            module[event](module, ...)
        end
    end
end

addon.mainFrame = CreateFrame("Frame")
addon.mainFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
addon.mainFrame:SetScript("OnEvent", MainFrameOnEvent)
