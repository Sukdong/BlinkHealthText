local module = _G["BlinkHealthTextModule"]

-------------------------------------------------------------------------------
-- WOW APIs/variables
-------------------------------------------------------------------------------

local GetLocale, AuraUtil, IsSpellKnown = GetLocale, AuraUtil, IsSpellKnown
local UnitClass, UnitPower, UnitHealthMax, UnitStagger = UnitClass, UnitPower, UnitHealthMax, UnitStagger
local GetSpecialization, GetSpellTabInfo, IsPassiveSpell = GetSpecialization, GetSpellTabInfo, IsPassiveSpell
local GetSpellTexture, GetSpellInfo = GetSpellTexture, GetSpellInfo
local GetSpellBookItemInfo, GetFlyoutInfo = GetSpellBookItemInfo, GetFlyoutInfo
local GetFlyoutSlotInfo, GetSpellSubtext = GetFlyoutSlotInfo, GetSpellSubtext
local select = select


-------------------------------------------------------------------------------
-- local variables
-------------------------------------------------------------------------------

if select(2, UnitClass("player")) ~= "WARRIOR" or not module then return end

local tinsert = table.insert

local L_WARRIOR_CONFIG = "Warrior Setting"
local L_USE_WARRIOR_ACTIVATED_SPELL = "Displays the spell icons when activating effect."
--local L_USE_FOCUSED_RAGE = "|TInterface\\Icons\\ability_warrior_focusedrage:20|t집중된 분노 효과의 중첩 갯수(무기,방어 전문화)를 표시합니다."

-- koKR locale
if GetLocale() == "koKR" then
    L_WARRIOR_CONFIG = "전사 설정"
    L_USE_WARRIOR_ACTIVATED_SPELL = "전문화별 발동 효과 발동시 아이콘을 표시합니다."
end

local my_spells = {}
local activation_spells = {}
local config_added = false
local name, icon, count, debufType, duration, expirationTime

local defaultDB = {
    db_ver = 1.1,
    use_activated_spells = true,
    --use_focused_rage = true,
}

-------------------------------------------------------------------------------
-- local functions
-------------------------------------------------------------------------------

local function tcopy(to, from) -- "to" must be a table (possibly empty)
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

local function focusedRageUpdator(unit, f1)

    name, icon, count, debufType, duration, expirationTime = AuraUtil.FindAuraByName("집중된 분노", "player",
        "PLAYER|HELPFUL") -- UnitAura("player", "집중된 분노", nil, "PLAYER|HELPFUL")

    if count and count > 0 then
        f1:SetText(count)
    else
        f1:SetText("")
    end
end

