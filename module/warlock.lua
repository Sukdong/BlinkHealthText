-------------------------------------------------------------------------------
-- WOW APIs/variables
-------------------------------------------------------------------------------

local UnitClass, UnitPower = UnitClass, UnitPower
local GetLocale, GetTalentInfo, GetSpecialization = GetLocale, GetTalentInfo, GetSpecialization
local IsPlayerSpell, GetSpellTexture = IsPlayerSpell, GetSpellTexture
local Enum = Enum
local select = select


-------------------------------------------------------------------------------
-- local variables
-------------------------------------------------------------------------------

local module = _G["BlinkHealthTextModule"]

local activation_spells = {}

if select(2, UnitClass("player")) ~= "WARLOCK" or not module then return end

local loaded = false
local L_WARLOCK_CONFIG = "Warlock Setting"
local L_USE_POWER = "Displays number of Soul Shards."
local L_USE_ACTIVATED_SPELL = "Displays the spell icons when activating effect."

-- koKR locale
if GetLocale() == "koKR" then
    L_USE_POWER = "영혼의 조각 갯수 표시하기"
    L_WARLOCK_CONFIG = "흑마법사 설정"
    L_USE_ACTIVATED_SPELL = "전문화별 발동 효과 발동시 아이콘을 표시합니다."
end

local text
local name, icon, count, debufType, duration, expirationTime
local size
local auraCount
local usable, nomana
local aCount
local updateAlterPower

local defaultDB = {
    db_ver = 1.0,
    use_activated_spells = true,
    use_power = true,
}
-------------------------------------------------------------------------------
-- local functions
-------------------------------------------------------------------------------

module.config = {
}

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

-- local function getSize(baseSize, expirationTime, duration)
-- 	local size = (expirationTime-GetTime()) / duration
-- 	if size < 0.3 then
-- 		size = baseSize * .8
-- 	elseif size < 0.6 then
-- 		size = baseSize * 1.0
-- 	else
-- 		size = baseSize * 1.2
-- 	end
-- 	return size / 2
-- end


-------------------------------------------------------------------------------
-- module functions
-------------------------------------------------------------------------------

function module:init()
    if self.addon.db then
        if not self.addon.db.class or not self.addon.db.class.db_ver or self.addon.db.class.db_ver < defaultDB.db_ver then
            self.addon.db.class = {}
            tcopy(self.addon.db.class, defaultDB)
        end
    end

    if self.addon.db.class.use_activated_spells then
        module:EnableActivatedSpell()
    end

    self.addon.mainFrame:RegisterEvent("PLAYER_ALIVE")
    self.addon.mainFrame:RegisterEvent("LEARNED_SPELL_IN_TAB")
    self.addon.mainFrame:RegisterEvent("CHARACTER_POINTS_CHANGED")

    self:update()

    if loaded == false then
        self:AddMiscConfig {
            type = "description",
            text = L_WARLOCK_CONFIG,
            fontobject = "QuestTitleFont",
            r = 1,
            g = 0.82,
            b = 0,
            justifyH = "LEFT",
        }
        self:AddMiscConfig {
            type = "toggle",
            text = L_USE_ACTIVATED_SPELL,
            tooltip = L_USE_ACTIVATED_SPELL,
            get = function()
                return self.addon.db.class.use_activated_spells
            end,
            set = function(value)
                self.addon.db.class.use_activated_spells = value
                if self.addon.db.class.use_activated_spells then
                    module:EnableActivatedSpell()
                else
                    module:DisableActivatedSpell()
                end
            end,
        }
        self:AddMiscConfig {
            type = "toggle",
            text = L_USE_POWER,
            tooltip = L_USE_POWER,
            get = function()
                return self.addon.db.class.use_power
            end,
            set = function(value)
                self.addon.db.class.use_power = value
                if self.addon.db.class.use_power then
                    module:EnablePower()
                else
                    module:DisablePower()
                end
            end,
            disable = not module.addon.db.useModule,
        }

    end
    loaded = true
end

