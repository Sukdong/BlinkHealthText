
local module = _G["BlinkHealthTextModule"]

if select(2, UnitClass("player")) ~= "MONK" or not module then return end

local L_MONK_CONFIG = "Monk Setting"
local L_USE_MONK_ACTIVATED_SPELL = "Displays the spell icons when activating effect."
local L_USE_MONK_COMBO_AND_STAGGER = "Displays Stagger% of Brewmaster and number of Chi of Windwalker."

-- koKR locale
if GetLocale()=="koKR" then
	L_MONK_CONFIG = "수도사 설정"
	L_USE_MONK_ACTIVATED_SPELL = "전문화별 발동 효과 발동시 아이콘을 표시합니다."
	L_USE_MONK_COMBO_AND_STAGGER = "양조의 시간차%, 풍운의 기 갯수를 표시합니다."
end

local activation_spells = {}
local config_added = false
local updateComboAndStagger

local defaultDB = {
	db_ver = 1.1,
	use_activated_spells = true,
	use_combo_and_stagger = true,
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
		self:EnableActivatedSpell()
	end

	if self.addon.db.class.use_combo_and_stagger then
		self:EnableComboAndStagger()
	end

	if not config_added then
		self:AddMiscConfig{
			type = "description",
			text = L_MONK_CONFIG,
			fontobject = "QuestTitleFont",
			r = 1,
			g = 0.82,
			b = 0,
			justifyH = "LEFT",
		}
		self:AddMiscConfig{
			type = "toggle",
			text = L_USE_MONK_ACTIVATED_SPELL,
			tooltip = L_USE_MONK_ACTIVATED_SPELL,
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
		self:AddMiscConfig{
			type = "toggle",
			text = L_USE_MONK_COMBO_AND_STAGGER,
			tooltip = L_USE_MONK_COMBO_AND_STAGGER,
			get = function ()
				return self.addon.db.class.use_combo_and_stagger
			end,
			set = function (value)
				self.addon.db.class.use_combo_and_stagger = value
				if self.addon.db.class.use_combo_and_stagger then
					module:EnableComboAndStagger()
				else
					module:DisableComboAndStagger()
				end
			end,
		}
		config_added = true
	end
end

function module:EnableComboAndStagger()
	if not self.addon.playerFrame.combo then
		self.addon.playerFrame.combo = self.addon.playerFrame:CreateFontString(nil, "OVERLAY")
		self.addon.playerFrame.combo:SetFont(self.addon.db.font, self.addon.db.fontSizePower*0.75, self.addon.db.fontOutline)
		self.addon.playerFrame.combo:SetPoint("LEFT", self.addon.playerFrame.health, "RIGHT")
		self.addon.playerFrame.combo:SetAlpha(self.addon.db.unit.player.alpha)
		self.addon.playerFrame.combo:SetJustifyH("LEFT")
	end
	self.addon.playerFrame.combo:Show()
	self:RegisterUpdators(updateComboAndStagger)
end

function module:DisableComboAndStagger()
	if self.addon.playerFrame.combo then
		self.addon.playerFrame.combo:Hide()
	end
	self:UnregisterUpdators(updateComboAndStagger)
end

function updateComboAndStagger()
	local text = ""
	if module.addon.db.class.use_combo_and_stagger then
		local spec = GetSpecialization()
		if spec == 1 then
			local stagger = UnitStagger( "player")
			if stagger and stagger > 0 then
				text = ("|cff%02x%02x%02x%d%%|r"):format(255, 255, 150, stagger / UnitHealthMax("player") * 100)
			end
		elseif spec == 3 then
			local numChi = UnitPower( "player", Enum.PowerType.Chi )
			if numChi > 0 then
				text = ("|cff%02x%02x%02x%d|r"):format(0, 255, 150, numChi)
			end
		end
	end
	module.addon.playerFrame.combo:SetText(text)
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


--function module:getPlayerText()
--	if self.addon.db.class.use_combo_and_stagger then
--		local spec = GetSpecialization()
--		if spec == 1 then
--			local stagger = UnitStagger( "player")
--			if stagger and stagger > 0 then
--				return (":|cff%02x%02x%02x%d|r"):format(255, 255, 150, stagger / UnitHealthMax("player") * 100)
--			end
--		elseif spec == 3 then
--			local numChi = UnitPower( "player", Enum.PowerType.Chi )
--			if numChi > 0 then
--				return (":|cff%02x%02x%02x%d|r"):format(0, 255, 150, numChi)
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
				text = text .. (":|T%s:%d|t"):format(texture, self.addon.db.fontSizeHealth/2)
			end
		end
	end

	return text
end

