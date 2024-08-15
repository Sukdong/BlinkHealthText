local module = _G["BlinkHealthTextModule"]

-------------------------------------------------------------------------------
-- WOW APIs/variables
-------------------------------------------------------------------------------

local GetLocale, Enum, AuraUtil = GetLocale, Enum, AuraUtil
local UnitClass, UnitPower, UnitPowerType = UnitClass, UnitPower, UnitPowerType
local IsSpellKnown, IsPlayerSpell = IsSpellKnown, IsPlayerSpell
local select = select


-------------------------------------------------------------------------------
-- local variables
-------------------------------------------------------------------------------

if select(2, UnitClass("player")) ~= "DRUID" or not module then return end

local tcopy
local ComboSkill = 40
local FinishSkill = 30
local config_added = false
local activation_spells = {}

local L_DRUID_CONFIG = "Druid Setting"
local L_USE_COMBO = "Displays the number of combo points."
local L_USE_COMBO_BESIDE_PLAYER = "Displays the number of combo points next to the Player's health text.(default: beside target's health text)"
local L_USE_COMBO_BESIDE_PLAYER_DESC = "Check to display the number of combo points to the right of Player's health."
local L_USE_THRASH = "곰의 난타 디버프 개수를 표시합니다."
local L_USE_DRUID_ACTIVATED_SPELL = "Displays the spell icons when activating effect."

-- koKR locale
if GetLocale() == "koKR" then
    L_DRUID_CONFIG = "드루이드 설정"
    L_USE_COMBO = "표범의 연계점수를 표시합니다."
    L_USE_COMBO_BESIDE_PLAYER = "표범의 연계점수를 플레이어 체력 텍스트 옆에 표시합니다."
    L_USE_COMBO_BESIDE_PLAYER_DESC = "체크하면 표범의 연계점수를 플레이어 체력 텍스트 오른쪽에 표시합니다."
    L_USE_THRASH = "곰의 난타 디버프 개수를 표시합니다."
    L_USE_DRUID_ACTIVATED_SPELL = "전문화별 발동 효과 발동시 아이콘을 표시합니다."
end

local defaultDB = {
    db_ver = 1.1,
    use_combo = true,
    use_combo_beside_player = false,
    use_activated_spells = true,
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

local function getComboText()
    if (UnitPowerType("player") == 3) then -- energy
        local combo = UnitPower("player", Enum.PowerType.ComboPoints)
        local comboText, r, g, b = "", 1.0, 0.5, 0.1

        if (combo <= 0) then
            return ""
        end

        local mana = UnitPower("player")
        if (mana >= ComboSkill) then
            r = 0.1
            g = 1.0
            b = 0.1 -- green
        elseif (mana >= FinishSkill) then
            r = 0.0
            g = 0.39
            b = 0.88 -- blue
        else
            r = 1.0
            g = 0.1
            b = 0.1 -- red
        end
        return (":|cff%02x%02x%02x%d|r"):format(r * 255, g * 255, b * 255, combo)
    end
    return ""
end

local function getThrashCount()
    if (UnitPowerType("player") == 1) then -- rage

        local name, icon, count, debufType, duration, expirationTime = AuraUtil.FindAuraByName("난타", "target",
            "TARGET|HARMFUL") -- UnitAura("player", "집중된 분노", nil, "PLAYER|HELPFUL")
        local r, g, b = 1.0, 0.5, 0.1

        if count and count > 0 then
            return (":|cff%02x%02x%02x%d|r"):format(r * 255, g * 255, b * 255, count)
        end
    end
    return ""
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

    if self.addon.db.class.use_activated_spells then
        module:EnableActivatedSpell()
    end

    if not config_added then
        self:AddMiscConfig {
            type = "description",
            text = L_DRUID_CONFIG,
            fontobject = "QuestTitleFont",
            r = 1,
            g = 0.82,
            b = 0,
            justifyH = "LEFT",
        }
        self:AddMiscConfig {
            type = "toggle",
            text = L_USE_COMBO,
            tooltip = L_USE_COMBO,
            get = function()
                if self.addon and self.addon.db then
                    return self.addon.db.class.use_combo
                end
                return
            end,
            set = function(value)
                self.addon.db.class.use_combo = value
            end,
            needRefresh = true,
        }
        self:AddMiscConfig {
            type = "toggle",
            depth = 1,
            text = L_USE_COMBO_BESIDE_PLAYER,
            tooltip = L_USE_COMBO_BESIDE_PLAYER_DESC,
            get = function()
                if self.addon and self.addon.db then
                    return self.addon.db.class.use_combo_beside_player
                end
                return
            end,
            set = function(value)
                self.addon.db.class.use_combo_beside_player = value
            end,
            disable = function()
                return not self.addon.db.class.use_combo
            end,
            needRefresh = true,
        }
        self:AddMiscConfig {
            type = "toggle",
            text = L_USE_THRASH,
            tooltip = L_USE_THRASH,
            get = function()
                if self.addon and self.addon.db then
                    return self.addon.db.class.use_thrash
                end
                return
            end,
            set = function(value)
                self.addon.db.class.use_thrash = value
            end,
            needRefresh = true,
        }
        self:AddMiscConfig {
            type = "toggle",
            text = L_USE_DRUID_ACTIVATED_SPELL,
            tooltip = L_USE_DRUID_ACTIVATED_SPELL,
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
        config_added = true
    end
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

function module:getPlayerText()
    local text = ""

    if self.addon.db.class.use_combo and self.addon.db.class.use_combo_beside_player then
        text = text .. getComboText()
    end

    return text
end

function module:getTargetText()
    local text = ""
    -- local m_cat, m_bear, aura, rank, icon, count, debufType, duration, expirationTime
    -- local size

    if self.addon.db.class.use_combo and not self.addon.db.class.use_combo_beside_player then
        text = getComboText()
    end

    if self.addon.db.class.use_thrash and not self.addon.db.class.use_combo_beside_player then
        text = text .. getThrashCount()
    end

    if self.addon.db.class.use_activated_spells then
        for texture, cnt in pairs(activation_spells) do
            if cnt > 0 then
                text = text .. (":|T%s:%d|t"):format(texture, self.addon.db.fontSizeHealth / 2)
            end
        end
    end

    return text
end
