-- SPDX-License-Identifier: CC-BY-NC-SA-4.0
-- Lightweight i18n: not ox_lib lib.locale(); supports [missing: key] and en fallback.

Locales = Locales or {}

---@param key string
---@param ... any format args for string.format
---@return string
function Locale(key, ...)
    local lang = (Config and Config.Locale) or 'ja'
    local primary = Locales[lang]
    local str = primary and primary[key]
    if not str then
        local fallback = Locales['en']
        str = fallback and fallback[key]
    end
    if not str then
        return '[missing: ' .. tostring(key) .. ']'
    end
    if select('#', ...) > 0 then
        local ok, formatted = pcall(string.format, str, ...)
        if ok then
            return formatted
        end
        return str
    end
    return str
end

--- English-only strings (Discord / admin logs). Ignores Config.Locale.
---@param key string
---@param ... any format args for string.format
---@return string
function LocaleEn(key, ...)
    local t = Locales['en']
    local str = t and t[key]
    if not str then
        return '[missing: ' .. tostring(key) .. ']'
    end
    if select('#', ...) > 0 then
        local ok, formatted = pcall(string.format, str, ...)
        if ok then
            return formatted
        end
        return str
    end
    return str
end
