-- jp-LetterCarrier サーバー（スタンドアロン・引数は必ず検証）
local PlayerJobs = {}

-- 受注中ジョブを解放
---@param src number
local function clearJobState(src)
    if src and PlayerJobs[src] then
        PlayerJobs[src] = nil
    end
end

-- 1〜n の重複なし乱数インデックスを取得
---@param need number
---@return table|nil
local function drawUniqueIndices(need)
    local max = #Config.DeliveryLocations
    if need > max or need < 1 then
        return nil
    end
    local pool = {}
    for i = 1, max do
        pool[i] = i
    end
    for i = max, 2, -1 do
        local j = math.random(i)
        pool[i], pool[j] = pool[j], pool[i]
    end
    local res = {}
    for i = 1, need do
        res[i] = pool[i]
    end
    return res
end

---@param count number
---@return number
local function completionBonusFor(count)
    if count == 5 then
        return Config.CompletionBonus5
    end
    if count == 10 then
        return Config.CompletionBonus10
    end
    if count == 20 then
        return Config.CompletionBonus20
    end
    return 0
end

---@param source number
---@param amount number
local function GiveMoney(source, amount)
    if not source or not amount or amount < 0 then
        print(('[jp-LetterCarrier] GiveMoney skipped invalid args source=%s amount=%s'):format(tostring(source), tostring(amount)))
        return
    end
    print(('[jp-LetterCarrier] GiveMoney requested source=%s amount=%s'):format(source, amount))
    local ok1, ESX = pcall(function()
        return exports['es_extended']:getSharedObject()
    end)
    if ok1 and ESX then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer and xPlayer.addMoney then
            xPlayer.addMoney(amount)
            print(('[jp-LetterCarrier] GiveMoney ESX addMoney success source=%s amount=%s'):format(source, amount))
            return
        end
    end
    local ok2, QBCore = pcall(function()
        return exports['qb-core']:GetCoreObject()
    end)
    if ok2 and QBCore and QBCore.Functions then
        local p = QBCore.Functions.GetPlayer(source)
        if p and p.Functions and p.Functions.AddMoney then
            p.Functions.AddMoney('cash', amount, 'jp-LetterCarrier')
            print(('[jp-LetterCarrier] GiveMoney QBCore AddMoney success source=%s amount=%s'):format(source, amount))
            return
        end
    end
    print(('[jp-LetterCarrier] GiveMoney fallback: $%s to player %s'):format(amount, source))
    TriggerClientEvent('chat:addMessage', source, {
        args = { '配達', ('報酬: $%s（経済システム未検出のため仮通知）'):format(amount) }
    })
end

RegisterNetEvent('jp-LetterCarrier:startJob', function(count)
    local source = source
    local c = type(count) == 'number' and math.floor(count) or 0
    if c ~= 5 and c ~= 10 and c ~= 20 then
        return
    end
    if PlayerJobs[source] and PlayerJobs[source].active then
        return
    end
    local indices = drawUniqueIndices(c)
    if not indices then
        return
    end
    local locs = {}
    for i = 1, #indices do
        local cfgI = indices[i]
        local v = Config.DeliveryLocations[cfgI]
        if not v then
            return
        end
        locs[i] = { x = v.x, y = v.y, z = v.z, slot = i }
    end
    local completed = {}
    for i = 1, c do
        completed[i] = false
    end
    PlayerJobs[source] = {
        active = true,
        courseSize = c,
        total = c,
        completed = completed,
        locations = locs,
        rewardAccum = 0,
        readyToReport = false,
        pendingBonus = completionBonusFor(c)
    }
    TriggerClientEvent('jp-LetterCarrier:clientJobData', source, {
        courseSize = c,
        total = c,
        locations = locs,
        rewardPer = Config.RewardPerDelivery,
        bonus = completionBonusFor(c)
    })
end)

