-- jp-mi-train サーバー側
-- 責務:
--   1. ヘイスト開始判定（クールダウン・既存ヘイスト中チェック）
--   2. 列車ホスト管理（最初の参加者を host に固定、切断時に再選出）
--   3. 参加者リスト（heist 中の権限管理）
--   4. 管理者コマンド (/mitrain)
-- 設計参考: TheNickoos/FiveM-Trains/server/server.lua（再選出ロジック）

---@class State
local State = {
    ---@type 'idle'|'active'
    phase = 'idle',

    ---@type integer|nil ヘイストを開始したプレイヤー（host 優先候補）
    initiator = nil,

    ---@type integer|nil 現在の列車ホスト（クライアント側の列車所有者）
    host = nil,

    ---@type table<integer, boolean> 参加者リスト
    participants = {},

    ---@type integer 最後にヘイストが終了した時刻（os.time() 秒）
    lastEndedAt = 0,

    ---@type integer|nil ヘイストの自動終了タイマー（CreateThread の運用フラグ）
    autoEndCancelled = false,

    ---@type number|nil 直近の列車 X（Blip 用キャッシュ）
    lastTrainX = nil,
    ---@type number|nil
    lastTrainY = nil,
    ---@type number|nil
    lastTrainZ = nil,
    ---@type boolean
    lastHasWagon = false,
    ---@type number|nil
    lastWagonX = nil,
    ---@type number|nil
    lastWagonY = nil,
    ---@type number|nil
    lastWagonZ = nil,

    ---@type boolean ホストが列車スポーン成功を報告したか
    trainReady = false,
}

-- ============================================================
-- ロガー
-- ============================================================

---@param msg string
local function log(msg)
    if Config.Debug then
        print(('[%s] %s'):format(GetCurrentResourceName(), msg))
    end
end

-- ============================================================
-- 内部ロジック
-- ============================================================

---@param src integer
---@return boolean isAdmin
local function IsAdmin(src)
    if not Config.Commands.adminAce then
        return true  -- ACE 未設定なら全員許可（MVP）
    end
    return IsPlayerAceAllowed(src, Config.Commands.adminAce)
end

---@return boolean canStart
---@return string|nil reasonKey 失敗理由（クライアントに返すキー）
local function CanStartHeist()
    if State.phase ~= 'idle' then
        return false, 'already_active'
    end
    local elapsed = os.time() - State.lastEndedAt
    if elapsed < math.floor(Config.Heist.cooldownMs / 1000) then
        return false, 'cooldown'
    end
    return true, nil
end

---@param newHost integer
local function PromoteHost(newHost)
    State.host = newHost
    TriggerClientEvent('jp-mi-train:becomeHost', newHost)
    log(('host promoted to %s (%d)'):format(GetPlayerName(newHost) or '?', newHost))
end

local function ChooseNewHost(excludeSrc)
    -- 優先順位: initiator > 既存 participants > 残存プレイヤー
    if State.initiator and State.initiator ~= excludeSrc and GetPlayerName(State.initiator) then
        PromoteHost(State.initiator)
        return
    end
    for participant in pairs(State.participants) do
        if participant ~= excludeSrc and GetPlayerName(participant) then
            PromoteHost(participant)
            return
        end
    end
    for _, pid in ipairs(GetPlayers()) do
        local p = tonumber(pid)
        if p and p ~= excludeSrc then
            PromoteHost(p)
            return
        end
    end
    -- 誰もいなければ列車を畳む
    log('no host candidate found, ending heist')
    State.phase = 'idle'
    State.host = nil
end

---@param src integer ヘイストを開始するプレイヤー
local function StartHeistInternal(src)
    State.phase = 'active'
    State.initiator = src
    State.host = src
    State.participants[src] = true
    State.autoEndCancelled = false

    -- ホストクライアントに列車生成を依頼
    TriggerClientEvent('jp-mi-train:becomeHost', src)
    -- 全クライアントにヘイスト開始通知
    TriggerClientEvent('jp-mi-train:heistStarted', -1, src)
    -- 列車スポーン前でも MAP に仮 Blip（スポーン地点）
    local spawn = Config.Train.spawn
    TriggerClientEvent('jp-mi-train:heistBlipBootstrap', -1, spawn.x, spawn.y, spawn.z)

    log(('heist started by %s (%d)'):format(GetPlayerName(src) or '?', src))

    -- 自動終了タイマー
    Citizen.SetTimeout(Config.Heist.maxDurationMs, function()
        if State.autoEndCancelled then return end
        if State.phase == 'active' then
            log('heist auto-ended (max duration)')
            EndHeistInternal('timeout')
        end
    end)
