-- jp-mi-train クライアント側: ステートマシン統合
-- 責務:
--   1. リソース起動時の受注 NPC スポーン
--   2. サーバーからの net イベントをディスパッチ
--   3. 全体クリーンアップ
-- 注意: 本ファイルは fxmanifest の client_scripts で **最後** に読み込まれる
--        train / heli_board / start_npc が _G.MiTrain / MiTrainHeli / MiTrainNpc を定義済み前提

---@class MiTrainClientState
local ClientState = {
    heistActive = false,
}

---@param msg string
local function log(msg)
    if Config.Debug then
        print(('[%s/main] %s'):format(GetCurrentResourceName(), msg))
    end
end

---@return boolean
function ClientState.IsHeistActive()
    return ClientState.heistActive
end

_G.MiTrainClient = ClientState

-- ============================================================
-- 通知ラッパー
-- ============================================================

RegisterNetEvent('jp-mi-train:notify', function(message, msgType)
    lib.notify({
        type = msgType or 'inform',
        description = message,
    })
end)

-- ============================================================
-- 起動時: 受注 NPC をスポーン
-- ============================================================

Citizen.CreateThread(function()
    -- 他リソースの初期化を待つ
    Wait(1000)
    if _G.MiTrainNpc then
        _G.MiTrainNpc.Spawn()
    end
end)

-- ============================================================
-- サーバー → クライアント イベント
-- ============================================================

-- ヘイスト開始拒否
RegisterNetEvent('jp-mi-train:startRejected', function(reason)
    local messages = {
        already_active = 'すでに別のヘイストが進行中です',
        cooldown       = 'まだ次のヘイストを受注できません',
        reset_denied   = 'リセットできません（進行中のヘイストに参加していない）',
    }
    lib.notify({
        type = 'error',
        title = 'MI Train',
        description = messages[reason] or ('開始不可: ' .. tostring(reason)),
    })
end)

-- ヘイスト開始（全クライアントに broadcast）
RegisterNetEvent('jp-mi-train:heistStarted', function(initiatorSrc)
    ClientState.heistActive = true
    log(('heist started (initiator src=%s)'):format(tostring(initiatorSrc)))

    lib.notify({
        type = 'inform',
        title = 'MI Train',
        description = '列車ヘイストが始動した。ヘリで最後尾（客車）に接近し [E] で車内に飛び込め。',
        duration = 8000,
    })

    -- 全クライアントでヘリ侵入監視を起動
    if _G.MiTrainHeli then
        _G.MiTrainHeli.Start()
    end
end)

-- 列車スポーン成功（全クライアント）
RegisterNetEvent('jp-mi-train:trainReady', function(wagonCount)
    log(('train ready (%d wagons)'):format(tonumber(wagonCount) or 0))
    lib.notify({
        type = 'success',
        title = 'MI Train',
        description = '目標列車が走行を開始した。マップの赤 Blip / 黄色サークルが有効になった。',
        duration = 7000,
    })
end)

-- ホスト昇格（このクライアントが列車を生成する）
RegisterNetEvent('jp-mi-train:becomeHost', function()
    log('becomeHost received')
    if _G.MiTrain then
        _G.MiTrain.BecomeHost()
    end
end)

-- リセット直前: 車内コリジョン解除・安全降車
RegisterNetEvent('jp-mi-train:prepareReset', function()
    log('prepareReset: safe exit train')
    if _G.MiTrainHeli then
        _G.MiTrainHeli.SafeExitTrain()
    end
end)

-- ヘイスト終了（全クライアントに broadcast）
RegisterNetEvent('jp-mi-train:heistEnded', function(reason)
    ClientState.heistActive = false
    log(('heist ended (reason=%s)'):format(tostring(reason)))

    if _G.MiTrainHeli then
        _G.MiTrainHeli.SafeExitTrain()
    end

    local messages = {
        success      = 'ヘイスト成功',
        reset        = 'ヘイストをリセットした',
        reset_denied = 'リセットできません（進行中のヘイストに参加していない）',
        timeout      = '時間切れ。ヘイストは中断された',
        admin        = '管理者がヘイストを終了した',
        no_host      = 'ホスト不在。ヘイストは中断',
        train_lost   = '列車のロード解除。ヘイストを中断',
        spawn_failed = '列車のスポーンに失敗（貨車モデル未ロードの可能性。ensure 再起動後に再試行）',
        host_ended   = 'ホストがヘイストを終了した',
        resource_stop = 'リソース停止によりヘイストを中断',
    }
    lib.notify({
        type = (reason == 'success') and 'success' or 'inform',
        title = 'MI Train',
        description = messages[reason] or ('終了: ' .. tostring(reason)),
        duration = 6000,
    })

    -- 全モジュールをクリーンアップ
    if _G.MiTrainHeli then _G.MiTrainHeli.Stop() end
    if _G.MiTrain then _G.MiTrain.Cleanup() end
    if _G.MiTrainBlip then _G.MiTrainBlip.Cleanup() end
end)

-- ============================================================
-- リソース停止時クリーンアップ
-- ============================================================

AddEventHandler('onResourceStop', function(resName)
    if resName ~= GetCurrentResourceName() then return end

    if _G.MiTrainHeli then
        _G.MiTrainHeli.SafeExitTrain()
        _G.MiTrainHeli.Stop()
    end
    if _G.MiTrain then _G.MiTrain.Cleanup() end
    if _G.MiTrainBlip then _G.MiTrainBlip.Cleanup() end
    if _G.MiTrainNpc then _G.MiTrainNpc.Cleanup() end

    -- NUI フォーカスやテキスト UI のリセット
    pcall(function() lib.hideTextUI() end)

    -- 屋根アタッチ解除
    local ped = PlayerPedId()
    if IsEntityAttachedToAnyVehicle(ped) then
        DetachEntity(ped, true, true)
    end
end)

log('jp-mi-train client initialized')