RegisterNetEvent('jp-LetterCarrier:deliveryComplete', function(shopIndex)
    local source = source
    print(('[jp-LetterCarrier] deliveryComplete from player %s slot=%s'):format(source, tostring(shopIndex)))
    local job = PlayerJobs[source]
    if not job or not job.active then
        print(('[jp-LetterCarrier] deliveryComplete ignored (no active job) source=%s'):format(source))
        return
    end
    local i = type(shopIndex) == 'number' and math.floor(shopIndex) or 0
    if i < 1 or i > job.total then
        print(('[jp-LetterCarrier] deliveryComplete invalid slot source=%s slot=%s total=%s'):format(source, tostring(i), tostring(job.total)))
        return
    end
    if job.completed[i] then
        print(('[jp-LetterCarrier] deliveryComplete duplicate source=%s slot=%s'):format(source, i))
        return
    end
    if job.readyToReport then
        print(('[jp-LetterCarrier] deliveryComplete ignored (waiting report) source=%s'):format(source))
        return
    end
    -- 位置はクライアント主役のため、スタンドアロンでは厳格な 3D 照合は省略（同じ index の二重完了は防止済み）
    job.completed[i] = true
    local pay = Config.RewardPerDelivery
    job.rewardAccum = (job.rewardAccum or 0) + pay
    GiveMoney(source, pay)
    local done = 0
    for n = 1, job.total do
        if job.completed[n] then
            done = done + 1
        end
    end
    TriggerClientEvent('jp-LetterCarrier:deliveryResult', source, { completed = done, total = job.total, paid = pay })
    TriggerClientEvent('chat:addMessage', source, {
        args = { '配達', ('配達完了！$%s を受け取りました（%s/%s件）'):format(pay, done, job.total) }
    })
    if done < job.total then
        return
    end
    -- 全件配達後は「報告待ち」へ遷移（即完了しない）
    local bonus = job.pendingBonus or completionBonusFor(job.total)
    job.readyToReport = true
    print(('[jp-LetterCarrier] all deliveries done, waiting report source=%s total=%s bonus=%s'):format(source, job.total, bonus))
    TriggerClientEvent('jp-LetterCarrier:readyToReport', source, { total = job.total, bonus = bonus })
    TriggerClientEvent('chat:addMessage', source, {
        args = { '配達', ('全配達完了！受注担当へ報告してください（完遂ボーナス $%s）'):format(bonus) }
    })
end)

RegisterNetEvent('jp-LetterCarrier:reportCompletion', function()
    local source = source
    local job = PlayerJobs[source]
    print(('[jp-LetterCarrier] reportCompletion from player %s'):format(source))
    if not job or not job.active then
        print(('[jp-LetterCarrier] reportCompletion ignored (no active job) source=%s'):format(source))
        return
    end
    if not job.readyToReport then
        print(('[jp-LetterCarrier] reportCompletion ignored (not ready) source=%s'):format(source))
        return
    end
    local bonus = job.pendingBonus or completionBonusFor(job.total)
    local totalC = job.total
    GiveMoney(source, bonus)
    PlayerJobs[source] = nil
    TriggerClientEvent('jp-LetterCarrier:allDeliveriesDone', source, { completed = totalC, total = totalC, bonus = bonus })
    TriggerClientEvent('chat:addMessage', source, {
        args = { '配達', ('報告完了！完遂ボーナス $%s を受け取りました！'):format(bonus) }
    })
end)

RegisterNetEvent('jp-LetterCarrier:resetJob', function()
    local source = source
    if PlayerJobs[source] and PlayerJobs[source].active then
        clearJobState(source)
    end
    TriggerClientEvent('jp-LetterCarrier:forceReset', source, { reason = 'reset' })
end)

RegisterNetEvent('jp-LetterCarrier:cancelJob', function()
    local source = source
    if PlayerJobs[source] and PlayerJobs[source].active then
        clearJobState(source)
    end
    TriggerClientEvent('jp-LetterCarrier:forceReset', source, { reason = 'cancel' })
end)

AddEventHandler('playerDropped', function()
    local s = source
    clearJobState(s)
end)
