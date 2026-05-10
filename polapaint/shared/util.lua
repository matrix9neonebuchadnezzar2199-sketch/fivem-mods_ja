PolaPaintUtil = {}

--- ゲームタイマー（ms）。クライアント・サーバー共通。
function PolaPaintUtil.now()
    return GetGameTimer()
end

--- UTF-8 コードポイント数（簡易長さチェック）
---@param s string
---@return number|nil
function PolaPaintUtil.utf8len(s)
    if type(s) ~= 'string' then return nil end
    local ok, len = pcall(utf8.len, s)
    if ok then return len end
    return nil
end

--- 制御文字を含むか
---@param s string
function PolaPaintUtil.hasControl(s)
    return s:find('[%z\1-\31\127]') ~= nil
end

--- ランダム16進トークン
---@param bytes number
function PolaPaintUtil.token(bytes)
    bytes = bytes or 16
    local t = {}
    for i = 1, bytes do t[i] = ('%02x'):format(math.random(0, 255)) end
    return table.concat(t)
end

--- RFC Base64 デコード（純 Lua）。壊れた入力は nil。
---@param data string
---@return string|nil
function PolaPaintUtil.b64decode(data)
    if type(data) ~= 'string' or data == '' then return nil end
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    data = string.gsub(data, '[^' .. b .. '=]', '')
    local ok, result = pcall(function()
        return (data:gsub('.', function(x)
            if x == '=' then return '' end
            local r, f = '', (string.find(b, x, 1, true) - 1)
            for i = 6, 1, -1 do
                r = r .. (((f % 2 ^ i - f % 2 ^ (i - 1)) > 0) and '1' or '0')
            end
            return r
        end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
            if #x ~= 8 then return '' end
            local c = 0
            for i = 1, 8 do c = c + (x:sub(i, i) == '1' and 2 ^ (8 - i) or 0) end
            return string.char(c)
        end))
    end)
    if not ok then return nil end
    return result
end

--- ロケール参照
---@param key string
function PolaPaintUtil.L(key)
    local pack = Locales and Locales[Config.Locale or 'ja']
    if type(pack) == 'table' and pack[key] then return pack[key] end
    return key
end
