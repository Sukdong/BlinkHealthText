local module = _G["BlinkHealthTextModule"]

-------------------------------------------------------------------------------
-- WOW APIs/variables
-------------------------------------------------------------------------------

local GetLocale, AuraUtil = GetLocale, AuraUtil
local UnitClass, UnitAura = UnitClass, UnitAura
local UnitExists = UnitExists
local GetRuneCooldown = GetRuneCooldown
local select, GetTime = select, GetTime

-------------------------------------------------------------------------------
-- modules
-------------------------------------------------------------------------------

if select(2, UnitClass("player")) ~= "DEATHKNIGHT" or not module then return end

local tcopy
local loaded = false

local L_DK_CONFIG = "Deathknight Setting"
local L_USE_RUNE = "Displays the currently remaining runes."
local L_USE_DK_ACTIVATED_SPELL = "Displays the spell icons when activating effect."
local L_USE_DISEASE = "|TInterface\\Icons\\spell_yorsahj_bloodboil_purpleoil:20|tDisplays the number of Festering Wound in the target."
local L_USE_BONE_SHIELD = "|TInterface\\Icons\\ability_deathknight_boneshield:20|tDisplays the number of Bone Shield."
local L_SPELL_FESTERING_WOUND = "Festering Wound"
local L_SPELL_BONE_SHIELD = "Bone Shield"
--local L_USE_SCOURGE_OF_WORLDS = "|TInterface\\Icons\\artifactability_unholydeathknight_flagellation:20|t세계의 스컬지(부정 유물 대재앙) 발동시 표시합니다."

-- koKR locale
if GetLocale() == "koKR" then
    L_DK_CONFIG = "죽음의 기사 설정"
    L_USE_RUNE = "룬 개수 표시"
    L_USE_RUNE_TOOLTIP = "현재 남아있는 룬을 표시합니다."
    L_USE_DK_ACTIVATED_SPELL = "발동 효과 아이콘 표시"
    L_USE_DK_ACTIVATED_SPELL_TOOLTIP = "전문화별 발동 효과 발동시 아이콘을 표시합니다."
    L_USE_DISEASE = "|TInterface\\Icons\\spell_yorsahj_bloodboil_purpleoil:20|t 고름 상처 개수 표시"
    L_USE_DISEASE_TOOLTIP = "고름 상처 효과의 개수를 표시합니다."
    L_USE_BONE_SHIELD = "|TInterface\\Icons\\ability_deathknight_boneshield:20|t 뼈의 보호막 개수 표시"
    L_USE_BONE_SHIELD_TOOLTIP = "뼈의 보호막 효과의 개수를 표시합니다."
    L_SPELL_FESTERING_WOUND = "고름 상처"
    L_SPELL_BONE_SHIELD = "뼈의 보호막"
end

local text
local name, icon, count, debufType, duration, expirationTime
local size
local usable
local aCount
local activation_spells = {}

local defaultDB = {
    db_ver = 1.3,
    use_rune = true,
    use_activated_spells = true,
    --	use_scourge_of_worlds = false,
}


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

    if self.addon.db.class.use_rune then
        self:EnableRune()
    end

    if self.addon.db.class.use_activated_spells then
        module:EnableActivatedSpell()
    end

    if loaded == false then
        self.addon.guiConfig:CreateLabel(L_DK_CONFIG)
        self.addon.guiConfig:CreateCheckBox({
            label = L_USE_RUNE,
            tooltip = L_USE_RUNE_TOOLTIP,
            key = "use_rune",
            defaultValue = Settings.Default.True,
            get = function()
                return module.addon.db.class.use_rune
            end,
            set = function(value)
                module.addon.db.class.use_rune = value
                if module.addon.db.class.use_rune then
                    module:EnableRune()
                else
                    module:DisableRune()
                end
            end,
        })
        self.addon.guiConfig:CreateCheckBox({
            label = L_USE_DK_ACTIVATED_SPELL,
            tooltip = L_USE_DK_ACTIVATED_SPELL_TOOLTIP,
            key = "use_activated_spells",
            defaultValue = Settings.Default.True,
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
        })

        loaded = true
    end
end

function module:RUNE_POWER_UPDATE(...)
    self:updateRunes()
end

--module.RUNE_TYPE_UPDATE = module.RUNE_POWER_UPDATE

function module:SPELL_ACTIVATION_OVERLAY_GLOW_SHOW(...)
    local spellID = ...;
    local icon = C_Spell.GetSpellTexture(spellID)
    if icon and IsSpellKnown(spellID) and IsPlayerSpell(spellID) then
        if not activation_spells[icon] then
            activation_spells[icon] = 0
        end
        activation_spells[icon] = activation_spells[icon] + 1
    end
end

function module:SPELL_ACTIVATION_OVERLAY_GLOW_HIDE(...)
    local spellID = ...;
    local icon = C_Spell.GetSpellTexture(spellID)
    if icon and activation_spells and activation_spells[icon] then
        activation_spells[icon] = activation_spells[icon] - 1
        if activation_spells[icon] < 0 then
            activation_spells[icon] = 0
        end
    end
end

function module:EnableRune()
    if not self.addon.playerFrame.runes then
        self.addon.playerFrame.runes = self.addon.playerFrame:CreateFontString(nil, "OVERLAY")
        self.addon.playerFrame.runes:SetFont(self.addon.db.font, self.addon.db.fontSizePower, self.addon.db.fontOutline)
        self.addon.playerFrame.runes:SetPoint("BOTTOM", self.addon.playerFrame.health, "TOP")
        self.addon.playerFrame.runes:SetAlpha(self.addon.db.unit.player.alpha)
        self.addon.playerFrame.runes:SetJustifyH("CENTER")
    end
    self.addon.playerFrame.runes:Show()
    self.addon.mainFrame:RegisterEvent("RUNE_POWER_UPDATE")
end

function module:DisableRune()
    if self.addon.playerFrame.runes then
        self.addon.playerFrame.runes:Hide()
    end
    self.addon.mainFrame:UnregisterEvent("RUNE_POWER_UPDATE")
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

function module:getTargetText()
    text = ""

    if self.addon.db.class.use_activated_spells then
        for texture, cnt in pairs(activation_spells) do
            if cnt > 0 then
                text = text .. (":|T%s:%d|t"):format(texture, self.addon.db.fontSizeHealth / 2)
            end
        end
    end

    return text
end

function module:updateRunes()
    local text = ""
    local runeReady
    for i = 1, 7 do
        _, _, runeReady = GetRuneCooldown(i)
        if runeReady then
            text = text .. "|TInterface\\PlayerFrame\\UI-PlayerFrame-Deathknight-SingleRune:12|t"
        end
    end
    self.addon.playerFrame.runes:SetText(text)
end
