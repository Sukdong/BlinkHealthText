local module = _G["BlinkHealthTextModule"]

-------------------------------------------------------------------------------
-- WOW APIs/variables
-------------------------------------------------------------------------------

local GetLocale, AuraUtil = GetLocale, AuraUtil
local UnitClass, UnitAura = UnitClass, UnitAura
local GetSpellTexture = GetSpellTexture
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
    L_USE_RUNE = "현재 남아있는 룬을 표시합니다."
    L_USE_DK_ACTIVATED_SPELL = "전문화별 발동 효과 발동시 아이콘을 표시합니다."
    L_USE_DISEASE = "|TInterface\\Icons\\spell_yorsahj_bloodboil_purpleoil:20|t고름 상처 효과의 갯수를 표시합니다."
    L_USE_BONE_SHIELD = "|TInterface\\Icons\\ability_deathknight_boneshield:20|t뼈의 보호막 효과의 갯수를 표시합니다."
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
    use_disease = true,
    use_bone_shield = true,
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

local function getSize(baseSize, expirationTime, duration)
    local size = (expirationTime - GetTime()) / duration
    if size < 0.3 then
        size = baseSize * .8
    elseif size < 0.6 then
        size = baseSize * 1.0
    else
        size = baseSize * 1.2
    end
    return size / 2
end

local function diseaseUpdator(unit, f2)
    if not UnitExists("target") then
        f2:SetText("")
        return
    end
    name, icon, count = AuraUtil.FindAuraByName(L_SPELL_FESTERING_WOUND, "target", "PLAYER|HARMFUL")

    if count and count > 0 then
        f2:SetText(count)
    else
        f2:SetText("")
    end
end

local function boneShieldUpdator(unit, f1)

    name, icon, count = AuraUtil.FindAuraByName(L_SPELL_BONE_SHIELD, "player", "PLAYER|HELPFUL")

    if count and count > 0 then
        f1:SetText(count)
    else
        f1:SetText("")
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

    if self.addon.db.class.use_bone_shield then
        self:EnableBoneShield()
    end

    if self.addon.db.class.use_disease then
        self:EnableDisease()
    end

    if loaded == false then
        self:AddMiscConfig {
            type = "description",
            text = L_DK_CONFIG,
            fontobject = "QuestTitleFont",
            r = 1,
            g = 0.82,
            b = 0,
            justifyH = "LEFT",
        }
        self:AddMiscConfig {
            type = "toggle",
            text = L_USE_RUNE,
            tooltip = L_USE_RUNE,
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
        }
        self:AddMiscConfig {
            type = "toggle",
            text = L_USE_DK_ACTIVATED_SPELL,
            tooltip = L_USE_DK_ACTIVATED_SPELL,
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
            text = L_USE_BONE_SHIELD,
            tooltip = L_USE_BONE_SHIELD,
            get = function()
                return module.addon.db.class.use_bone_shield
            end,
            set = function(value)
                module.addon.db.class.use_bone_shield = value
                if module.addon.db.class.use_bone_shield then
                    module:EnableBoneShield()
                else
                    module:DisableBoneShield()
                end
            end,
        }
        self:AddMiscConfig {
            type = "toggle",
            text = L_USE_DISEASE,
            tooltip = L_USE_DISEASE,
            get = function()
                return module.addon.db.class.use_disease
            end,
            set = function(value)
                module.addon.db.class.use_disease = value
                if module.addon.db.class.use_disease then
                    module:EnableDisease()
                else
                    module:DisableDisease()
                end
            end,
        }
        --		self:AddMiscConfig{
        --			type = "toggle",
        --			text = L_USE_SCOURGE_OF_WORLDS,
        --			tooltip = L_USE_SCOURGE_OF_WORLDS,
        --			get = function ()
        --				return module.addon.db.class.use_scourge_of_worlds
        --			end,
        --			set = function (value)
        --				module.addon.db.class.use_scourge_of_worlds = value
        --			end,
        --		}

        loaded = true
    end
