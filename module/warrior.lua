
local module = _G["BlinkHealthTextModule"]

if select(2, UnitClass("player")) ~= "WARRIOR" or not module then return end


local L_WARRIOR_CONFIG = "Warrior Setting"
local L_USE_WARRIOR_ACTIVATED_SPELL = "Displays the spell icons when activating effect."
--local L_USE_FOCUSED_RAGE = "|TInterface\\Icons\\ability_warrior_focusedrage:20|t집중된 분노 효과의 중첩 갯수(무기,방어 전문화)를 표시합니다."

-- koKR locale
if GetLocale()=="koKR" then
	L_WARRIOR_CONFIG = "전사 설정"
	L_USE_WARRIOR_ACTIVATED_SPELL = "전문화별 발동 효과 발동시 아이콘을 표시합니다."
end


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

function tcopy(to, from) -- "to" must be a table (possibly empty)
	for k,v in pairs(from) do
		if(type(v)=="table") then
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

--	if self.addon.db.class.use_focused_rage then
--		self:EnableFocusedRage()
--	end

	if not config_added then
		self:AddMiscConfig{
			type = "description",
			text = L_WARRIOR_CONFIG,
			fontobject = "QuestTitleFont",
			r = 1,
			g = 0.82,
			b = 0,
			justifyH = "LEFT",
		}
		self:AddMiscConfig{
			type = "toggle",
			text = L_USE_WARRIOR_ACTIVATED_SPELL,
			tooltip = L_USE_WARRIOR_ACTIVATED_SPELL,
			get = function ()
				return self.addon.db.class.use_activated_spells
			end,
			set = function (value)
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

function module:getTargetText()
	local text = ""

	if self.addon.db.class.use_activated_spells then
		for texture, cnt in pairs(activation_spells) do
			if cnt > 0 then
				text = text .. (":|T%s:%d|t"):format(texture, self.addon.db.fontSizeHealth/2)
			end
		end
	end

	return text
end


function module:EnableFocusedRage()
	if not self.addon.playerFrame.focused_rage then
		self.addon.playerFrame.focused_rage = self.addon.playerFrame:CreateFontString(nil, "OVERLAY")
		self.addon.playerFrame.focused_rage:SetFont(self.addon.db.font, self.addon.db.fontSizePower, self.addon.db.fontOutline)
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


function focusedRageUpdator(unit, f1)

	name, icon, count, debufType, duration, expirationTime = AuraUtil.FindAuraByName("집중된 분노", "player", "PLAYER|HELPFUL") -- UnitAura("player", "집중된 분노", nil, "PLAYER|HELPFUL")

	if count and count > 0 then
		f1:SetText(count)
	else
		f1:SetText("")
	end
end