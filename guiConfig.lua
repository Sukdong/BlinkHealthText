local moduleName = "BlinkHealthTextConfig"
local guiConfig = {}
_G[moduleName] = guiConfig

guiConfig.addon = nil

-------------------------------------------------------------------------------
-- locale load
-------------------------------------------------------------------------------

local L = _G["BlinkHealthTextLocale"]


-------------------------------------------------------------------------------
-- local variables
-------------------------------------------------------------------------------

local fonts = {
    {
        text = "퀘스트글꼴",
        value = "Fonts\\K_Pagetext.TTF",
        font = "Fonts\\K_Pagetext.TTF",
        r = 1,
        g = .82,
        b = 0,
        size = 16,
    },
    {
        text = "기본글꼴",
        value = "Fonts\\2002.TTF",
        font = "Fonts\\2002.TTF",
        r = 1,
        g = .82,
        b = 0,
        size = 16,
    },
    {
        text = "데미지글꼴",
        value = "Fonts\\K_Damage.TTF",
        font = "Fonts\\K_Damage.TTF",
        r = 1,
        g = .82,
        b = 0,
        size = 16,
    },
    --[[
	더 추가하고싶은 폰트가 있다면 여기에 다음 형식으로 넣으시면됩니다.
	{
		text = "화면에 표시할 텍스트",
		value = "설정값에 저장될 값",
		font = (생략가능) text부분의 글꼴지정,
		r = (생략가능) text부분의 글자의 red색상값 0~1,
		g = (생략가능) text부분의 글자의 green색상값 0~1,
		b = (생략가능) text부분의 글자의 blue색상값 0~1,
		a = (생략가능) text부분의 글자의 투명도 0~1,
		size = (생략가능) text의 글자크기,
	}
	]]
}


local getArgs, tmp, new, del, gettext, getfunc, gettable, getbool, getvalue, showhide, disable
do
    local cache = setmetatable({}, { __mode = 'k' })
    function new()
        local t = next(cache)
        if t then
            cache[t] = nil
            return t
        else
            return {}
        end
    end

    function del(t)
        for k in pairs(t) do
            t[k] = nil
        end
        cache[t] = true
        return nil
    end

    local t = {}
    function tmp(...)
        for k in pairs(t) do
            t[k] = nil
        end
        for i = 1, select('#', ...), 2 do
            local k = select(i, ...)
            if k then
                t[k] = select(i + 1, ...)
            else
                break
            end
        end
        return t
    end

    local info = {}
    function getArgs(...)
        if type(select(1, ...)) == 'table' then
            info = select(1, ...)
        else
            info = tmp(...)
        end
        return info
    end

    function getbool(value)
        if type(value) == 'boolean' then
            return value
        elseif type(value) == 'function' then
            return value()
        end
    end

    function getvalue(value)
        if type(value) == 'function' then
            return value()
        else
            return value
        end
    end

    function gettext(text)
        if type(text) == 'string' then
            return text
        elseif type(text) == 'function' then
            return text()
        end
    end

    function gettable(t)
        if type(t) == 'table' then
            return t
        elseif type(t) == 'function' then
            return t()
        end
    end

    function getfunc(func)
        if func and type(func) == 'function' then
            return func
        elseif func and type(func) == 'string' then
            local f = getglobal(func)
            if f and type(f) == 'function' then
                return f
            end
        end
    end

    function showhide(frame, showhideValue)
        if showhideValue then
            if getbool(showhideValue) then
                frame:Show()
            else
                frame:Hide()
            end
        else
            frame:Show()
        end
    end

    function disable(frame, disableValue)
        if disableValue then
            if getbool(disableValue) then
                frame.disable()
            else
                frame.enable()
            end
        end
    end
end

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

local function makeVariableName(variableName)
    return "PROXY_BHT_" .. variableName:upper();
end

