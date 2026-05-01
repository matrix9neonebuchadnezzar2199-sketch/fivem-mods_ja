--- プレイヤー一意キー（DB列 citizenid に保存する値）
--- フレームワーク非依存。将来 QBCore 等に合わせる場合はこの関数のみ差し替え。
--- @param source number サーバー側のプレイヤー source
--- @return string|nil
function GetPlayerUid(source)
    if type(source) ~= 'number' or source <= 0 then
        return nil
    end

    -- クライアントでは識別子取得ができないため nil
    if not IsDuplicityVersion() then
        return nil
    end

    local license = GetPlayerIdentifierByType(source, 'license')
    if license and license ~= '' then
        return license
    end

    local discord = GetPlayerIdentifierByType(source, 'discord')
    if discord and discord ~= '' then
        return discord
    end

    local fivem = GetPlayerIdentifierByType(source, 'fivem')
    if fivem and fivem ~= '' then
        return fivem
    end

    local steam = GetPlayerIdentifierByType(source, 'steam')
    if steam and steam ~= '' then
        return steam
    end

    return nil
end
