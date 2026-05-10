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
    if type(s) ~= 'string' then return false end
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

do
    local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local decmap = {}
    for i = 1, #b64chars do
        decmap[b64chars:byte(i)] = i - 1
    end
    decmap[('='):byte()] = 0

    --- 高速 Base64 デコード。失敗時 nil。
    ---@param data string
    ---@return string|nil
    function PolaPaintUtil.b64decode(data)
        if type(data) ~= 'string' or data == '' then return nil end
        -- 改行・空白除去
        data = data:gsub('[\r\n\t ]', '')
        local len = #data
        if len % 4 ~= 0 then return nil end

        local pad = 0
        if data:sub(-1) == '=' then pad = 1 end
        if data:sub(-2) == '==' then pad = 2 end

        local out = {}
        local outIdx = 0
        local byte = string.byte
        local char = string.char

        for i = 1, len, 4 do
            local c1 = decmap[byte(data, i)]
            local c2 = decmap[byte(data, i + 1)]
            local c3 = decmap[byte(data, i + 2)]
            local c4 = decmap[byte(data, i + 3)]
            if not (c1 and c2 and c3 and c4) then return nil end

            local n = c1 * 0x40000 + c2 * 0x1000 + c3 * 0x40 + c4
            outIdx = outIdx + 1
            out[outIdx] = char(
                (n >> 16) & 0xFF,
                (n >> 8) & 0xFF,
                n & 0xFF
            )
        end

        local result = table.concat(out)
        if pad > 0 then
            result = result:sub(1, #result - pad)
        end
        return result
    end
end

--- ロケール参照
---@param key string
function PolaPaintUtil.L(key)
    local pack = Locales and Locales[Config.Locale or 'ja']
    if type(pack) == 'table' and pack[key] then return pack[key] end
    return key
end
