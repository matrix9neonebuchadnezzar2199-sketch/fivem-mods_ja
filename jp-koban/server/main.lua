-- jp-koban サーバー（DB なし。セッション中だけメモリで巡回状態を保持）

---@type table<integer, { count: number }>
local activePatrol = {}

local function clearPatrol(source)
    activePatrol[source] = nil
end

lib.callback.register('jp-koban:server:tryStartPatrol', function(source, count)
    if count ~= 5 and count ~= 10 then
        return false, 'invalid'
    end
    local player = exports.qbx_core:GetPlayer(source)
    if not player then
        return false, 'no_player'
    end
    local j = player.PlayerData.job
    if not j or j.name ~= Config.RequiredJob then
        return false, 'wrong_job'
    end
    if activePatrol[source] then
        return false, 'busy'
    end
    activePatrol[source] = { count = count }
    return true
end)

RegisterNetEvent('jp-koban:cancelPatrol', function()
    local src = source
    clearPatrol(src)
end)

RegisterNetEvent('jp-koban:completePatrol', function()
    local src = source
    local session = activePatrol[src]
    if not session then
        TriggerClientEvent('jp-koban:client:completeResult', src, { ok = false, reason = 'no_session' })
        return
    end
    local player = exports.qbx_core:GetPlayer(src)
    if not player then
        clearPatrol(src)
        return
    end
    if not player.PlayerData.job or player.PlayerData.job.name ~= Config.RequiredJob then
        clearPatrol(src)
        TriggerClientEvent('jp-koban:client:completeResult', src, { ok = false, reason = 'not_police' })
        return
    end
    local c = session.count
    local amount = (c == 10) and Config.CompletionBonus10 or Config.CompletionBonus5
    if c ~= 10 and c ~= 5 then
        clearPatrol(src)
        TriggerClientEvent('jp-koban:client:completeResult', src, { ok = false, reason = 'invalid' })
        return
    end
    player.Functions.AddMoney('cash', amount, 'patrol-bonus')
    clearPatrol(src)
    TriggerClientEvent('jp-koban:client:completeResult', src, { ok = true, amount = amount })
end)

AddEventHandler('playerDropped', function()
    local src = source
    if activePatrol[src] then
        clearPatrol(src)
    end
end)
