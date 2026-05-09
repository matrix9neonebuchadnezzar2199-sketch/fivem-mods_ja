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

--- ロケール参照
---@param key string
function PolaPaintUtil.L(key)
    local pack = Locales and Locales[Config.Locale or 'ja']
    if type(pack) == 'table' and pack[key] then return pack[key] end
    return key
end
