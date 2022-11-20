local module = _G["BlinkHealthTextModule"]

-------------------------------------------------------------------------------
-- WOW APIs/variables
-------------------------------------------------------------------------------

local GetLocale, Enum = GetLocale, Enum
local UnitClass, UnitPower, UnitPowerType = UnitClass, UnitPower, UnitPowerType
local GetSpecialization = GetSpecialization
local GetSpellTexture = GetSpellTexture
local select = select


-------------------------------------------------------------------------------
-- local variables
-------------------------------------------------------------------------------

if select(2, UnitClass("player")) ~= "ROGUE" or not module then return end

local loaded = false
local ComboSkill = 45 -- 주력 콤보스킬 기력
local FinishSkill = 35 -- 주력 마무리스킬 기력

local L_ROGUE_CONFIG = "Rogue Setting"
local L_USE_ROGUE_ACTIVATED_SPELL = "Displays the spell icons when activating effect."
local L_SWITCH_COMBO_POSITION = "Location of Combo points"
local L_SWITCH_COMBO_POSITION_TT = "Sets the location of the combo point next to the Player or Target."
local L_SWITCH_COMBO_POSITION_PLAYER = "Player"
local L_SWITCH_COMBO_POSITION_TARGET = "Target"

-- koKR locale
if GetLocale() == "koKR" then
    L_ROGUE_CONFIG = "도적 설정"
    L_USE_ROGUE_ACTIVATED_SPELL = "전문화별 발동 효과 발동시 아이콘을 표시합니다."
    L_SWITCH_COMBO_POSITION = "연계수치 위치 설정"
    L_SWITCH_COMBO_POSITION_TT = "연계수치의 위치를 플레이어 또는 대상 옆으로 설정합니다."
    L_SWITCH_COMBO_POSITION_PLAYER = "플레이어옆"
    L_SWITCH_COMBO_POSITION_TARGET = "대상옆"
end

local activation_spells = {}

local defaultDB = {
    db_ver = 1.1,
    use_activated_spells = true,
    rg_combo_position = "target",
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
            text = L_ROGUE_CONFIG,
            fontobject = "QuestTitleFont",
            r = 1,
            g = 0.82,
            b = 0,
            justifyH = "LEFT",
        }

        self:AddMiscConfig {
            type = "toggle",
            text = L_USE_ROGUE_ACTIVATED_SPELL,
            tooltip = L_USE_ROGUE_ACTIVATED_SPELL,
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
            type = "radio",
            text = L_SWITCH_COMBO_POSITION,
            tooltip = L_SWITCH_COMBO_POSITION_TT,
            values = {
                {
                    text = L_SWITCH_COMBO_POSITION_PLAYER,
                    value = "player",
                },
                {
                    text = L_SWITCH_COMBO_POSITION_TARGET,
                    value = "target",
                },
            },
            get = function()
                return self.addon.db.class.rg_combo_position or "target"
            end,
            set = function(value)
                self.addon.db.class.rg_combo_position = value
            end,
            col = 2,
            --disable = not module.addon.db.useModule,
        }
    end
    loaded = true
end

function module:update()
    if GetSpecialization() == 1 then
        ComboSkill = 55 -- 절단 GetSpellInfo(1329) -- 절단
    elseif GetSpecialization() == 2 then
        ComboSkill = 50 -- 사브르 베기 GetSpellInfo(200758) -- 사악한 일격
    elseif GetSpecialization() == 3 then
        ComboSkill = 35 -- 기습 GetSpellInfo(16511) -- 과다출혈
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
    if icon then
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

function module:getComboText()
    local combo = UnitPower("player", Enum.PowerType.ComboPoints)
    local comboText, r, g, b = "", 1.0, 0.5, 0.1

    if (combo <= 0) then
        return ""
    end

    if (UnitPowerType("player") == 3) then -- energy
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
    end
    return (":|cff%02x%02x%02x%d|r"):format(r * 255, g * 255, b * 255, combo)
end

function module:getPlayerText()
    if self.addon.db.class.rg_combo_position == "player" then
        local text = self:getComboText()
        return text
    end
end

-- function module:getTargetText()
-- end

function module:getTargetText()
    local text = ""

    if not self.addon.db.class.rg_combo_position or self.addon.db.class.rg_combo_position == "target" then
        text = self:getComboText()
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