function module:update()
    self.primary = GetSpecialization()
    for auraName, t in pairs(self.config) do
        if t.talent and t.talent > 0 then
            local name, iconTexture, tier, column, selected, available = GetTalentInfo(t.talent);
            if name and available then
                self.config[auraName].use = true
                if t.event and self.addon and self.addon.mainFrame then
                    self.addon.mainFrame:RegisterEvent(t.event)
                end
            end
        else
            self.config[auraName].use = false
            if IsPlayerSpell(t.spellid) then
                self.config[auraName].use = true
                if t.event and self.addon and self.addon.mainFrame then
                    self.addon.mainFrame:RegisterEvent(t.event)
                end
            end
        end
    end
    if self.addon.db.class.use_power then
        self:EnablePower()
    else
        self:DisablePower()
    end

end

function module:LEARNED_SPELL_IN_TAB(...)
    self:update()
end

module.CHARACTER_POINTS_CHANGED = module.LEARNED_SPELL_IN_TAB
function module:PLAYER_ALIVE(...)
    self.addon.mainFrame:UnregisterEvent("PLAYER_ALIVE")
    self:update()
end

function module:EnableActivatedSpell()
    activation_spells = {}
    self.addon.mainFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
    self.addon.mainFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
end

function module:DisableActivatedSpell()
    activation_spells = {}
    self.addon.mainFrame:UnregisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
    self.addon.mainFrame:UnregisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
end

function module:SPELL_ACTIVATION_OVERLAY_GLOW_SHOW(...)
    local spellID, texture, positions, scale, r, g, b = ...;
    local icon = GetSpellTexture(spellID)
    if icon and IsSpellKnown(spellID) and IsPlayerSpell(spellID) then
        if not activation_spells[icon] then
            activation_spells[icon] = 0
        end
        activation_spells[icon] = activation_spells[icon] + 1
    end
end

function module:SPELL_ACTIVATION_OVERLAY_GLOW_HIDE(...)
    local spellID = ...;
    local icon = GetSpellTexture(spellID)
    if icon and activation_spells and activation_spells[icon] then
        activation_spells[icon] = activation_spells[icon] - 1
        if activation_spells[icon] < 0 then
            activation_spells[icon] = 0
        end
    end
end

function module:EnablePower()
    if not self.addon.playerFrame.altPower then
        self.addon.playerFrame.altPower = self.addon.playerFrame:CreateFontString(nil, "OVERLAY")
        self.addon.playerFrame.altPower:SetFont(self.addon.db.font, self.addon.db.fontSizePower * 0.75,
            self.addon.db.fontOutline)
        self.addon.playerFrame.altPower:SetPoint("BOTTOM", self.addon.playerFrame.health, "TOP")
        self.addon.playerFrame.altPower:SetAlpha(self.addon.db.unit.player.alpha)
        self.addon.playerFrame.altPower:SetJustifyH("CENTER")
    end
    self.addon.playerFrame.altPower:Show()
    self:RegisterUpdators(updateAlterPower)
end

function module:DisablePower()
    if self.addon.playerFrame.altPower then
        self.addon.playerFrame.altPower:Hide()
    end
    self:UnregisterUpdators(updateAlterPower)
end

function updateAlterPower()
    local df = UnitPower("player", Enum.PowerType.SoulShards)
    local text = ""
    if df > 0 then
        text = ("|cff%02x%02x%02x%d|r"):format(127, 82, 127, df)
        module.addon.playerFrame.altPower:SetText(text)
    else
        module.addon.playerFrame.altPower:SetText("")
    end
end

--function module:getPlayerText()
--	if self.addon.db.class.use_power and self.primary == SPEC_WARLOCK_AFFLICTION then
--		if ( IsPlayerSpell(WARLOCK_SOULBURN) ) then
--			local shards = UnitPower( "player", Enum.PowerType.SoulShards )
--			if shards > 0 then
--				return (":|cff%02x%02x%02x%d|r"):format(127, 82, 127, shards)
--			end
--		end
--	end
--	return ""
--end

function module:getTargetText()
    local text = ""

    if self.addon.db.class.use_activated_spells then
        for texture, cnt in pairs(activation_spells) do
            if cnt > 0 then
                text = text .. (":|T%s:%d|t"):format(texture, self.addon.db.fontSizeHealth / 2)
            end
        end
    end

    return text
end