end

function module:RUNE_POWER_UPDATE(...)
    self:updateRunes()
end

--module.RUNE_TYPE_UPDATE = module.RUNE_POWER_UPDATE

function module:SPELL_ACTIVATION_OVERLAY_GLOW_SHOW(...)
    local spellID = ...;
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

function module:getAuraTypeCount(unit, auraType, filter)
    if not UnitExists(unit) then return end

    local i = 1
    aCount = 0

    name, icon, count, debufType, duration, expirationTime = UnitAura(unit, i, filter)
    while name do
        if debufType == auraType then
            if count > 0 then
                aCount = aCount + count
            else
                aCount = aCount + 1
            end
        end
        i = i + 1
        name, icon, count, debufType, duration, expirationTime = UnitAura(unit, i, filter)
    end
    return aCount
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
    --self.addon.mainFrame:RegisterEvent("RUNE_TYPE_UPDATE")
end

function module:DisableRune()
    if self.addon.playerFrame.runes then
        self.addon.playerFrame.runes:Hide()
    end
    self.addon.mainFrame:UnregisterEvent("RUNE_POWER_UPDATE")
    --self.addon.mainFrame:UnregisterEvent("RUNE_TYPE_UPDATE")
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

function module:EnableBoneShield()
    --print("EnableBoneShield")
    if not self.addon.playerFrame.bone_shield then
        self.addon.playerFrame.bone_shield = self.addon.playerFrame:CreateFontString(nil, "OVERLAY")
        self.addon.playerFrame.bone_shield:SetFont(self.addon.db.font, self.addon.db.fontSizePower,
            self.addon.db.fontOutline)
        self.addon.playerFrame.bone_shield:SetPoint("LEFT", self.addon.playerFrame.health, "RIGHT")
        self.addon.playerFrame.bone_shield:SetAlpha(self.addon.db.unit.player.alpha)
        self.addon.playerFrame.bone_shield:SetJustifyH("LEFT")
        self.addon.playerFrame.bone_shield:SetTextColor(0.50, 0.32, 0.55)
    end
    self.addon.playerFrame.bone_shield:Show()
    self:RegisterUpdators(boneShieldUpdator, self.addon.playerFrame.bone_shield)
end

function module:DisableBoneShield()
    --print("DisableBoneShield")
    if self.addon.playerFrame.bone_shield then
        self.addon.playerFrame.bone_shield:Hide()
    end
    self:UnregisterUpdators(boneShieldUpdator)
end

function module:EnableDisease()
    --print("EnableDisease")
    if not self.addon.targetFrame.disease then
        self.addon.targetFrame.disease = self.addon.targetFrame:CreateFontString(nil, "OVERLAY")
        self.addon.targetFrame.disease:SetFont(self.addon.db.font, self.addon.db.fontSizePower, self.addon.db.fontOutline)
        self.addon.targetFrame.disease:SetPoint("RIGHT", self.addon.targetFrame.health, "LEFT")
        self.addon.targetFrame.disease:SetAlpha(self.addon.db.unit.player.alpha)
        self.addon.targetFrame.disease:SetJustifyH("RIGHT")
        self.addon.targetFrame.disease:SetTextColor(0.50, 0.32, 0.55)
    end
    self.addon.targetFrame.disease:Show()
    self:RegisterUpdators(diseaseUpdator, self.addon.targetFrame.disease)
end

function module:DisableDisease()
    --print("DisableDisease")
    if self.addon.targetFrame.disease then
        self.addon.targetFrame.disease:Hide()
    end
    self:UnregisterUpdators(diseaseUpdator)
end

function module:getTargetText()
    text = ""

    --	if self.addon.db.class.use_scourge_of_worlds then
    --		name, icon = AuraUtil.FindAuraByName("세계의 스컬지", "target", "PLAYER|HARMFUL")
    --		if name and icon then
    --			text = text .. (":|T%s:%d|t"):format(icon, self.addon.db.fontSizeHealth/2)
    --		end
    --	end
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