local function scanSpells()
    local currentActiveSpells = {}
    local duplicateSpells = {}

    -- Specialization spells (Active)
    local name, texture, offset, numSpells = GetSpellTabInfo(3)
    for id = 1, numSpells do
        if not IsPassiveSpell(id + offset, "book") then
            local spellName, _, icon, _, _, _, spellid = GetSpellInfo(id + offset, "book")
            local slotType, slotid = GetSpellBookItemInfo(id + offset, "book")
            if slotType == "FLYOUT" then
                local _, _, numSlots, isKnown = GetFlyoutInfo(slotid)
                for i = 1, numSlots do
                    local foSpellID, foOverrideSpellID, foIsKnown, foSpellName, foSlotSpecID = GetFlyoutSlotInfo(slotid,
                        i)
                    if foIsKnown and not duplicateSpells[foSpellID] then
                        currentActiveSpells[foSpellID] = { foSpellName, GetSpellTexture(foOverrideSpellID), foSpellID }
                        duplicateSpells[foSpellID] = true
                    end
                end
            elseif slotType == 'SPELL' then
                if not duplicateSpells[spellid] then
                    currentActiveSpells[spellid] = { spellName, icon, spellid }
                    duplicateSpells[spellid] = true
                end
            end
        end
    end

    -- Class common spells (Active)
    name, texture, offset, numSpells = GetSpellTabInfo(2)
    for id = 1, numSpells do
        if not IsPassiveSpell(id + offset, "book") then
            local spellName, _, icon, _, _, _, spellid = GetSpellInfo(id + offset, "book")
            local slotType, slotid = GetSpellBookItemInfo(id + offset, "book")
            -- spellid = addon:GetReplacementSpellId(spellid)
            if slotType == "FLYOUT" then
                local _, _, numSlots, isKnown = GetFlyoutInfo(slotid)
                for i = 1, numSlots do
                    local foSpellID, foOverrideSpellID, foIsKnown, foSpellName, foSlotSpecID = GetFlyoutSlotInfo(slotid,
                        i)
                    if foIsKnown and not duplicateSpells[foSpellID] then
                        currentActiveSpells[foSpellID] = { foSpellName, GetSpellTexture(foOverrideSpellID), foSpellID }
                        duplicateSpells[foSpellID] = true
                    end
                end
            elseif slotType == 'SPELL' then
                if not duplicateSpells[spellid] then
                    currentActiveSpells[spellid] = { spellName, icon, spellid }
                    duplicateSpells[spellid] = true
                end
            end
        end
    end

    -- racial spells
    name, texture, offset, numSpells = GetSpellTabInfo(1) -- general skill tab
    for id = 1, numSpells do
        if not IsPassiveSpell(id + offset, "book") then
            local spellName, _, icon, _, _, _, spellid = GetSpellInfo(id + offset, "book")
            local slotType, slotid = GetSpellBookItemInfo(id + offset, "book")
            local subSpellName = GetSpellSubtext(spellid)
            if slotType == 'SPELL' and subSpellName == "종족 특성" then
                currentActiveSpells[spellid] = { spellName, icon, spellid }
            end
        end
    end

    -- for spellid, value in pairs(duplicateSpells) do
    -- 	print(spellid, GetSpellInfo(spellid))
    -- end
    -- print("-------------------------")
    -- for key, value in pairs(currentActiveSpells) do
    -- 	print(value[3], GetSpellInfo(value[3]))
    -- end

    return currentActiveSpells
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
        -- my_spells = scanSpells()
        -- print("스킬 스캔 완료 init")
        module:EnableActivatedSpell()
    end

    --	if self.addon.db.class.use_focused_rage then
    --		self:EnableFocusedRage()
    --	end

    if not config_added then
        self:AddMiscConfig {
            type = "description",
            text = L_WARRIOR_CONFIG,
            fontobject = "QuestTitleFont",
            r = 1,
            g = 0.82,
            b = 0,
            justifyH = "LEFT",
        }
        self:AddMiscConfig {
            type = "toggle",
            text = L_USE_WARRIOR_ACTIVATED_SPELL,
            tooltip = L_USE_WARRIOR_ACTIVATED_SPELL,
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
        --		self:AddMiscConfig{
        --			type = "toggle",
        --			text = L_USE_FOCUSED_RAGE,
        --			tooltip = L_USE_FOCUSED_RAGE,
        --			get = function ()
        --				return module.addon.db.class.use_bone_shield
        --			end,
        --			set = function (value)
        --				module.addon.db.class.use_focused_rage = value
        --				if module.addon.db.class.use_focused_rage then
        --					module:EnableFocusedRage()
        --				else
        --					module:DisableFocusedRage()
        --				end
        --			end,
        --		}
        config_added = true
    end
end

function module:EnableActivatedSpell()
    activation_spells = {}
    self.addon.mainFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
    self.addon.mainFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
    self.addon.mainFrame:RegisterEvent("SPELLS_CHANGED")
end

function module:DisableActivatedSpell()
    activation_spells = {}
    self.addon.mainFrame:UnregisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
    self.addon.mainFrame:UnregisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
    self.addon.mainFrame:UnregisterEvent("SPELLS_CHANGED")
end

function module:PLAYER_SPECIALIZATION_CHANGED(...)
    local arg1 = ...;
    if arg1 == "player" then
        -- my_spells = scanSpells()
        -- print("스킬 스캔 완료 PLAYER_SPECIALIZATION_CHANGED")
    end
end

function module:SPELLS_CHANGED(...)
    -- my_spells = scanSpells()
    -- print("스킬 스캔 완료 SPELLS_CHANGED")
end

function module:SPELL_ACTIVATION_OVERLAY_GLOW_SHOW(...)
    -- 분노: 마무리 일격 5308 -> override ID 280735
    -- 분노: 마무리 일격 163201
    -- 분노: 마무리 일격 163201
    -- 분노: 규탄 330325
    local spellID = ...;
    local icon = GetSpellTexture(spellID)
    -- local spellName = GetSpellInfo(spellID)
    if icon and IsSpellKnown(spellID) then
        -- print("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", spellID, icon, spellName)
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

function module:EnableFocusedRage()
    if not self.addon.playerFrame.focused_rage then
        self.addon.playerFrame.focused_rage = self.addon.playerFrame:CreateFontString(nil, "OVERLAY")
        self.addon.playerFrame.focused_rage:SetFont(self.addon.db.font, self.addon.db.fontSizePower,
            self.addon.db.fontOutline)
        self.addon.playerFrame.focused_rage:SetPoint("LEFT", self.addon.playerFrame.health, "RIGHT")
        self.addon.playerFrame.focused_rage:SetAlpha(self.addon.db.unit.player.alpha)
        self.addon.playerFrame.focused_rage:SetJustifyH("LEFT")
        self.addon.playerFrame.focused_rage:SetTextColor(1.0, 0.52, 0.25)
    end
    self.addon.playerFrame.focused_rage:Show()
    self:RegisterUpdators(focusedRageUpdator, self.addon.playerFrame.focused_rage)
end

function module:DisableFocusedRage()
    if self.addon.playerFrame.focused_rage then
        self.addon.playerFrame.focused_rage:Hide()
    end
    self:UnregisterUpdators(focusedRageUpdator)
end