end

---@param reason string 'success' | 'timeout' | 'admin' | 'no_host'
function EndHeistInternal(reason)
    if State.phase ~= 'active' then return end
    State.phase = 'idle'
    State.host = nil
    State.initiator = nil
    State.participants = {}
    State.lastEndedAt = os.time()
    State.autoEndCancelled = true
    State.lastTrainX = nil
    State.lastTrainY = nil
    State.lastTrainZ = nil
    State.lastHasWagon = false
    State.lastWagonX = nil
    State.lastWagonY = nil
    State.lastWagonZ = nil
    State.trainReady = false

    TriggerClientEvent('jp-mi-train:heistEnded', -1, reason)
    log(('heist ended (reason=%s)'):format(reason))
end

-- ============================================================
-- net イベント
-- ============================================================

-- クライアント → サーバー: ヘイスト開始要求（受注 NPC または管理者コマンド）
RegisterNetEvent('jp-mi-train:requestStart', function()
    local src = source
    if not src or src <= 0 then return end

    local ok, reason = CanStartHeist()
    if not ok then
        TriggerClientEvent('jp-mi-train:startRejected', src, reason)
        return
    end

    StartHeistInternal(src)
end)

-- 受注 NPC からのリセット（進行中ヘイストを中断）
RegisterNetEvent('jp-mi-train:requestReset', function()
    local src = source
    if not src or src <= 0 then return end

    if State.phase ~= 'active' then
        TriggerClientEvent('jp-mi-train:notify', src, '進行中のヘイストはありません', 'error')
        return
    end

    local allowAnyone = Config.Heist and Config.Heist.resetAllowAnyone == true
    local canReset = allowAnyone
        or State.participants[src]
        or src == State.initiator
        or IsAdmin(src)

    if not canReset then
        TriggerClientEvent('jp-mi-train:startRejected', src, 'reset_denied')
        return
    end

    log(('heist reset requested by %s (%d)'):format(GetPlayerName(src) or '?', src))
    -- 先に全クライアントで降車・コリジョン復帰（即 DeleteMissionTrain より前）
    TriggerClientEvent('jp-mi-train:prepareReset', -1)
    Citizen.SetTimeout(300, function()
        if State.phase == 'active' then
            EndHeistInternal('reset')
        end
    end)
end)

-- クライアント → サーバー: ヘイストに参加表明（屋根に着地した瞬間など）
RegisterNetEvent('jp-mi-train:joinHeist', function()
    local src = source
    if not src or src <= 0 then return end
    if State.phase ~= 'active' then return end
    State.participants[src] = true
    log(('participant joined: %s (%d)'):format(GetPlayerName(src) or '?', src))
end)

-- クライアント → サーバー: ホストが列車座標を報告（Blip 更新用）
-- 全クライアントへリレーする。ホスト以外からの送信は無視（権威性確保）
RegisterNetEvent('jp-mi-train:reportTrainCoords', function(tx, ty, tz, hasLast, lx, ly, lz)
    local src = source
    if not src or src <= 0 then return end
    if State.phase ~= 'active' then return end
    if src ~= State.host then return end

    if type(tx) ~= 'number' or type(ty) ~= 'number' or type(tz) ~= 'number' then
        log(('reportTrainCoords ignored: invalid coords from %d'):format(src))
        return
    end

    State.lastTrainX = tx
    State.lastTrainY = ty
    State.lastTrainZ = tz
    State.lastHasWagon = hasLast == true
    if State.lastHasWagon then
        State.lastWagonX = lx
        State.lastWagonY = ly
        State.lastWagonZ = lz
    end

    TriggerClientEvent('jp-mi-train:trainCoordsUpdate', -1,
        tx, ty, tz,
        State.lastHasWagon,
        State.lastWagonX or 0.0, State.lastWagonY or 0.0, State.lastWagonZ or 0.0)
end)

