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

--- サーバー専用。クライアント側からは呼ばないこと（GetPlayerName / exports は server context 依存）。
--- 戻り値: string（必ず非空。最終フォールバックでも `player:<src>` を返す）
--- 用途: `tcg_players.display_name` の UPSERT、ランキング表示の名前ソース。
--- @param src number
--- @return string
function GetPlayerDisplayName(src)
    if not src or src == 0 then
        return 'console'
    end

    local okQbx, qbxName = pcall(function()
        if exports and exports['qbx_core'] and exports['qbx_core'].GetPlayer then
            local p = exports['qbx_core']:GetPlayer(src)
            if p and p.PlayerData and p.PlayerData.charinfo then
                local ci = p.PlayerData.charinfo
                local fn = ci.firstname or ''
                local ln = ci.lastname or ''
                local n = (fn .. ' ' .. ln):gsub('^%s+', ''):gsub('%s+$', '')
                if n ~= '' then
                    return n
                end
            end
        end
        return nil
    end)
    if okQbx and qbxName and qbxName ~= '' then
        return qbxName
    end

    local okQb, qbName = pcall(function()
        if exports and exports['qb-core'] and exports['qb-core'].GetCoreObject then
            local QB = exports['qb-core']:GetCoreObject()
            local p = QB and QB.Functions and QB.Functions.GetPlayer and QB.Functions.GetPlayer(src)
            if p and p.PlayerData and p.PlayerData.charinfo then
                local ci = p.PlayerData.charinfo
                local fn = ci.firstname or ''
                local ln = ci.lastname or ''
                local n = (fn .. ' ' .. ln):gsub('^%s+', ''):gsub('%s+$', '')
                if n ~= '' then
                    return n
                end
            end
        end
        return nil
    end)
    if okQb and qbName and qbName ~= '' then
        return qbName
    end

    local okEsx, esxName = pcall(function()
        if ESX and ESX.GetPlayerFromId then
            local xp = ESX.GetPlayerFromId(src)
            if xp and xp.getName then
                local n = xp.getName()
                if n and n ~= '' then
                    return n
                end
            end
        end
        return nil
    end)
    if okEsx and esxName and esxName ~= '' then
        return esxName
    end

    local connName = GetPlayerName(src)
    if connName and connName ~= '' then
        return connName
    end

    return 'player:' .. tostring(src)
end