function guiConfig:CreateCheckBox(options)
    if not options then
        return
    end
    local o = gettable(options)
    if not o.label or not o.key then
        return
    end

    local setting = Settings.RegisterProxySetting(self.category, makeVariableName(o.key), Settings.VarType.Boolean, o.label, o.defaultValue, o.get, o.set)
    local initializer = Settings.CreateCheckbox(self.category, setting, o.tooltip);

    if o.key ~= "enable" then
        initializer:SetParentInitializer(self.enableControl, function ()
            return self.addon.db.enable
        end);
    end

    return initializer
end

function guiConfig:CreateDropdown(options)
    if not options then
        return
    end
    local o = gettable(options)
    if not o.label or not o.key or not o.values then
        return
    end

    local setting = Settings.RegisterProxySetting(self.category, makeVariableName(o.key), o.varType, o.label, o.defaultValue, o.get, o.set)
    local function GetOptions()
        local container = Settings.CreateControlTextContainer();
        for i, f in pairs(o.values) do
            container:Add(f.value, f.text);
        end
        return container:GetData();
    end

    local initializer = Settings.CreateDropdown(self.category, setting, GetOptions);

    if o.key ~= "enable" then
        initializer:SetParentInitializer(self.enableControl, function ()
            return self.addon.db.enable
        end);
    end

    return initializer
end

function guiConfig:CreateSlider(options)
    if not options then
        return
    end
    local o = gettable(options)
    if not o.label or not o.key then
        return
    end
    local setting = Settings.RegisterProxySetting(self.category, makeVariableName(o.key), Settings.VarType.Number, o.label, o.defaultValue, o.get, o.set)
    local options = Settings.CreateSliderOptions(o.min, o.max, o.step);
    options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, o.format);
    local initializer = Settings.CreateSlider(self.category, setting, options, tooltip);

    if o.key ~= "enable" then
        initializer:SetParentInitializer(self.enableControl, function ()
            return self.addon.db.enable
        end);
    end

    return initializer
end

function guiConfig:CreateLabel(label)
    self.layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(label))
end

