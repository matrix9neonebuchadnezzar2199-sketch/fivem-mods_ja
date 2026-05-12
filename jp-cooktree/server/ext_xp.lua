-- 料理専用 XP / Level / SP（Resource KVP）。識別子は CookTree.Stars.GetIdentifier（fxmanifest で stars.lua を本ファイルより前に列挙すること）。

CookTree = CookTree or {}
CookTree.ExtXP = CookTree.ExtXP or {}

local resName = GetCurrentResourceName()

---@param src number
---@return string
local function getIdentifier(src)
    if CookTree.Stars and CookTree.Stars.GetIdentifier then
        return CookTree.Stars.GetIdentifier(src)
    end
    return ('noid:%d'):format(type(src) == 'number' and src or 0)
end

---@param identifier string
---@return string
local function safeIdentifier(identifier)
    local safe = (identifier or 'unknown'):gsub(':', '_'):gsub('[^%w_%-%.]', '_')
    if #safe > 96 then safe = safe:sub(1, 96) end
    return safe
end

---@param identifier string
---@return string
local function kvpXpKey(identifier)
    return ('%s:cooking_xp:%s'):format(resName, safeIdentifier(identifier))
end

---@param identifier string
---@return string
local function kvpSpKey(identifier)
    return ('%s:cooking_sp:%s'):format(resName, safeIdentifier(identifier))
end

---@param xp number
---@return integer
local function calcLevelFromXp(xp)
    local tbl = Config and Config.LevelTable
    if type(tbl) ~= 'table' then return 1 end
    local best = 1
    for lv, need in pairs(tbl) do
        if type(lv) == 'number' and type(need) == 'number' and xp >= need and lv > best then
            best = lv
        end
    end
    return best
end

---@param level integer
---@return number|nil
local function getNextLevelThreshold(level)
    local tbl = Config and Config.LevelTable
    if type(tbl) ~= 'table' then return nil end
    return tbl[level + 1]
end

---@param src number
---@return integer
function CookTree.ExtXP.GetXP(src)
    if type(src) ~= 'number' or src <= 0 then return 0 end
    local v = GetResourceKvpInt(kvpXpKey(getIdentifier(src)))
    if not v or v < 0 then return 0 end
    return math.floor(v)
end

---@param src number
---@return integer
function CookTree.ExtXP.GetLevel(src)
    return calcLevelFromXp(CookTree.ExtXP.GetXP(src))
end

---@param src number
---@return integer
function CookTree.ExtXP.GetSP(src)
    if type(src) ~= 'number' or src <= 0 then return 0 end
    local v = GetResourceKvpInt(kvpSpKey(getIdentifier(src)))
    if not v or v < 0 then return 0 end
    return math.floor(v)
end

---@param src number
---@param amount number
function CookTree.ExtXP.AddXP(src, amount)
    if type(src) ~= 'number' or src <= 0 then return end
    local n = tonumber(amount)
    if not n or n <= 0 or math.floor(n) ~= n then return end
    n = math.floor(n)

    local ident = getIdentifier(src)
    local xKey = kvpXpKey(ident)
    local sKey = kvpSpKey(ident)

    local oldXp = GetResourceKvpInt(xKey)
    if not oldXp or oldXp < 0 then oldXp = 0 end
    local newXp = oldXp + n
    SetResourceKvpInt(xKey, newXp)

    local oldLevel = calcLevelFromXp(oldXp)
    local newLevel = calcLevelFromXp(newXp)
    local spPer = (Config and tonumber(Config.SpPerLevel)) or 1

    print(('[%s][XP] AddXP src=%d amount=%d total=%d level=%d->%d'):format(
        resName, src, n, newXp, oldLevel, newLevel
    ))

    if newLevel > oldLevel then
        local gain = (newLevel - oldLevel) * spPer
        local oldSp = GetResourceKvpInt(sKey)
        if not oldSp or oldSp < 0 then oldSp = 0 end
        SetResourceKvpInt(sKey, oldSp + gain)
        print(('[%s][XP] LevelUp src=%d oldLevel=%d newLevel=%d SP+=%d'):format(
            resName, src, oldLevel, newLevel, gain
        ))
    end
end

---@param src number
---@param amount number
---@return boolean
function CookTree.ExtXP.ConsumeSP(src, amount)
    if type(src) ~= 'number' or src <= 0 then return false end
    local n = tonumber(amount)
    if not n or n <= 0 or math.floor(n) ~= n then return false end
    n = math.floor(n)
    local ident = getIdentifier(src)
    local sKey = kvpSpKey(ident)
    local cur = GetResourceKvpInt(sKey)
    if not cur or cur < 0 then cur = 0 end
    if cur < n then return false end
    SetResourceKvpInt(sKey, cur - n)
    return true
end

---@param src number
---@return table xp: integer, level: integer, sp: integer, nextLevelXp: number|nil
function CookTree.ExtXP.GetAll(src)
    if type(src) ~= 'number' or src <= 0 then
        return { xp = 0, level = 1, sp = 0, nextLevelXp = getNextLevelThreshold(1) }
    end
    local xp = CookTree.ExtXP.GetXP(src)
    local level = calcLevelFromXp(xp)
    local sp = CookTree.ExtXP.GetSP(src)
    return {
        xp = xp,
        level = level,
        sp = sp,
        nextLevelXp = getNextLevelThreshold(level),
    }
end

---@param src number
---@return nil
local function resetCookingProgressForSrc(src)
    if type(src) ~= 'number' or src <= 0 then return end
    local ident = getIdentifier(src)
    SetResourceKvpInt(kvpXpKey(ident), 0)
    SetResourceKvpInt(kvpSpKey(ident), 0)
    print(('[%s][XP] Reset src=%d id=%s'):format(resName, src, ident))
end

if Config and Config.Debug then
    RegisterCommand('cook_reset_xp', function(source)
        if source == 0 then return end
        resetCookingProgressForSrc(source)
    end, false)
end
