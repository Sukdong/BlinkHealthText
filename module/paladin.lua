local module = _G["BlinkHealthTextModule"]

-------------------------------------------------------------------------------
-- WOW APIs/variables
-------------------------------------------------------------------------------

local GetLocale, Enum = GetLocale, Enum
local UnitClass, UnitPower = UnitClass, UnitPower
local GetSpecialization = GetSpecialization
local GetSpellTexture = GetSpellTexture
local select = select


-------------------------------------------------------------------------------
-- local variables
-------------------------------------------------------------------------------

if select(2, UnitClass("player")) ~= "PALADIN" or not module then return end

local tcopy
local config_added = false
local enabled_the_art_of_war = false


local L_PALADIN_CONFIG = "Paladin Setting"
local L_USE_COMBO = "Displays the number of Holy Powers."
local L_USE_3HOLY_POWER_SKILL = "|TInterface\\Icons\\Spell_Paladin_Templarsverdict:20|t Displays Templar's Verdict skills when there are more than 3 Holy Powers.(Retribution only)"
local L_USE_3HOLY_POWER_SKILL_DESC = "|TInterface\\Icons\\Spell_Paladin_Templarsverdict:20|t Displays Templar's Verdict skills when there are more than 3 Holy Powers."
local L_USE_PALADIN_ACTIVATED_SPELL = "Displays the spell icons when activating effect."

-- koKR locale
if GetLocale() == "koKR" then
    L_PALADIN_CONFIG = "성기사 설정"
    L_USE_COMBO = "성기사 신성한 힘의 갯수를 표시합니다."
    L_USE_3HOLY_POWER_SKILL = "|TInterface\\Icons\\Spell_Paladin_Templarsverdict:20|t 신성한 힘이 3개 이상일때 기사단의 선고 아이콘을 표시해줍니다.(징벌 전용)"
    L_USE_3HOLY_POWER_SKILL_DESC = "|TInterface\\Icons\\Spell_Paladin_Templarsverdict:20|t 신성한 힘이 3개 이상일때 기사단의 선고 아이콘을 표시해줍니다.(징벌 전용)"
    L_USE_PALADIN_ACTIVATED_SPELL = "전문화별 발동 효과 발동시 아이콘을 표시합니다."
end


local activation_spells = {}

local defaultDB = {
    db_ver = 1.1,
    use_combo = true,
    use_3holy_power_skill = true,
    use_activated_spells = true,
}

local alter_texture = {
    [85416] = "Interface\\Icons\\Spell_Holy_Avengersshield",
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

    if not config_added then
        self:AddMiscConfig {
            type = "description",
            text = L_PALADIN_CONFIG,
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
            text = L_USE_PALADIN_ACTIVATED_SPELL,
            tooltip = L_USE_PALADIN_ACTIVATED_SPELL,
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
            text = L_USE_3HOLY_POWER_SKILL,
            tooltip = L_USE_3HOLY_POWER_SKILL_DESC,
            get = function()
                if self.addon and self.addon.db then
                    return self.addon.db.class.use_3holy_power_skill
                end
                return
            end,
            set = function(value)
                self.addon.db.class.use_3holy_power_skill = value
            end,
            needRefresh = true,
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
    local spellID, texture, positions, scale, r, g, b = ...;
    local icon
    if alter_texture[spellID] then
        icon = alter_texture[spellID]
    else
        icon = GetSpellTexture(spellID)
    end
    if icon then
        if not activation_spells[icon] then
            activation_spells[icon] = 0
        end
        activation_spells[icon] = activation_spells[icon] + 1
    end
end

function module:SPELL_ACTIVATION_OVERLAY_GLOW_HIDE(...)
    local spellID = ...;
    local icon
    if alter_texture[spellID] then
        icon = alter_texture[spellID]
    else
        icon = GetSpellTexture(spellID)
    end
    if icon and activation_spells and activation_spells[icon] then
        activation_spells[icon] = activation_spells[icon] - 1
        if activation_spells[icon] < 0 then
            activation_spells[icon] = 0
        end
    end
end

function module:getPlayerText()
    if self.addon.db.class.use_combo then
        local numHolyPower = UnitPower("player", Enum.PowerType.HolyPower)
        if numHolyPower > 0 then
            return (":|cff%02x%02x%02x%d|r"):format(255, 255, 63, numHolyPower)
        end
    end
    return ""
end

function module:getTargetText()
    local text = ""
    local size = self.addon.db.fontSizeHealth
    local name, rank, icon, count, debufType, duration, expirationTime
    local r, g, b = 1, 1, 1

    if self.addon.db.class.use_activated_spells then
        for texture, cnt in pairs(activation_spells) do
            if cnt > 0 then
                text = text .. (":|T%s:%d|t"):format(texture, size / 2)
            end
        end
    end

    if self.addon.db.class.use_3holy_power_skill and GetSpecialization() == 3 then
        local numHolyPower = UnitPower("player", Enum.PowerType.HolyPower)
        if numHolyPower >= 3 then
            size = self.addon.db.fontSizeHealth / 2
            text = text .. (":|TInterface\\Icons\\Spell_Paladin_Templarsverdict:%d|t"):format(size)
        end
    end

    return text
end