function guiConfig:registBlizzGUI(addon)
    self.addon = addon
    local category, layout = Settings.RegisterVerticalLayoutCategory(L.BLINKHEALTHTEXT);
    category.ID = "BlinkHealthText"
    Settings.RegisterAddOnCategory(category)
    self.category = category
    self.layout = layout

    SlashCmdList["BLINKHEALTHTEXT"] = function()
        Settings.OpenToCategory(category:GetID(), L.BLINKHEALTHTEXT)
    end
    setglobal("SLASH_BLINKHEALTHTEXT1", "/bht")
    setglobal("SLASH_BLINKHEALTHTEXT2", "/체력텍스트")


    -- 사용
    guiConfig.enableControl = guiConfig:CreateCheckBox({
        label = L.ADDON_ENABLE,
        tooltip = L.BHT_DESCRIPTION,
        key = "enable",
        defaultValue = Settings.Default.True,
        get = function ()
            return addon.db.enable
        end,
        set = function (value)
            addon.db.enable = value
            if addon.db.enable then
                addon:EnableAddon()
            else
                addon:DisableAddon()
            end
        end,
    })

    -- 공통 설정
    guiConfig:CreateLabel(L.GENERAL)

    -- 글꼴
    guiConfig:CreateDropdown({
        label = L.FONT,
        tooltip = L.FONT_TOOLTIP,
        key = "font",
        values = fonts,
        varType = Settings.VarType.String,
        defaultValue = "Fonts\\K_Pagetext.TTF",
        get = function ()
            return addon.db.font
        end,
        set = function (value)
            addon.db.font = value
            if addon.db.enable then
                addon:FrameFontUpdate()
            end
        end
    })

    -- 글꼴외각선
    guiConfig:CreateDropdown({
        label = L.FONT_OUTLINE,
        tooltip = L.FONT_OUTLINE_TOOLTIP,
        key = "fontOutline",
        values = {
            {
                text = L.FONT_OUTLINE_NONE,
                value = "",
            },
            {
                text = L.FONT_OUTLINE_THIN,
                value = "OUTLINE",
            },
            {
                text = L.FONT_OUTLINE_THICK,
                value = "THICKOUTLINE",
            },
        },
        varType = Settings.VarType.String,
        defaultValue = "THICKOUTLINE",
        get = function ()
            return addon.db.fontOutline
        end,
        set = function (value)
            addon.db.fontOutline = value
            if addon.db.enable then
                addon:FrameFontUpdate()
            end
        end
    })

    -- 체력크기
    guiConfig:CreateSlider({
        label = L.HP_SIZE,
        tooltip = L.HP_SIZE_TOOLTIP,
        key = "fontSizeHealth",
        min = 10,
        max= 36,
        step = 2,
        defaultValue = 28,
        get = function ()
            return addon.db.fontSizeHealth
        end,
        set = function (value)
            addon.db.fontSizeHealth = value
            if addon.db.enable then
                addon:FrameFontUpdate()
            end
        end
    })

    -- 파워크기
    guiConfig:CreateSlider({
        label = L.POWER_SIZE,
        tooltip = L.POWER_SIZE_TOOLTIP,
        key = "fontSizePower",
        min = 10,
        max= 36,
        step = 2,
        defaultValue = 20,
        get = function ()
            return addon.db.fontSizePower
        end,
        set = function (value)
            addon.db.fontSizePower = value
            if addon.db.enable then
                addon:FrameFontUpdate()
            end
        end
    })

    -- 가로위치
    guiConfig:CreateSlider({
        label = L.X_POSISTION,
        tooltip = L.X_POSISTION_TOOLTIP,
        key = "posX",
        min = 0,
        max= 600,
        step = 10,
        defaultValue = 170,
        get = function ()
            return addon.db.posX
        end,
        set = function (value)
            addon.db.posX = value
            if addon.db.enable then
                addon:FramePositionUpdate()
            end
        end
    })

    -- 세로위치
    guiConfig:CreateSlider({
        label = L.Y_POSISTION,
        tooltip = L.Y_POSISTION_TOOLTIP,
        key = "posY",
        min = -400,
        max= 400,
        step = 10,
        defaultValue = 10,
        get = function ()
            return addon.db.posY
        end,
        set = function (value)
            addon.db.posY = value
            if addon.db.enable then
                addon:FramePositionUpdate()
            end
        end
    })

    -- 전술목표 아이콘
    guiConfig:CreateCheckBox({
        label = L.SHOW_RAIDICONS,
        tooltip = L.SHOW_RAIDICONS_TOOLTIP,
        key = "SHOW_RAID_ICONS",
        defaultValue = Settings.Default.True,
        get = function ()
            return addon.db.showRaidIcons
        end,
        set = function (value)
            addon.db.showRaidIcons = value
            if addon.db.enable then
                addon:FrameUpdate("target")
            end
        end
    })

    -- 플레이어 텍스트
    guiConfig:CreateLabel(L.PLAYER)

    -- 전투시에만 보이기
    guiConfig:CreateCheckBox({
        label = L.HIDE_OUT_OF_COMBAT_PLAYER,
        tooltip = L.HIDE_OUT_OF_COMBAT_PLAYER_TOOLTIP,
        key = "UNIT_PLAYER_HIDE_OOC",
        defaultValue = Settings.Default.True,
        get = function ()
            return addon.db.unit.player.hideOOC 
        end,
        set = function (value)
            addon.db.unit.player.hideOOC  = value
            if addon.db.enable then
                addon.db.unit.player.hideOOC = value
				addon:FrameUpdate("player")
            end
        end
    })

    -- 체력수치 %로 표시
    guiConfig:CreateCheckBox({
        label = L.SHOW_HEALTH_AS_PERCENTAGE_PLAYER,
        tooltip = L.SHOW_HEALTH_AS_PERCENTAGE_PLAYER_TOOLTIP,
        key = "UNIT_PLAYER_REAL_VALUE",
        defaultValue = Settings.Default.True,
        get = function ()
            return not addon.db.unit.player.realValue
        end,
        set = function (value)
            addon.db.unit.player.realValue = not value
            if addon.db.enable then
                addon:DisplayHealthText("player")
                addon:DisplayPowerText("player")
            end
        end
    })

    -- 파워수치 %로 표시
    guiConfig:CreateCheckBox({
        label = L.SHOW_POWER_AS_PERCENTAGE_PLAYER,
        tooltip = L.SHOW_POWER_AS_PERCENTAGE_PLAYER_TOOLTIP,
        key = "UNIT_PLAYER_REAL_POWER_VALUE",
        defaultValue = Settings.Default.True,
        get = function ()
            return not addon.db.unit.player.realPowerValue
        end,
        set = function (value)
            addon.db.unit.player.realPowerValue = not value
            if addon.db.enable then
                addon:DisplayHealthText("player")
                addon:DisplayPowerText("player")
            end
        end
    })

    -- 투명도
    guiConfig:CreateSlider({
        label = L.OPACITY_PLAYER,
        tooltip = L.OPACITY_PLAYER_TOOLTIP,
        key = "UNIT_PLAYER_REAL_ALPHA",
        min = 0.1,
        max= 1.0,
        step = 0.05,
        defaultValue = 1.0,
        get = function ()
            return addon.db.unit.player.alpha
        end,
        set = function (value)
            addon.db.unit.player.alpha = value
            if addon.db.enable then
                addon:FrameUpdate("player")
            end
        end,
        format = FormatPercentage
    })


    -- 대상 텍스트
    guiConfig:CreateLabel(L.TARGET)

    -- 전투시에만 보이기
    guiConfig:CreateCheckBox({
        label = L.HIDE_OUT_OF_COMBAT_TARGET,
        tooltip = L.HIDE_OUT_OF_COMBAT_TARGET_TOOLTIP,
        key = "UNIT_TARGET_HIDE_OOC",
        defaultValue = Settings.Default.True,
        get = function ()
            return addon.db.unit.target.hideOOC
        end,
        set = function (value)
            addon.db.unit.target.hideOOC  = value
            if addon.db.enable then
                addon.db.unit.target.hideOOC = value
				addon:FrameUpdate("target")
            end
        end
    })

    -- 체력수치 %로 표시
    guiConfig:CreateCheckBox({
        label = L.SHOW_HEALTH_AS_PERCENTAGE_TARGET,
        tooltip = L.SHOW_HEALTH_AS_PERCENTAGE_TARGET_TOOLTIP,
        key = "UNIT_TARGET_REAL_VALUE",
        defaultValue = Settings.Default.True,
        get = function ()
            return not addon.db.unit.target.realValue
        end,
        set = function (value)
            addon.db.unit.target.realValue = not value
            if addon.db.enable then
                addon:DisplayHealthText("target")
                addon:DisplayPowerText("target")
            end
        end
    })

    -- 파워수치 %로 표시
    guiConfig:CreateCheckBox({
        label = L.SHOW_POWER_AS_PERCENTAGE_TARGET,
        tooltip = L.SHOW_POWER_AS_PERCENTAGE_TARGET_TOOLTIP,
        key = "UNIT_TARGET_REAL_POWER_VALUE",
        defaultValue = Settings.Default.True,
        get = function ()
            return not addon.db.unit.target.realPowerValue
        end,
        set = function (value)
            addon.db.unit.target.realPowerValue = not value
            if addon.db.enable then
                addon:DisplayHealthText("target")
                addon:DisplayPowerText("target")
            end
        end
    })

    -- 투명도
    guiConfig:CreateSlider({
        label = L.OPACITY_TARGET,
        tooltip = L.OPACITY_TARGET_TOOLTIP,
        key = "UNIT_TARGET_REAL_ALPHA",
        min = 0.1,
        max= 1.0,
        step = 0.05,
        defaultValue = 1.0,
        get = function ()
            return addon.db.unit.target.alpha
        end,
        set = function (value)
            addon.db.unit.target.alpha = value
            if addon.db.enable then
                addon:FrameUpdate("target")
            end
        end,
        format = FormatPercentage
    })


    -- 소환수 텍스트
    guiConfig:CreateLabel(L.PET)

    -- 전투시에만 보이기
    guiConfig:CreateCheckBox({
        label = L.HIDE_OUT_OF_COMBAT_PET,
        tooltip = L.HIDE_OUT_OF_COMBAT_PET_TOOLTIP,
        key = "UNIT_PET_HIDE_OOC",
        defaultValue = Settings.Default.True,
        get = function ()
            return addon.db.unit.pet.hideOOC
        end,
        set = function (value)
            addon.db.unit.pet.hideOOC  = value
            if addon.db.enable then
                addon.db.unit.pet.hideOOC = value
				addon:FrameUpdate("pet")
            end
        end
    })

    -- 체력수치 %로 표시
    guiConfig:CreateCheckBox({
        label = L.SHOW_HEALTH_AS_PERCENTAGE_PET,
        tooltip = L.SHOW_HEALTH_AS_PERCENTAGE_PET_TOOLTIP,
        key = "UNIT_PET_REAL_VALUE",
        defaultValue = Settings.Default.True,
        get = function ()
            return not addon.db.unit.pet.realValue
        end,
        set = function (value)
            addon.db.unit.pet.realValue = not value
            if addon.db.enable then
                addon:DisplayHealthText("pet")
                addon:DisplayPowerText("pet")
            end
        end
    })

    -- 파워수치 %로 표시
    guiConfig:CreateCheckBox({
        label = L.SHOW_POWER_AS_PERCENTAGE_PET,
        tooltip = L.SHOW_POWER_AS_PERCENTAGE_PET_TOOLTIP,
        key = "UNIT_PET_REAL_POWER_VALUE",
        defaultValue = Settings.Default.True,
        get = function ()
            return not addon.db.unit.pet.realPowerValue
        end,
        set = function (value)
            addon.db.unit.pet.realPowerValue = not value
            if addon.db.enable then
                addon:DisplayHealthText("pet")
                addon:DisplayPowerText("pet")
            end
        end
    })

    -- 투명도
    guiConfig:CreateSlider({
        label = L.OPACITY_PET,
        tooltip = L.OPACITY_PET_TOOLTIP,
        key = "UNIT_PET_REAL_ALPHA",
        min = 0.1,
        max= 1.0,
        step = 0.05,
        defaultValue = 1.0,
        get = function ()
            return addon.db.unit.pet.alpha
        end,
        set = function (value)
            addon.db.unit.pet.alpha = value
            if addon.db.enable then
                addon:FrameUpdate("pet")
            end
        end,
        format = FormatPercentage
    })

    -- 체력크기
    guiConfig:CreateSlider({
        label = L.PET_HP_SIZE,
        tooltip = L.PET_HP_SIZE_TOOLTIP,
        key = "fontSizeHealthForPet",
        min = 10,
        max= 36,
        step = 2,
        defaultValue = 14,
        get = function ()
            return addon.db.fontSizeHealthForPet
        end,
        set = function (value)
            addon.db.fontSizeHealthForPet = value
            if addon.db.enable then
                addon:FrameFontUpdate()
            end
        end
    })

    -- 파워크기
    guiConfig:CreateSlider({
        label = L.PET_POWER_SIZE,
        tooltip = L.PET_POWER_SIZE_TOOLTIP,
        key = "fontSizePowerForPet",
        min = 10,
        max= 36,
        step = 2,
        defaultValue = 10,
        get = function ()
            return addon.db.fontSizePowerForPet
        end,
        set = function (value)
            addon.db.fontSizePowerForPet = value
            if addon.db.enable then
                addon:FrameFontUpdate()
            end
        end
    })
end
