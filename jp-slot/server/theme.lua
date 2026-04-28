-- アクティブテーマの保存・検証・配信ヘルパー
Theme = {}

local KVP_ACTIVE = 'jp-slot:theme:active'

--- 現在適用中のテーマ（無ければ DefaultTheme）
---@return table
function Theme.getActive()
    local raw = GetResourceKvpString(KVP_ACTIVE)
    if raw and raw ~= '' then
        local ok, decoded = pcall(json.decode, raw)
        if ok and type(decoded) == 'table' then
            return decoded
        end
    end
    return Config.DefaultTheme
end

--- 簡易バリデーション（必須キーのみ）
---@param data table|nil
---@return boolean
function Theme.validate(data)
    if type(data) ~= 'table' then
        return false
    end
    if type(data.colors) ~= 'table' or type(data.fonts) ~= 'table' then
        return false
    end
    return true
end

--- テーマ保存し全クライアントへ反映
---@param themeData table
---@return boolean
function Theme.save(themeData)
    if not Theme.validate(themeData) then
        return false
    end
    SetResourceKvp(KVP_ACTIVE, json.encode(themeData))
    TriggerClientEvent('jp-slot:themeUpdated', -1, themeData)
    return true
end