-- クライアント → サーバー: ホストが列車スポーンに成功
RegisterNetEvent('jp-mi-train:hostReportSpawnOk', function(wagonCount)
    local src = source
    if not src or src <= 0 then return end
    if State.phase ~= 'active' then return end
    if src ~= State.host then return end

    State.trainReady = true
    log(('train ready: %d wagons reported by host %d'):format(tonumber(wagonCount) or 0, src))
    TriggerClientEvent('jp-mi-train:trainReady', -1, tonumber(wagonCount) or 0)
end)

-- クライアント → サーバー: ホストが列車を畳んだ（クリーンアップ完了）
RegisterNetEvent('jp-mi-train:hostReportEnd', function(reason)
    local src = source
    if not src or src <= 0 then return end
    if src ~= State.host then
        log(('hostReportEnd ignored: src=%d host=%s'):format(src, tostring(State.host)))
        return
    end
    EndHeistInternal(tostring(reason or 'host_ended'))
end)

-- ============================================================
-- playerDropped: ホスト切断時の再選出
-- ============================================================

AddEventHandler('playerDropped', function()
    local src = source
    State.participants[src] = nil

    if State.host == src and State.phase == 'active' then
        log(('host %d dropped during heist, choosing new host'):format(src))
        ChooseNewHost(src)
        if not State.host then
            EndHeistInternal('no_host')
        end
    end
end)

-- ============================================================
-- 管理者コマンド /mitrain
-- ============================================================

if Config.Commands.enableAdminCommand then
    RegisterCommand('mitrain', function(source, args)
        local src = tonumber(source) or 0

        if src ~= 0 and not IsAdmin(src) then
            TriggerClientEvent('jp-mi-train:notify', src, '権限がありません', 'error')
            return
        end

        local sub = args[1] or 'status'

        if sub == 'start' then
            if src == 0 then
                -- コンソール起動: 任意の最初のプレイヤーをホストに
                local players = GetPlayers()
                if #players == 0 then
                    print('[jp-mi-train] no player online, cannot start')
                    return
                end
                local first = tonumber(players[1])
                if not first then return end
                if State.phase == 'active' then
                    print('[jp-mi-train] already active')
                    return
                end
                StartHeistInternal(first)
            else
                local ok, reason = CanStartHeist()
                if not ok then
                    TriggerClientEvent('jp-mi-train:notify', src,
                        ('開始不可: %s'):format(reason or 'unknown'), 'error')
                    return
                end
                StartHeistInternal(src)
            end

        elseif sub == 'stop' then
            EndHeistInternal('admin')
            if src ~= 0 then
                TriggerClientEvent('jp-mi-train:notify', src, 'ヘイストを強制終了しました', 'inform')
            end

        elseif sub == 'status' then
            local msg = ('phase=%s host=%s participants=%d')
                :format(State.phase, tostring(State.host), table.count and table.count(State.participants) or 0)
            if src == 0 then
                print('[jp-mi-train] ' .. msg)
            else
                TriggerClientEvent('jp-mi-train:notify', src, msg, 'inform')
            end

        else
            local help = '/mitrain start | stop | status'
            if src == 0 then
                print('[jp-mi-train] ' .. help)
            else
                TriggerClientEvent('jp-mi-train:notify', src, help, 'inform')
            end
        end
    end, false)
end

-- ============================================================
-- リソース停止時クリーンアップ
-- ============================================================

AddEventHandler('onResourceStop', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    if State.phase == 'active' then
        TriggerClientEvent('jp-mi-train:heistEnded', -1, 'resource_stop')
    end
end)

-- ============================================================
-- 起動ログ
-- ============================================================

log(('jp-mi-train server started (cooldown=%ds, maxDur=%ds)')
    :format(math.floor(Config.Heist.cooldownMs / 1000),
            math.floor(Config.Heist.maxDurationMs / 1000)))
