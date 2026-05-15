-- ============================================================
-- jp-meridian9 / client/transition.lua
-- ============================================================
-- 次元転送・サイト・ナイン演出（最小実装）。
-- 本格演出は INSTRUCTION-017 で拡張予定。
-- ============================================================

MRD9 = MRD9 or {}
MRD9.Transition = MRD9.Transition or {}

local State = {
    active = false,
    appliedModifier = nil,
    appliedBlackout = false,
}

---@return table
local function cfg()
    return Config.SiteNine or {}
end

local function applyClockOverride()
    local c = cfg()
    if not c.timeFreeze then
        return
    end
    local h = tonumber(c.timeHour) or 3
    local m = tonumber(c.timeMinute) or 0
    NetworkOverrideClockTime(h, m, 0)
end

local function clearClockOverride()
    NetworkClearClockTimeOverride()
end

local function applyWeather()
    local c = cfg()
    local w = c.weather
    if type(w) ~= 'string' or w == '' then
        return
    end
    SetWeatherTypeNowPersist(w)
    SetWeatherTypeNow(w)
    SetOverrideWeather(w)
end

local function clearWeather()
    ClearOverrideWeather()
    ClearWeatherTypePersist()
end

local function applyTimecycle()
    local c = cfg()
    local m = c.timecycleModifier
    if type(m) ~= 'string' or m == '' then
        return
    end
    SetTimecycleModifier(m)
    local s = tonumber(c.timecycleStrength)
    if s and s >= 0.0 and s <= 1.0 then
        SetTimecycleModifierStrength(s)
    end
    State.appliedModifier = m
end

local function clearTimecycle()
    if State.appliedModifier then
        ClearTimecycleModifier()
        State.appliedModifier = nil
    end
end

local function applyBlackout()
    if cfg().blackout then
        SetArtificialLightsState(true)
        State.appliedBlackout = true
    end
end

local function clearBlackout()
    if State.appliedBlackout then
        SetArtificialLightsState(false)
        State.appliedBlackout = false
    end
end

---@return nil
function MRD9.Transition.Enter()
    if State.active then
        return
    end
    State.active = true
    applyClockOverride()
    applyWeather()
    applyTimecycle()
    applyBlackout()
end

---@return nil
function MRD9.Transition.Leave()
    if not State.active then
        return
    end
    State.active = false
    clearBlackout()
    clearTimecycle()
    clearWeather()
    clearClockOverride()
end

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then
        return
    end
    MRD9.Transition.Leave()
end)
