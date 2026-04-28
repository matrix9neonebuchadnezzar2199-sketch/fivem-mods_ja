-- locales/*.json をサーバー側で読み込み（マーキー配列等）

Locales = {}

local cached = nil

local function loadOnce()
    if cached ~= nil then
        return
    end
    local name = (Config.Locale or 'ja') .. '.json'
    local raw = LoadResourceFile(GetCurrentResourceName(), 'locales/' .. name)
    if not raw then
        raw = LoadResourceFile(GetCurrentResourceName(), 'locales/ja.json')
    end
    if not raw or raw == '' then
        cached = {}
        return
    end
    local ok, t = pcall(json.decode, raw)
    cached = (ok and type(t) == 'table') and t or {}
end

---@return table
function Locales.getCurrent()
    loadOnce()
    return cached or {}
end

--- JSON ルートのフラットキー（例: marquee.hype）またはネスト参照で配列を取得
---@param key string
---@return table|nil
function Locales.getList(key)
    if not key or key == '' then
        return nil
    end
    local data = Locales.getCurrent()
    local v = data[key]
    if type(v) == 'table' then
        return v
    end
    local nested = data
    for part in string.gmatch(key, '[^.]+') do
        if type(nested) ~= 'table' then
            return nil
        end
        nested = nested[part]
    end
    return type(nested) == 'table' and nested or nil
end
