
local module = _G["BlinkHealthTextModule"]

if select(2, UnitClass("player")) ~= "PRIEST" or not module then return end

local L_PRIEST_CONFIG = "Priest Setting"
local L_USE_PRIEST_ACTIVATED_SPELL = "Displays the spell icons when activating effect."

-- koKR locale
if GetLocale()=="koKR" then
	L_PRIEST_CONFIG = "사제 설정"
	L_USE_PRIEST_ACTIVATED_SPELL = "전문화별 발동 효과 발동시 아이콘을 표시합니다."
end

local activation_spells = {}
local config_added = false

local defaultDB = {
	db_ver = 1.0,
	use_activated_spells = true,
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

	if not config_added then
		self:AddMiscConfig{
			type = "description",
			text = L_PRIEST_CONFIG,
			fontobject = "QuestTitleFont",
			r = 1,
			g = 0.82,
			b = 0,
			justifyH = "LEFT",
		}
		self:AddMiscConfig{
			type = "toggle",
			text = L_USE_PRIEST_ACTIVATED_SPELL,
			tooltip = L_USE_PRIEST_ACTIVATED_SPELL,
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
	if icon == 1035040 then
		icon = 1386548 -- 공허 화살 => 공허 방출 hack
	end
	if icon and activation_spells and activation_spells[icon] then
		activation_spells[icon] = activation_spells[icon] - 1
		if activation_spells[icon] < 0 then
			activation_spells[icon] = 0
		end
	end
end

--function module:getPlayerText()
--	local numShadowOrbs = UnitPower( "player", SPELL_POWER_SHADOW_ORBS )
--	if numShadowOrbs > 0 then
--		return (":|cff%02x%02x%02x%d|r"):format(255, 63, 255, numShadowOrbs)
--	end
--	return ""
--end

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


