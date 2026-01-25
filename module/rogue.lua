local module = _G["BlinkHealthTextModule"]

-------------------------------------------------------------------------------
-- WOW APIs/variables
-------------------------------------------------------------------------------

local GetLocale, Enum = GetLocale, Enum
local UnitClass, UnitPower, UnitPowerType = UnitClass, UnitPower, UnitPowerType
local GetSpecialization = GetSpecialization
local select = select


-------------------------------------------------------------------------------
-- local variables
-------------------------------------------------------------------------------

if select(2, UnitClass("player")) ~= "ROGUE" or not module then return end

local loaded = false

local L_ROGUE_CONFIG = "Rogue Setting"
local L_USE_ROGUE_ACTIVATED_SPELL = "Displays the spell icons when activating effect."
local L_USE_ROGUE_ACTIVATED_SPELL_TOOLTIP = "Displays the spell icons when activating effect."
local L_SWITCH_COMBO_POSITION = "Location of Combo points"
local L_SWITCH_COMBO_POSITION_TT = "Sets the location of the combo point next to the Player or Target."
local L_SWITCH_COMBO_POSITION_PLAYER = "Player"
local L_SWITCH_COMBO_POSITION_TARGET = "Target"

-- koKR locale
if GetLocale() == "koKR" then
    L_ROGUE_CONFIG = "도적 설정"
    L_USE_ROGUE_ACTIVATED_SPELL = "발동 효과 아이콘 표시"
    L_USE_ROGUE_ACTIVATED_SPELL_TOOLTIP = "전문화별 발동 효과 발동시 아이콘을 표시합니다."
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

    if loaded == false then
        self.addon.guiConfig:CreateLabel(L_ROGUE_CONFIG)
        self.addon.guiConfig:CreateCheckBox({
            label = L_USE_ROGUE_ACTIVATED_SPELL,
            tooltip = L_USE_ROGUE_ACTIVATED_SPELL_TOOLTIP,
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
        self.addon.guiConfig:CreateDropdown({
            label = L_SWITCH_COMBO_POSITION,
            tooltip = L_SWITCH_COMBO_POSITION_TT,
            key = "rg_combo_position",
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
            varType = Settings.VarType.String,
            defaultValue = "target",
            get = function()
                return self.addon.db.class.rg_combo_position or "target"
            end,
            set = function(value)
                self.addon.db.class.rg_combo_position = value
            end,
        })
    end
    loaded = true
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
    local icon = C_Spell.GetSpellTexture(spellID)
    if icon then
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

function module:getComboText()
    local combo = UnitPower("player", Enum.PowerType.ComboPoints)
    local r, g, b = 1.0, 0.5, 0.1

    if (combo <= 0) then
        return ""
    end

    return (":|cff%02x%02x%02x%d|r"):format(r * 255, g * 255, b * 255, combo)
end

function module:getPlayerText()
    if self.addon.db.class.rg_combo_position == "player" then
        local text = self:getComboText()
        return text
    end
end

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
