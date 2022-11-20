local moduleName = "BlinkHealthTextModule"
local module = {}
_G[moduleName] = module
module.addon = nil
module.updators = {}
module.miscOptions = {}

-------------------------------------------------------------------------------
-- WOW APIs/variables
-------------------------------------------------------------------------------

local AuraUtil = AuraUtil
local UnitExists = UnitExists
local select = select
local GetTime = GetTime


-------------------------------------------------------------------------------
-- modules
-------------------------------------------------------------------------------

function module:RegisterUpdators(func, ...)
    if func and type(func) == "function" then
        if not self.updators[func] then
            if select("#", ...) == 0 then
                self.updators[func] = true
            else
                self.updators[func] = { ... }
            end
        end
    end
end

function module:UnregisterUpdators(func)
    if func and type(func) == "function" then
        if self.updators[func] then
            self.updators[func] = nil
        end
    end
end

function module:ExtraUpdators(unit)
    for func, v in pairs(self.updators) do
        if type(v) == "table" then
            func(unit, unpack(v))
        else
            func(unit)
        end
    end
end

function module:GetMiscConfig()
    return self.miscOptions
end

function module:AddMiscConfig(opt)
    table.insert(self.miscOptions, opt)
end

function module:getAuraInfo(unit, spell, filter)
    if not UnitExists(unit) then return end

    return AuraUtil.FindAuraByName(spell, unit, filter)

    --	local i = 1
    --	local countText, r, g, b = "", 1.0, 0.5, 0.1
    --
    --	local name, rank, icon, count, debufType, duration, expirationTime = UnitAura(unit, i, filter)
    --	while name do
    --		if name == spell or name:find(spell) then
    --			return name, rank, icon, count, debufType, duration, expirationTime
    --		end
    --		i = i + 1
    --		name, rank, icon, count, debufType, duration, expirationTime = UnitAura(unit, i, filter)
    --	end
end

function module:getAuraCount(unit, spell, filter, iconOnly)
    if not UnitExists(unit) then return "" end

    local i = 1
    local countText, r, g, b = "", 1.0, 0.5, 0.1

    local name, icon, count, debufType, duration, expirationTime = self:getAuraInfo(unit, spell, filter)
    if name then
        if (count <= 0) then
            return ""
        end

        if not expirationTime then
            -- nothing
        else
            local timeLeft = (expirationTime - GetTime()) / duration
            if timeLeft < 0.3 then -- 30%미만 - 빨간색
                r = 1.0
                g = 0.1
                b = 0.1
            elseif timeLeft < 0.6 then -- 30%~60% - 파란색
                r = 0.0
                g = 0.39
                b = 0.88
            else -- 60%이상 녹색
                r = 0.1
                g = 1.0
                b = 0.1
            end
        end
        if iconOnly then
            return (":|T%s:0|t"):format(icon)
        else
            return (":|cff%02x%02x%02x%d|r"):format(r * 255, g * 255, b * 255, count)
        end
    end
    return ""
end

function module:init() end

function module:getPlayerText() end

function module:getTargetText() end

function module:getPlayerHealthColor() end

function module:getPlayerPowerColor() end

function module:getTargetHealthColor() end

function module:getTargetPowerColor() end
